-- Complete SQL Schema for Showcase Posts
-- This file creates a comprehensive showcase_posts table with all related tables
-- Based on the mobile app requirements from ShowcasePostModel

-- ============================================================================
-- DROP EXISTING TABLES (if they exist)
-- ============================================================================
DROP TABLE IF EXISTS showcase_post_shares CASCADE;
DROP TABLE IF EXISTS showcase_post_comments CASCADE;
DROP TABLE IF EXISTS showcase_post_likes CASCADE;
DROP TABLE IF EXISTS showcase_posts CASCADE;

-- ============================================================================
-- MAIN SHOWCASE POSTS TABLE
-- ============================================================================
CREATE TABLE showcase_posts (
    -- Primary identification
    id VARCHAR(128) PRIMARY KEY,  -- UUID string format
    user_id VARCHAR(128) NOT NULL,
    
    -- Post content
    title VARCHAR(255) DEFAULT '',
    description TEXT,
    content TEXT NOT NULL,
    
    -- Categorization and privacy
    category VARCHAR(50) DEFAULT 'general',
    privacy VARCHAR(20) DEFAULT 'public',  -- 'public', 'department', 'friends'
    location VARCHAR(255),
    
    -- Media content (JSON arrays)
    media_urls JSON DEFAULT '[]',
    media_types JSON DEFAULT '[]',  -- 'image' or 'video'
    media JSON,  -- Full media objects with metadata
    
    -- Tags and skills
    tags JSON DEFAULT '[]',
    skills_used JSON DEFAULT '[]',
    mentions JSON DEFAULT '[]',
    
    -- User information (cached for performance)
    user_name VARCHAR(255),
    user_profile_image TEXT,
    user_role VARCHAR(50),
    user_department VARCHAR(100),
    user_headline TEXT,
    
    -- Engagement metrics
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    shares_count INTEGER DEFAULT 0,
    views_count INTEGER DEFAULT 0,
    
    -- Post settings
    is_public BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    is_pinned BOOLEAN DEFAULT false,
    is_archived BOOLEAN DEFAULT false,
    allow_comments BOOLEAN DEFAULT true,
    
    -- Content moderation
    is_approved BOOLEAN DEFAULT true,
    moderated_by VARCHAR(128),
    moderation_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_edited BOOLEAN DEFAULT false
);

-- ============================================================================
-- RELATED TABLES FOR SOCIAL FEATURES
-- ============================================================================

-- Likes table for tracking individual likes
CREATE TABLE showcase_post_likes (
    id SERIAL PRIMARY KEY,
    post_id VARCHAR(128) NOT NULL,
    user_id VARCHAR(128) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(post_id, user_id),
    FOREIGN KEY (post_id) REFERENCES showcase_posts(id) ON DELETE CASCADE
);

-- Comments table for post comments
CREATE TABLE showcase_post_comments (
    id VARCHAR(128) PRIMARY KEY,
    post_id VARCHAR(128) NOT NULL,
    user_id VARCHAR(128) NOT NULL,
    parent_comment_id VARCHAR(128),  -- For threaded replies
    content TEXT NOT NULL,
    user_name VARCHAR(255),
    user_profile_image TEXT,
    likes_count INTEGER DEFAULT 0,
    mentions JSON DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_edited BOOLEAN DEFAULT false,
    FOREIGN KEY (post_id) REFERENCES showcase_posts(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_comment_id) REFERENCES showcase_post_comments(id) ON DELETE CASCADE
);

