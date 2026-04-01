-- Phase B3 support table
-- Run in Supabase SQL editor before using hackathon request endpoints.

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
