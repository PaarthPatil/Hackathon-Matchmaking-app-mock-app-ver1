-- Phase B5 hardening: indexes + integrity constraints for concurrency safety
-- Run in Supabase SQL editor.

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
