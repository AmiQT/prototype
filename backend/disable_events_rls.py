"""
Temporarily disable RLS on events table for testing
Run this if service_role key is not bypassing RLS
"""
from supabase import create_client
import os
from dotenv import load_dotenv

load_dotenv()

def disable_rls():
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_KEY")
    
    if not supabase_url or not supabase_key:
        print("❌ Missing Supabase credentials")
        return
    
    try:
        supabase = create_client(supabase_url, supabase_key)
        
        # Disable RLS on events table
        print("🔓 Disabling RLS on events table...")
        result = supabase.rpc('exec_sql', {
            'query': 'ALTER TABLE public.events DISABLE ROW LEVEL SECURITY;'
        }).execute()
        
        print("✅ RLS disabled on events table")
        print("⚠️ WARNING: This is for testing only. Re-enable RLS for production!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        print("\n💡 Try running this SQL directly in Supabase SQL Editor:")
        print("ALTER TABLE public.events DISABLE ROW LEVEL SECURITY;")

if __name__ == "__main__":
    disable_rls()
