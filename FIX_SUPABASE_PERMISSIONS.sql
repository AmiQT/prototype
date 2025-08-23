-- 🔧 Fix Supabase Permissions for Mobile App
-- Run this in your Supabase SQL Editor to fix permission issues

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE showcase_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE showcase_interactions ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can view all users" ON users FOR SELECT USING (true);
CREATE POLICY "Users can insert their own record" ON users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update their own record" ON users FOR UPDATE USING (auth.uid() = id);

-- Profiles table policies
CREATE POLICY "Users can view all profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = user_id);

-- Events table policies (all users can view, only admins can modify)
CREATE POLICY "Users can view all events" ON events FOR SELECT USING (true);
CREATE POLICY "Admins can modify events" ON events FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'admin'
  )
);

-- Showcase posts policies
CREATE POLICY "Users can view all showcase posts" ON showcase_posts FOR SELECT USING (true);
CREATE POLICY "Users can insert their own posts" ON showcase_posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own posts" ON showcase_posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own posts" ON showcase_posts FOR DELETE USING (auth.uid() = user_id);

-- Showcase interactions policies
CREATE POLICY "Users can view all interactions" ON showcase_interactions FOR SELECT USING (true);
CREATE POLICY "Users can insert their own interactions" ON showcase_interactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own interactions" ON showcase_interactions FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own interactions" ON showcase_interactions FOR DELETE USING (auth.uid() = user_id);

-- Grant necessary permissions to authenticated users
GRANT ALL ON users TO authenticated;
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON events TO authenticated;
GRANT ALL ON showcase_posts TO authenticated;
GRANT ALL ON showcase_interactions TO authenticated;

-- Allow authenticated users to access sequences (for auto-incrementing IDs if any)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
