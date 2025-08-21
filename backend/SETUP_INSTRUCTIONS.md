# 🚀 Backend Database Setup Instructions

## ✅ **Step 1.1.3: Complete Your Configuration**

You've successfully created the database models! Now you need to complete your Supabase configuration.

### **Update your .env file:**

1. **Open** `backend/.env` file
2. **Replace the placeholder values** with your actual Supabase credentials:

```env
# Replace these placeholders with your actual Supabase values:
DATABASE_URL=postgresql://postgres:[YOUR_ACTUAL_PASSWORD]@db.[YOUR_PROJECT_REF].supabase.co:5432/postgres
SUPABASE_URL=https://[YOUR_PROJECT_REF].supabase.co
SUPABASE_ANON_KEY=your_actual_anon_key_here
SUPABASE_SERVICE_KEY=your_actual_service_key_here
```

### **Where to find these values in Supabase:**

1. **Go to your Supabase project dashboard**
2. **For DATABASE_URL:**
   - Click "Settings" → "Database"
   - Copy the "Connection string" (URI format)
   - Make sure to replace `[YOUR-PASSWORD]` with your actual database password

3. **For SUPABASE_URL and Keys:**
   - Click "Settings" → "API"
   - Copy "Project URL" → use as SUPABASE_URL
   - Copy "anon public" key → use as SUPABASE_ANON_KEY  
   - Copy "service_role" key → use as SUPABASE_SERVICE_KEY

## ✅ **Step 1.1.4: Run Database Setup**

Once you've updated your `.env` file:

### **Option A: Automatic Setup (Recommended)**
```bash
cd backend
python setup_database.py
```

### **Option B: Manual Setup**
```bash
cd backend

# Install dependencies
pip install -r requirements.txt

# Create migration
alembic revision --autogenerate -m "Initial migration"

# Run migration
alembic upgrade head
```

## ✅ **Step 1.1.5: Test Your Setup**

```bash
# Start the backend server
python main.py

# Test in browser:
# http://localhost:8000/health
```

You should see:
```json
{
  "status": "healthy",
  "services": {
    "api": "running",
    "cloudinary": "demo_mode"
  }
}
```

## 🎯 **What We've Accomplished:**

✅ **Database Models Created:**
- `User` - User accounts and authentication
- `Profile` - Student profile information  
- `Achievement` - Student achievements and badges
- `Event` - University events and programs
- `ShowcasePost` - Student talent showcase posts
- `EventParticipation` - Event attendance tracking
- `ShowcaseComment` & `ShowcaseLike` - Social features

✅ **Database Setup:**
- Supabase PostgreSQL connection
- SQLAlchemy ORM models
- Alembic migrations
- Automated setup script

## 🔄 **Next Phase Preview:**

Once this is working, we'll move to **Phase 1, Step 1.2: Backend Authentication Setup** where we'll:
- Set up Supabase integration
- Create authentication middleware
- Protect API endpoints
- Test the auth flow

---

## 🆘 **Need Help?**

**Common Issues:**

1. **"Database connection failed"**
   - Double-check your DATABASE_URL
   - Verify your Supabase project is active
   - Confirm your database password

2. **"Module not found"**
   - Run: `pip install -r requirements.txt`
   - Make sure you're in the `backend` directory

3. **"Migration failed"**
   - Check your database connection first
   - Ensure all environment variables are set

**Ready for the next step?** Let me know when you've:
- ✅ Updated your .env file with real Supabase credentials
- ✅ Run the setup script successfully  
- ✅ Tested the health endpoint

Then we'll move to authentication setup!