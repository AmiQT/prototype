-- 🔧 Update Supabase Policies to Fix App Issues
-- Run this in your Supabase SQL Editor

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view their own data" ON users;
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Anyone can view showcase posts" ON showcase_posts;
DROP POLICY IF EXISTS "Anyone can view approved showcase posts" ON showcase_posts;

-- Create new permissive policies for viewing
CREATE POLICY "Users can view all users" ON users FOR SELECT USING (true);
CREATE POLICY "Users can view all profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can view all showcase posts" ON showcase_posts FOR SELECT USING (true);

-- Add missing policies for showcase_interactions and events
CREATE POLICY "Users can view all events" ON events FOR SELECT USING (true);
CREATE POLICY "Users can view all interactions" ON showcase_interactions FOR SELECT USING (true);

-- Ensure showcase posts can be created/updated by their owners
DROP POLICY IF EXISTS "Users can insert showcase posts" ON showcase_posts;
DROP POLICY IF EXISTS "Users can update showcase posts" ON showcase_posts;
CREATE POLICY "Users can insert their own posts" ON showcase_posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own posts" ON showcase_posts FOR UPDATE USING (auth.uid() = user_id);

-- Ensure interactions can be created by any authenticated user
CREATE POLICY "Users can insert interactions" ON showcase_interactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own interactions" ON showcase_interactions FOR UPDATE USING (auth.uid() = user_id);

-- Check if RLS is enabled on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE showcase_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE showcase_interactions ENABLE ROW LEVEL SECURITY;
