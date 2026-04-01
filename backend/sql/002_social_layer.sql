-- Phase B4 social layer support
-- Run in Supabase SQL editor before using community voting and atomic XP endpoints.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Source-of-truth vote table to prevent duplicate post voting.
CREATE TABLE IF NOT EXISTS public.post_votes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  vote_type TEXT NOT NULL CHECK (vote_type IN ('upvote', 'downvote')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_post_votes_post_id ON public.post_votes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_votes_user_id ON public.post_votes(user_id);

-- XP event ledger to deduplicate rewards per event and keep XP updates consistent.
CREATE TABLE IF NOT EXISTS public.xp_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  reference_id TEXT NOT NULL,
  xp_delta INTEGER NOT NULL CHECK (xp_delta >= 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, event_type, reference_id)
);

CREATE INDEX IF NOT EXISTS idx_xp_events_user_id ON public.xp_events(user_id);
CREATE INDEX IF NOT EXISTS idx_xp_events_event_type ON public.xp_events(event_type);

ALTER TABLE public.post_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.xp_events ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'post_votes' AND policyname = 'Users can insert own votes'
  ) THEN
    CREATE POLICY "Users can insert own votes" ON public.post_votes
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'post_votes' AND policyname = 'Users can update own votes'
  ) THEN
    CREATE POLICY "Users can update own votes" ON public.post_votes
      FOR UPDATE USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'post_votes' AND policyname = 'Users can view votes'
  ) THEN
    CREATE POLICY "Users can view votes" ON public.post_votes
      FOR SELECT USING (true);
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.award_xp_event(
  p_user_id UUID,
  p_event_type TEXT,
  p_reference_id TEXT,
  p_xp_delta INTEGER
)
RETURNS TABLE(xp INTEGER, level INTEGER, awarded BOOLEAN)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  inserted_id UUID;
BEGIN
  INSERT INTO public.xp_events (user_id, event_type, reference_id, xp_delta)
  VALUES (p_user_id, p_event_type, p_reference_id, p_xp_delta)
  ON CONFLICT (user_id, event_type, reference_id) DO NOTHING
  RETURNING id INTO inserted_id;

  IF inserted_id IS NULL THEN
    RETURN QUERY
    SELECT
      COALESCE(p.xp, 0)::INTEGER AS xp,
      FLOOR(COALESCE(p.xp, 0) / 100.0)::INTEGER AS level,
      FALSE AS awarded
    FROM public.profiles p
    WHERE p.id = p_user_id;
    RETURN;
  END IF;

  RETURN QUERY
  UPDATE public.profiles p
  SET
    xp = COALESCE(p.xp, 0) + p_xp_delta,
    level = FLOOR((COALESCE(p.xp, 0) + p_xp_delta) / 100.0)::INTEGER
  WHERE p.id = p_user_id
  RETURNING p.xp::INTEGER, p.level::INTEGER, TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.award_xp_event(UUID, TEXT, TEXT, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.award_xp_event(UUID, TEXT, TEXT, INTEGER) TO authenticated;
