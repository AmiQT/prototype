#!/usr/bin/env python3
"""
Check if showcase_posts table exists and show its structure
"""
import sys
import os

# Add the backend directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine
from sqlalchemy import text

def check_table():
    """Check if showcase_posts table exists"""
    try:
        with engine.connect() as conn:
            # Check if table exists
            result = conn.execute(text("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = 'showcase_posts'
                );
            """))
            
            table_exists = result.fetchone()[0]
            
            if table_exists:
                print("✅ showcase_posts table EXISTS")
                
                # Show table structure
                result = conn.execute(text("""
                    SELECT column_name, data_type, is_nullable, column_default 
                    FROM information_schema.columns 
                    WHERE table_name = 'showcase_posts' 
                    ORDER BY ordinal_position;
                """))
                
                print("\n📋 Table structure:")
                for row in result:
                    print(f"  - {row[0]}: {row[1]} (nullable: {row[2]})")
                    
            else:
                print("❌ showcase_posts table DOES NOT EXIST")
                print("Please run: python create_showcase_simple.py")
                
    except Exception as e:
        print(f"❌ Error checking table: {e}")
        return False
    
    return table_exists

if __name__ == "__main__":
    exists = check_table()
    sys.exit(0 if exists else 1)