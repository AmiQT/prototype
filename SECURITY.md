# 🔒 Security Guidelines

## Overview
This document outlines security best practices for the UTHM Talent Profiling system.

## ⚠️ IMPORTANT: Before Deployment

### 1. Environment Variables
**NEVER commit these files to git:**
- `.env`
- `.env.local`
- `.env.production`
- Any file containing API keys, secrets, or credentials

**Always use:**
- `.env.example` as a template (safe to commit)
- Environment variables on your deployment platform

### 2. Required Environment Variables

#### Critical (Must be set):
```bash
SUPABASE_URL=              # Your Supabase project URL
SUPABASE_ANON_KEY=         # Public anon key (RLS protected)
SUPABASE_JWT_SECRET=       # JWT secret from Supabase settings
OPENROUTER_API_KEY=        # Your OpenRouter API key (if using AI)
```

#### Optional (with safe defaults):
```bash
CLOUDINARY_CLOUD_NAME=     # For media uploads
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
```

### 3. Frontend Configuration

The frontend (`web_dashboard/js/config/supabase-config.js`) now uses placeholders.

**For development:**
1. Create `web_dashboard/js/config/env.js`:
```javascript
window.ENV = {
  SUPABASE_URL: 'https://your-project.supabase.co',
  SUPABASE_ANON_KEY: 'your-anon-key-here'
};
```

2. Add to `.gitignore`:
```
web_dashboard/js/config/env.js
```

3. Load before other scripts in HTML:
```html
<script src="js/config/env.js"></script>
<script type="module" src="js/config/supabase-config.js"></script>
```

## 🔐 Supabase Security

### Row Level Security (RLS)
Ensure RLS is enabled on all tables:
```sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
```

### Policies
Example safe policy:
```sql
-- Users can only read their own profile
CREATE POLICY "Users can view own profile"
ON profiles FOR SELECT
USING (auth.uid() = user_id);
```

## 🚀 Deployment Checklist

### Before pushing to GitHub:
- [ ] Remove all hardcoded credentials
- [ ] Check `.gitignore` includes `.env`
- [ ] Create `.env.example` with placeholder values
- [ ] Update README with setup instructions
- [ ] Test with environment variables only

### On deployment platform (Vercel/Netlify/Render):
- [ ] Set all environment variables in platform dashboard
- [ ] Enable HTTPS
- [ ] Configure CORS properly
- [ ] Test authentication flow
- [ ] Monitor logs for security warnings

## 🛡️ Best Practices

### 1. API Keys
- ✅ Use `ANON_KEY` for frontend (safe, RLS protected)
- ❌ Never use `SERVICE_ROLE_KEY` in frontend
- ✅ Rotate keys if exposed

### 2. Authentication
- ✅ Always verify JWT tokens on backend
- ✅ Use HTTPOnly cookies when possible
- ✅ Implement rate limiting

### 3. Database
- ✅ Enable RLS on all tables
- ✅ Use prepared statements (SQLAlchemy does this)
- ✅ Validate all user inputs

## 🚨 If Keys Are Exposed

1. **Immediately rotate all exposed keys:**
   - Supabase: Project Settings → API → Reset keys
   - OpenRouter: Regenerate API key
   - Cloudinary: Regenerate credentials

2. **Update your `.env` file with new keys**

3. **Check git history:**
```bash
# Remove sensitive data from git history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/file" \
  --prune-empty --tag-name-filter cat -- --all
```

## 📞 Reporting Security Issues

If you discover a security vulnerability:
1. **DO NOT** open a public issue
2. Email: security@yourproject.com (if applicable)
3. Include: Description, steps to reproduce, impact

## 📚 Resources

- [Supabase Security Best Practices](https://supabase.com/docs/guides/auth/row-level-security)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [GitHub Security](https://docs.github.com/en/code-security)

---

**Last Updated**: October 2025
**Maintainer**: UTHM Talent Profiling Team

