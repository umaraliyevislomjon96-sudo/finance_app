-- ==============================================================================
-- MIGRATION 002: AI PERSONAL FINANCIAL OPERATING SYSTEM (SUPABASE POSTGRESQL 16+)
-- 17 Core Tables, Foreign Keys, Indexes, RLS Policies, & User Isolation Enforcement
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 1. PROFILES
-- ==============================================================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name VARCHAR(64),
    last_name VARCHAR(64),
    display_name VARCHAR(128),
    avatar_url TEXT,
    phone VARCHAR(32),
    email VARCHAR(255),
    currency VARCHAR(3) NOT NULL DEFAULT 'UZS',
    language VARCHAR(8) NOT NULL DEFAULT 'ru',  -- 'ru', 'en', 'uz'
    timezone VARCHAR(64) NOT NULL DEFAULT 'Asia/Tashkent',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_user ON profiles(user_id);

-- ==============================================================================
-- 2. ACCOUNTS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(128) NOT NULL,
    type VARCHAR(32) NOT NULL CHECK (type IN ('bank', 'cash', 'savings', 'investment', 'other')),
    currency VARCHAR(3) NOT NULL DEFAULT 'UZS',
    balance BIGINT NOT NULL DEFAULT 0, -- Stored in minimum currency units (Tiyin / Cents)
    institution_name VARCHAR(128),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_accounts_user ON accounts(user_id, is_active);

-- ==============================================================================
-- 3. CARDS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
    name VARCHAR(128) NOT NULL,
    card_type VARCHAR(32) NOT NULL CHECK (card_type IN ('debit', 'credit', 'virtual', 'physical', 'other')),
    last4 VARCHAR(4) NOT NULL CHECK (length(last4) = 4),
    currency VARCHAR(3) NOT NULL DEFAULT 'UZS',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cards_user ON cards(user_id, is_active);

-- ==============================================================================
-- 4. CATEGORIES
-- ==============================================================================
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- NULL for system categories
    name VARCHAR(64) NOT NULL,
    code VARCHAR(64) NOT NULL, -- Language-neutral identifier: 'food', 'groceries', etc.
    icon VARCHAR(64) NOT NULL,
    color VARCHAR(32) NOT NULL,
    type VARCHAR(32) NOT NULL CHECK (type IN ('income', 'expense', 'transfer', 'neutral')),
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_categories_user ON categories(user_id, code);

