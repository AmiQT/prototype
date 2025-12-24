"""
Fix RLS Policies Script
Run this script to fix infinite recursion in Supabase RLS policies.
Uses the same Supabase credentials from backend .env file.
"""
import os
import sys
from dotenv import load_dotenv

# Load env from backend
load_dotenv(os.path.join(os.path.dirname(__file__), '..', 'backend', '.env'))

# Check for supabase package
try:
    from supabase import create_client
except ImportError:
    print("Installing supabase package...")
    os.system(f"{sys.executable} -m pip install supabase")
    from supabase import create_client

def main():
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_KEY") or os.getenv("SUPABASE_KEY")
    
    if not supabase_url or not supabase_key:
        print("❌ Error: SUPABASE_URL or SUPABASE_SERVICE_KEY not found in .env")
        print("Please ensure backend/.env has these variables set.")
        sys.exit(1)
    
    print(f"✅ Supabase URL: {supabase_url[:30]}...")
    print("🔧 Running RLS policy fixes...")
    
    supabase = create_client(supabase_url, supabase_key)
    
    # SQL statements to fix RLS policies
    sql_statements = [
        # Drop existing problematic policies
        "DROP POLICY IF EXISTS \"Users can view their conversation participants\" ON conversation_participants",
        "DROP POLICY IF EXISTS \"Users can insert as participants\" ON conversation_participants",
        "DROP POLICY IF EXISTS \"Users can view conversations they belong to\" ON conversations",
        "DROP POLICY IF EXISTS \"Users can create conversations\" ON conversations",
        "DROP POLICY IF EXISTS \"Users can view messages in their conversations\" ON messages",
        "DROP POLICY IF EXISTS \"Users can insert messages in their conversations\" ON messages",
        "DROP POLICY IF EXISTS \"conversations_select_policy\" ON conversations",
        "DROP POLICY IF EXISTS \"conversations_insert_policy\" ON conversations",
        "DROP POLICY IF EXISTS \"participants_select_policy\" ON conversation_participants",
        "DROP POLICY IF EXISTS \"participants_select_own\" ON conversation_participants",
        "DROP POLICY IF EXISTS \"participants_select_same_convo\" ON conversation_participants",
        "DROP POLICY IF EXISTS \"participants_select_final\" ON conversation_participants",
        "DROP POLICY IF EXISTS \"participants_insert_policy\" ON conversation_participants",
        "DROP POLICY IF EXISTS \"messages_select_policy\" ON messages",
        "DROP POLICY IF EXISTS \"messages_insert_policy\" ON messages",
        
        # Recreate CONVERSATIONS policies
        """CREATE POLICY "conversations_select_policy" ON conversations
           FOR SELECT USING (
             id IN (SELECT conversation_id FROM conversation_participants WHERE user_id = auth.uid())
           )""",
        
        """CREATE POLICY "conversations_insert_policy" ON conversations
           FOR INSERT WITH CHECK (true)""",
        
        # CONVERSATION_PARTICIPANTS - simple policy: users see their own rows only
        """CREATE POLICY "participants_select_final" ON conversation_participants
           FOR SELECT USING (user_id = auth.uid())""",
        
        """CREATE POLICY "participants_insert_policy" ON conversation_participants
           FOR INSERT WITH CHECK (user_id = auth.uid())""",
        
        # MESSAGES policies
        """CREATE POLICY "messages_select_policy" ON messages
           FOR SELECT USING (
             conversation_id IN (SELECT conversation_id FROM conversation_participants WHERE user_id = auth.uid())
           )""",
        
        """CREATE POLICY "messages_insert_policy" ON messages
           FOR INSERT WITH CHECK (
             sender_id = auth.uid()
             AND conversation_id IN (SELECT conversation_id FROM conversation_participants WHERE user_id = auth.uid())
           )""",
    ]
    
    success_count = 0
    error_count = 0
    
    for i, sql in enumerate(sql_statements):
        try:
            # Use rpc to execute raw SQL
            result = supabase.rpc('exec_sql', {'query': sql}).execute()
            print(f"  ✅ Statement {i+1}/{len(sql_statements)} executed")
            success_count += 1
        except Exception as e:
            # Try alternative: direct postgrest call (won't work for DDL)
            # Fall back to noting the error
            error_str = str(e)
            if "does not exist" in error_str and "DROP POLICY" in sql:
                print(f"  ⏭️ Statement {i+1}: Policy didn't exist (OK)")
                success_count += 1
            else:
                print(f"  ❌ Statement {i+1} failed: {error_str[:100]}")
                error_count += 1
    
    print(f"\n📊 Results: {success_count} succeeded, {error_count} failed")
    
    if error_count > 0:
        print("\n⚠️ Some statements failed. You may need to run the SQL manually.")
        print("Open Supabase Dashboard -> SQL Editor and run fix_rls_policies.sql")
    else:
        print("\n🎉 All RLS policies fixed successfully!")

if __name__ == "__main__":
    main()
