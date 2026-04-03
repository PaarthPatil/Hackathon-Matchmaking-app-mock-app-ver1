-- Phase B6: add admin role fields to profiles for admin-mode authorization.

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user';

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS roles JSONB DEFAULT '["user"]'::jsonb;

-- Backfill empty values to keep authorization checks deterministic.
UPDATE public.profiles
SET role = COALESCE(NULLIF(TRIM(role), ''), 'user');

UPDATE public.profiles
SET roles = CASE
  WHEN jsonb_typeof(roles) = 'array' AND jsonb_array_length(roles) > 0 THEN roles
  ELSE jsonb_build_array(COALESCE(NULLIF(TRIM(role), ''), 'user'))
END;
