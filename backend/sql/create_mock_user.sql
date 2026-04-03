-- Create a mock user for guest testing
-- UUID: 00000000-0000-0000-0000-000000000000

-- 1. Insert into auth.users (Supabase managed auth)
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  'guest@catalyst.test',
  crypt('guest-mode-testing-123', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Guest User","avatar_url":null}',
  now(),
  now(),
  '',
  '',
  '',
  ''
) ON CONFLICT (id) DO NOTHING;

-- 2. Insert into public.profiles (Application database)
INSERT INTO public.profiles (
  id,
  username,
  name,
  bio,
  skills,
  tech_stack,
  experience_level,
  looking_for_team,
  xp,
  level,
  created_at
)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  'guest',
  'Guest Developer',
  'Exploring Catalyst functionality in Guest Mode.',
  '["Testing", "Exploring"]'::jsonb,
  '["General"]'::jsonb,
  'intermediate',
  true,
  0,
  1,
  now(),
) ON CONFLICT (id) DO NOTHING;

-- 3. Optional: set admin role if your profiles table includes a role column.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'profiles'
      AND column_name = 'role'
  ) THEN
    EXECUTE $q$
      UPDATE public.profiles
      SET role = 'admin'
      WHERE id = '00000000-0000-0000-0000-000000000000'
    $q$;
  END IF;
END $$;
