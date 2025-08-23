-- 🗑️ Clear Supabase Database
-- Run these commands in your Supabase SQL Editor
-- Go to: https://supabase.com/dashboard/project/xibffemtpboiecpeynon/sql

-- ⚠️ WARNING: This will permanently delete ALL data
-- Make sure you want to proceed before running these commands

-- Clear data in dependency order (child tables first)

-- 1. Clear showcase-related tables
DELETE FROM showcase_interactions;
DELETE FROM showcase_posts;

-- 2. Clear event-related tables  
DELETE FROM events;

-- 3. Clear user-related tables
DELETE FROM profiles;
DELETE FROM users;

-- ✅ Database cleared!
-- All tables are now empty and ready for fresh data

-- Optional: Reset any auto-increment sequences (if you have any)
-- ALTER SEQUENCE IF EXISTS some_sequence_name RESTART WITH 1;

-- 📝 Note: This preserves table structure and only removes data
-- Your tables, columns, and schema remain intact
