# 🚀 Deployment Guide

Complete guide to deploy the Student Talent Profiling App to production.

## 🎯 **Deployment Overview**

**Current Live Production:**
- **Web Dashboard**: [https://amiqt.github.io/prototype/](https://amiqt.github.io/prototype/)
- **Backend API**: [https://prototype-348e.onrender.com](https://prototype-348e.onrender.com)
- **Database**: Hosted on Supabase (Free Tier)
- **Media Storage**: Cloudinary (Free Tier)

---

## 🔧 **Backend Deployment**

### **Option 1: Render (Recommended - Current)**

**✅ Pros**: Free tier, easy setup, automatic deployments
**❌ Cons**: Cold starts, limited compute time

```bash
# 1. Prepare repository
git add .
git commit -m "Prepare for deployment"
git push origin main

# 2. Create Render account
# Visit: https://render.com

# 3. Create Web Service
# - Connect GitHub repository
# - Root Directory: backend/
# - Build Command: pip install -r requirements.txt
# - Start Command: uvicorn main:app --host 0.0.0.0 --port $PORT

# 4. Environment Variables (in Render dashboard)
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:5432/postgres
SUPABASE_URL=https://[PROJECT_REF].supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_KEY=eyJ...
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
ALLOWED_ORIGINS=https://your-frontend-domain.com
PORT=8000
```

### **Option 2: Railway**

**✅ Pros**: Better performance, $5 free credit, excellent DX
**❌ Cons**: May require credit card

```bash
# 1. Install Railway CLI
npm install -g @railway/cli

# 2. Login and create project
railway login
railway new

# 3. Add services
railway add postgresql
railway add redis  # Optional for caching

# 4. Deploy backend
cd backend
railway up

# 5. Environment variables
railway variables set DATABASE_URL=$RAILWAY_DATABASE_URL
railway variables set SUPABASE_URL=https://[PROJECT_REF].supabase.co
# ... add other variables
```

### **Option 3: Vercel (Serverless)**

**✅ Pros**: Excellent performance, global edge network
**❌ Cons**: Serverless limitations, requires code changes

```bash
# 1. Install Vercel CLI
npm install -g vercel

# 2. Create vercel.json in backend/
{
  "builds": [
    {
      "src": "main.py",
      "use": "@vercel/python"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "main.py"
    }
  ]
}

# 3. Deploy
cd backend
vercel --prod

# 4. Configure environment variables
vercel env add DATABASE_URL
vercel env add SUPABASE_URL
# ... add other variables
```

---

## 🌐 **Frontend Deployment**

### **Web Dashboard - GitHub Pages (Current)**

**✅ Pros**: Free, simple, good performance
**❌ Cons**: Static hosting only

```bash
# 1. Prepare web dashboard
cd web_dashboard

# 2. Update API endpoints
# Edit js/config/api-config.js
const API_BASE_URL = 'https://your-backend.render.com';

# 3. Commit changes
git add .
git commit -m "Update production API endpoints"
git push origin main

# 4. Enable GitHub Pages
# Go to GitHub repository settings
# Pages → Source → GitHub Actions
# Select "Deploy from branch" → main branch
```

### **Web Dashboard - Netlify (Alternative)**

```bash
# 1. Install Netlify CLI
npm install -g netlify-cli

# 2. Build and deploy
cd web_dashboard
netlify deploy --prod --dir .

# 3. Configure redirects
# Create _redirects file:
/api/* https://your-backend.render.com/api/* 200
/* /index.html 200
```

### **Web Dashboard - Vercel (Alternative)**

```bash
# 1. Install Vercel CLI
npm install -g vercel

# 2. Create vercel.json
{
  "rewrites": [
    {
      "source": "/api/(.*)",
      "destination": "https://your-backend.render.com/api/$1"
    }
  ]
}

# 3. Deploy
cd web_dashboard
vercel --prod
```

---

## 📱 **Mobile App Deployment**

### **Android - Google Play Store**

```bash
# 1. Prepare for release
cd mobile_app

# 2. Update version
# Edit pubspec.yaml
version: 1.0.0+1

# 3. Configure signing
# Create android/key.properties:
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=key
storeFile=../app-release-key.keystore

# 4. Build release APK
flutter build apk --release

# 5. Build App Bundle (recommended)
flutter build appbundle --release

# 6. Upload to Google Play Console
# - Create app listing
# - Upload app-release.aab
# - Complete store listing
# - Submit for review
```

### **iOS - Apple App Store**

```bash
# 1. Xcode setup
cd mobile_app
flutter build ios --release

# 2. Open Xcode
open ios/Runner.xcworkspace

# 3. Configure signing
# Select Runner target
# Signing & Capabilities → Team
# Select your Apple Developer account

# 4. Archive and distribute
# Product → Archive
# Distribute App → App Store Connect
# Upload to App Store Connect

# 5. Submit for review
# Visit App Store Connect
# Complete app information
# Submit for Apple review
```

### **Web App Deployment**

```bash
# 1. Build web version
cd mobile_app
flutter build web --release

# 2. Deploy to hosting service
# Option A: Firebase Hosting
firebase init hosting
firebase deploy

# Option B: Netlify
cd build/web
netlify deploy --prod --dir .

# Option C: Vercel
cd build/web
vercel --prod
```

---

## 🗄️ **Database Deployment**

### **Supabase (Current - Recommended)**

**✅ Pros**: Managed service, built-in auth, real-time features
**❌ Cons**: Vendor lock-in, free tier limits

```bash
# 1. Create Supabase project
# Visit: https://supabase.com
# Create new project

# 2. Configure database
# Run migrations using Alembic
cd backend
alembic upgrade head

# 3. Setup Row Level Security (RLS)
# In Supabase SQL editor:
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE showcase_posts ENABLE ROW LEVEL SECURITY;

# 4. Create policies
CREATE POLICY "Users can read their own data" ON profiles
    FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Public posts are readable by all" ON showcase_posts
    FOR SELECT USING (is_public = true OR user_id = auth.uid());
```

### **Self-hosted PostgreSQL (Alternative)**

```bash
# 1. Setup PostgreSQL server
# On Ubuntu/Debian:
sudo apt update
sudo apt install postgresql postgresql-contrib

# 2. Create database and user
sudo -u postgres psql
CREATE DATABASE talent_profiling;
CREATE USER talent_user WITH ENCRYPTED PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE talent_profiling TO talent_user;

# 3. Configure connection
DATABASE_URL=postgresql://talent_user:secure_password@your-server:5432/talent_profiling

# 4. Run migrations
cd backend
alembic upgrade head
```

---

## 🖼️ **Media Storage Deployment**

### **Cloudinary (Current - Recommended)**

**✅ Pros**: Free tier (25GB), auto-optimization, global CDN
**❌ Cons**: Pricing scales with usage

```bash
# 1. Create Cloudinary account
# Visit: https://cloudinary.com

# 2. Get credentials
# Dashboard → Account Details
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# 3. Configure upload presets
# Settings → Upload → Upload presets
# Create preset: "talent_uploads"
# Mode: Unsigned
# Transformations: f_auto,q_auto,w_1920,h_1080,c_limit
```

### **AWS S3 (Alternative)**

```bash
# 1. Create S3 bucket
aws s3 mb s3://talent-profiling-media

# 2. Configure CORS
{
  "CORSRules": [
    {
      "AllowedHeaders": ["*"],
      "AllowedMethods": ["GET", "POST", "PUT"],
      "AllowedOrigins": ["https://your-domain.com"],
      "MaxAgeSeconds": 3000
    }
  ]
}

# 3. Setup CloudFront CDN
# Create distribution pointing to S3 bucket
```

---

## 🔍 **Monitoring & Observability**

### **Application Monitoring**

```python
# 1. Add health checks
@app.get("/health")
async def health_check():
    try:
        # Test database connection
        await database.fetch_one("SELECT 1")
        
        # Test external services
        cloudinary_status = "configured" if os.getenv("CLOUDINARY_CLOUD_NAME") else "missing"
        
        return {
            "status": "healthy",
            "timestamp": datetime.utcnow(),
            "services": {
                "database": "connected",
                "cloudinary": cloudinary_status
            }
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Service unhealthy: {str(e)}")

# 2. Add performance logging
import time

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    
    logger.info(
        f"{request.method} {request.url.path} "
        f"status={response.status_code} "
        f"time={process_time:.3f}s"
    )
    
    return response
```

### **Uptime Monitoring**

```bash
# 1. Setup monitoring services
# - UptimeRobot (free): https://uptimerobot.com
# - Pingdom (paid): https://pingdom.com
# - StatusCake (freemium): https://statuscake.com

# 2. Monitor these endpoints:
# - Backend: https://your-backend.com/health
# - Web Dashboard: https://your-frontend.com
# - Database: Connection test via backend

# 3. Setup alerts
# - Email notifications
# - SMS for critical issues
# - Slack/Discord webhooks
```

---

## 🔒 **Security Configuration**

### **HTTPS Configuration**

```bash
# 1. Render/Vercel/Netlify provide HTTPS by default
# No additional configuration needed

# 2. For custom domains:
# Add CNAME record: api.yourdomain.com → your-backend.render.com
# Configure custom domain in hosting platform

# 3. Update CORS settings
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

### **Environment Variables Security**

```bash
# 1. Never commit .env files
echo ".env" >> .gitignore
echo "*.env" >> .gitignore

# 2. Use different credentials for production
# Generate new Supabase service role key for production
# Use separate Cloudinary account for production

# 3. Rotate secrets regularly
# Schedule quarterly rotation of:
# - Database passwords
# - API keys
# - JWT secrets
```

---

## 📊 **Performance Optimization**

### **Database Optimization**

```sql
-- 1. Add production indexes
CREATE INDEX CONCURRENTLY idx_showcase_posts_created_at 
    ON showcase_posts(created_at DESC);
CREATE INDEX CONCURRENTLY idx_users_email 
    ON users(email);
CREATE INDEX CONCURRENTLY idx_profiles_user_id 
    ON profiles(user_id);

-- 2. Setup connection pooling
-- Configure in DATABASE_URL:
-- ?pool=true&pool_timeout=15&pool_max_conns=30

-- 3. Enable query optimization
ANALYZE;
```

### **CDN Configuration**

```javascript
// 1. Configure caching headers
app.use((req, res, next) => {
  if (req.url.match(/\.(js|css|png|jpg|jpeg|gif|ico|svg)$/)) {
    res.setHeader('Cache-Control', 'public, max-age=31536000'); // 1 year
  }
  next();
});

// 2. Enable compression
const compression = require('compression');
app.use(compression());
```

---

## 🔄 **CI/CD Pipeline**

### **GitHub Actions (Recommended)**

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Python
        uses: actions/setup-python@v3
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          cd backend
          pip install -r requirements.txt
      - name: Run tests
        run: |
          cd backend
          pytest

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to Render
        run: |
          curl -X POST "${{ secrets.RENDER_DEPLOY_HOOK }}"
```

### **Automatic Deployments**

```bash
# 1. Render: Connect GitHub repository
# Auto-deploy on push to main branch

# 2. Vercel: Install GitHub app
# Auto-deploy on push to main branch

# 3. Railway: Connect GitHub
# Auto-deploy on push to main branch
```

---

## 📋 **Deployment Checklist**

### **Pre-deployment**
- [ ] All tests passing
- [ ] Environment variables configured
- [ ] Database migrations ready
- [ ] SSL certificates configured
- [ ] Domain names configured
- [ ] CORS settings updated

### **Post-deployment**
- [ ] Health checks passing
- [ ] Authentication working
- [ ] Database connections stable
- [ ] Media uploads functional
- [ ] Real-time features working
- [ ] Monitoring alerts configured
- [ ] Backup procedures in place

### **Go-live**
- [ ] DNS updated
- [ ] Load testing completed
- [ ] Team notified
- [ ] Documentation updated
- [ ] Rollback plan ready
- [ ] User communication sent

---

## 🆘 **Rollback Procedures**

```bash
# 1. Backend rollback
# Render: Redeploy previous version from dashboard
# Railway: railway rollback
# Vercel: vercel rollback

# 2. Database rollback
cd backend
alembic downgrade -1  # Go back one migration

# 3. Frontend rollback
git revert <commit-hash>
git push origin main
# Hosting platforms will auto-deploy reverted version

# 4. Emergency maintenance mode
# Set environment variable: MAINTENANCE_MODE=true
```

---

## 🎉 **Success Metrics**

**Performance Targets:**
- API response time: < 500ms (95th percentile)
- Web page load time: < 3 seconds
- Mobile app start time: < 5 seconds
- Uptime: > 99.5%

**Monitoring Dashboards:**
- Server metrics (CPU, memory, disk)
- Application metrics (response times, error rates)
- User metrics (active users, feature usage)
- Business metrics (registrations, posts, engagement)

---

Your Student Talent Profiling App is now ready for production! 🚀

For ongoing maintenance, refer to the [Performance Guide](../development/performance.md) and [Debugging Guide](../development/debugging.md).