-- ==============================================================================
-- 5. TRANSACTIONS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
    card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
    amount BIGINT NOT NULL, -- in minimum units (Tiyin / Cents)
    currency VARCHAR(3) NOT NULL DEFAULT 'UZS',
    transaction_type VARCHAR(64) NOT NULL,
    direction VARCHAR(16) NOT NULL CHECK (direction IN ('income', 'expense', 'neutral', 'transfer', 'refund')),
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    merchant_name VARCHAR(128) NOT NULL,
    description TEXT,
    transaction_date TIMESTAMPTZ NOT NULL,
    source VARCHAR(32) NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'bank_notification', 'sms', 'open_banking', 'csv_import')),
    source_app VARCHAR(128),
    external_id VARCHAR(128),
    notification_id UUID,
    raw_reference_hash VARCHAR(64),
    confidence_score NUMERIC(3, 2) NOT NULL DEFAULT 1.00,
    is_manual BOOLEAN NOT NULL DEFAULT FALSE,
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    is_internal_transfer BOOLEAN NOT NULL DEFAULT FALSE,
    is_refund BOOLEAN NOT NULL DEFAULT FALSE,
    original_transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tx_user_date ON transactions(user_id, transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_tx_user_type ON transactions(user_id, transaction_type);
CREATE INDEX IF NOT EXISTS idx_tx_user_cat ON transactions(user_id, category_id);
CREATE INDEX IF NOT EXISTS idx_tx_user_ref ON transactions(user_id, raw_reference_hash);

-- ==============================================================================
-- 6. BUDGETS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    amount BIGINT NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'UZS',
    period VARCHAR(32) NOT NULL DEFAULT 'monthly' CHECK (period IN ('weekly', 'monthly', 'quarterly', 'yearly')),
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_budgets_user ON budgets(user_id, category_id, is_active);

-- ==============================================================================
-- 7. GOALS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(128) NOT NULL,
    target_amount BIGINT NOT NULL,
    current_amount BIGINT NOT NULL DEFAULT 0,
    currency VARCHAR(3) NOT NULL DEFAULT 'UZS',
    target_date DATE,
    priority VARCHAR(16) NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status VARCHAR(32) NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'paused', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_goals_user ON goals(user_id, status);

-- ==============================================================================
-- 8. LOANS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS loans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(128) NOT NULL,
    principal_amount BIGINT NOT NULL,
    remaining_amount BIGINT NOT NULL,
    interest_rate NUMERIC(5, 2) NOT NULL,
    term_months INT NOT NULL,
    monthly_payment BIGINT NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'UZS',
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paid_off', 'defaulted')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_loans_user ON loans(user_id, status);

-- ==============================================================================
-- 9. CREDIT CARDS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS credit_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    credit_limit BIGINT NOT NULL,
    available_limit BIGINT NOT NULL,
    current_balance BIGINT NOT NULL DEFAULT 0,
    interest_rate NUMERIC(5, 2) NOT NULL,
    minimum_payment BIGINT NOT NULL,
    payment_due_date DATE NOT NULL,
    statement_date DATE,
    currency VARCHAR(3) NOT NULL DEFAULT 'UZS',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_credit_cards_user ON credit_cards(user_id, card_id);

-- ==============================================================================
-- 10. SUBSCRIPTIONS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(128) NOT NULL,
    merchant VARCHAR(128) NOT NULL,
    amount BIGINT NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'UZS',
    frequency VARCHAR(32) NOT NULL DEFAULT 'monthly' CHECK (frequency IN ('weekly', 'monthly', 'quarterly', 'yearly')),
    next_payment_date DATE NOT NULL,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id, is_active, next_payment_date);

-- ==============================================================================
-- 11. FINANCIAL SOURCES
-- ==============================================================================
CREATE TABLE IF NOT EXISTS financial_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    source_type VARCHAR(64) NOT NULL, -- 'android_notification_listener', 'bank_api', 'email', 'csv_import', 'manual'
    provider VARCHAR(64) NOT NULL,    -- 'click', 'payme', 'uzum', 'kapitalbank', etc.
    status VARCHAR(32) NOT NULL DEFAULT 'connected' CHECK (status IN ('connected', 'permission_required', 'disabled', 'error')),
    permission_status VARCHAR(32) NOT NULL DEFAULT 'granted',
    last_sync_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_source_provider UNIQUE (user_id, source_type, provider)
);

CREATE INDEX IF NOT EXISTS idx_sources_user ON financial_sources(user_id, status);

-- ==============================================================================
-- 12. NOTIFICATIONS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    source_app VARCHAR(128) NOT NULL,
    notification_type VARCHAR(64) NOT NULL,
    notification_hash VARCHAR(64) NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    processing_status VARCHAR(32) NOT NULL DEFAULT 'processed' CHECK (processing_status IN ('processed', 'rejected', 'duplicate', 'needs_review')),
    transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_notif_hash UNIQUE (user_id, notification_hash)
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, received_at DESC);

-- ==============================================================================
-- 13. AI MEMORY (PERSONALIZED PER USER, STRICTLY PRIVATE)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS ai_memory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    memory_type VARCHAR(64) NOT NULL, -- 'goal_intent', 'preference', 'budget_constraint', 'lifestyle_fact'
    content TEXT NOT NULL,
    importance INT NOT NULL DEFAULT 1 CHECK (importance BETWEEN 1 AND 5),
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_memory_user ON ai_memory(user_id, memory_type, importance DESC);

