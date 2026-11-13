-- 004: encrypted per-user backup of the app's local data (ledger, obligations,
-- cards, utilities), so reinstalling the app restores everything.
-- payload is AES-256-GCM ciphertext (base64); no SMS / notification texts.
-- The API also creates this table on first use (CREATE TABLE IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS user_data_backups (
    user_id     TEXT PRIMARY KEY,          -- usr_<keyed hash of phone number>
    payload     TEXT NOT NULL,
    version     INTEGER NOT NULL DEFAULT 1,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
