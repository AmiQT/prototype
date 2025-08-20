-- Create showcase_posts table
DROP TABLE IF EXISTS showcase_posts CASCADE;

CREATE TABLE showcase_posts (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR NOT NULL,
    title VARCHAR DEFAULT '',
    description TEXT,
    content TEXT,
    category VARCHAR DEFAULT 'general',
    tags JSON DEFAULT '[]',
    skills_used JSON DEFAULT '[]',
    media_urls JSON DEFAULT '[]',
    media_types JSON DEFAULT '[]',
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    shares_count INTEGER DEFAULT 0,
    views_count INTEGER DEFAULT 0,
    is_public BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    allow_comments BOOLEAN DEFAULT true,
    is_approved BOOLEAN DEFAULT true,
    moderated_by VARCHAR,
    moderation_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Verify the table was created
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'showcase_posts' 
ORDER BY ordinal_position;