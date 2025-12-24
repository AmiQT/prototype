-- ==================================================
-- CLEANUP: Delete conversations with orphan participants
-- ==================================================

-- Step 1: Find conversations with participants that have no profile
SELECT DISTINCT cp.conversation_id
FROM conversation_participants cp
LEFT JOIN profiles p ON cp.user_id = p.user_id
WHERE p.user_id IS NULL;

-- Step 2: Delete messages from those conversations first
DELETE FROM messages
WHERE conversation_id IN (
  SELECT DISTINCT cp.conversation_id
  FROM conversation_participants cp
  LEFT JOIN profiles p ON cp.user_id = p.user_id
  WHERE p.user_id IS NULL
);

-- Step 3: Delete participants from those conversations
DELETE FROM conversation_participants
WHERE conversation_id IN (
  SELECT DISTINCT cp.conversation_id
  FROM conversation_participants cp
  LEFT JOIN profiles p ON cp.user_id = p.user_id
  WHERE p.user_id IS NULL
);

-- Step 4: Delete the conversations themselves
DELETE FROM conversations
WHERE id NOT IN (
  SELECT DISTINCT conversation_id FROM conversation_participants
);

-- Step 5: Verify - should show only conversations with valid participants
SELECT 
  c.id as conversation_id,
  cp.user_id,
  p.full_name
FROM conversations c
JOIN conversation_participants cp ON c.id = cp.conversation_id
JOIN profiles p ON cp.user_id = p.user_id
ORDER BY c.created_at DESC;
