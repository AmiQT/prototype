-- 🔧 TEMPORARY: Disable RLS to fix permission issues
-- This is for testing only - we'll re-enable with proper policies later

-- Disable RLS temporarily
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE events DISABLE ROW LEVEL SECURITY;
ALTER TABLE showcase_posts DISABLE ROW LEVEL SECURITY;
ALTER TABLE showcase_interactions DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies (clean slate)
DROP POLICY IF EXISTS "Users can view all users" ON users;
DROP POLICY IF EXISTS "Users can insert their own data" ON users;
DROP POLICY IF EXISTS "Users can update their own data" ON users;

DROP POLICY IF EXISTS "Users can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

DROP POLICY IF EXISTS "Users can view all showcase posts" ON showcase_posts;
DROP POLICY IF EXISTS "Users can insert their own posts" ON showcase_posts;
DROP POLICY IF EXISTS "Users can update their own posts" ON showcase_posts;

DROP POLICY IF EXISTS "Users can view all events" ON events;
DROP POLICY IF EXISTS "Users can view all interactions" ON showcase_interactions;
DROP POLICY IF EXISTS "Users can insert interactions" ON showcase_interactions;
DROP POLICY IF EXISTS "Users can update their own interactions" ON showcase_interactions;

-- Ensure full permissions for authenticated users
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Also grant to anon just in case
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
