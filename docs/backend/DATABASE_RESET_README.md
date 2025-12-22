# Database Reset Guide

This guide explains how to completely reset your database and start fresh with sample data.

## 🚨 WARNING

**This will DELETE ALL EXISTING DATA in your database!** Make sure you have backups if needed.

## 🎯 Why Reset Database?

- Migration failed during auth setup
- Database tables not synced with Supabase auth
- Need fresh start with proper structure
- Want to test with sample data

## 📋 Prerequisites

1. **Backend server is NOT running**
2. **Supabase connection is working**
3. **Environment variables are set correctly**
4. **Python dependencies are installed**

## 🔄 Complete Database Reset

### Option 1: Full Reset with Sample Data

This will drop all tables, recreate them, and insert comprehensive sample data:

```bash
cd backend
python reset_database.py
```

**What this creates:**
- ✅ 9 users (1 admin, 3 lecturers, 5 students)
- ✅ User profiles with skills, interests, experiences
- ✅ 20+ achievements across different categories
- ✅ 4 events (workshops, seminars, competitions)
- ✅ 15+ showcase posts with comments and likes
- ✅ Event participations and registrations

### Option 2: Create Only Test Users

If you just want basic test accounts without sample data:

```bash
cd backend
python create_test_users.py
```

**What this creates:**
- ✅ 1 admin user (admin@test.com)
- ✅ 1 lecturer user (lecturer@test.com)
- ✅ 3 student users (student1@test.com, student2@test.com, student3@test.com)
- ✅ Basic profiles for students

## 🧪 Test Account Information

After running the scripts, you'll have these test accounts:

### Admin Account
- **Email:** admin@test.com
- **Role:** Admin
- **UID:** test_admin_001
- **Password:** Use Supabase Auth (create user manually)

### Lecturer Account
- **Email:** lecturer@test.com
- **Role:** Lecturer
- **UID:** test_lecturer_001
- **Password:** Use Supabase Auth (create user manually)

### Student Accounts
- **Email:** student1@test.com, student2@test.com, student3@test.com
- **Role:** Student
- **UID:** test_student_001, test_student_002, test_student_003
- **Password:** Use Supabase Auth (create user manually)

## 🔥 Supabase Auth Setup

Since the database reset only creates database records, you need to create corresponding Supabase Auth users:

### Method 1: Supabase Console
1. Go to [Supabase Console](https://supabase.com/dashboard)
2. Select your project
3. Go to Authentication > Users
4. Click "Add User"
5. Enter email and temporary password
6. Use the same UID as in the database

### Method 2: Supabase API
```python
import firebase_admin
from firebase_admin import auth

# Create user with specific UID
user = auth.create_user(
    email='admin@test.com',
    password='temporary123',
    uid='test_admin_001'
)
```

## 📊 Sample Data Overview

### Users & Profiles
- **Admin:** Full administrative access
- **Lecturers:** Teaching staff with event creation rights
- **Students:** Regular users with showcase posting rights

### Achievements
- Academic awards (Dean's List, Best Project)
- Technical certifications (Microsoft Azure, Programming)
- Competition wins (Programming Contest)
- Project achievements (Final Year Project)

### Events
- **Web Development Workshop:** Hands-on coding session
- **Machine Learning Seminar:** AI/ML introduction
- **Programming Competition:** Coding contest
- **Career Fair:** Professional networking

### Showcase Posts
- Project showcases with images
- Research updates
- Learning progress
- Technical discussions

## 🚀 After Reset

1. **Start your backend server**
2. **Test API endpoints** with the sample data
3. **Verify authentication** works with test accounts
4. **Check all features** are working properly

## 🔧 Troubleshooting

### Common Issues

1. **Connection Error**
   - Check DATABASE_URL in .env
   - Verify Supabase is accessible

2. **Permission Error**
   - Ensure database user has CREATE/DROP privileges
   - Check Supabase RLS policies

3. **Import Error**
   - Install required Python packages
   - Check Python path and imports

### Reset Failed?

If the reset fails:

1. **Check error messages** in the console
2. **Verify database connection**
3. **Check table permissions**
4. **Try manual table creation** if needed

## 📝 Manual Table Creation

If scripts fail, you can manually create tables:

```python
from app.database import engine, Base
from app.models import *  # Import all models

# Create all tables
Base.metadata.create_all(engine)
```

## 🎉 Success Indicators

You'll know the reset worked when you see:

- ✅ All tables dropped successfully
- ✅ All tables created successfully
- ✅ Sample data inserted successfully
- ✅ Database reset completed successfully
- ✅ Test users created (if using create_test_users.py)

## 🔒 Security Notes

- **Test accounts are for development only**
- **Don't use test passwords in production**
- **Reset database before deploying to production**
- **Use strong passwords for real users**

## 📞 Need Help?

If you encounter issues:

1. Check the error messages carefully
2. Verify your environment setup
3. Ensure Supabase is accessible
4. Check database permissions
5. Review the migration files

---

**Remember:** This is a destructive operation that will remove all your data. Use only in development/testing environments!
