# 🚂 Railway Deployment Guide - Student Talent Backend

## 📋 Pre-Deployment Checklist

### ✅ What You Already Have:
- [x] Railway account
- [x] GitHub repository: `AmiQT/prototype`
- [x] Supabase database running
- [x] Vercel frontend deployed
- [x] Railway config files ready

---

## 🚀 Step-by-Step Deployment

### 1️⃣ **Login to Railway**
Go to: https://railway.app/
- Login dengan GitHub account

### 2️⃣ **Create New Project**
1. Click "New Project"
2. Select "Deploy from GitHub repo"
3. Select repository: `AmiQT/prototype`
4. Railway will auto-detect your backend in `/backend` folder

### 3️⃣ **Configure Root Directory**
Railway needs to know where your backend is:
1. Go to **Settings** tab
2. Find **Root Directory**
3. Set to: `backend`
4. Click Save

### 4️⃣ **Add Environment Variables**
Go to **Variables** tab and add these:

#### 🔐 Required Variables:

```bash
# Database
DATABASE_URL=postgresql://postgres.[YOUR-PROJECT]:[PASSWORD]@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres

# Supabase
SUPABASE_URL=https://xibffemtpboiecpeynon.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhpYmZmZW10cGJvaWVjcGV5bm9uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU1ODkzOTYsImV4cCI6MjA3MTE2NTM5Nn0.mwQndhu5_uX26T-qTEOCiLya74DUD6Iw8vV3ffuA5mM
SUPABASE_SERVICE_ROLE_KEY=[YOUR_SERVICE_ROLE_KEY]
SUPABASE_JWT_SECRET=[YOUR_JWT_SECRET]

# Cloudinary
CLOUDINARY_CLOUD_NAME=[YOUR_CLOUD_NAME]
CLOUDINARY_API_KEY=[YOUR_API_KEY]
CLOUDINARY_API_SECRET=[YOUR_API_SECRET]

# Google AI
GOOGLE_API_KEY=[YOUR_GEMINI_API_KEY]

# Security
SECRET_KEY=[GENERATE_RANDOM_STRING]
ALGORITHM=HS256

# CORS - IMPORTANT!
ALLOWED_ORIGINS=https://student-talent-profiling-2cw1eyzuc-noor-azamis-projects.vercel.app,https://your-custom-domain.vercel.app

# Environment
ENVIRONMENT=production
PORT=8000
```

#### 📍 Where to Get These Values:

**DATABASE_URL:**
- Go to Supabase → Settings → Database
- Copy "Connection pooling" string (port 6543)
- Use this for Railway (better for serverless)

**SUPABASE_JWT_SECRET:**
- Go to Supabase → Settings → API
- Copy "JWT Secret"

**SUPABASE_SERVICE_ROLE_KEY:**
- Go to Supabase → Settings → API
- Copy "service_role" key (secret)

**CLOUDINARY:**
- Go to Cloudinary Dashboard
- Copy Cloud Name, API Key, API Secret

**GOOGLE_API_KEY:**
- Go to Google AI Studio
- https://makersuite.google.com/app/apikey
- Copy your Gemini API key

**SECRET_KEY (Generate):**
```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

### 5️⃣ **Deploy!**
1. Railway will auto-deploy after you set environment variables
2. Wait for build to complete (2-3 minutes)
3. Look for ✅ "Deploy successful"

### 6️⃣ **Get Your Backend URL**
1. Go to **Settings** tab
2. Find **Domains** section
3. Click "Generate Domain"
4. You'll get: `https://your-app.up.railway.app`
5. **SAVE THIS URL!** You need it for frontend

### 7️⃣ **Test Your Deployment**
Open in browser:
```
https://your-app.up.railway.app/docs
```
You should see FastAPI Swagger documentation!

Test health endpoint:
```
https://your-app.up.railway.app/health
```

---

## 🔗 Update Frontend (Vercel)

Now update your Vercel frontend to use Railway backend:

### In Vercel Dashboard:
1. Go to your project → Settings → Environment Variables
2. Add/Update:
```bash
NEXT_PUBLIC_API_URL=https://your-app.up.railway.app
# or if using plain JS
API_URL=https://your-app.up.railway.app
```

### Update web_dashboard config:
Update `web_dashboard/js/config/api-config.js`:
```javascript
const API_BASE_URL = 'https://your-app.up.railway.app';
```

Then redeploy Vercel!

---

## 📊 Monitoring & Logs

### View Logs:
1. Go to Railway project
2. Click on your service
3. Go to **Deployments** tab
4. Click latest deployment
5. View **Logs** in real-time

### Check Metrics:
- CPU usage
- Memory usage
- Request count
- Response times

---

## 🔧 Common Issues & Solutions

### ❌ Issue: "Module not found"
**Solution:** Make sure `Root Directory` is set to `backend`

### ❌ Issue: "Database connection failed"
**Solution:** 
- Use Supabase connection pooling URL (port 6543)
- Add `?sslmode=require` at the end

### ❌ Issue: "CORS errors"
**Solution:**
- Add your Vercel URL to `ALLOWED_ORIGINS`
- Include both preview and production URLs

### ❌ Issue: "Health check failing"
**Solution:**
- Check logs for errors
- Verify `/health` endpoint exists
- Increase `healthcheckTimeout` in railway.json

---

## 💰 Cost Management

### Free Tier (GitHub Education):
- $5/month credit
- ~500 hours execution time
- 1GB RAM, 1 vCPU
- Perfect untuk small-medium traffic!

### Monitor Usage:
- Go to **Account** → **Usage**
- Check credit remaining
- Set up alerts

---

## 🎯 Production Best Practices

### 1. Custom Domain (Optional)
Railway supports custom domains:
1. Go to Settings → Domains
2. Add your domain
3. Update DNS records

### 2. Environment-specific configs
Keep separate configs for:
- Development (local)
- Staging (Railway)
- Production (Railway with custom domain)

### 3. Database Backups
Supabase handles this automatically!
- Daily backups
- Point-in-time recovery (paid plans)

### 4. Monitoring
Set up external monitoring:
- UptimeRobot (free)
- Better Stack (free tier)
- Ping your `/health` endpoint every 5 mins

---

## 🆘 Need Help?

### Railway Docs:
https://docs.railway.app/

### Railway Discord:
https://discord.gg/railway

### Your Backend Status:
- Backend: `https://your-app.up.railway.app`
- Frontend: `https://student-talent-profiling-2cw1eyzuc-noor-azamis-projects.vercel.app`
- Database: Supabase (already running)

---

## ✅ Deployment Complete Checklist

- [ ] Railway project created
- [ ] Root directory set to `backend`
- [ ] All environment variables added
- [ ] Deployment successful (green ✅)
- [ ] `/docs` endpoint accessible
- [ ] `/health` endpoint returns 200
- [ ] Vercel updated with Railway URL
- [ ] CORS configured correctly
- [ ] Test API endpoints from frontend
- [ ] Check logs for any errors

---

## 🚀 Next Steps

1. **Test all features** from your Vercel frontend
2. **Monitor logs** for first few hours
3. **Set up alerts** for downtime
4. **Document your API endpoints**
5. **Share with users!** 🎉

---

**Congratulations!** Your full-stack app is now LIVE on production! 🎊

**Stack:**
- Frontend: Vercel
- Backend: Railway
- Database: Supabase
- Storage: Cloudinary
- AI: Google Gemini

Everything is connected and ready for users! 🚀
