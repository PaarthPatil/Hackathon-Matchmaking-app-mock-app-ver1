-- CATALYST MOCK DATA SEEDING SCRIPT (SCHEMA COMPATIBLE)
-- Optimized for the specific schema provided by the user.
-- Populates: 5 Hackathons, 1 Admin, 50 Users, 20 Teams, and Social Feed items.

DO $$
DECLARE
    admin_id UUID := '00000000-0000-0000-0000-111111111111';
    guest_id UUID := '00000000-0000-0000-0000-000000000000';
    h_ids UUID[];
    u_ids UUID[];
    t_ids UUID[];
    i INTEGER;
    j INTEGER;
BEGIN
    -- 1. SEED ADMIN USER
    -- First in auth.users
    INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
    VALUES (admin_id, 'admin@catalyst.test', crypt('admin123', gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Catalyst Admin"}'::jsonb, now(), now())
    ON CONFLICT (id) DO NOTHING;

    -- Then in public.profiles (Using exact columns from your schema)
    INSERT INTO public.profiles (id, username, name, bio, created_at, xp, level, looking_for_team)
    VALUES (admin_id, 'admin', 'Catalyst Admin', 'System Administrator with full access.', now(), 0, 1, true)
    ON CONFLICT (id) DO NOTHING;

    -- 2. SEED HACKATHONS (Using exact columns from your schema)
    WITH inserted_hackathons AS (
        INSERT INTO public.hackathons (title, description, organizer, start_date, end_date, mode, location, prize_pool, max_team_size, tags)
        VALUES 
        ('Global AI Challenge', 'Build the next generation of AI-driven solutions.', 'OpenAI', now() + INTERVAL '10 days', now() + INTERVAL '12 days', 'Online', 'Global', '$50,000', 5, '["AI", "Machine Learning"]'::jsonb),
        ('Fintech Future Hack', 'Revolutionize the world of finance and payments.', 'Stripe', now() + INTERVAL '20 days', now() + INTERVAL '23 days', 'Hybrid', 'New York, US', '$25,000', 4, '["Fintech", "Blockchain"]'::jsonb),
        ('Cyber Security Sprint', 'Secure the digital frontier against emerging threats.', 'Cloudflare', now() + INTERVAL '5 days', now() + INTERVAL '7 days', 'In-Person', 'Austin, TX', '$15,000', 3, '["Security", "Networking"]'::jsonb),
        ('Green Tech Marathon', 'Sustainable engineering for a better planet.', 'Tesla', now() + INTERVAL '30 days', now() + INTERVAL '35 days', 'Online', 'Global', '$10,000', 6, '["Sustainability", "IoT"]'::jsonb),
        ('Health-Tech Innovate', 'Transforming healthcare through digital innovation.', 'Mayo Clinic', now() + INTERVAL '15 days', now() + INTERVAL '18 days', 'In-Person', 'Remote', '$30,000', 4, '["Health", "Data"]'::jsonb)
        RETURNING id
    )
    SELECT array_agg(id) INTO h_ids FROM inserted_hackathons;

    -- 3. SEED 50 USERS
    FOR i IN 1..50 LOOP
        DECLARE
            v_user_id UUID;
        BEGIN
            INSERT INTO auth.users (email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
            VALUES ('user' || i || '@catalyst.test', crypt('password123', gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, ('{"full_name":"Mock Developer ' || i || '"}')::jsonb, now(), now())
            ON CONFLICT (email) DO UPDATE SET raw_user_meta_data = EXCLUDED.raw_user_meta_data
            RETURNING id INTO v_user_id;
            
            u_ids[i] := v_user_id;

            INSERT INTO public.profiles (id, username, name, bio, experience_level, skills, tech_stack, looking_for_team)
            VALUES (u_ids[i], 'dev_' || i, 'Mock Developer ' || i, 'Bio for mock user ' || i, 'Intermediate', '["Flutter", "Dart"]'::jsonb, '["Mobile"]'::jsonb, true)
            ON CONFLICT (id) DO NOTHING;
        END;
    END LOOP;

    -- 4. SEED 20 TEAMS
    FOR j IN 1..5 LOOP
        FOR i IN 1..4 LOOP
            DECLARE
                v_team_id UUID;
            BEGIN
                INSERT INTO public.teams (hackathon_id, creator_id, name, description, required_skills, max_members, commitment_level, availability)
                VALUES (h_ids[j], u_ids[((j-1)*4 + i) % 50 + 1], 'Team ' || i || ' for Hackathon ' || j, 'Innovative team description for ' || j || '-' || i, '["Python", "Flutter"]'::jsonb, 5, 'High', 'Weekends')
                RETURNING id INTO v_team_id;
                
                t_ids[(j-1)*4 + i] := v_team_id;

                -- Assign Creator as Member in team_members
                INSERT INTO public.team_members (team_id, user_id, role, status)
                VALUES (t_ids[(j-1)*4 + i], u_ids[((j-1)*4 + i) % 50 + 1], 'Lead', 'accepted');

                -- Fill 2 teams per hackathon, leave 2 open for test-joining (Empty Space)
                IF i <= 2 THEN
                    INSERT INTO public.team_members (team_id, user_id, role, status) VALUES (t_ids[(j-1)*4 + i], u_ids[((j-1)*4 + i + 10) % 50 + 1], 'Developer', 'accepted');
                    INSERT INTO public.team_members (team_id, user_id, role, status) VALUES (t_ids[(j-1)*4 + i], u_ids[((j-1)*4 + i + 20) % 50 + 1], 'Designer', 'accepted');
                END IF;
            END;
        END LOOP;
    END LOOP;

    -- 5. SEED SOCIAL FEED (posts: id, user_id, content, upvotes, downvotes)
    FOR i IN 1..30 LOOP
        INSERT INTO public.posts (user_id, content, upvotes, downvotes)
        VALUES (u_ids[i % 50 + 1], 'This is mock post ' || i || '. Testing the social layer compatibility!', floor(random() * 50)::int, 0);
    END LOOP;

    -- 6. SEED COMMENTS (comments: id, post_id, user_id, content)
    INSERT INTO public.comments (post_id, user_id, content)
    SELECT id, u_ids[floor(random() * 49 + 1)::int], 'Compatible comment #' || floor(random()*100)
    FROM public.posts
    LIMIT 60;

    -- Optional: set admin role if the column exists.
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'profiles'
          AND column_name = 'role'
    ) THEN
        EXECUTE format(
            'UPDATE public.profiles SET role = %L WHERE id = %L',
            'admin',
            admin_id::text
        );
    END IF;

    RAISE NOTICE 'Seeding completed: Compatible with provided schema snapshot.';
END $$;
