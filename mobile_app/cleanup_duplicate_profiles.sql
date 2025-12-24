-- ==================================================
-- CLEANUP: Remove Duplicate Profiles
-- ==================================================
-- Keep only the OLDEST profile per user_id
-- ==================================================

-- Step 1: Check duplicates first
SELECT user_id, COUNT(*) as count, array_agg(id) as profile_ids
FROM profiles
GROUP BY user_id
HAVING COUNT(*) > 1;

-- Step 2: Delete duplicates, keep the first one (oldest by id or created_at)
DELETE FROM profiles p1
USING profiles p2
WHERE p1.user_id = p2.user_id
  AND p1.id > p2.id;

-- Alternative if above doesn't work:
-- DELETE FROM profiles
-- WHERE id NOT IN (
--   SELECT MIN(id) FROM profiles GROUP BY user_id
-- );

-- Step 3: Verify - each user_id should now have only 1 profile
SELECT user_id, COUNT(*) as count
FROM profiles
GROUP BY user_id
HAVING COUNT(*) > 1;

-- Should return 0 rows if cleanup successful
