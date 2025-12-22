# 🏗️ System Architecture

Comprehensive overview of the Student Talent Profiling App architecture.

## 🎯 **Architecture Overview**

**Hybrid Cloud Architecture** combining Supabase managed services with custom FastAPI backend.

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │    │   Web Dashboard │    │     Admin       │
│   (Flutter)     │◄──►│   (HTML/CSS/JS) │◄──►│   Interface     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         ▲                        ▲                        ▲
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FastAPI Backend (Python)                     │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌──────────┐  │
│  │   Auth      │ │  Business   │ │  Analytics  │ │   Media  │  │
│  │ Middleware  │ │   Logic     │ │   & ML      │ │ Service  │  │
│  └─────────────┘ └─────────────┘ └─────────────┘ └──────────┘  │
└─────────────────────────────────────────────────────────────────┘
         ▲                        ▲                        ▲
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Supabase Auth  │    │ Supabase        │    │   Cloudinary    │
│  (JWT Tokens)   │    │ PostgreSQL      │    │ (Media Storage) │
│                 │    │ (Real-time DB)  │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## 🔄 **Why Hybrid Architecture?**

### **Traditional vs Hybrid Comparison**

| Aspect | Firebase Only | Custom Backend Only | **Hybrid (Our Choice)** |
|--------|---------------|-------------------|------------------------|
| **Development Speed** | ⚡ Very Fast | 🐌 Slow | ⚡ Fast |
| **Real-time Features** | ✅ Built-in | ❌ Custom implementation | ✅ Built-in |
| **Complex Queries** | ❌ Limited | ✅ Full SQL | ✅ Full SQL |
| **ML/Analytics** | ❌ Limited | ✅ Full control | ✅ Full control |
| **Cost at Scale** | 💰 High | 💰 Medium | 💰 Low |
| **Flexibility** | ❌ Limited | ✅ Full | ✅ Full |

### **Key Benefits**
- **🚀 Rapid Development**: Supabase handles auth, database, real-time
- **💪 Full Power**: Custom FastAPI for complex business logic
- **📈 Scalable**: Can handle 100K+ users efficiently  
- **💰 Cost Effective**: Optimized for free tiers and scaling
- **🔮 Future-Proof**: Can add any feature without platform limitations

---

## 🛠️ **Technology Stack**

### **Frontend Applications**
```yaml
Mobile App (Flutter):
  - Framework: Flutter 3.19+
  - State Management: Provider
  - HTTP Client: http package
  - Local Storage: SharedPreferences
  - Authentication: Supabase Auth
  - Real-time: Supabase Realtime

Web Dashboard (HTML/CSS/JS):
  - Framework: Vanilla JavaScript (lightweight)
  - CSS Framework: Custom CSS Grid/Flexbox
  - HTTP Client: Fetch API
  - Authentication: Supabase Auth
  - Real-time: Supabase Realtime
```

### **Backend Services**
```yaml
Custom FastAPI Backend:
  - Framework: FastAPI 0.104+
  - Language: Python 3.11+
  - ORM: SQLAlchemy + Alembic
  - Authentication: JWT token verification
  - Caching: Redis (planned)
  - Background Tasks: Celery (planned)
  
Supabase Services:
  - Database: PostgreSQL 15+ with JSONB support
  - Authentication: Built-in Auth with JWT
  - Real-time: WebSocket connections
  - Storage: File storage (backup only)
```

### **External Services**
```yaml
Media Storage:
  - Primary: Cloudinary (25GB free tier)
  - Features: Auto-optimization, CDN, transformations
  - Backup: Supabase Storage (5GB free tier)

Deployment:
  - Backend: Render.com (free tier)  
  - Frontend: GitHub Pages (free)
  - Database: Supabase (free tier)
```

---

## 🗄️ **Data Architecture**

### **Database Schema Design**

**Users & Authentication**
```sql
-- Core user data (synced with Supabase Auth)
users {
  id: string (pk)           -- Supabase user ID  
  email: string (unique)    -- User email
  name: string             -- Display name
  role: enum               -- student, lecturer, admin
  created_at: timestamp
}

-- Extended profile information  
profiles {
  id: string (pk)
  user_id: string (fk)     -- References users.id
  full_name: string
  bio: text
  skills: jsonb            -- ["Python", "JavaScript"]
  academic_info: jsonb     -- Flexible academic data
  social_links: jsonb      -- LinkedIn, GitHub, etc.
}
```

**Content & Engagement**
```sql
-- Student talent showcase posts
showcase_posts {
  id: string (pk)
  user_id: string (fk)
  content: text
  media_urls: jsonb        -- Array of Cloudinary URLs
  category: string         -- technical, creative, etc.
  skills_used: jsonb       -- Skills demonstrated
  is_public: boolean
  created_at: timestamp
}

-- Social engagement
showcase_likes {
  user_id: string (fk)
  post_id: string (fk)
  created_at: timestamp
  PRIMARY KEY (user_id, post_id)
}
```

**Events & Achievements**
```sql
-- University events and competitions
events {
  id: string (pk)
  title: string
  description: text
  category: string
  start_date: timestamp
  created_by: string (fk)
}

-- Student achievements and certifications
achievements {
  id: string (pk)
  title: string
  description: text
  badge_image_url: string
  verification_url: string
  is_verified: boolean
}
```

### **JSONB Usage Strategy**
```json
// Flexible skill storage
"skills": [
  {"name": "Python", "level": "Advanced", "verified": true},
  {"name": "Machine Learning", "level": "Intermediate", "verified": false}
]

// Academic information
"academic_info": {
  "student_id": "FSKTM123456",
  "department": "Computer Science", 
  "year": 3,
  "cgpa": 3.75,
  "graduation_date": "2025-07-01"
}
```

