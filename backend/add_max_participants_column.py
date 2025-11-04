"""
Add max_participants column to events table
Allows admin to set participant limit (number or NULL for unlimited)
"""
from supabase import create_client
import os
from dotenv import load_dotenv

load_dotenv()

def add_max_participants_column():
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_KEY")
    
    if not supabase_url or not supabase_key:
        print("❌ Missing Supabase credentials")
        return
    
    try:
        supabase = create_client(supabase_url, supabase_key)
        
        print("📝 Adding max_participants column to events table...")
        
        # Add max_participants column (NULL = unlimited, number = limit)
        sql = """
        ALTER TABLE public.events 
        ADD COLUMN IF NOT EXISTS max_participants INTEGER NULL;
        
        COMMENT ON COLUMN public.events.max_participants IS 
        'Maximum number of participants allowed (NULL = unlimited)';
        """
        
        result = supabase.rpc('exec_sql', {'query': sql}).execute()
        
        print("✅ max_participants column added successfully!")
        print("   - NULL = Unlimited participants")
        print("   - Number = Maximum participants allowed")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        print("\n💡 Run this SQL directly in Supabase SQL Editor:")
        print("""
ALTER TABLE public.events 
ADD COLUMN IF NOT EXISTS max_participants INTEGER NULL;

COMMENT ON COLUMN public.events.max_participants IS 
'Maximum number of participants allowed (NULL = unlimited)';
        """)

if __name__ == "__main__":
    add_max_participants_column()
