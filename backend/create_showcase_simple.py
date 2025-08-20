#!/usr/bin/env python3
"""
Simple script to create showcase_posts table without foreign key constraints
"""
import sys
import os

# Add the backend directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine
from sqlalchemy import text

def create_showcase_table_simple():
    """Create showcase_posts table with simple SQL"""
    try:
        print("Creating showcase_posts table...")
        
        # Create the table with SQL directly
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS showcase_posts (
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
        """
        
        with engine.connect() as conn:
            conn.execute(text(create_table_sql))
            conn.commit()
        
        print("✅ showcase_posts table created successfully!")
        
    except Exception as e:
        print(f"❌ Error creating table: {e}")
        return False
    
    return True

if __name__ == "__main__":
    success = create_showcase_table_simple()
    sys.exit(0 if success else 1)