-- ==============================================================================
-- 14. AI INSIGHTS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS ai_insights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type VARCHAR(32) NOT NULL,
    title VARCHAR(128) NOT NULL,
    description TEXT NOT NULL,
    severity VARCHAR(16) NOT NULL DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'critical')),
    data_reference JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_insights_user ON ai_insights(user_id, is_read, created_at DESC);

-- ==============================================================================
-- 15. SETTINGS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    language VARCHAR(8) NOT NULL DEFAULT 'ru',
    currency VARCHAR(3) NOT NULL DEFAULT 'UZS',
    theme VARCHAR(16) NOT NULL DEFAULT 'dark',
    notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    ai_insights_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    ai_autopilot_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    weekly_report_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    ai_memory_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_settings_user ON settings(user_id);

-- ==============================================================================
-- 16. DEVICES
-- ==============================================================================
CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_name VARCHAR(128) NOT NULL,
    platform VARCHAR(32) NOT NULL, -- 'android', 'ios', 'web'
    device_identifier VARCHAR(128) NOT NULL,
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_device UNIQUE (user_id, device_identifier)
);

CREATE INDEX IF NOT EXISTS idx_devices_user ON devices(user_id);

-- ==============================================================================
-- 17. SECURITY EVENTS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS security_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_type VARCHAR(64) NOT NULL,
    ip_reference VARCHAR(45),
    device_reference VARCHAR(128),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_security_events_user ON security_events(user_id, created_at DESC);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- Strict Isolation: User A can NEVER query User B records.
-- Enforces: auth.uid() = user_id (or current_setting('app.current_user_id') fallback)
-- ==============================================================================

-- Helper function to resolve the acting user id
CREATE OR REPLACE FUNCTION current_auth_user_id() RETURNS UUID AS $$
BEGIN
    RETURN COALESCE(
        auth.uid(),
        NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid,
        NULLIF(current_setting('app.current_user_id', true), '')::uuid
    );
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Enable RLS on all 17 tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_memory ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_events ENABLE ROW LEVEL SECURITY;

