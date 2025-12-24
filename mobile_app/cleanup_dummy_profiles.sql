-- ==================================================
-- CLEANUP: Remove Dummy Profiles Without Real Auth
-- ==================================================
-- This script will DELETE profiles that don't have 
-- corresponding entries in auth.users
-- ==================================================

-- Step 1: First, let's see how many dummy profiles exist
SELECT 
  p.id,
  p.user_id,
  p.full_name,
  CASE WHEN au.id IS NULL THEN 'DUMMY (No Auth)' ELSE 'REAL (Has Auth)' END as status
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
ORDER BY status DESC, p.full_name;

-- Step 2: Count before deletion
SELECT 
  'Total profiles' as metric, 
  COUNT(*) as count 
FROM profiles
UNION ALL
SELECT 
  'Dummy profiles (no auth)' as metric,
  COUNT(*) as count
FROM profiles p
WHERE NOT EXISTS (SELECT 1 FROM auth.users au WHERE au.id = p.user_id)
UNION ALL
SELECT 
  'Real profiles (has auth)' as metric,
  COUNT(*) as count
FROM profiles p
WHERE EXISTS (SELECT 1 FROM auth.users au WHERE au.id = p.user_id);

-- Step 3: DELETE dummy profiles (those without auth.users entry)
-- UNCOMMENT THE LINES BELOW TO ACTUALLY DELETE:

-- DELETE FROM profiles 
-- WHERE user_id NOT IN (SELECT id FROM auth.users);

-- Step 4: Verify after deletion
-- SELECT COUNT(*) as remaining_profiles FROM profiles;
