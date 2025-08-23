-- 🚨 NUCLEAR OPTION: Remove ALL Security for Development
-- This removes ALL security - only for development/testing!

-- 1. Disable RLS on ALL tables
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE events DISABLE ROW LEVEL SECURITY;
ALTER TABLE showcase_posts DISABLE ROW LEVEL SECURITY;
ALTER TABLE showcase_interactions DISABLE ROW LEVEL SECURITY;

-- 2. Drop ALL existing policies (complete clean slate)
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    -- Drop all policies on all tables
    FOR r IN SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON ' || r.schemaname || '.' || r.tablename;
    END LOOP;
END $$;

-- 3. Grant EVERYTHING to everyone (no restrictions)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Also grant to anon (for non-authenticated access)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO anon;

-- 4. Grant usage on schema
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;

-- 5. Make sure postgres role has all permissions too
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;

-- 6. Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;

-- 7. Verify all tables are accessible
SELECT 'Tables with permissions:' as status;
SELECT table_name, privilege_type, grantee 
FROM information_schema.table_privileges 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'profiles', 'events', 'showcase_posts', 'showcase_interactions')
AND grantee IN ('authenticated', 'anon')
ORDER BY table_name, grantee;
