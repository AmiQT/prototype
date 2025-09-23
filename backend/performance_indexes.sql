-- Performance Optimization Indexes for Student Talent Profiling App
-- Run this script in your Supabase SQL editor or PostgreSQL client

-- Indexes for showcase_posts table
CREATE INDEX IF NOT EXISTS idx_showcase_posts_created_at ON showcase_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_showcase_posts_is_public ON showcase_posts(is_public);
CREATE INDEX IF NOT EXISTS idx_showcase_posts_user_id ON showcase_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_showcase_posts_category ON showcase_posts(category);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_showcase_posts_public_created ON showcase_posts(is_public, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_showcase_posts_user_created ON showcase_posts(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_showcase_posts_category_public ON showcase_posts(category, is_public);

-- Indexes for profiles table
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON profiles(created_at DESC);

-- Indexes for post_likes table (if exists)
CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_user_id ON post_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_post_user ON post_likes(post_id, user_id);

-- Check existing indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename IN ('showcase_posts', 'profiles', 'post_likes')
ORDER BY tablename, indexname;

