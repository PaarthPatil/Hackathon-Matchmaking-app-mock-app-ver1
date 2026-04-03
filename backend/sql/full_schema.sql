-- ==========================================
-- CATALYST FULL DATABASE SCHEMA
-- This file combines all individual SQL scripts
-- ==========================================

-- 1. BASE SCHEMA (from database_setup.sql)
-- PHASE 6: COMPLETE DATABASE + RLS SETUP
-- Execute this script in the Supabase SQL Editor.

-- STEP 1: ENABLE EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- STEP 2: CREATE TABLES (EXACT SCHEMA)

-- Profiles: User information, XP, and preferences.
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  name TEXT,
  bio TEXT,
  avatar_url TEXT,
  skills JSONB DEFAULT '[]',
  tech_stack JSONB DEFAULT '[]',
  experience_level TEXT,
  github TEXT,
  linkedin TEXT,
  portfolio TEXT,
  role TEXT DEFAULT 'user',
  roles JSONB DEFAULT '["user"]',
  xp INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  looking_for_team BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);

-- Hackathons: Event details and constraints.
CREATE TABLE IF NOT EXISTS public.hackathons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  organizer TEXT,
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,
  mode TEXT,
  location TEXT,
  prize_pool TEXT,
  max_team_size INTEGER,
  tags JSONB DEFAULT '[]'
);

-- Teams: Hackathon-specific team grouping.
CREATE TABLE IF NOT EXISTS public.teams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  hackathon_id UUID REFERENCES public.hackathons(id) ON DELETE CASCADE,
  creator_id UUID REFERENCES public.profiles(id),
  name TEXT,
  description TEXT,
  required_skills JSONB DEFAULT '[]',
  max_members INTEGER,
  commitment_level TEXT,
  availability TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Team Members: Junction table for team membership.
CREATE TABLE IF NOT EXISTS public.team_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id),
  role TEXT,
  status TEXT DEFAULT 'accepted', -- 'pending' or 'accepted'
  UNIQUE(team_id, user_id)
);

-- Messages: Real-time chat persistence.
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES public.profiles(id),
  content TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_team ON public.messages(team_id);

-- Posts: Community social feed.
CREATE TABLE IF NOT EXISTS public.posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  upvotes INTEGER DEFAULT 0,
  downvotes INTEGER DEFAULT 0
);

-- Comments: Social engagement on posts.
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Achievements: Gamification master list.
CREATE TABLE IF NOT EXISTS public.achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT,
  description TEXT,
  icon TEXT
);

-- User Achievements: Unlocked gamification milestones.
CREATE TABLE IF NOT EXISTS public.user_achievements (
  user_id UUID REFERENCES public.profiles(id),
  achievement_id UUID REFERENCES public.achievements(id),
  UNIQUE(user_id, achievement_id)
);

-- Notifications: Alerts and reminders.
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT,
  message TEXT,
  read BOOLEAN DEFAULT FALSE,
  reference_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- STEP 3: ENABLE ROW LEVEL SECURITY (RLS)

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hackathons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

-- STEP 4: DEFINE POLICIES (STRICT)

-- Profiles Policies
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Hackathons Policies
CREATE POLICY "Hackathons are viewable by everyone" ON public.hackathons
  FOR SELECT USING (true);

-- Teams Policies
CREATE POLICY "Teams are viewable by everyone" ON public.teams
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert teams" ON public.teams
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Creators can update their own teams" ON public.teams
  FOR UPDATE USING (creator_id = auth.uid());

-- Team Members Policies
CREATE POLICY "Members can view their own team membership" ON public.team_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.team_members tm
      WHERE tm.team_id = team_members.team_id AND tm.user_id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can join teams" ON public.team_members
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can remove themselves from teams or creators can remove members" ON public.team_members
  FOR DELETE USING (
    user_id = auth.uid() OR 
    EXISTS (
      SELECT 1 FROM public.teams t WHERE t.id = team_members.team_id AND t.creator_id = auth.uid()
    )
  );

-- Messages Policies (Chat)
CREATE POLICY "Team members can view messages" ON public.messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.team_members tm 
      WHERE tm.team_id = messages.team_id AND tm.user_id = auth.uid()
    )
  );

CREATE POLICY "Team members can send messages" ON public.messages
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.team_members tm 
      WHERE tm.team_id = messages.team_id AND tm.user_id = auth.uid()
    )
  );

-- Posts/Comments Policies
CREATE POLICY "Posts/Comments are public viewable" ON public.posts
  FOR SELECT USING (true);

CREATE POLICY "Posts/Comments are public viewable" ON public.comments
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create posts" ON public.posts
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can create comments" ON public.comments
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Notifications Policies
CREATE POLICY "Users can view their own notifications" ON public.notifications
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update their own notifications" ON public.notifications
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own notifications" ON public.notifications
  FOR DELETE USING (user_id = auth.uid());

