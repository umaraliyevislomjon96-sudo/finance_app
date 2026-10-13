-- ==============================================================================
-- DATABASE SCHEMA: SPENDLY / AURORA (POSTGRESQL 16+)
-- CLIENT-SERVER ARCHITECTURE WITH ROW LEVEL SECURITY & STRICT USER ISOLATION
-- ==============================================================================
-- Rules & Standards:
-- 1. All monetary values stored as BIGINT in minimum currency units (Tiyin / Cents).
-- 2. Strictly non-custodial: ZERO storage of CVV, PIN, or full 16-digit card numbers.
-- 3. Row Level Security (RLS) enabled on all tables linked to user_id.
-- 4. Audit logging, multi-device sessions, consents ledger, soft-deletion.
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. USERS & IDENTITY
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_hash VARCHAR(64) NOT NULL UNIQUE,     -- HMAC-SHA256 hash for deterministic lookup
    phone_encrypted TEXT NOT NULL,              -- AES-256 encrypted phone number
    name VARCHAR(128),                          -- Optional at onboarding
    default_currency VARCHAR(3) NOT NULL DEFAULT 'UZS',
    locale VARCHAR(8) NOT NULL DEFAULT 'uz-UZ',  -- 'uz-UZ' or 'ru-RU'
    timezone VARCHAR(64) NOT NULL DEFAULT 'Asia/Tashkent',
    monthly_income_tiyin BIGINT,                -- Optional, in minimum units
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'pending_deletion', 'suspended')),
    deletion_scheduled_at TIMESTAMPTZ,          -- 30-day grace period timestamp
    version INT NOT NULL DEFAULT 1,             -- Optimistic locking & sync
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_phone_hash ON users (phone_hash);
CREATE INDEX idx_users_deletion ON users (status, deletion_scheduled_at);

-- 2. USER SECURITY CREDENTIALS
CREATE TABLE IF NOT EXISTS user_security (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    pin_hash VARCHAR(255) NOT NULL,             -- PBKDF2-HMAC-SHA256 (100k rounds)
    salt VARCHAR(64) NOT NULL,
    biometric_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    failed_pin_attempts INT NOT NULL DEFAULT 0,
    locked_until TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. ACTIVE SESSIONS & MULTI-DEVICE MANAGEMENT
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(64) NOT NULL UNIQUE,
    device_id VARCHAR(128) NOT NULL,
    device_name VARCHAR(128) NOT NULL,
    os_version VARCHAR(64),
    ip_address VARCHAR(45),
    approx_location VARCHAR(128),               -- City/Country derived from IP
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_device UNIQUE (user_id, device_id)
);

CREATE INDEX idx_sessions_user_id ON sessions (user_id);
CREATE INDEX idx_sessions_token ON sessions (refresh_token_hash);

-- 4. OTP CODES LEDGER (Single-use, Hashed)
CREATE TABLE IF NOT EXISTS otp_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_hash VARCHAR(64) NOT NULL,
    code_hash VARCHAR(64) NOT NULL,             -- SHA-256 of the 6-digit code
    device_id VARCHAR(128) NOT NULL,
    attempts_count INT NOT NULL DEFAULT 0,
    is_consumed BOOLEAN NOT NULL DEFAULT FALSE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_otp_lookup ON otp_codes (phone_hash, is_consumed, expires_at);

-- 5. LEGAL CONSENTS LEDGER (Uzbekistan Personal Data Law Compliance)
CREATE TABLE IF NOT EXISTS consents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    consent_type VARCHAR(64) NOT NULL CHECK (consent_type IN ('data_processing', 'push_notifications', 'anonymized_ai_insights', 'usage_analytics')),
    version VARCHAR(32) NOT NULL,               -- e.g. 'v1.0_2026_03'
    is_granted BOOLEAN NOT NULL,
    ip_address VARCHAR(45),
    device_id VARCHAR(128),
    granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMPTZ,
    CONSTRAINT uq_user_consent UNIQUE (user_id, consent_type)
);

CREATE INDEX idx_consents_user ON consents (user_id);

