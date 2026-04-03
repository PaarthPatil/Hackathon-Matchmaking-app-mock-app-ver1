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

-- STORAGE SETUP (Comments for manual setup)
-- 1. Create a bucket named 'avatars' in Supabase Storage.
-- 2. Create a bucket named 'post-images' in Supabase Storage.
-- 3. Set the public availability to 'True' for simple URL fetching.

-- DONE
