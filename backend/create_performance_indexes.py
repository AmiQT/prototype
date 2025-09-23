#!/usr/bin/env python3
"""
Create database indexes for performance optimization
"""
import sys
import os

# Add the backend directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine
from sqlalchemy import text

def create_performance_indexes():
    """Create indexes for better query performance"""
    try:
        print("Creating performance indexes...")
        
        with engine.connect() as conn:
            # Indexes for showcase_posts table
            indexes = [
                # Primary performance indexes
                "CREATE INDEX IF NOT EXISTS idx_showcase_posts_created_at ON showcase_posts(created_at DESC);",
                "CREATE INDEX IF NOT EXISTS idx_showcase_posts_is_public ON showcase_posts(is_public);",
                "CREATE INDEX IF NOT EXISTS idx_showcase_posts_user_id ON showcase_posts(user_id);",
                "CREATE INDEX IF NOT EXISTS idx_showcase_posts_category ON showcase_posts(category);",
                
                # Composite indexes for common queries
                "CREATE INDEX IF NOT EXISTS idx_showcase_posts_public_created ON showcase_posts(is_public, created_at DESC);",
                "CREATE INDEX IF NOT EXISTS idx_showcase_posts_user_created ON showcase_posts(user_id, created_at DESC);",
                "CREATE INDEX IF NOT EXISTS idx_showcase_posts_category_public ON showcase_posts(category, is_public);",
                
                # Indexes for profiles table
                "CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);",
                "CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON profiles(created_at DESC);",
                
                # Indexes for post_likes table (if exists)
                "CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON post_likes(post_id);",
                "CREATE INDEX IF NOT EXISTS idx_post_likes_user_id ON post_likes(user_id);",
                "CREATE INDEX IF NOT EXISTS idx_post_likes_post_user ON post_likes(post_id, user_id);",
            ]
            
            for index_sql in indexes:
                try:
                    conn.execute(text(index_sql))
                    print(f"✅ Created index: {index_sql.split('idx_')[1].split(' ')[0]}")
                except Exception as e:
                    print(f"⚠️  Index might already exist or table doesn't exist: {e}")
            
            conn.commit()
        
        print("\n🎯 Performance indexes created successfully!")
        print("This should significantly improve query performance for:")
        print("  - Feed loading (created_at ordering)")
        print("  - Public posts filtering")
        print("  - User profile lookups")
        print("  - Category filtering")
        
    except Exception as e:
        print(f"❌ Error creating indexes: {e}")
        return False
    
    return True

def check_existing_indexes():
    """Check what indexes already exist"""
    try:
        print("\n📋 Checking existing indexes...")
        
        with engine.connect() as conn:
            # Check showcase_posts indexes
            result = conn.execute(text("""
                SELECT indexname, indexdef 
                FROM pg_indexes 
                WHERE tablename = 'showcase_posts'
                ORDER BY indexname;
            """))
            
            print("\nShowcase Posts Indexes:")
            for row in result:
                print(f"  - {row[0]}")
            
            # Check profiles indexes
            result = conn.execute(text("""
                SELECT indexname, indexdef 
                FROM pg_indexes 
                WHERE tablename = 'profiles'
                ORDER BY indexname;
            """))
            
            print("\nProfiles Indexes:")
            for row in result:
                print(f"  - {row[0]}")
                
    except Exception as e:
        print(f"❌ Error checking indexes: {e}")

if __name__ == "__main__":
    print("🚀 Database Performance Optimization")
    print("=" * 50)
    
    # Check existing indexes first
    check_existing_indexes()
    
    # Create new indexes
    success = create_performance_indexes()
    
    if success:
        print("\n✅ Performance optimization completed!")
        print("Your app should now load much faster! 🚀")
    else:
        print("\n❌ Performance optimization failed!")

