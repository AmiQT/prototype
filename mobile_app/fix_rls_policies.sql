-- ==================================================
-- SIMPLE FIX: Disable RLS on Chat Tables
-- ==================================================
-- Since dummy data is cleaned, just disable RLS for now.
-- Security handled at application level.
-- ==================================================

-- Drop all policies first
DO $$ 
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname, tablename FROM pg_policies 
               WHERE tablename IN ('conversations', 'conversation_participants', 'messages')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', pol.policyname, pol.tablename);
    END LOOP;
END $$;

-- Disable RLS
ALTER TABLE conversations DISABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;

-- Verify RLS is disabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('conversations', 'conversation_participants', 'messages');
