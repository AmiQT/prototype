# 📚 Student Talent Profiling App - Documentation

A comprehensive talent management system for UTHM FSKTM that digitizes manual talent management processes.

## 🚀 **Live System**
- **Web Dashboard**: [https://amiqt.github.io/prototype/](https://amiqt.github.io/prototype/)
- **Backend API**: [https://prototype-348e.onrender.com](https://prototype-348e.onrender.com)
- **Status**: ✅ Production Ready

---

## 🏗️ **System Architecture**

**Hybrid Supabase + Custom FastAPI Backend**
```
Mobile App (Flutter) ←→ Web Dashboard (HTML/JS)
        ↓                        ↓
    Custom FastAPI Backend (Python)
        ↓                        ↓
  Supabase Auth           Supabase PostgreSQL
  Cloudinary Media        Real-time Features
```

**Tech Stack:**
- 📱 **Frontend**: Flutter + HTML5/CSS3/JS
- 🔧 **Backend**: FastAPI + Supabase (Hybrid)
- 🗄️ **Database**: Supabase PostgreSQL  
- 🖼️ **Media**: Cloudinary (25GB free tier)
- 🔐 **Auth**: Supabase Auth + JWT

---

## 👥 **User Roles & Features**

| Role | Key Features |
|------|-------------|
| **🎓 Students** | Profile management, talent showcase, achievement tracking |
| **👨‍🏫 Lecturers** | Student profiles, feedback, progress monitoring |
| **🔧 Admins** | User management, analytics, content moderation |

---

## 🚀 **Quick Start for Developers**

### **⚡ 5-Minute Setup**
```bash
# 1. Clone & setup backend
git clone <repo-url>
cd backend
pip install -r requirements.txt

# 2. Configure environment
cp .env.example .env
# Add your Supabase credentials

# 3. Run backend
python main.py

# 4. Test
curl http://localhost:8000/health
```

### **📱 Mobile App Setup**
```bash
cd mobile_app
flutter pub get
flutter run
```

---

## 📖 **Documentation Structure**

### **🛠️ Setup Guides**
- **[Backend Setup](setup/backend-setup.md)** - Complete backend installation & configuration
- **[Mobile Setup](setup/mobile-setup.md)** - Flutter app development setup
- **[Deployment](setup/deployment.md)** - Production deployment guides

### **💻 Development**
- **[Architecture Guide](development/architecture.md)** - System architecture & design decisions
- **[Performance Guide](development/performance.md)** - Optimization strategies & best practices
- **[Debugging Guide](development/debugging.md)** - Common issues & troubleshooting

### **🔧 Utilities & References**
- **[Cloudinary Setup](backend/CLOUDINARY_SETUP.md)** - Media storage configuration guide
- **[Database Reset Guide](backend/DATABASE_RESET_README.md)** - Database troubleshooting & reset instructions

### **🎯 Strategy & Implementation Plans**
- **[🎯 Current Focus Summary](CURRENT_FOCUS_SUMMARY_by_claude.md)** - ⚡ **Quick Start** - What we're working on right now
- **[Showcase Module Strategy](SHOWCASE_MODULE_PRACTICAL_STRATEGY_by_claude.md)** - ⭐ **Main Plan** - Comprehensive implementation strategy

### **🚀 Future Enhancement Proposals**
- **[🤖 AI Agentic Features Proposal](development/ai-agentic-features-proposal.md)** - 📋 **Future Scope** - AI agent integration for administrative automation
- **[🎯 AI Admin Usage Guide](development/ai-admin-usage-guide.md)** - 💡 **Practical Examples** - How admin akan guna AI features dalam real world
- **[🔗 AI Features Connection Examples](development/ai-features-practical-examples.md)** - ⚡ **The Magic Explained** - How simple commands trigger advanced AI capabilities
- **[💰 Zero Budget AI Reality Check](development/ai-zero-budget-reality-check.md)** - 🎯 **Realistic Plan** - What's actually possible dengan RM 0 budget
- **[🚀 Real AI Implementation Plan](development/real-ai-implementation-plan.md)** - 🔥 **GAME CHANGER** - Full implementation dengan Gemini/Qwen/DeepSeek APIs
- **[⚡ OpenRouter Development Phase](development/openrouter-development-phase.md)** - 🎯 **CURRENT PLAN** - Realistic development using OpenRouter free tier

---

## 🎯 **Key Achievements**

✅ **Production Deployment** - Live system with real users  
✅ **Hybrid Architecture** - Best of Supabase + Custom FastAPI  
✅ **Performance Optimized** - 50-80% faster loading with caching  
✅ **Media System** - Cloudinary integration with 25GB free tier  
✅ **Modern UI/UX** - Dark mode, responsive design  
✅ **AI/ML Ready** - Architecture supports ML features  

---

## 📈 **Project Status**

| Component | Status | Version | Notes |
|-----------|--------|---------|--------|
| 🌐 Web Dashboard | ✅ Production Ready | v1.1 | **Fixed: User creation + clean architecture** |
| 📱 Mobile App | ✅ Production Ready | v1.1 | **Fixed: Like UI + Comment username issues** |
| 🔧 Backend API | ✅ Live | v1.0 | Reserved for data mining & analytics only |
| 🎯 Showcase Module | ✅ Completed | v1.1 | All critical issues resolved |
| 🤖 ML Features | 📋 Planned | v2.0 | Future scope - custom backend analytics |

---

## 🆘 **Need Help?**

- **🚀 Quick Issues**: Check [Debugging Guide](development/debugging.md)
- **🏗️ Architecture Questions**: See [Architecture Guide](development/architecture.md)  
- **🐛 Bug Reports**: Create GitHub issue with full details
- **💡 Feature Requests**: Discuss in GitHub Discussions

---

## 🤝 **Contributing**

1. Read [Contributing Guidelines](development/contributing.md)
2. Fork repository & create feature branch
3. Follow code standards & write tests
4. Submit pull request with clear description

---

**Last Updated**: $(Get-Date -Format "MMMM dd, yyyy")  
**Maintainers**: Development Team  
**License**: MIT