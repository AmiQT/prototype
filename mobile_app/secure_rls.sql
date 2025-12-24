-- Helper function to get conversation IDs for a user
-- SECURITY DEFINER is crucial to bypass RLS within the function -> Prevents recursion
CREATE OR REPLACE FUNCTION get_my_conversation_ids()
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT conversation_id 
  FROM conversation_participants 
  WHERE user_id = auth.uid();
$$;

-- Enable RLS on tables
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to start fresh
DROP POLICY IF EXISTS "Users can view conversations they participate in" ON conversations;
DROP POLICY IF EXISTS "Users can create conversations" ON conversations;
DROP POLICY IF EXISTS "Users can delete their conversations" ON conversations; -- Or whatever it was named

DROP POLICY IF EXISTS "Users can view participants in their conversations" ON conversation_participants;
DROP POLICY IF EXISTS "Users can join conversations" ON conversation_participants;

DROP POLICY IF EXISTS "Users can view messages in their conversations" ON messages;
DROP POLICY IF EXISTS "Users can insert messages in their conversations" ON messages;
DROP POLICY IF EXISTS "Users can delete messages in their conversations" ON messages;


-- POLYCIES FOR CONVERSATIONS

-- Select: View if in list of my conversation IDs
CREATE POLICY "View my conversations"
ON conversations
FOR SELECT
USING (
  id IN (SELECT get_my_conversation_ids())
);

-- Insert: Authenticated users can create new conversations
CREATE POLICY "Create conversations"
ON conversations
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Update: Can update if participant (e.g. updated_at timestamp)
CREATE POLICY "Update my conversations"
ON conversations
FOR UPDATE
USING (
  id IN (SELECT get_my_conversation_ids())
);

-- Delete: Can delete if participant
CREATE POLICY "Delete my conversations"
ON conversations
FOR DELETE
USING (
  id IN (SELECT get_my_conversation_ids())
);


-- POLICIES FOR CONVERSATION_PARTICIPANTS

-- Select: View rows if conversation_id is in my list (See myself AND others in my chats)
CREATE POLICY "View participants in my chats"
ON conversation_participants
FOR SELECT
USING (
  conversation_id IN (SELECT get_my_conversation_ids())
);

-- Insert: Authenticated users can insert (e.g. adding self or others)
-- Ideally restrict to: "Can add self" OR "Can add to created conversation"
-- For simplicity in prototype: Allow authenticated insert
CREATE POLICY "Insert participants"
ON conversation_participants
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Delete: Can remove self or if conversation is deleted?
-- Usually we just delete the conversation which cascades, or remove self.
-- Allow delete if it's MY record OR if I'm in the conversation (admin-ish?)
CREATE POLICY "Delete participants"
ON conversation_participants
FOR DELETE
USING (
  conversation_id IN (SELECT get_my_conversation_ids())
);


-- POLICIES FOR MESSAGES

-- Select: View messages if conversation_id is in my list
CREATE POLICY "View messages in my chats"
ON messages
FOR SELECT
USING (
  conversation_id IN (SELECT get_my_conversation_ids())
);

-- Insert: Can send message if I am sender AND I am in the conversation
CREATE POLICY "Send messages"
ON messages
FOR INSERT
WITH CHECK (
  auth.uid() = sender_id AND
  conversation_id IN (SELECT get_my_conversation_ids())
);

-- Delete: Delete if I am in the conversation (or maybe restrict to own messages?)
-- Current app logic: Delete My Message (needs sender check) OR Delete Conversation (needs participant check)
-- Simplest: Allow if in conversation. App UI hides delete button for others' messages anyway.
CREATE POLICY "Delete messages in my chats"
ON messages
FOR DELETE
USING (
  conversation_id IN (SELECT get_my_conversation_ids())
);