---

## 🔀 **Data Flow Patterns**

### **Authentication Flow**
```
1. User logs in via Supabase Auth (Mobile/Web)
2. Supabase returns JWT token
3. Client includes JWT in API requests
4. FastAPI verifies JWT with Supabase
5. Request processed with user context
```

### **Content Publishing Flow**
```
1. User creates showcase post (Mobile)
2. Media uploaded to Cloudinary
3. Post data sent to FastAPI backend
4. FastAPI saves to Supabase database  
5. Real-time update via Supabase Realtime
6. Other users see update instantly
```

### **Search & Analytics Flow**
```
1. User searches for students (Web/Mobile)
2. Request sent to FastAPI backend
3. Complex SQL query executed
4. Results cached in Redis
5. Formatted results returned
6. Cache serves subsequent similar queries
```

---

## 🔐 **Security Architecture**

### **Authentication & Authorization**
```python
# JWT Token Verification
@app.middleware("http")
async def verify_jwt_token(request: Request, call_next):
    # Extract JWT from Authorization header
    # Verify with Supabase Auth
    # Add user context to request
    pass

# Role-based Access Control  
@app.get("/admin/users")
async def get_all_users(current_user: dict = Depends(verify_admin_role)):
    # Only admin users can access this endpoint
    pass
```

### **Data Privacy**
```python
# Profile visibility based on privacy settings
def filter_profile_data(profile_data: dict, requesting_user: dict):
    if profile_data.get('privacy') == 'private':
        # Return limited data for private profiles
        return limited_profile_data
    return full_profile_data
```

### **Input Validation**
```python
# Pydantic models for data validation
class ShowcasePostCreate(BaseModel):
    content: str = Field(..., max_length=5000)
    category: str = Field(..., regex="^(technical|creative|academic)$")
    media_urls: List[HttpUrl] = Field(default=[])
```

---

## ⚡ **Performance Architecture**

### **Caching Strategy**
```python
# Multi-level caching
Application Cache (Redis):
├── User profiles (5 minutes)
├── Search results (2 minutes)  
├── Analytics data (10 minutes)
└── Media metadata (30 minutes)

Database Query Optimization:
├── Selective column fetching
├── Proper indexing strategy
├── Connection pooling
└── Query result caching
```

### **Media Optimization**
```python
# Cloudinary auto-optimization
Image Processing:
├── Format: auto (WebP/AVIF)
├── Quality: auto (intelligent)
├── Compression: lossless when possible
├── Responsive: multiple sizes generated
└── CDN: global edge delivery

Video Processing:
├── Compression: auto (H.264/H.265)
├── Resolution: 720p/1080p adaptive
├── Thumbnail: auto-generated
└── Streaming: progressive download
```

---

## 📈 **Scalability Considerations**

### **Current Scale (Free Tiers)**
```yaml
Users: Up to 10,000 monthly active users
Database: 1GB storage, 2GB bandwidth (Supabase)
Backend: 750 hours/month (Render free tier)  
Media: 25GB bandwidth (Cloudinary free tier)
Total Cost: $0/month
```

### **Scale-Up Strategy (When Needed)**
```yaml
Phase 1 (10K+ users):
├── Upgrade to Supabase Pro: $25/month
├── Render Starter Plan: $7/month  
├── Cloudinary Pro: $89/month
└── Total: ~$120/month

Phase 2 (100K+ users):
├── Dedicated backend servers
├── Redis caching layer
├── CDN for static assets
├── Load balancing
└── Database read replicas
```

### **Monitoring & Observability**
```python
# Performance monitoring
Metrics Collection:
├── Request latency (p50, p95, p99)
├── Error rates by endpoint
├── Database query performance
├── Cache hit rates
└── User engagement metrics

Alerting:
├── API response time > 500ms
├── Error rate > 1%
├── Database connection issues
└── Service downtime
```

---

## 🔮 **Future Architecture Evolution**

### **Planned Enhancements**
```yaml
Phase 1 (Q1 2024):
├── Redis caching implementation
├── Background job processing
├── Enhanced analytics dashboard
└── Mobile app performance optimization

Phase 2 (Q2 2024):  
├── Machine learning recommendations
├── Advanced search with Elasticsearch
├── Real-time collaboration features
└── API rate limiting

Phase 3 (Q3 2024):
├── Microservices architecture
├── Event-driven architecture  
├── University system integrations
└── Advanced reporting system
```

### **Technology Migration Path**
```yaml
Current → Future:
├── Single FastAPI → Microservices
├── Direct DB calls → Event sourcing
├── Manual caching → Automated caching
├── Basic search → Semantic search
└── Rule-based → ML-powered features
```

---

## 🤝 **Integration Points**

### **University Systems**
```yaml
Planned Integrations:
├── Student Information System (SIS)
├── Learning Management System (LMS)
├── Event Management System
├── Academic Records System
└── Alumni Database
```

### **Third-party Services**
```yaml
Current Integrations:
├── Supabase (Auth, Database, Realtime)
├── Cloudinary (Media Storage)
└── Render (Backend Hosting)

Future Integrations:
├── Google Analytics (Usage tracking)
├── SendGrid (Email notifications)
├── Twilio (SMS notifications)
└── Microsoft Teams (Collaboration)
```

---

This architecture provides a solid foundation for current needs while maintaining flexibility for future growth and feature additions.
