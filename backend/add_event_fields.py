#!/usr/bin/env python3
"""
Add missing fields to events table: category, image_url, registration_url
"""
import sys
import os
from sqlalchemy import text

# Add the backend directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine

def add_event_fields():
    """Add category, image_url, and registration_url to events table"""
    try:
        with engine.connect() as conn:
            # Check if columns exist first
            check_sql = """
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'events' 
            AND column_name IN ('category', 'image_url', 'registration_url');
            """
            result = conn.execute(text(check_sql))
            existing_columns = [row[0] for row in result]
            
            print(f"Existing columns: {existing_columns}")
            
            # Add category if it doesn't exist
            if 'category' not in existing_columns:
                print("Adding category column...")
                conn.execute(text("""
                    ALTER TABLE events 
                    ADD COLUMN category VARCHAR(50) DEFAULT 'general';
                """))
                conn.commit()
                print("✅ Added category column")
            else:
                print("✓ category column already exists")
            
            # Add image_url if it doesn't exist
            if 'image_url' not in existing_columns:
                print("Adding image_url column...")
                conn.execute(text("""
                    ALTER TABLE events 
                    ADD COLUMN image_url TEXT;
                """))
                conn.commit()
                print("✅ Added image_url column")
            else:
                print("✓ image_url column already exists")
            
            # Add registration_url if it doesn't exist
            if 'registration_url' not in existing_columns:
                print("Adding registration_url column...")
                conn.execute(text("""
                    ALTER TABLE events 
                    ADD COLUMN registration_url TEXT;
                """))
                conn.commit()
                print("✅ Added registration_url column")
            else:
                print("✓ registration_url column already exists")
            
            print("\n✅ All event fields added successfully!")
        
    except Exception as e:
        print(f"❌ Error adding fields: {e}")
        return False
    
    return True

if __name__ == "__main__":
    success = add_event_fields()
    sys.exit(0 if success else 1)