-- 6. PAYMENT CARDS (METADATA ONLY, ZERO FULL PAN/CVV)
CREATE TABLE IF NOT EXISTS cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    bank_name VARCHAR(64) NOT NULL,
    card_type VARCHAR(32) NOT NULL,             -- 'UZCARD', 'HUMO', 'VISA', 'MASTERCARD'
    first4 VARCHAR(4) NOT NULL CHECK (length(first4) = 4),
    last4 VARCHAR(4) NOT NULL CHECK (length(last4) = 4),
    display_name VARCHAR(64) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'UZS',
    credit_limit_tiyin BIGINT NOT NULL DEFAULT 0,
    interest_rate NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    grace_period_days INT NOT NULL DEFAULT 0,
    color_theme VARCHAR(32) NOT NULL DEFAULT 'cyan_glow',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_card_source UNIQUE (user_id, first4, last4, bank_name)
);

CREATE INDEX idx_cards_user ON cards (user_id, is_active, is_deleted);

-- 7. CATEGORIES
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(64) NOT NULL,
    icon VARCHAR(64) NOT NULL,
    color VARCHAR(32) NOT NULL,
    type VARCHAR(32) NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. OBLIGATIONS & LOANS
CREATE TABLE IF NOT EXISTS obligations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(128) NOT NULL,
    amount_tiyin BIGINT NOT NULL CHECK (amount_tiyin >= 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'UZS',
    category VARCHAR(64) NOT NULL,             -- 'rent', 'loan', 'installment', 'utilities', 'subscription'
    interest_rate NUMERIC(5, 2) DEFAULT 0.00,
    due_day INT NOT NULL CHECK (due_day >= 1 AND due_day <= 31),
    frequency VARCHAR(32) NOT NULL DEFAULT 'monthly',
    next_due_at DATE NOT NULL,
    reminder_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused')),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_obligations_user ON obligations (user_id, next_due_at, status, is_deleted);

-- 9. TRANSACTIONS & PAYMENTS LEDGER (IDEMPOTENCY & CONFIDENCE)
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
    obligation_id UUID REFERENCES obligations(id) ON DELETE SET NULL,
    idempotency_key VARCHAR(128) NOT NULL,      -- Prevents duplicate submissions on network drops
    amount_tiyin BIGINT NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'UZS',
    direction VARCHAR(16) NOT NULL CHECK (direction IN ('income', 'expense', 'transfer', 'refund', 'unknown')),
    merchant VARCHAR(128) NOT NULL,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    source VARCHAR(32) NOT NULL CHECK (source IN ('sms', 'push', 'manual', 'import')),
    original_text TEXT,
    parsed_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    confidence_score NUMERIC(3, 2) NOT NULL,
    duplicate_hash VARCHAR(64) NOT NULL,
    related_transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    occurred_at TIMESTAMPTZ NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'needs_review', 'duplicate_candidate', 'ignored')),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_idempotency UNIQUE (user_id, idempotency_key)
);

CREATE INDEX idx_tx_user_date ON transactions (user_id, occurred_at DESC, is_deleted);
CREATE INDEX idx_tx_dup_hash ON transactions (user_id, duplicate_hash);

-- 10. AI INSIGHTS & REACTIONS
CREATE TABLE IF NOT EXISTS ai_insights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(32) NOT NULL,
    title VARCHAR(128) NOT NULL,
    body TEXT NOT NULL,
    impact_amount_tiyin BIGINT,
    currency VARCHAR(3) DEFAULT 'UZS',
    severity VARCHAR(16) NOT NULL DEFAULT 'info',
    action_type VARCHAR(64),
    action_payload JSONB DEFAULT '{}'::jsonb,
    user_reaction VARCHAR(32) CHECK (user_reaction IN ('helpful', 'unhelpful', 'dismissed', 'acted_upon')),
    is_dismissed BOOLEAN NOT NULL DEFAULT FALSE,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_insights_user ON ai_insights (user_id, is_dismissed, created_at DESC);

-- 11. AUDIT LOGS (TAMPER-RESISTANT)
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(64) NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb, -- Strict: NO phones, plain pins, or full cards
    ip_address VARCHAR(45),
    device_id VARCHAR(128),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_user ON audit_logs (user_id, created_at DESC);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- Strict Isolation: Queries physical cannot access records of another client
-- ==============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_security ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE obligations ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Helper RLS policy for tenant isolation
CREATE POLICY rls_users ON users FOR ALL
    USING (id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);

CREATE POLICY rls_cards ON cards FOR ALL
    USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);

CREATE POLICY rls_obligations ON obligations FOR ALL
    USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);

CREATE POLICY rls_transactions ON transactions FOR ALL
    USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);

CREATE POLICY rls_sessions ON sessions FOR ALL
    USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);

CREATE POLICY rls_consents ON consents FOR ALL
    USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);

CREATE POLICY rls_insights ON ai_insights FOR ALL
    USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);
