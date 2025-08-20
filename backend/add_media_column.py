#!/usr/bin/env python3
"""
Add media column to existing showcase_posts table
"""
import sys
import os

# Add the backend directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine
from sqlalchemy import text

def add_media_column():
    """Add media column to showcase_posts table"""
    try:
        print("Adding media column to showcase_posts table...")
        
        with engine.connect() as conn:
            # Add media column to store JSON string of media URLs
            conn.execute(text("""
                ALTER TABLE showcase_posts 
                ADD COLUMN IF NOT EXISTS media TEXT;
            """))
            conn.commit()
        
        print("✅ Media column added successfully!")
        
    except Exception as e:
        print(f"❌ Error adding media column: {e}")
        return False
    
    return True

if __name__ == "__main__":
    success = add_media_column()
    sys.exit(0 if success else 1)