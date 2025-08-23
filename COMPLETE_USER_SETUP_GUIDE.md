# 👥 Complete Test User Setup Guide

## ⚠️ Important: Two-Step Process Required

To create working test users, you need to create them in **BOTH** places:
1. **Supabase Auth** (for login functionality)
2. **Database Tables** (for application data)

---

## 🔐 Step 1: Create Auth Users in Supabase

### Go to Supabase Auth Dashboard:
1. Visit: https://supabase.com/dashboard/project/xibffemtpboiecpeynon/auth/users
2. Click **"Add User"** button

### Create Admin User:
- **Email**: `admin@uthm.edu.my`
- **Password**: `admin123456` (or your preferred password)
- **Email Confirm**: ✅ Check "Email Confirm"
- **User ID**: `880698eb-2793-435f-ae67-734cc7d3d756` (copy this exact UUID)

### Create Student User:
- **Email**: `student@uthm.edu.my`  
- **Password**: `student123456` (or your preferred password)
- **Email Confirm**: ✅ Check "Email Confirm"
- **User ID**: `b68d744f-1f1b-4c1d-b747-5c2d8596e31b` (copy this exact UUID)

**⚠️ IMPORTANT**: Use the exact UUIDs provided above so they match the database records!

---

## 🗃️ Step 2: Create Database Records

### Go to Supabase SQL Editor:
1. Visit: https://supabase.com/dashboard/project/xibffemtpboiecpeynon/sql
2. Copy and paste the SQL from `CREATE_TEST_USERS.sql`
3. Click **"Run"** to execute

---

## ✅ Verification Steps

### Test Login:
1. **Admin Login**: 
   - Email: `admin@uthm.edu.my`
   - Password: `admin123456`

2. **Student Login**:
   - Email: `student@uthm.edu.my` 
   - Password: `student123456`

### Check Data:
- Verify users appear in Auth dashboard
- Verify profiles are complete
- Verify sample event exists
- Verify sample showcase post exists

---

## 🎯 What You'll Get

### 👨‍💼 Admin User - Dr. Ahmad Rahman
- **Role**: Admin/Head of Department
- **Access**: Full system access
- **Profile**: Complete academic and administrative profile
- **Can**: Create events, manage users, moderate content

### 👩‍🎓 Student User - Nurul Aisyah
- **Role**: Student (3rd year Computer Science)
- **Profile**: Complete with projects, skills, experiences
- **Sample Data**: AI project showcase post
- **Can**: Create posts, join events, update profile

### 📊 Sample Content
- **1 Event**: AI & Machine Learning Workshop 2025
- **1 Showcase Post**: AI Study Buddy project
- **Complete Profiles**: With realistic academic data

---

## 🚨 Troubleshooting

### If Login Fails:
1. Check Auth users exist in Supabase Auth dashboard
2. Verify email addresses match exactly
3. Ensure email confirmation is enabled
4. Check passwords are correct

### If Data Missing:
1. Run the SQL script in Supabase SQL Editor
2. Check UUIDs match between Auth and database
3. Verify all tables have data

### If UUIDs Don't Match:
1. Update the SQL script with correct UUIDs from Auth dashboard
2. Or recreate Auth users with the UUIDs from the SQL script

---

## 🎉 Ready to Test!

Once both steps are complete, you can:
- ✅ Login with either account
- ✅ Test all features with realistic data
- ✅ Develop with proper user roles and permissions
- ✅ Demo the system with sample content

Your student talent profiling system is now ready for testing! 🚀
