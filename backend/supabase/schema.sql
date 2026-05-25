-- Mio App Database Schema
-- Run this in Supabase SQL Editor
-- All tables, indexes, RLS policies, triggers

-- USERS TABLE
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- SUBSCRIPTIONS TABLE
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  plan TEXT NOT NULL DEFAULT 'free'
    CHECK (plan IN ('free', 'basic', 'pro')),
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'cancelled', 'past_due')),
  current_period_end TIMESTAMPTZ,
  country_bucket TEXT NOT NULL DEFAULT 'premium'
    CHECK (country_bucket IN ('premium', 'middle', 'value')),
  stripe_customer_id TEXT,
  stripe_subscription_id TEXT,
  razorpay_customer_id TEXT,
  razorpay_subscription_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- API KEYS TABLE
CREATE TABLE IF NOT EXISTS public.api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  encrypted_key TEXT NOT NULL,
  iv TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, provider)
);

-- DEVICES TABLE
CREATE TABLE IF NOT EXISTS public.devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  device_name TEXT NOT NULL,
  device_type TEXT NOT NULL
    CHECK (device_type IN ('ios', 'android', 'web', 'desktop')),
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, device_id)
);

-- SETTINGS TABLE
CREATE TABLE IF NOT EXISTS public.settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
  theme TEXT NOT NULL DEFAULT 'system'
    CHECK (theme IN ('light', 'dark', 'system')),
  zero_fluff_on BOOLEAN NOT NULL DEFAULT TRUE,
  default_model TEXT NOT NULL DEFAULT '',
  default_provider TEXT NOT NULL DEFAULT '',
  loading_word_index INTEGER NOT NULL DEFAULT 0,
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- CHATS TABLE
CREATE TABLE IF NOT EXISTS public.chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT 'New Chat',
  model TEXT NOT NULL DEFAULT '',
  provider TEXT NOT NULL DEFAULT '',
  message_count INTEGER NOT NULL DEFAULT 0,
  last_preview TEXT NOT NULL DEFAULT '',
  storage_type TEXT NOT NULL DEFAULT 'local'
    CHECK (storage_type IN ('local', 'drive', 'cloud')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- MESSAGES TABLE
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  role TEXT NOT NULL
    CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  tokens_input INTEGER,
  tokens_output INTEGER,
  model TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TOKEN USAGE TABLE
CREATE TABLE IF NOT EXISTS public.token_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  month TEXT NOT NULL DEFAULT TO_CHAR(NOW(), 'YYYY-MM'),
  tokens_used_input INTEGER NOT NULL DEFAULT 0,
  tokens_used_output INTEGER NOT NULL DEFAULT 0,
  model_used TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_chats_user_id 
  ON public.chats(user_id);
CREATE INDEX IF NOT EXISTS idx_chats_updated_at 
  ON public.chats(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_chat_id 
  ON public.messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at 
  ON public.messages(created_at);
CREATE INDEX IF NOT EXISTS idx_token_usage_user_date 
  ON public.token_usage(user_id, date);
CREATE INDEX IF NOT EXISTS idx_devices_user_id 
  ON public.devices(user_id);

-- ROW LEVEL SECURITY
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.token_usage ENABLE ROW LEVEL SECURITY;

-- RLS POLICIES
-- Backend uses service role key which bypasses RLS
-- These policies are backup security layer only

CREATE POLICY "Users own data" ON public.users
  FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users own subscriptions" ON public.subscriptions
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users own api_keys" ON public.api_keys
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users own devices" ON public.devices
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users own settings" ON public.settings
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users own chats" ON public.chats
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users own messages" ON public.messages
  FOR ALL USING (
    auth.uid() = (
      SELECT user_id FROM public.chats 
      WHERE id = chat_id
    )
  );

CREATE POLICY "Users own token_usage" ON public.token_usage
  FOR ALL USING (auth.uid() = user_id);

-- REALTIME
ALTER PUBLICATION supabase_realtime 
  ADD TABLE public.chats;
ALTER PUBLICATION supabase_realtime 
  ADD TABLE public.messages;

-- UPDATED_AT TRIGGER
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_settings_updated_at
  BEFORE UPDATE ON public.settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_chats_updated_at
  BEFORE UPDATE ON public.chats
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
