-- ─────────────────────────────────────────────
-- PDF Tools Platform — PostgreSQL Schema
-- ─────────────────────────────────────────────

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── Users ───────────────────────────────────
CREATE TABLE users (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email       TEXT UNIQUE NOT NULL,
  name        TEXT,
  avatar_url  TEXT,
  provider    TEXT DEFAULT 'email',   -- 'email' | 'google'
  password_hash TEXT,                 -- NULL for OAuth users
  plan        TEXT DEFAULT 'free',    -- 'free' | 'premium'
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Processing Jobs ─────────────────────────
CREATE TABLE processing_jobs (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID REFERENCES users(id) ON DELETE SET NULL,
  tool_id       TEXT NOT NULL,              -- 'merge' | 'split' | 'compress' ...
  status        TEXT DEFAULT 'pending',     -- 'pending' | 'processing' | 'done' | 'error'
  input_files   JSONB,                      -- [{name, size, path}]
  output_file   TEXT,                       -- server temp path
  output_name   TEXT,                       -- download filename
  error_message TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  expires_at    TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '1 hour')
);

-- ─── Subscriptions ───────────────────────────
CREATE TABLE subscriptions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  plan        TEXT NOT NULL,              -- 'monthly' | 'yearly'
  status      TEXT DEFAULT 'active',     -- 'active' | 'cancelled' | 'expired'
  stripe_id   TEXT,
  started_at  TIMESTAMPTZ DEFAULT NOW(),
  expires_at  TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Usage Tracking ──────────────────────────
CREATE TABLE usage_logs (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES users(id) ON DELETE SET NULL,
  tool_id     TEXT NOT NULL,
  ip_address  TEXT,
  file_size   BIGINT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Indexes ─────────────────────────────────
CREATE INDEX idx_jobs_user_id   ON processing_jobs(user_id);
CREATE INDEX idx_jobs_status    ON processing_jobs(status);
CREATE INDEX idx_jobs_expires   ON processing_jobs(expires_at);
CREATE INDEX idx_usage_user_id  ON usage_logs(user_id);
CREATE INDEX idx_usage_tool     ON usage_logs(tool_id);
CREATE INDEX idx_subs_user_id   ON subscriptions(user_id);

-- ─── CV Versions ─────────────────────────────
CREATE TABLE cv_versions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  profile_data JSONB NOT NULL,
  template_id TEXT,
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_cv_versions_user_id ON cv_versions(user_id);

-- ─── Auto-update updated_at ──────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
