-- Supabase Final Setup - Handles both camelCase and snake_case
-- Copy and paste this entire file into your Supabase SQL Editor

-- ============================================================================
-- INSPECT EXISTING STRUCTURE
-- ============================================================================

-- Check existing tables and their columns
SELECT 'Checking existing table structures...' as status;

-- Show users table structure
SELECT 'USERS TABLE COLUMNS:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- Show profiles table structure if it exists
SELECT 'PROFILES TABLE COLUMNS (if exists):' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- ============================================================================
-- USERS TABLE SETUP
-- ============================================================================

-- Enable RLS on users
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Enable read access for all users" ON users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON users;
DROP POLICY IF EXISTS "Enable update for users based on email" ON users;
DROP POLICY IF EXISTS "Users can read own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Users can insert own data" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to read users" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to insert" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to update" ON users;

-- Create simple policies for users
CREATE POLICY "Allow authenticated read" ON users
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated insert" ON users
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated update" ON users
  FOR UPDATE USING (auth.role() = 'authenticated');

-- Add missing columns to users table
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'role') THEN
        ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'student';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'student_id') THEN
        ALTER TABLE users ADD COLUMN student_id TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'department') THEN
        ALTER TABLE users ADD COLUMN department TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'is_active') THEN
        ALTER TABLE users ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'profile_completed') THEN
        ALTER TABLE users ADD COLUMN profile_completed BOOLEAN DEFAULT false;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'name') THEN
        ALTER TABLE users ADD COLUMN name TEXT;
    END IF;
END $$;

-- ============================================================================
-- PROFILES TABLE SETUP (Handle existing structure)
-- ============================================================================

-- Check if profiles table exists and what columns it has
DO $$
DECLARE
    has_profiles_table boolean;
    has_user_id boolean;
    has_userId boolean;
BEGIN
    -- Check if profiles table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'profiles'
    ) INTO has_profiles_table;
    
    IF has_profiles_table THEN
        -- Check which user reference column exists
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'profiles' AND column_name = 'user_id'
        ) INTO has_user_id;
        
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'profiles' AND column_name = 'userId'
        ) INTO has_userId;
        
        RAISE NOTICE 'Profiles table exists. user_id: %, userId: %', has_user_id, has_userId;
        
        -- Enable RLS on existing profiles table
        ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
        
        -- Drop existing policies
        DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
        DROP POLICY IF EXISTS "Users can manage own profile" ON profiles;
        DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
        DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
        DROP POLICY IF EXISTS "Enable update for users based on userId" ON profiles;
        DROP POLICY IF EXISTS "Enable update for users based on user_id" ON profiles;
        
        -- Create policies based on which column exists
        IF has_user_id THEN
            CREATE POLICY "Profiles readable by all" ON profiles
              FOR SELECT USING (true);
            CREATE POLICY "Users can manage own profile via user_id" ON profiles
              FOR ALL USING (auth.uid() = user_id);
        ELSIF has_userId THEN
            CREATE POLICY "Profiles readable by all" ON profiles
              FOR SELECT USING (true);
            CREATE POLICY "Users can manage own profile via userId" ON profiles
              FOR ALL USING (auth.uid() = "userId");
        ELSE
            -- Create basic policies without user reference
            CREATE POLICY "Profiles readable by all" ON profiles
              FOR SELECT USING (true);
            CREATE POLICY "Profiles manageable by authenticated" ON profiles
              FOR ALL USING (auth.role() = 'authenticated');
        END IF;
        
    ELSE
        -- Create new profiles table with snake_case naming
        CREATE TABLE profiles (
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
        
        ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
        
        CREATE POLICY "Profiles readable by all" ON profiles
          FOR SELECT USING (true);
        CREATE POLICY "Users can manage own profile" ON profiles
          FOR ALL USING (auth.uid() = user_id);
          
        RAISE NOTICE 'Created new profiles table';
    END IF;
END $$;

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Create indexes safely
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Create profile indexes based on what columns exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'profiles' AND column_name = 'user_id') THEN
        CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'profiles' AND column_name = 'userId') THEN
        CREATE INDEX IF NOT EXISTS idx_profiles_userId ON profiles("userId");
    END IF;
END $$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'Setup completed successfully!' as status;

-- Show final table structures
SELECT 'FINAL USERS TABLE STRUCTURE:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;

SELECT 'FINAL PROFILES TABLE STRUCTURE:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- Show policies
SELECT 'ACTIVE POLICIES:' as info;
SELECT tablename, policyname, cmd
FROM pg_policies 
WHERE tablename IN ('users', 'profiles')
ORDER BY tablename, policyname;

-- Test auth
SELECT 'AUTH TEST:' as test;
SELECT 
  CASE 
    WHEN auth.uid() IS NOT NULL THEN 'Auth working - User: ' || auth.uid()::text
    ELSE 'No authenticated user (normal for SQL editor)'
  END as auth_status;

-- ============================================================================
-- NOTES
-- ============================================================================

/*
ADAPTIVE SETUP COMPLETED:

✅ FLEXIBLE APPROACH:
   - Detects existing table structure
   - Handles both camelCase and snake_case
   - Works with any existing setup

✅ USERS TABLE:
   - RLS enabled with permissive policies
   - Added required columns for app

✅ PROFILES TABLE:
   - Uses existing table or creates new one
   - Policies adapt to column naming

✅ READY FOR APP:
   - Should work with SupabaseAuthService
   - Basic operations enabled
   - Can authenticate and store data

NEXT: Test your Flutter app!
*/