-- Achievements/User Achievements Policies
CREATE POLICY "Achievements are viewable by everyone" ON public.achievements
  FOR SELECT USING (true);

CREATE POLICY "Users can view their own achievements" ON public.user_achievements
  FOR SELECT USING (user_id = auth.uid());


-- 2. HACKATHON REQUESTS (from 001_hackathon_requests.sql)
-- Phase B3 support table

CREATE TABLE IF NOT EXISTS public.hackathon_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  organizer TEXT,
  expected_start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  expected_end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  mode TEXT NOT NULL,
  location TEXT,
  tags JSONB DEFAULT '[]',
  additional_metadata JSONB DEFAULT '{}'::jsonb,
  status TEXT NOT NULL DEFAULT 'pending',
  rejection_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_hackathon_requests_status ON public.hackathon_requests(status);
CREATE INDEX IF NOT EXISTS idx_hackathon_requests_created_at ON public.hackathon_requests(created_at DESC);

ALTER TABLE public.hackathon_requests ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'hackathon_requests' AND policyname = 'Users can create own hackathon requests'
  ) THEN
    CREATE POLICY "Users can create own hackathon requests" ON public.hackathon_requests
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'hackathon_requests' AND policyname = 'Users can view own hackathon requests'
  ) THEN
    CREATE POLICY "Users can view own hackathon requests" ON public.hackathon_requests
      FOR SELECT USING (auth.uid() = user_id);
  END IF;
END $$;


-- 3. SOCIAL LAYER & XP (from 002_social_layer.sql)
-- Phase B4 social layer support

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


-- 4. BACKEND HARDENING (from 003_backend_hardening.sql)
-- Phase B5 hardening: indexes + integrity constraints for concurrency safety

-- Performance indexes for frequent filters and joins
CREATE INDEX IF NOT EXISTS idx_teams_hackathon_id ON public.teams(hackathon_id);
CREATE INDEX IF NOT EXISTS idx_teams_creator_id ON public.teams(creator_id);
CREATE INDEX IF NOT EXISTS idx_team_members_team_id ON public.team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON public.team_members(user_id);
CREATE INDEX IF NOT EXISTS idx_team_members_status ON public.team_members(status);
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON public.posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON public.comments(post_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read_user ON public.notifications(user_id, read);
CREATE INDEX IF NOT EXISTS idx_hackathons_start_date ON public.hackathons(start_date);
CREATE INDEX IF NOT EXISTS idx_hackathon_requests_user_status ON public.hackathon_requests(user_id, status);

-- Prevent a user from being accepted in multiple teams within the same hackathon.
CREATE OR REPLACE FUNCTION public.enforce_single_accepted_team_per_hackathon()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_hackathon_id UUID;
BEGIN
  IF NEW.status <> 'accepted' THEN
    RETURN NEW;
  END IF;

  SELECT t.hackathon_id INTO v_hackathon_id
  FROM public.teams t
  WHERE t.id = NEW.team_id;

  IF v_hackathon_id IS NULL THEN
    RAISE EXCEPTION 'Invalid team_id for accepted membership.';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.team_members tm
    JOIN public.teams t ON t.id = tm.team_id
    WHERE tm.user_id = NEW.user_id
      AND tm.status = 'accepted'
      AND t.hackathon_id = v_hackathon_id
      AND tm.team_id <> NEW.team_id
      AND (TG_OP = 'INSERT' OR tm.id <> NEW.id)
  ) THEN
    RAISE EXCEPTION 'User already has an accepted team in this hackathon.';
  END IF;

  RETURN NEW;
END;
$$;

-- Prevent accepted members from exceeding team capacity.
CREATE OR REPLACE FUNCTION public.enforce_team_capacity_on_accept()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_max_members INTEGER;
  v_accepted_count INTEGER;
BEGIN
  IF NEW.status <> 'accepted' THEN
    RETURN NEW;
  END IF;

  SELECT t.max_members INTO v_max_members
  FROM public.teams t
  WHERE t.id = NEW.team_id;

  IF v_max_members IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT COUNT(*)
  INTO v_accepted_count
  FROM public.team_members tm
  WHERE tm.team_id = NEW.team_id
    AND tm.status = 'accepted'
    AND (TG_OP = 'INSERT' OR tm.id <> NEW.id);

  IF v_accepted_count >= v_max_members THEN
    RAISE EXCEPTION 'Team capacity exceeded.';
  END IF;

  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trg_single_accepted_team_per_hackathon'
  ) THEN
    CREATE TRIGGER trg_single_accepted_team_per_hackathon
    BEFORE INSERT OR UPDATE OF status, team_id ON public.team_members
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_single_accepted_team_per_hackathon();
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trg_enforce_team_capacity_on_accept'
  ) THEN
    CREATE TRIGGER trg_enforce_team_capacity_on_accept
    BEFORE INSERT OR UPDATE OF status ON public.team_members
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_team_capacity_on_accept();
  END IF;
END $$;
