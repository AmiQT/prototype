-- Fix Supabase RLS policies and foreign key relationships
-- This script addresses the real issues causing the "column users_1.full_name does not exist" error

-- 1. Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE showcase_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 2. Create RLS policies for profiles table
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view public profiles" ON profiles
    FOR SELECT USING (true);

-- 3. Create RLS policies for showcase_posts table
CREATE POLICY "Users can view public posts" ON showcase_posts
    FOR SELECT USING (is_public = true);

CREATE POLICY "Users can view their own posts" ON showcase_posts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own posts" ON showcase_posts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own posts" ON showcase_posts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own posts" ON showcase_posts
    FOR DELETE USING (auth.uid() = user_id);

-- 4. Create RLS policies for users table
CREATE POLICY "Users can view their own user data" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own user data" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own user data" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 5. Add foreign key constraints if they don't exist
DO $$ 
BEGIN
    -- Add foreign key from showcase_posts to users
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'showcase_posts_user_id_fkey'
    ) THEN
        ALTER TABLE showcase_posts 
        ADD CONSTRAINT showcase_posts_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- Add foreign key from profiles to users
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'profiles_user_id_fkey'
    ) THEN
        ALTER TABLE profiles 
        ADD CONSTRAINT profiles_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 6. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_showcase_posts_user_id ON showcase_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_showcase_posts_is_public ON showcase_posts(is_public);
CREATE INDEX IF NOT EXISTS idx_showcase_posts_created_at ON showcase_posts(created_at);
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);

-- 7. Verify the structure
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name IN ('profiles', 'showcase_posts', 'users')
ORDER BY table_name, ordinal_position;

-- 8. Check RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename IN ('profiles', 'showcase_posts', 'users');
