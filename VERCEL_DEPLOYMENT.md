# 🚀 Vercel Deployment Guide untuk Prototype

## 📋 **Prasyarat**
- [Vercel Account](https://vercel.com/signup)
- [GitHub Repository](https://github.com) yang sudah connect dengan Vercel
- Node.js 18+ (untuk local development)

## 🔧 **Setup Deployment**

### **1. Install Vercel CLI**
```bash
npm i -g vercel
```

### **2. Login ke Vercel**
```bash
vercel login
```

### **3. Deploy dari Root Directory**
```bash
# Dari root folder projek
vercel --prod
```

### **4. Atau Deploy Web Dashboard Sahaja**
```bash
# Dari folder web_dashboard
cd web_dashboard
vercel --prod
```

## 🌐 **Environment Variables**

Set environment variables di Vercel Dashboard:

```bash
BACKEND_URL=https://prototype-348e.onrender.com
```

## 📁 **Struktur Deployment**

```
prototype/
├── web_dashboard/          # Frontend (akan di-deploy)
│   ├── index.html
│   ├── login.html
│   ├── css/
│   ├── js/
│   └── modals/
├── backend/                # Backend (deployed separately)
├── mobile_app/             # Mobile app (not deployed)
└── vercel.json            # Vercel configuration
```

## 🔄 **Auto-Deploy**

Setelah setup, setiap push ke branch `main` akan auto-deploy ke Vercel.

## 📱 **URLs**

- **Production**: `https://prototype-talent-app.vercel.app`
- **Preview**: `https://prototype-talent-app-git-main.vercel.app`

## 🚨 **Troubleshooting**

### **Build Error**
- Check `vercel.json` configuration
- Ensure all files are committed
- Check environment variables

### **Routing Issues**
- Verify routes in `vercel.json`
- Check file paths in `web_dashboard` folder

### **Environment Variables**
- Set `BACKEND_URL` in Vercel dashboard
- Restart deployment after adding variables

## 📞 **Support**

Jika ada masalah, check:
1. Vercel build logs
2. Browser console errors
3. Network requests
4. Environment variables

## 🎯 **Next Steps**

1. Deploy ke Vercel
2. Set environment variables
3. Test functionality
4. Connect custom domain (optional)
5. Setup monitoring