-- Shares table for tracking shares
CREATE TABLE showcase_post_shares (
    id SERIAL PRIMARY KEY,
    post_id VARCHAR(128) NOT NULL,
    user_id VARCHAR(128) NOT NULL,
    shared_to VARCHAR(50),  -- 'timeline', 'external', etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (post_id) REFERENCES showcase_posts(id) ON DELETE CASCADE
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Main table indexes
CREATE INDEX idx_showcase_user_id ON showcase_posts(user_id);
CREATE INDEX idx_showcase_category ON showcase_posts(category);
CREATE INDEX idx_showcase_privacy ON showcase_posts(privacy);
CREATE INDEX idx_showcase_created_at ON showcase_posts(created_at DESC);
CREATE INDEX idx_showcase_is_public ON showcase_posts(is_public);
CREATE INDEX idx_showcase_user_category ON showcase_posts(user_id, category);
CREATE INDEX idx_showcase_public_recent ON showcase_posts(is_public, created_at DESC);
CREATE INDEX idx_showcase_featured ON showcase_posts(is_featured, created_at DESC);

-- Related tables indexes
CREATE INDEX idx_post_likes_post_id ON showcase_post_likes(post_id);
CREATE INDEX idx_post_likes_user_id ON showcase_post_likes(user_id);
CREATE INDEX idx_post_comments_post_id ON showcase_post_comments(post_id);
CREATE INDEX idx_post_comments_user_id ON showcase_post_comments(user_id);
CREATE INDEX idx_post_comments_parent ON showcase_post_comments(parent_comment_id);
CREATE INDEX idx_post_shares_post_id ON showcase_post_shares(post_id);
CREATE INDEX idx_post_shares_user_id ON showcase_post_shares(user_id);

-- ============================================================================
-- TRIGGERS FOR AUTOMATIC COUNT UPDATES
-- ============================================================================

-- Function to update engagement counts
CREATE OR REPLACE FUNCTION update_showcase_post_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'showcase_post_likes' THEN
        IF TG_OP = 'INSERT' THEN
            UPDATE showcase_posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
        ELSIF TG_OP = 'DELETE' THEN
            UPDATE showcase_posts SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.post_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'showcase_post_comments' THEN
        IF TG_OP = 'INSERT' THEN
            UPDATE showcase_posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
        ELSIF TG_OP = 'DELETE' THEN
            UPDATE showcase_posts SET comments_count = GREATEST(0, comments_count - 1) WHERE id = OLD.post_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'showcase_post_shares' THEN
        IF TG_OP = 'INSERT' THEN
            UPDATE showcase_posts SET shares_count = shares_count + 1 WHERE id = NEW.post_id;
        ELSIF TG_OP = 'DELETE' THEN
            UPDATE showcase_posts SET shares_count = GREATEST(0, shares_count - 1) WHERE id = OLD.post_id;
        END IF;
    END IF;
    
    -- Update updated_at timestamp
    UPDATE showcase_posts SET updated_at = NOW() WHERE id = COALESCE(NEW.post_id, OLD.post_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER update_likes_count
    AFTER INSERT OR DELETE ON showcase_post_likes
    FOR EACH ROW EXECUTE FUNCTION update_showcase_post_counts();

CREATE TRIGGER update_comments_count
    AFTER INSERT OR DELETE ON showcase_post_comments
    FOR EACH ROW EXECUTE FUNCTION update_showcase_post_counts();

CREATE TRIGGER update_shares_count
    AFTER INSERT OR DELETE ON showcase_post_shares
    FOR EACH ROW EXECUTE FUNCTION update_showcase_post_counts();

-- Function to automatically update updated_at on main table changes
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_showcase_posts_updated_at
    BEFORE UPDATE ON showcase_posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SAMPLE DATA (Optional - remove if not needed)
-- ============================================================================

-- Insert sample showcase post
-- INSERT INTO showcase_posts (
--     id, user_id, content, category, privacy, user_name, user_role, user_department
-- ) VALUES (
--     'sample-post-001', 
--     'user-123', 
--     'Check out my latest project! Built this amazing mobile app using Flutter.',
--     'technical',
--     'public',
--     'John Doe',
--     'student',
--     'Computer Science'
-- );

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if tables were created successfully
SELECT 
    table_name, 
    column_name, 
    data_type, 
    is_nullable, 
    column_default 
FROM information_schema.columns 
WHERE table_name IN ('showcase_posts', 'showcase_post_likes', 'showcase_post_comments', 'showcase_post_shares')
ORDER BY table_name, ordinal_position;

-- Check indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename LIKE 'showcase_post%'
ORDER BY tablename, indexname;

-- ============================================================================
-- NOTES
-- ============================================================================

/*
FEATURES OF THIS SCHEMA:

1. COMPREHENSIVE DATA MODEL:
   - All fields from ShowcasePostModel in Flutter app
   - User information caching for performance
   - Media support with full metadata
   - Privacy controls (public/department/friends)

2. SOCIAL FEATURES:
   - Likes, comments, shares tracking
   - Threaded comment replies
   - User mentions support
   - Automatic count updates via triggers

3. CONTENT MANAGEMENT:
   - Content moderation fields
   - Featured/pinned post support
   - Archive functionality
   - Edit tracking

4. PERFORMANCE OPTIMIZATIONS:
   - Strategic indexes for common queries
   - Denormalized user data for fast display
   - Efficient JSON fields for arrays
   - Optimized for timeline queries

5. DATA INTEGRITY:
   - Foreign key constraints
   - Automatic timestamp updates
   - Cascade deletes for cleanup
   - Unique constraints where needed

USAGE:
- Run this SQL file in your PostgreSQL database
- Update your backend models to match this schema
- Modify API endpoints to use the new structure
- Test with sample data before deploying to production
*/