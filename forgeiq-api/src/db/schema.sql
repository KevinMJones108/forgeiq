-- ForgeIQ PostgreSQL Schema
-- Phase 1: VoiceCore + Auth + Session 10 (AI Call Summary + Pipedrive)
-- All tables multi-user from day 1 with user_id filtering

-- Users table (synced from Auth0)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth0_sub TEXT UNIQUE NOT NULL,
  email TEXT NOT NULL,
  name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_users_auth0_sub ON users(auth0_sub);

-- User Subscriptions (feature flags per user)
CREATE TABLE IF NOT EXISTS user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tier TEXT NOT NULL DEFAULT 'free',
  voice_core_enabled BOOLEAN DEFAULT true,
  idea_vault_enabled BOOLEAN DEFAULT false,
  sigma_vault_enabled BOOLEAN DEFAULT false,
  sales_forge_enabled BOOLEAN DEFAULT false,
  doe_enabled BOOLEAN DEFAULT false,
  apex_script_enabled BOOLEAN DEFAULT false,
  stripe_customer_id TEXT,
  stripe_subscription_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Recordings (audio file metadata)
CREATE TABLE IF NOT EXISTS recordings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  audio_duration_sec INTEGER,
  language_from TEXT,
  language_to TEXT,
  mode TEXT DEFAULT 'record_only',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_recordings_user_id ON recordings(user_id);
CREATE INDEX IF NOT EXISTS idx_recordings_created_at ON recordings(created_at DESC);

-- Transcripts (linked to recordings; user scoping enforced via recordings join)
CREATE TABLE IF NOT EXISTS transcripts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recording_id UUID NOT NULL REFERENCES recordings(id) ON DELETE CASCADE,
  transcript_text TEXT NOT NULL,
  source_language TEXT NOT NULL,
  translated_text TEXT,
  target_language TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_transcripts_recording_id ON transcripts(recording_id);

-- Call Summaries (Session 10 — Claude API output per recording)
CREATE TABLE IF NOT EXISTS call_summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recording_id UUID REFERENCES recordings(id) ON DELETE CASCADE,
  summary TEXT NOT NULL,
  went_well JSONB NOT NULL DEFAULT '[]',
  learning_points JSONB NOT NULL DEFAULT '[]',
  blown_past JSONB NOT NULL DEFAULT '[]',
  commitments JSONB NOT NULL DEFAULT '[]',
  next_step TEXT,
  call_score INTEGER,
  talk_time_rep_pct INTEGER,
  talk_time_prospect_pct INTEGER,
  re_engagement_candidate BOOLEAN NOT NULL DEFAULT false,
  pipedrive_activity_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_call_summaries_user_id ON call_summaries(user_id);
CREATE INDEX IF NOT EXISTS idx_call_summaries_recording_id ON call_summaries(recording_id);

-- Stub tables for Phase 2+ modules (501 responses until implemented)
CREATE TABLE IF NOT EXISTS idea_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sigma_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS forge_scripts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
