-- Supabase Database Setup (Fixed) - Handles UUID/TEXT type issues
-- Copy and paste this entire file into your Supabase SQL Editor

-- ============================================================================
-- CHECK EXISTING TABLES AND STRUCTURE
-- ============================================================================

-- Check what tables already exist
SELECT 'Checking existing tables...' as status;

SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'profiles');

-- Check users table structure
SELECT 'CURRENT USERS TABLE STRUCTURE:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- ============================================================================
-- USERS TABLE UPDATES (Safe column additions)
-- ============================================================================

-- Add missing columns to users table if they don't exist
DO $$ 
BEGIN
    -- Add student_id column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'student_id') THEN
        ALTER TABLE users ADD COLUMN student_id TEXT;
        RAISE NOTICE 'Added student_id column';
    END IF;
    
    -- Add department column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'department') THEN
        ALTER TABLE users ADD COLUMN department TEXT;
        RAISE NOTICE 'Added department column';
    END IF;
    
    -- Add is_active column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'is_active') THEN
        ALTER TABLE users ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE 'Added is_active column';
    END IF;
    
    -- Add profile_completed column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'profile_completed') THEN
        ALTER TABLE users ADD COLUMN profile_completed BOOLEAN DEFAULT false;
        RAISE NOTICE 'Added profile_completed column';
    END IF;
    
    -- Add role column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'role') THEN
        ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'student';
        RAISE NOTICE 'Added role column';
    END IF;
    
    -- Add name column if it doesn't exist (some Supabase setups might not have this)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'name') THEN
        ALTER TABLE users ADD COLUMN name TEXT;
        RAISE NOTICE 'Added name column';
    END IF;
END $$;

-- Enable Row Level Security on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PROFILES TABLE (Create if doesn't exist)
-- ============================================================================

-- Create profiles table only if it doesn't exist
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

-- ============================================================================
-- POLICIES (Fixed with proper UUID casting)
-- ============================================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Users can insert own data" ON users;
DROP POLICY IF EXISTS "Enable read access for all users" ON users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON users;
DROP POLICY IF EXISTS "Enable update for users based on email" ON users;

-- Create users policies with proper UUID handling
CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid()::text = id::text);

CREATE POLICY "Users can insert own data" ON users
  FOR INSERT WITH CHECK (auth.uid()::text = id::text);

-- Drop existing profiles policies if they exist
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON profiles;

-- Create profiles policies with proper UUID handling
CREATE POLICY "Profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own profile" ON profiles
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- INDEXES (Create if don't exist)
-- ============================================================================

-- Create indexes only if they don't exist
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_student_id ON users(student_id);
CREATE INDEX IF NOT EXISTS idx_users_department ON users(department);
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Create or replace the update function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;

-- Create triggers only if tables have updated_at column
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'users' AND column_name = 'updated_at') THEN
        CREATE TRIGGER update_users_updated_at 
            BEFORE UPDATE ON users 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'profiles' AND column_name = 'updated_at') THEN
        CREATE TRIGGER update_profiles_updated_at 
            BEFORE UPDATE ON profiles 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Show final table structure
SELECT 'Setup completed successfully!' as status;

-- Show users table structure
SELECT 'USERS TABLE STRUCTURE:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- Show profiles table structure  
SELECT 'PROFILES TABLE STRUCTURE:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- Show policies
SELECT 'SECURITY POLICIES:' as info;
SELECT schemaname, tablename, policyname, cmd
FROM pg_policies 
WHERE tablename IN ('users', 'profiles');

-- Test policy syntax
SELECT 'Testing auth.uid() function...' as test;
SELECT auth.uid() as current_user_id;

-- ============================================================================
-- NOTES
-- ============================================================================

/*
FIXED SETUP COMPLETED:

✅ UUID/TEXT CASTING FIXED:
   - Used proper ::text casting for UUID comparisons
   - Fixed auth.uid() policy references

✅ USERS TABLE:
   - Added missing columns safely
   - Proper RLS policies with UUID handling

✅ PROFILES TABLE:
   - Created with proper foreign key to auth.users
   - Full CRUD policies

✅ SECURITY:
   - Row Level Security enabled
   - Policies handle UUID/TEXT conversion

✅ COMPATIBILITY:
   - Works with existing Supabase auth
   - Compatible with SupabaseAuthService

READY TO USE:
- Database structure complete
- Security policies active
- App authentication ready
*/