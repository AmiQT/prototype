-- Supabase Database Setup (Safe Mode) - Only creates missing tables/policies
-- Copy and paste this entire file into your Supabase SQL Editor

-- ============================================================================
-- CHECK EXISTING TABLES
-- ============================================================================

-- Check what tables already exist
SELECT 'Checking existing tables...' as status;

SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'profiles');

-- ============================================================================
-- USERS TABLE (Only if missing columns)
-- ============================================================================

-- Add missing columns to users table if they don't exist
DO $$ 
BEGIN
    -- Add student_id column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'student_id') THEN
        ALTER TABLE users ADD COLUMN student_id TEXT;
    END IF;
    
    -- Add department column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'department') THEN
        ALTER TABLE users ADD COLUMN department TEXT;
    END IF;
    
    -- Add is_active column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'is_active') THEN
        ALTER TABLE users ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
    
    -- Add profile_completed column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'profile_completed') THEN
        ALTER TABLE users ADD COLUMN profile_completed BOOLEAN DEFAULT false;
    END IF;
    
    -- Add role column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'role') THEN
        ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'student';
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
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
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
-- POLICIES (Create if don't exist)
-- ============================================================================

-- Drop existing policies if they exist and recreate them
DROP POLICY IF EXISTS "Users can read own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Users can insert own data" ON users;

-- Create users policies
CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own data" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Drop existing profiles policies if they exist
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- Create profiles policies
CREATE POLICY "Profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON profiles
  FOR ALL USING (auth.uid() = user_id);

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

-- Create triggers
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at 
    BEFORE UPDATE ON profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

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
SELECT schemaname, tablename, policyname, cmd, qual
FROM pg_policies 
WHERE tablename IN ('users', 'profiles');

-- ============================================================================
-- NOTES
-- ============================================================================

/*
SAFE SETUP COMPLETED:

✅ USERS TABLE:
   - Checked existing table
   - Added missing columns only
   - Updated RLS policies

✅ PROFILES TABLE:
   - Created if didn't exist
   - Set up RLS policies

✅ SECURITY:
   - Row Level Security enabled
   - Policies recreated safely

✅ PERFORMANCE:
   - Indexes created if missing
   - Triggers for auto-timestamps

READY TO USE:
- Your existing users table is preserved
- New functionality added safely
- Compatible with SupabaseAuthService
*/