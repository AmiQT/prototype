# 🔧 Backend Setup Guide

Complete guide to set up the hybrid Supabase + FastAPI backend.

## 🎯 **Overview**

This backend uses a **hybrid architecture**:
- **Supabase**: Authentication, PostgreSQL database, real-time features
- **FastAPI**: Custom business logic, ML algorithms, advanced search
- **Cloudinary**: Media storage and optimization

## ⚡ **Quick Setup (5 Minutes)**

### **1. Prerequisites**
```bash
# Required software
- Python 3.11+
- Git
- Supabase account (free tier)
- Cloudinary account (free tier)
```

### **2. Clone & Install**
```bash
# Clone repository
git clone <your-repo-url>
cd backend

# Install dependencies
pip install -r requirements.txt
```

### **3. Environment Configuration**
```bash
# Copy environment template
cp .env.example .env

# Edit .env with your credentials
nano .env
```

**Required Environment Variables:**
```env
# Supabase Configuration
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:5432/postgres
SUPABASE_URL=https://[PROJECT_REF].supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_KEY=eyJ...

# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# FastAPI Configuration
SECRET_KEY=your-secret-key
ENVIRONMENT=development
ALLOWED_ORIGINS=*
```

### **4. Database Setup**
```bash
# Option A: Automatic setup (recommended)
python setup_database.py

# Option B: Manual setup
alembic revision --autogenerate -m "Initial migration"
alembic upgrade head
```

### **5. Run Backend**
```bash
# Development mode
python main.py

# Production mode
uvicorn main:app --host 0.0.0.0 --port 8000
```

### **6. Test Setup**
```bash
# Test health endpoint
curl http://localhost:8000/health

# Expected response:
{
  "status": "healthy",
  "services": {
    "api": "running",
    "cloudinary": "configured"
  }
}
```

---

## 📋 **Detailed Configuration**

### **Supabase Setup**

1. **Create Project**
   - Go to [supabase.com](https://supabase.com)
   - Click "New Project"
   - Choose organization and name

2. **Get Credentials**
   - **Database URL**: Settings → Database → Connection string (URI)
   - **Project URL**: Settings → API → Project URL
   - **API Keys**: Settings → API → anon/service keys

3. **Database Schema**
   ```sql
   -- Tables are auto-created via Alembic migrations
   -- Main tables: users, profiles, showcase_posts, events, achievements
   ```

### **Cloudinary Setup**

1. **Create Account**
   - Go to [cloudinary.com](https://cloudinary.com)
   - Sign up for free tier (25GB bandwidth)

2. **Get Credentials**
   - Dashboard → Account Details
   - Copy: Cloud name, API Key, API Secret

3. **Configuration**
   ```python
   # Automatic optimization settings
   - Quality: auto
   - Format: auto (WebP/AVIF)
   - Compression: intelligent
   - CDN: global delivery
   ```

---

## 🗄️ **Database Models**

### **Core Tables**
```sql
-- Users (authentication)
users: id, uid, email, name, role, created_at

-- Profiles (student/lecturer details)  
profiles: id, user_id, full_name, bio, skills, academic_info

-- Showcase Posts (talent display)
showcase_posts: id, user_id, content, media_urls, category

-- Events (university events)
events: id, title, category, start_date, created_by

-- Achievements (student achievements)
achievements: id, title, description, badge_url
```

### **Relationships**
- User → Profile (1:1)
- User → ShowcasePosts (1:many) 
- User → EventParticipation (many:many via junction)
- User → UserAchievements (many:many via junction)

---

## 🚀 **API Endpoints**

### **Authentication**
```
POST /auth/login          # User login
GET  /auth/verify         # Verify token
GET  /auth/profile        # Get user profile
```

### **Users & Profiles**
```
GET    /users             # List users (admin only)
POST   /users             # Create user
GET    /profiles/{id}     # Get profile
PUT    /profiles/{id}     # Update profile
```

### **Showcase System**
```
GET    /showcase          # List posts
POST   /showcase          # Create post
GET    /showcase/{id}     # Get post
PUT    /showcase/{id}     # Update post
DELETE /showcase/{id}     # Delete post
```

### **Analytics & Search**
```
GET  /analytics/users/{id}/similar    # Find similar users
GET  /search/students                 # Advanced student search  
POST /recommendations/{id}            # Get recommendations
```

### **Media Upload**
```
POST /media/upload/image   # Upload image to Cloudinary
POST /media/upload/video   # Upload video to Cloudinary
```

---

## ⚡ **Performance Features**

### **Caching Strategy**
```python
# Redis caching for:
- User profiles (5 minutes)
- Search results (2 minutes) 
- Analytics data (10 minutes)
- Media metadata (30 minutes)
```

### **Database Optimization**
```sql
-- Optimized indexes
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_profiles_skills ON profiles USING GIN(skills);
CREATE INDEX idx_showcase_category ON showcase_posts(category, created_at);
```

### **Connection Pooling**
```python
# SQLAlchemy pool settings
pool_size=20
max_overflow=30
pool_pre_ping=True
pool_recycle=3600
```

---

## 🐛 **Troubleshooting**

### **Common Issues**

**"Database connection failed"**
```bash
# Check DATABASE_URL format
# Verify Supabase project is active
# Confirm database password is correct
```

**"Module not found"**
```bash
pip install -r requirements.txt
# Ensure you're in backend/ directory
```

**"Migration failed"**
```bash
# Check database connection first
# Verify all environment variables are set
# Try manual migration:
alembic revision --autogenerate -m "Fix migration"
```

**"Cloudinary upload failed"**
```bash
# Verify API credentials
# Check file size limits (10MB max)
# Ensure proper file format (jpg, png, mp4)
```

### **Debug Mode**
```python
# Enable debug logging
import logging
logging.basicConfig(level=logging.DEBUG)

# Check logs for detailed errors
tail -f backend.log
```

---

## 🔄 **Development Workflow**

1. **Start Development Server**
   ```bash
   python main.py
   # Auto-reload enabled in development
   ```

2. **Database Changes**
   ```bash
   # Create migration
   alembic revision --autogenerate -m "Description"
   
   # Apply migration
   alembic upgrade head
   
   # Rollback if needed
   alembic downgrade -1
   ```

3. **Testing**
   ```bash
   # Run tests
   pytest tests/
   
   # Test specific endpoint
   curl -X GET http://localhost:8000/health
   ```

4. **Code Quality**
   ```bash
   # Format code
   black .
   
   # Check types
   mypy .
   
   # Lint code  
   flake8 .
   ```

---

## 🚀 **Deployment**

See [Deployment Guide](deployment.md) for production deployment instructions.

---

## 🆘 **Need Help?**

- **Issues**: Check [Debugging Guide](../development/debugging.md)
- **Architecture**: See [Architecture Guide](../development/architecture.md)
- **Performance**: Check [Performance Guide](../development/performance.md)
