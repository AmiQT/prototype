-- Quick fix: Create only the main showcase_posts table
-- Run this in your PostgreSQL database to fix the table creation error

-- Drop existing table if it exists
DROP TABLE IF EXISTS showcase_posts CASCADE;

-- Create the main showcase_posts table
CREATE TABLE showcase_posts (
    -- Primary identification
    id VARCHAR(128) PRIMARY KEY,
    user_id VARCHAR(128) NOT NULL,
    
    -- Post content
    title VARCHAR(255) DEFAULT '',
    description TEXT,
    content TEXT NOT NULL,
    
    -- Categorization and privacy
    category VARCHAR(50) DEFAULT 'general',
    privacy VARCHAR(20) DEFAULT 'public',
    location VARCHAR(255),
    
    -- Media content (JSON arrays)
    media_urls JSON DEFAULT '[]',
    media_types JSON DEFAULT '[]',
    media JSON,
    
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

-- Create basic indexes for performance
CREATE INDEX idx_showcase_user_id ON showcase_posts(user_id);
CREATE INDEX idx_showcase_created_at ON showcase_posts(created_at DESC);
CREATE INDEX idx_showcase_is_public ON showcase_posts(is_public);

-- Verify table was created
SELECT 'Table created successfully!' as status;

-- Show table structure
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'showcase_posts'
ORDER BY ordinal_position;