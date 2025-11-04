# 🚀 Guide: Link Backend dengan Vercel

## 📋 Overview
Web dashboard anda sekarang deployed di Vercel. Untuk connect dengan backend, ikut langkah ini:

---

## 1️⃣ Deploy Backend (Pilih salah satu)

### **Option A: Railway (Recommended)**

```powershell
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Deploy
cd backend
railway init
railway up
```

Selepas deploy, Railway akan bagi URL: `https://your-app.railway.app`

---

### **Option B: Render (Free Forever)**

1. Pergi ke https://render.com
2. Sign up/Login dengan GitHub
3. Click **"New +"** → **"Web Service"**
4. Connect repository: **AmiQT/prototype**
5. Configure:
   - **Name**: student-talent-backend
   - **Root Directory**: `backend`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`
6. Set Environment Variables:
   ```
   DATABASE_URL=<your-supabase-or-postgres-url>
   CLOUDINARY_CLOUD_NAME=<your-cloudinary-name>
   CLOUDINARY_API_KEY=<your-cloudinary-key>
   CLOUDINARY_API_SECRET=<your-cloudinary-secret>
   SECRET_KEY=<generate-random-key>
   ALGORITHM=HS256
   ENVIRONMENT=production
   ```
7. Click **"Create Web Service"**

Selepas deploy, Render akan bagi URL: `https://your-app.onrender.com`

---

## 2️⃣ Update Backend URL di Code

Edit file: `web_dashboard/js/config/env-setup.js`

```javascript
// Line 12-13: Update dengan backend URL anda
const LOCAL_BACKEND_URL = 'http://127.0.0.1:8000';
const PRODUCTION_BACKEND_URL = 'https://your-actual-backend.railway.app'; // ⚠️ GANTI INI
```

**Replace** `https://your-actual-backend.railway.app` dengan URL yang anda dapat dari Railway/Render.

---

## 3️⃣ Push Update ke Vercel

```powershell
cd web_dashboard
vercel --prod
```

---

## 4️⃣ Test Connection

1. Buka production URL: https://student-talent-profiling-2cw1eyzuc-noor-azamis-projects.vercel.app
2. Login
3. Check browser console untuk confirm backend connection
4. Test features yang guna backend API

---

## 🔧 Troubleshooting

### CORS Error
Pastikan backend ada CORS configuration untuk Vercel domain:

```python
# backend/main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://student-talent-profiling-2cw1eyzuc-noor-azamis-projects.vercel.app",
        "https://*.vercel.app",
        "http://localhost:*"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Backend Not Responding
- Check backend logs: `railway logs` atau Render dashboard
- Verify environment variables are set
- Check database connection

### Local Development
Code automatically detect local vs production:
- **Local**: Guna `http://127.0.0.1:8000`
- **Production**: Guna URL yang anda set dalam `PRODUCTION_BACKEND_URL`

---

## 📝 Notes

- ✅ Frontend auto-switch antara local dan production backend
- ✅ No build step needed untuk update backend URL
- ✅ CORS configured untuk accept Vercel domain
- ✅ Environment detection automatic

---

## 🎯 Next Steps

1. Deploy backend → Get URL
2. Update `PRODUCTION_BACKEND_URL` in `env-setup.js`
3. Push to Vercel: `vercel --prod`
4. Test & verify ✅
