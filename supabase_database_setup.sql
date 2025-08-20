-- Supabase Database Setup for Student Talent Profiling App
-- Copy and paste this entire file into your Supabase SQL Editor

-- ============================================================================
-- USERS TABLE
-- ============================================================================

-- Create users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT auth.uid(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  role TEXT DEFAULT 'student',
  student_id TEXT,
  department TEXT,
  is_active BOOLEAN DEFAULT true,
  profile_completed BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies for users table
CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own data" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================================================
-- PROFILES TABLE (Optional - for extended user profiles)
-- ============================================================================

-- Create profiles table
CREATE TABLE profiles (
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

-- Profiles policies
CREATE POLICY "Profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON profiles
  FOR ALL USING (auth.uid() = user_id);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Users table indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_student_id ON users(student_id);
CREATE INDEX idx_users_department ON users(department);

-- Profiles table indexes
CREATE INDEX idx_profiles_user_id ON profiles(user_id);

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at 
    BEFORE UPDATE ON profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if tables were created successfully
SELECT 'Tables created successfully!' as status;

-- Show table structure
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name IN ('users', 'profiles')
ORDER BY table_name, ordinal_position;

-- ============================================================================
-- NOTES
-- ============================================================================

/*
SETUP INSTRUCTIONS:

1. Go to your Supabase dashboard: https://xibffemtpboiecpeynon.supabase.co
2. Navigate to SQL Editor
3. Copy and paste this entire file
4. Click "Run" to execute all commands
5. Verify tables were created in the Table Editor

WHAT THIS CREATES:

1. USERS TABLE:
   - Stores basic user authentication data
   - Linked to Supabase Auth
   - Row Level Security enabled

2. PROFILES TABLE:
   - Extended user profile information
   - JSON fields for flexible data storage
   - Public read access, user-only write access

3. SECURITY:
   - Row Level Security policies
   - Users can only access their own data
   - Profiles are publicly readable

4. PERFORMANCE:
   - Indexes on commonly queried fields
   - Automatic timestamp updates

INTEGRATION:
- Works with your existing backend API
- Compatible with SupabaseAuthService
- Supports your current user model structure
*/