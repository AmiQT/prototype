"""
Add max_participants column to events table using direct SQL connection
"""
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

def add_max_participants_column():
    database_url = os.getenv("DATABASE_URL")
    
    if not database_url:
        print("❌ Missing DATABASE_URL")
        return
    
    try:
        # Connect to database
        conn = psycopg2.connect(database_url)
        cursor = conn.cursor()
        
        print("📝 Adding max_participants column to events table...")
        
        # Add max_participants column (NULL = unlimited, number = limit)
        cursor.execute("""
            ALTER TABLE public.events 
            ADD COLUMN IF NOT EXISTS max_participants INTEGER NULL;
        """)
        
        # Add comment
        cursor.execute("""
            COMMENT ON COLUMN public.events.max_participants IS 
            'Maximum number of participants allowed (NULL = unlimited)';
        """)
        
        conn.commit()
        
        print("✅ max_participants column added successfully!")
        print("   - NULL = Unlimited participants")
        print("   - Number = Maximum participants allowed")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    add_max_participants_column()
