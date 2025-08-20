# 🚀 Cloud Development Setup Guide

This guide will help you set up your project for cloud-based development without running local servers.

## 📋 Prerequisites

- GitHub account
- Supabase account (already configured)
- Cloudinary account (for media uploads)
- Railway/Render account (for backend)
- Vercel/Netlify account (for web dashboard)

## 🔧 Step 1: Backend Deployment (FastAPI)

### Option A: Railway (Recommended - Free Tier)
1. Go to [Railway.app](https://railway.app)
2. Connect your GitHub repository
3. Create new project from GitHub
4. Select the `backend` folder
5. Add environment variables from `.env.cloud`
6. Deploy!

### Option B: Render
1. Go to [Render.com](https://render.com)
2. Connect your GitHub repository
3. Create new Web Service
4. Select the `backend` folder
5. Add environment variables from `.env.cloud`
6. Deploy!

## 🌐 Step 2: Web Dashboard Deployment

### Option A: Vercel (Recommended)
1. Go to [Vercel.com](https://vercel.com)
2. Import your GitHub repository
3. Set root directory to `web_dashboard`
4. Deploy!

### Option B: Netlify
1. Go to [Netlify.com](https://netlify.com)
2. Import your GitHub repository
3. Set publish directory to `web_dashboard`
4. Deploy!

## 📱 Step 3: Mobile App Development

### Flutter Web Development
```bash
cd mobile_app
flutter run -d chrome --web-port 3000
```

### Flutter Web Build for Testing
```bash
cd mobile_app
flutter build web
# Serve the build/web folder
```

## 🔑 Step 4: Environment Variables Setup

### Backend (Railway/Render)
Copy these from `.env.cloud`:
- `DATABASE_URL` - Your Supabase PostgreSQL connection string
- `CLOUDINARY_CLOUD_NAME` - Your Cloudinary cloud name
- `CLOUDINARY_API_KEY` - Your Cloudinary API key
- `CLOUDINARY_API_SECRET` - Your Cloudinary API secret
- `SECRET_KEY` - Generate a secure random string
- `ALLOWED_ORIGINS` - Your web dashboard URLs

### Web Dashboard
- `BACKEND_URL` - Your deployed backend URL

## 🚀 Step 5: Update Configuration Files

### Update Backend URL in Mobile App
```dart
// mobile_app/lib/config/app_config.dart
class AppConfig {
  static const String backendUrl = 'https://your-backend.railway.app';
  // ... other config
}
```

### Update Web Dashboard Backend URL
```javascript
// web_dashboard/js/config/backend-config.js
const BACKEND_CONFIG = {
  baseUrl: 'https://your-backend.railway.app',
  // ... other config
};
```

## 📊 Step 6: Database Setup

Your Supabase database is already configured! Just ensure:
1. Database is accessible from cloud platforms
2. Connection string is correct in environment variables
3. Tables are created (run migrations if needed)

## 🧪 Step 7: Testing Your Setup

### Test Backend
```bash
curl https://your-backend.railway.app/health
```

### Test Web Dashboard
- Open your deployed web dashboard URL
- Check if it can connect to the backend

### Test Mobile App
- Run Flutter web version
- Test API connections

## 🔄 Development Workflow

1. **Code Changes**: Make changes locally
2. **Push to GitHub**: Commit and push your changes
3. **Auto-Deploy**: Railway/Render will automatically redeploy
4. **Test**: Test on deployed URLs
5. **Repeat**: Continue development cycle

## 🆘 Troubleshooting

### Backend Issues
- Check Railway/Render logs
- Verify environment variables
- Check database connectivity

### Web Dashboard Issues
- Check browser console for errors
- Verify backend URL configuration
- Check CORS settings

### Database Issues
- Verify Supabase connection string
- Check if database is accessible from cloud
- Run database migrations if needed

## 💡 Tips for Cloud Development

1. **Use Environment Variables**: Never hardcode URLs or secrets
2. **Monitor Logs**: Check deployment logs regularly
3. **Test Early**: Test on cloud environment early in development
4. **Use Preview Deployments**: Test changes before production
5. **Backup Data**: Regular database backups

## 🎯 Next Steps

1. Deploy backend to Railway/Render
2. Deploy web dashboard to Vercel/Netlify
3. Update configuration files with new URLs
4. Test all connections
5. Start developing in the cloud! 🚀
