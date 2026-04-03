-- ==========================================
-- ONBOARDING SUPPORT MIGRATION
-- Adds fields needed for the onboarding flow
-- ==========================================

-- Add interests column to profiles
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS interests JSONB DEFAULT '[]';

-- Add availability column
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS availability TEXT;

-- Add onboarding_completed flag
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT FALSE;

-- Add onboarding_step for resume support
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS onboarding_step INTEGER DEFAULT 0;

-- Create index for onboarding queries
CREATE INDEX IF NOT EXISTS idx_profiles_onboarding_completed 
  ON public.profiles(onboarding_completed);

-- Update existing profiles to mark onboarding as completed
-- (for users who already have skills set)
UPDATE public.profiles 
SET onboarding_completed = TRUE, onboarding_step = 5
WHERE skills IS NOT NULL 
  AND skills != '[]'::jsonb 
  AND onboarding_completed = FALSE;

-- ==========================================
-- STORAGE BUCKET SETUP (run in Supabase Dashboard)
-- ==========================================
-- 1. Go to Storage in Supabase Dashboard
-- 2. Create bucket named 'avatars' with public access
-- 3. Set max file size to 5MB
-- 4. Allow MIME types: image/jpeg, image/png