-- 1. Profiles
DROP POLICY IF EXISTS rls_profiles_select ON profiles;
CREATE POLICY rls_profiles_select ON profiles FOR SELECT USING (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_profiles_insert ON profiles;
CREATE POLICY rls_profiles_insert ON profiles FOR INSERT WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_profiles_update ON profiles;
CREATE POLICY rls_profiles_update ON profiles FOR UPDATE USING (user_id = current_auth_user_id()) WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_profiles_delete ON profiles;
CREATE POLICY rls_profiles_delete ON profiles FOR DELETE USING (user_id = current_auth_user_id());

-- 2. Accounts
DROP POLICY IF EXISTS rls_accounts_select ON accounts;
CREATE POLICY rls_accounts_select ON accounts FOR SELECT USING (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_accounts_insert ON accounts;
CREATE POLICY rls_accounts_insert ON accounts FOR INSERT WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_accounts_update ON accounts;
CREATE POLICY rls_accounts_update ON accounts FOR UPDATE USING (user_id = current_auth_user_id()) WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_accounts_delete ON accounts;
CREATE POLICY rls_accounts_delete ON accounts FOR DELETE USING (user_id = current_auth_user_id());

-- 3. Cards
DROP POLICY IF EXISTS rls_cards_select ON cards;
CREATE POLICY rls_cards_select ON cards FOR SELECT USING (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_cards_insert ON cards;
CREATE POLICY rls_cards_insert ON cards FOR INSERT WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_cards_update ON cards;
CREATE POLICY rls_cards_update ON cards FOR UPDATE USING (user_id = current_auth_user_id()) WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_cards_delete ON cards;
CREATE POLICY rls_cards_delete ON cards FOR DELETE USING (user_id = current_auth_user_id());

-- 4. Categories (Allows viewing system categories OR user-owned categories)
DROP POLICY IF EXISTS rls_categories_select ON categories;
CREATE POLICY rls_categories_select ON categories FOR SELECT USING (is_system = TRUE OR user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_categories_insert ON categories;
CREATE POLICY rls_categories_insert ON categories FOR INSERT WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_categories_update ON categories;
CREATE POLICY rls_categories_update ON categories FOR UPDATE USING (user_id = current_auth_user_id()) WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_categories_delete ON categories;
CREATE POLICY rls_categories_delete ON categories FOR DELETE USING (user_id = current_auth_user_id());

-- 5. Transactions
DROP POLICY IF EXISTS rls_tx_select ON transactions;
CREATE POLICY rls_tx_select ON transactions FOR SELECT USING (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_tx_insert ON transactions;
CREATE POLICY rls_tx_insert ON transactions FOR INSERT WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_tx_update ON transactions;
CREATE POLICY rls_tx_update ON transactions FOR UPDATE USING (user_id = current_auth_user_id()) WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_tx_delete ON transactions;
CREATE POLICY rls_tx_delete ON transactions FOR DELETE USING (user_id = current_auth_user_id());

-- 6. Budgets
DROP POLICY IF EXISTS rls_budgets_select ON budgets;
CREATE POLICY rls_budgets_select ON budgets FOR SELECT USING (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_budgets_insert ON budgets;
CREATE POLICY rls_budgets_insert ON budgets FOR INSERT WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_budgets_update ON budgets;
CREATE POLICY rls_budgets_update ON budgets FOR UPDATE USING (user_id = current_auth_user_id()) WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_budgets_delete ON budgets;
CREATE POLICY rls_budgets_delete ON budgets FOR DELETE USING (user_id = current_auth_user_id());

-- 7. Goals
DROP POLICY IF EXISTS rls_goals_select ON goals;
CREATE POLICY rls_goals_select ON goals FOR SELECT USING (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_goals_insert ON goals;
CREATE POLICY rls_goals_insert ON goals FOR INSERT WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_goals_update ON goals;
CREATE POLICY rls_goals_update ON goals FOR UPDATE USING (user_id = current_auth_user_id()) WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_goals_delete ON goals;
CREATE POLICY rls_goals_delete ON goals FOR DELETE USING (user_id = current_auth_user_id());

-- 8. Loans
DROP POLICY IF EXISTS rls_loans_select ON loans;
CREATE POLICY rls_loans_select ON loans FOR SELECT USING (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_loans_insert ON loans;
CREATE POLICY rls_loans_insert ON loans FOR INSERT WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_loans_update ON loans;
CREATE POLICY rls_loans_update ON loans FOR UPDATE USING (user_id = current_auth_user_id()) WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_loans_delete ON loans;
CREATE POLICY rls_loans_delete ON loans FOR DELETE USING (user_id = current_auth_user_id());

-- 9. Credit Cards
DROP POLICY IF EXISTS rls_credit_cards_select ON credit_cards;
CREATE POLICY rls_credit_cards_select ON credit_cards FOR SELECT USING (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_credit_cards_insert ON credit_cards;
CREATE POLICY rls_credit_cards_insert ON credit_cards FOR INSERT WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_credit_cards_update ON credit_cards;
CREATE POLICY rls_credit_cards_update ON credit_cards FOR UPDATE USING (user_id = current_auth_user_id()) WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_credit_cards_delete ON credit_cards;
CREATE POLICY rls_credit_cards_delete ON credit_cards FOR DELETE USING (user_id = current_auth_user_id());

-- 10. Subscriptions
DROP POLICY IF EXISTS rls_subs_select ON subscriptions;
CREATE POLICY rls_subs_select ON subscriptions FOR SELECT USING (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_subs_insert ON subscriptions;
CREATE POLICY rls_subs_insert ON subscriptions FOR INSERT WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_subs_update ON subscriptions;
CREATE POLICY rls_subs_update ON subscriptions FOR UPDATE USING (user_id = current_auth_user_id()) WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_subs_delete ON subscriptions;
CREATE POLICY rls_subs_delete ON subscriptions FOR DELETE USING (user_id = current_auth_user_id());

-- 11. Financial Sources
DROP POLICY IF EXISTS rls_sources_select ON financial_sources;
CREATE POLICY rls_sources_select ON financial_sources FOR SELECT USING (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_sources_insert ON financial_sources;
CREATE POLICY rls_sources_insert ON financial_sources FOR INSERT WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_sources_update ON financial_sources;
CREATE POLICY rls_sources_update ON financial_sources FOR UPDATE USING (user_id = current_auth_user_id()) WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_sources_delete ON financial_sources;
CREATE POLICY rls_sources_delete ON financial_sources FOR DELETE USING (user_id = current_auth_user_id());

-- 12. Notifications
DROP POLICY IF EXISTS rls_notifs_select ON notifications;
CREATE POLICY rls_notifs_select ON notifications FOR SELECT USING (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_notifs_insert ON notifications;
CREATE POLICY rls_notifs_insert ON notifications FOR INSERT WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_notifs_update ON notifications;
CREATE POLICY rls_notifs_update ON notifications FOR UPDATE USING (user_id = current_auth_user_id()) WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_notifs_delete ON notifications;
CREATE POLICY rls_notifs_delete ON notifications FOR DELETE USING (user_id = current_auth_user_id());

-- 13. AI Memory
DROP POLICY IF EXISTS rls_ai_mem_select ON ai_memory;
CREATE POLICY rls_ai_mem_select ON ai_memory FOR SELECT USING (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_ai_mem_insert ON ai_memory;
CREATE POLICY rls_ai_mem_insert ON ai_memory FOR INSERT WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_ai_mem_update ON ai_memory;
CREATE POLICY rls_ai_mem_update ON ai_memory FOR UPDATE USING (user_id = current_auth_user_id()) WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_ai_mem_delete ON ai_memory;
CREATE POLICY rls_ai_mem_delete ON ai_memory FOR DELETE USING (user_id = current_auth_user_id());

-- 14. AI Insights
DROP POLICY IF EXISTS rls_ai_insights_select ON ai_insights;
CREATE POLICY rls_ai_insights_select ON ai_insights FOR SELECT USING (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_ai_insights_insert ON ai_insights;
CREATE POLICY rls_ai_insights_insert ON ai_insights FOR INSERT WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_ai_insights_update ON ai_insights;
CREATE POLICY rls_ai_insights_update ON ai_insights FOR UPDATE USING (user_id = current_auth_user_id()) WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_ai_insights_delete ON ai_insights;
CREATE POLICY rls_ai_insights_delete ON ai_insights FOR DELETE USING (user_id = current_auth_user_id());

-- 15. Settings
DROP POLICY IF EXISTS rls_settings_select ON settings;
CREATE POLICY rls_settings_select ON settings FOR SELECT USING (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_settings_insert ON settings;
CREATE POLICY rls_settings_insert ON settings FOR INSERT WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_settings_update ON settings;
CREATE POLICY rls_settings_update ON settings FOR UPDATE USING (user_id = current_auth_user_id()) WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_settings_delete ON settings;
CREATE POLICY rls_settings_delete ON settings FOR DELETE USING (user_id = current_auth_user_id());

-- 16. Devices
DROP POLICY IF EXISTS rls_devices_select ON devices;
CREATE POLICY rls_devices_select ON devices FOR SELECT USING (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_devices_insert ON devices;
CREATE POLICY rls_devices_insert ON devices FOR INSERT WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_devices_update ON devices;
CREATE POLICY rls_devices_update ON devices FOR UPDATE USING (user_id = current_auth_user_id()) WITH CHECK (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_devices_delete ON devices;
CREATE POLICY rls_devices_delete ON devices FOR DELETE USING (user_id = current_auth_user_id());

-- 17. Security Events
DROP POLICY IF EXISTS rls_sec_events_select ON security_events;
CREATE POLICY rls_sec_events_select ON security_events FOR SELECT USING (user_id = current_auth_user_id());
DROP POLICY IF EXISTS rls_sec_events_insert ON security_events;
CREATE POLICY rls_sec_events_insert ON security_events FOR INSERT WITH CHECK (user_id = current_auth_user_id());
