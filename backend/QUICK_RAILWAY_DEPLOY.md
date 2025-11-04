# ⚡ Quick Railway Deployment Checklist

## 📋 Before You Start
- [x] Railway account created
- [x] GitHub repo pushed
- [x] Supabase database running
- [x] Vercel frontend deployed

---

## 🚀 5-Minute Railway Deployment

### Step 1: Create Project (1 min)
1. Go to https://railway.app/new
2. Click "Deploy from GitHub repo"
3. Select: `AmiQT/prototype`
4. Wait for detection...

### Step 2: Configure Service (2 min)
1. Click on the deployed service
2. Go to **Settings** tab
3. Scroll to **Root Directory**
4. Enter: `backend`
5. Click **Save**

### Step 3: Add Environment Variables (2 min)
Click **Variables** tab, then copy-paste these one by one:

**Quick Copy Variables:**
```
DATABASE_URL=<GET_FROM_SUPABASE>
SUPABASE_URL=https://xibffemtpboiecpeynon.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhpYmZmZW10cGJvaWVjcGV5bm9uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU1ODkzOTYsImV4cCI6MjA3MTE2NTM5Nn0.mwQndhu5_uX26T-qTEOCiLya74DUD6Iw8vV3ffuA5mM
SUPABASE_SERVICE_ROLE_KEY=<GET_FROM_SUPABASE>
SUPABASE_JWT_SECRET=<GET_FROM_SUPABASE>
CLOUDINARY_CLOUD_NAME=<YOUR_VALUE>
CLOUDINARY_API_KEY=<YOUR_VALUE>
CLOUDINARY_API_SECRET=<YOUR_VALUE>
GOOGLE_API_KEY=<YOUR_VALUE>
SECRET_KEY=<GENERATE_NEW>
ALGORITHM=HS256
ALLOWED_ORIGINS=https://student-talent-profiling-2cw1eyzuc-noor-azamis-projects.vercel.app
ENVIRONMENT=production
PORT=8000
```

**🔑 Quick Links to Get Values:**

| Variable | Where to Get |
|----------|-------------|
| `DATABASE_URL` | Supabase → Settings → Database → Connection Pooling (port 6543) |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase → Settings → API → service_role key |
| `SUPABASE_JWT_SECRET` | Supabase → Settings → API → JWT Secret |
| `CLOUDINARY_*` | https://console.cloudinary.com/console |
| `GOOGLE_API_KEY` | https://makersuite.google.com/app/apikey |
| `SECRET_KEY` | Run: `python -c "import secrets; print(secrets.token_urlsafe(32))"` |

### Step 4: Generate Domain (30 sec)
1. Go to **Settings** → **Networking**
2. Click **Generate Domain**
3. Copy your URL: `https://xxxxx.up.railway.app`

### Step 5: Test Deployment (30 sec)
Open these URLs:
```
✅ https://your-app.up.railway.app/docs
✅ https://your-app.up.railway.app/health
```

---

## 🔗 Update Frontend

### In Vercel:
1. Go to project → **Settings** → **Environment Variables**
2. Add new variable:
   - Name: `VITE_API_URL` (or `API_URL`)
   - Value: `https://your-app.up.railway.app`
3. Redeploy!

---

## ✅ Post-Deployment Test

Test these endpoints from your browser:

1. **Health Check:**
   ```
   https://your-app.up.railway.app/health
   Expected: {"status": "healthy"}
   ```

2. **API Docs:**
   ```
   https://your-app.up.railway.app/docs
   Expected: Swagger UI page
   ```

3. **CORS Test:**
   - Go to your Vercel frontend
   - Try login
   - Check browser console for CORS errors

---

## 🐛 If Something Goes Wrong

### Check Logs:
1. Railway Dashboard → Your Service
2. Click **Deployments** tab
3. Click latest deployment
4. View **Logs** - look for errors

### Common Fixes:

**Error: "Module not found"**
```
Fix: Settings → Root Directory → Set to "backend"
```

**Error: "Database connection failed"**
```
Fix: Use connection pooling URL (port 6543)
Add: ?sslmode=require at end of DATABASE_URL
```

**Error: "CORS blocked"**
```
Fix: Add Vercel URL to ALLOWED_ORIGINS variable
No spaces between URLs!
```

---

## 📊 Monitor Your App

### Check Usage:
- Railway Dashboard → Account → Usage
- Monitor your $5/month credit

### Set Up Monitoring:
- Use UptimeRobot (free): https://uptimerobot.com/
- Ping your `/health` endpoint every 5 minutes

---

## 🎯 Production URLs

After deployment, you'll have:

| Service | URL |
|---------|-----|
| Frontend | https://student-talent-profiling-2cw1eyzuc-noor-azamis-projects.vercel.app |
| Backend | https://your-app.up.railway.app |
| Database | Supabase (managed) |
| Storage | Cloudinary (managed) |

---

## 🎉 Success Checklist

- [ ] Railway deployment successful (green checkmark)
- [ ] `/docs` endpoint loads
- [ ] `/health` returns 200
- [ ] Vercel updated with Railway URL
- [ ] Can login from frontend
- [ ] API calls work from frontend
- [ ] No CORS errors in console
- [ ] Logs show no critical errors

---

**Time to complete: ~5 minutes** ⚡

**Questions?** Check full guide: `RAILWAY_DEPLOYMENT_GUIDE.md`
