# Student Talent Profiling App - Prototype

Projek ini adalah aplikasi Student Talent Profiling yang terdiri daripada tiga komponen utama: backend, mobile app, dan web dashboard.

## 📁 Struktur Projek

```
Prototype/
├── 📱 mobile_app/          # Flutter mobile application
├── 🔧 backend/             # Python FastAPI backend
├── 🌐 web_dashboard/       # Web dashboard (HTML/CSS/JS)
├── 📊 data/                # JSON data files
├── 🖼️ assets/              # Images, icons, and media files
├── 🛠️ tools/               # Executable tools (acli.exe, ngrok.exe)
├── 📝 docs/                # Documentation files
├── ⚡ api/                 # API files
└── 🔧 functions/           # Cloud functions
```

## 🏗️ Hybrid Backend Architecture

Projek ini menggunakan **architecture hybrid** yang menggabungkan kekuatan Supabase dengan fleksibiliti custom FastAPI:

```
Frontend Apps → FastAPI (Custom Logic) → Supabase (Auth + DB)
     ↓              ↓                        ↓
  Mobile App    Business Logic           PostgreSQL
  Web Dashboard  Search Engine           Authentication
                 Analytics               Real-time Features
                 Media Upload
```

### 🔄 Mengapa Hybrid?
- **Supabase**: Instant backend, auth, real-time DB
- **FastAPI**: Custom business logic, advanced features
- **Best of Both Worlds**: Rapid development + Full control

### 📈 Migration History
- ✅ **Migrated from Firebase to Supabase** for better PostgreSQL support
- ✅ **Kept FastAPI** for custom endpoints & business logic
- ✅ **Added Cloudinary** for optimized media storage

### 🔧 Technical Stack
```
Authentication:  Supabase Auth → JWT tokens
Database:        Supabase PostgreSQL → SQLAlchemy ORM
API Layer:       Custom FastAPI → RESTful endpoints
Media:           Cloudinary → Image/Video upload
Search:          Custom algorithms → Advanced filtering
```

## 🚀 Komponen Utama

### 1. Mobile App (Flutter)
- **Lokasi**: `mobile_app/`
- **Platform**: Android, iOS, Web, Windows, macOS, Linux
- **Framework**: Flutter/Dart
- **Features**: Student profiling, talent assessment, dark mode support

### 2. Backend (Hybrid Architecture)
- **Lokasi**: `backend/`
- **Architecture**: **Hybrid Supabase + Custom FastAPI**
- **Framework**: Python FastAPI
- **Database**: Supabase PostgreSQL
- **Authentication**: Supabase Auth dengan JWT
- **Media Storage**: Cloudinary
- **Features**: 
  - 🔐 Supabase authentication & real-time database
  - 🚀 Custom FastAPI endpoints & business logic
  - 📱 Advanced search & analytics
  - 🖼️ Media upload & management
  - 🔄 Database migrations dengan Alembic

### 3. Web Dashboard
- **Lokasi**: `web_dashboard/`
- **Tech Stack**: HTML5, CSS3, JavaScript
- **Features**: Admin dashboard, analytics, user management

## 📊 Data & Assets

### Data Files (`data/`)
- `complete_fsktm_data.json` - Data lengkap FSKTM
- `fsktm_comprehensive_knowledge_base.json` - Knowledge base
- `fsktm_website_data_collection.json` - Data collection

### Assets (`assets/`)
- `App Cover Page.png` - Cover page aplikasi
- `uthm.png` - Logo UTHM
- `favicon.ico` - Favicon untuk web

### Tools (`tools/`)
- `acli.exe` - Azure CLI tool
- `ngrok.exe` - Tunneling tool untuk development

## 📖 Dokumentasi

Dokumentasi lengkap tersedia di folder `docs/`:
- **Backend**: Setup instructions, database management
- **Mobile App**: Implementation guides, troubleshooting
- **Web Dashboard**: Local testing, deployment guides

## 🚨 **Current Development Focus**

**⚡ PRIORITY**: Showcase Module Fixes untuk Mobile App

### 🎯 **What We're Working On (Sept 2025)**
- **📱 Mobile App Showcase Features**: Fixing critical user experience issues
- **🔧 Database Consistency**: Standardizing like/comment systems  
- **🚀 Performance**: Improving app responsiveness and reliability
- **📊 Timeline**: 6-week implementation plan

### 📖 **Key Documents**
- **[🎯 Current Focus Summary](docs/CURRENT_FOCUS_SUMMARY_by_claude.md)** - What we're doing right now
- **[Showcase Strategy Plan](docs/SHOWCASE_MODULE_PRACTICAL_STRATEGY_by_claude.md)** - Complete implementation roadmap

---

## 🛠️ Development Setup

### Backend (Hybrid Setup)
1. **Supabase Setup**: Configure Supabase project & database
2. **Environment Variables**: Setup JWT secrets & database URL
3. **FastAPI**: Install dependencies & run custom server
4. **Cloudinary**: Configure media upload credentials

**Detailed guides:**
- Backend: `docs/backend/SETUP_INSTRUCTIONS.md`
- Hybrid Architecture: `docs/backend/HYBRID_BACKEND_ARCHITECTURE.md`

### Frontend Applications  
- Mobile App: `docs/mobile_app/README.md`  
- Web Dashboard: `docs/web_dashboard/README.md`

## 📝 File Konfigurasi

- `Prototype.code-workspace` - VS Code workspace settings
- `remove_firebase_dependencies.yaml` - Firebase cleanup script

## 🎯 Tujuan Projek

Aplikasi ini bertujuan untuk:
- Membantu pelajar mengenal pasti bakat dan minat mereka
- Menyediakan platform profiling yang komprehensif
- Memberikan insights kepada pelajar tentang kerjaya yang sesuai

---

Untuk maklumat teknikal yang lebih terperinci, sila rujuk dokumentasi dalam folder `docs/`.
