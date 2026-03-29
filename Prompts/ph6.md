You are continuing a Flutter + Supabase production app.

This is PHASE 6: COMPLETE DATABASE + RLS SETUP.

---

# EXECUTION INSTRUCTIONS

You MUST generate:

1. Executable SQL (Supabase compatible)
2. Table relationships with constraints
3. Indexes for performance
4. Row Level Security policies (strict and correct)

---

# STEP 1: ENABLE EXTENSIONS

* Enable uuid generation:
  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

---

# STEP 2: CREATE TABLES (EXACT SCHEMA)

## profiles

* id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
* username TEXT UNIQUE NOT NULL
* name TEXT
* bio TEXT
* avatar_url TEXT
* skills JSONB DEFAULT '[]'
* tech_stack JSONB DEFAULT '[]'
* experience_level TEXT
* github TEXT
* linkedin TEXT
* portfolio TEXT
* xp INTEGER DEFAULT 0
* level INTEGER DEFAULT 1
* looking_for_team BOOLEAN DEFAULT TRUE
* created_at TIMESTAMP DEFAULT NOW()

CREATE INDEX idx_profiles_username ON profiles(username);

---

## hackathons

* id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
* title TEXT NOT NULL
* description TEXT
* organizer TEXT
* start_date TIMESTAMP
* end_date TIMESTAMP
* mode TEXT
* location TEXT
* prize_pool TEXT
* max_team_size INTEGER
* tags JSONB DEFAULT '[]'

---

## teams

* id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
* hackathon_id UUID REFERENCES hackathons(id) ON DELETE CASCADE
* creator_id UUID REFERENCES profiles(id)
* name TEXT
* description TEXT
* required_skills JSONB DEFAULT '[]'
* max_members INTEGER
* commitment_level TEXT
* availability TEXT
* created_at TIMESTAMP DEFAULT NOW()

---

## team_members

* id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
* team_id UUID REFERENCES teams(id) ON DELETE CASCADE
* user_id UUID REFERENCES profiles(id)
* role TEXT

UNIQUE(team_id, user_id)

---

## messages

* id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
* team_id UUID REFERENCES teams(id)
* sender_id UUID REFERENCES profiles(id)
* content TEXT
* created_at TIMESTAMP DEFAULT NOW()

CREATE INDEX idx_messages_team ON messages(team_id);

---

## posts

* id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
* user_id UUID REFERENCES profiles(id)
* content TEXT
* image_url TEXT
* created_at TIMESTAMP DEFAULT NOW()
* upvotes INTEGER DEFAULT 0
* downvotes INTEGER DEFAULT 0

---

## comments

* id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
* post_id UUID REFERENCES posts(id) ON DELETE CASCADE
* user_id UUID REFERENCES profiles(id)
* content TEXT

---

## achievements

* id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
* title TEXT
* description TEXT
* icon TEXT

---

## user_achievements

* user_id UUID REFERENCES profiles(id)
* achievement_id UUID REFERENCES achievements(id)

UNIQUE(user_id, achievement_id)

---

## notifications

* id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
* user_id UUID REFERENCES profiles(id)
* type TEXT
* message TEXT
* read BOOLEAN DEFAULT FALSE
* created_at TIMESTAMP DEFAULT NOW()

---

# STEP 3: ENABLE RLS

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

---

# STEP 4: DEFINE POLICIES (STRICT)

## profiles

* SELECT: allow all authenticated users
* UPDATE: only where auth.uid() = id

## teams

* SELECT: public
* INSERT: authenticated
* UPDATE: only creator_id = auth.uid()

## team_members

* SELECT: only if user belongs to team
* INSERT: authenticated
* DELETE: only self or team creator

## messages

* SELECT: only if user in team_members
* INSERT: only if user in team_members

## posts/comments

* SELECT: public
* INSERT: authenticated

## notifications

* SELECT: user_id = auth.uid()
* UPDATE: user_id = auth.uid()

---

# OUTPUT

* Full SQL file
* Ready to paste into Supabase SQL editor

END OF PHASE 6
