-- Supabase Minimal Setup - Works with existing table structure
-- Copy and paste this entire file into your Supabase SQL Editor

-- ============================================================================
-- INSPECT EXISTING STRUCTURE FIRST
-- ============================================================================

-- Check what we're working with
SELECT 'Inspecting existing users table...' as status;

-- Show current users table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- ============================================================================
-- BASIC POLICIES FOR EXISTING USERS TABLE
-- ============================================================================

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies to avoid conflicts
DROP POLICY IF EXISTS "Enable read access for all users" ON users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON users;
DROP POLICY IF EXISTS "Enable update for users based on email" ON users;
DROP POLICY IF EXISTS "Users can read own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Users can insert own data" ON users;

-- Create simple policies that work with any ID structure
-- Policy 1: Allow users to read all user data (for now - can restrict later)
CREATE POLICY "Allow authenticated users to read users" ON users
  FOR SELECT USING (auth.role() = 'authenticated');

-- Policy 2: Allow users to insert their own data
CREATE POLICY "Allow authenticated users to insert" ON users
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Policy 3: Allow users to update (we'll refine this based on your table structure)
CREATE POLICY "Allow authenticated users to update" ON users
  FOR UPDATE USING (auth.role() = 'authenticated');

-- ============================================================================
-- ADD MISSING COLUMNS SAFELY
-- ============================================================================

-- Add columns that your app expects, only if they don't exist
DO $$ 
BEGIN
    -- Add role column if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'role') THEN
        ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'student';
        RAISE NOTICE 'Added role column';
    END IF;
    
    -- Add student_id column if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'student_id') THEN
        ALTER TABLE users ADD COLUMN student_id TEXT;
        RAISE NOTICE 'Added student_id column';
    END IF;
    
    -- Add department column if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'department') THEN
        ALTER TABLE users ADD COLUMN department TEXT;
        RAISE NOTICE 'Added department column';
    END IF;
    
    -- Add is_active column if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'is_active') THEN
        ALTER TABLE users ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE 'Added is_active column';
    END IF;
    
    -- Add profile_completed column if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'profile_completed') THEN
        ALTER TABLE users ADD COLUMN profile_completed BOOLEAN DEFAULT false;
        RAISE NOTICE 'Added profile_completed column';
    END IF;
    
    -- Add name column if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'name') THEN
        ALTER TABLE users ADD COLUMN name TEXT;
        RAISE NOTICE 'Added name column';
    END IF;
    
    -- Add created_at if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'created_at') THEN
        ALTER TABLE users ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added created_at column';
    END IF;
    
    -- Add updated_at if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'updated_at') THEN
        ALTER TABLE users ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column';
    END IF;
END $$;

-- ============================================================================
-- CREATE PROFILES TABLE (SIMPLE VERSION)
-- ============================================================================

-- Create a simple profiles table that references auth.users directly
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  headline TEXT,
  bio TEXT,
  profile_image_url TEXT,
  academic_info JSONB,
  skills JSONB DEFAULT '[]',
  interests JSONB DEFAULT '[]',
  is_profile_complete BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Simple profiles policies
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can manage own profile" ON profiles;

CREATE POLICY "Profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can manage own profile" ON profiles
  FOR ALL USING (auth.uid() = user_id);

-- ============================================================================
-- BASIC INDEXES
-- ============================================================================

-- Create basic indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Show final structure
SELECT 'Minimal setup completed!' as status;

-- Show updated users table structure
SELECT 'UPDATED USERS TABLE:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- Show profiles table structure
SELECT 'PROFILES TABLE:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- Show active policies
SELECT 'ACTIVE POLICIES:' as info;
SELECT tablename, policyname, cmd
FROM pg_policies 
WHERE tablename IN ('users', 'profiles');

-- Test auth function
SELECT 'Testing auth functions...' as test;
SELECT auth.uid() as current_user, auth.role() as current_role;

-- ============================================================================
-- NOTES
-- ============================================================================

/*
MINIMAL SETUP COMPLETED:

✅ SAFE APPROACH:
   - Works with any existing users table structure
   - Only adds missing columns
   - Simple, permissive policies to start

✅ USERS TABLE:
   - RLS enabled
   - Basic policies for authenticated users
   - Added app-required columns

✅ PROFILES TABLE:
   - Created with proper auth.users reference
   - Simple RLS policies

✅ READY FOR TESTING:
   - App should be able to authenticate
   - Basic database operations should work
   - Can refine policies later

NEXT STEPS:
1. Test app authentication
2. Refine security policies if needed
3. Add more specific permissions later
*/