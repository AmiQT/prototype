# 🚀 Supabase Setup Guide

## 1. **Configure Supabase Credentials**

### Update `mobile_app/lib/config/supabase_config.dart`:
```dart
static const String supabaseUrl = 'https://your-project-id.supabase.co';
static const String supabaseAnonKey = 'your-anon-key-here';
```

**Where to find these:**
1. Go to your Supabase dashboard
2. Select your project
3. Go to Settings → API
4. Copy the "Project URL" and "anon public" key

## 2. **Install Dependencies**
```bash
cd mobile_app
flutter pub get
```

## 3. **Create Database Tables in Supabase**

### Users Table:
```sql
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

-- Policy: Users can read their own data
CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = id);

-- Policy: Users can update their own data
CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);
```

### Profiles Table (if using separate profiles):
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  full_name TEXT,
  headline TEXT,
  bio TEXT,
  profile_image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON profiles
  FOR ALL USING (auth.uid() = user_id);
```

## 4. **Update Authentication Flow**

### Your app now uses:
- ✅ `SupabaseAuthService` instead of `AuthService`
- ✅ Supabase authentication tokens
- ✅ Supabase session management

### Key Changes:
```dart
// OLD (Firebase)
final authService = Provider.of<AuthService>(context);

// NEW (Supabase)
final authService = Provider.of<SupabaseAuthService>(context);
```

## 5. **Test Authentication**

### Sign Up Flow:
```dart
await authService.registerWithEmailAndPassword(
  email,
  password,
  name,
  UserRole.student,
  studentId: studentId,
  department: department,
);
```

### Sign In Flow:
```dart
await authService.signInWithEmailAndPassword(email, password);
```

## 6. **Environment Variables (Optional)**

### Create `.env` file in `mobile_app/assets/`:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### Update `supabase_config.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'YOUR_FALLBACK_URL';
static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? 'YOUR_FALLBACK_KEY';
```

## 7. **Backend Integration**

Your showcase posts will continue working with your existing backend! The Supabase auth tokens will be sent to your backend API for authentication.

### Backend receives:
- ✅ Supabase JWT tokens instead of Firebase tokens
- ✅ Same user ID format (UUID)
- ✅ Same API structure

## 8. **Test Checklist**

- [ ] Supabase credentials configured
- [ ] `flutter pub get` completed
- [ ] Database tables created
- [ ] App builds without errors
- [ ] User registration works
- [ ] User login works
- [ ] Showcase posts still work
- [ ] User session persists on app restart

## 🎯 **Current Status:**
- ✅ **Firebase completely removed**
- ✅ **Supabase authentication ready**
- ✅ **Showcase posts working via backend**
- 🔄 **Need to configure Supabase credentials**

## 🚨 **Important Notes:**
1. **Showcase posts will continue working** through your backend API
2. **User authentication** now uses Supabase
3. **Session management** is handled by Supabase
4. **Your backend API** receives Supabase tokens instead of Firebase tokens

Ready to configure your Supabase credentials! 🚀