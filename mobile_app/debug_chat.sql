-- ==================================================
-- DEBUG: Check profiles table structure and data
-- ==================================================

-- Check profiles table columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles';

-- Check sample of profiles data
SELECT * FROM profiles LIMIT 5;

-- Check conversation_participants with profile join
SELECT 
  cp.conversation_id,
  cp.user_id as participant_user_id,
  p.id as profile_id,
  p.user_id as profile_user_id,
  p.full_name
FROM conversation_participants cp
LEFT JOIN profiles p ON cp.user_id = p.user_id
ORDER BY cp.conversation_id;
