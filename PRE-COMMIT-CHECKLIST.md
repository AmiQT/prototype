# ✅ Pre-Commit Security Checklist

**ALWAYS run this checklist before committing to git!**

## 🔒 Security Checks

### 1. Environment Variables
- [ ] No `.env` files in commit
- [ ] No hardcoded API keys
- [ ] No hardcoded passwords
- [ ] No hardcoded database credentials
- [ ] Only `.env.example` files committed

### 2. Sensitive Files
```bash
# Check for sensitive files
git status | grep -i ".env"
git status | grep -i "secret"
git status | grep -i "password"
```

### 3. Search for Hardcoded Secrets
```bash
# In backend
cd backend
grep -r "api_key\|password\|secret" --include="*.py" | grep -v "os.getenv\|Field(default=None"

# In frontend
cd web_dashboard
grep -r "supabase.*key\|api.*key" --include="*.js" | grep -v "window.ENV\|YOUR_.*_HERE"
```

### 4. Files That MUST Be in .gitignore
- [ ] `.env`
- [ ] `.env.local`
- [ ] `.env.production`
- [ ] `backend/.env`
- [ ] `web_dashboard/js/config/env.js`
- [ ] `node_modules/`
- [ ] `__pycache__/`
- [ ] `*.pyc`

### 5. Files That ARE SAFE to Commit
- [x] `.env.example`
- [x] `.gitignore`
- [x] `SECURITY.md`
- [x] `SETUP.md`
- [x] Config files with placeholders (e.g., `YOUR_KEY_HERE`)

## 🧪 Pre-Commit Tests

### Backend
```bash
cd backend
python -c "from app.auth.supabase_auth import SUPABASE_JWT_SECRET; print('✅ OK' if SUPABASE_JWT_SECRET is None else '❌ HARDCODED!')"
```

### Frontend
```bash
cd web_dashboard
grep "YOUR_.*_HERE" js/config/supabase-config.js && echo "✅ Using placeholders" || echo "❌ Hardcoded keys found!"
```

## 🚀 Quick Commands

### Remove accidentally committed .env
```bash
git rm --cached .env
git rm --cached backend/.env
git rm --cached web_dashboard/js/config/env.js
git commit -m "Remove sensitive environment files"
```

### Check what you're about to commit
```bash
git diff --cached
```

### Undo last commit (if you committed secrets)
```bash
git reset --soft HEAD~1  # Keeps changes
# OR
git reset --hard HEAD~1  # Removes changes
```

## ⚠️ If You Accidentally Committed Secrets

### 1. Rotate ALL exposed credentials immediately
- Supabase: Reset JWT secret & keys
- OpenRouter: Regenerate API key
- Cloudinary: Regenerate credentials

### 2. Remove from git history
```bash
# Remove file from all commits
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/secret-file" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (DANGEROUS - coordinate with team!)
git push origin --force --all
```

### 3. Alternative: Use BFG Repo Cleaner
```bash
# Install BFG
# https://rtyley.github.io/bfg-repo-cleaner/

# Remove secrets
bfg --delete-files .env
bfg --replace-text passwords.txt  # File with patterns to replace

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

## 📋 Final Check Before Push

```bash
# 1. Check .gitignore
cat .gitignore | grep -E ".env|env.js"

# 2. Check staged files
git status

# 3. Review changes
git diff --cached

# 4. Search for secrets in staged files
git diff --cached | grep -i "api_key\|secret\|password"

# 5. Only if ALL CLEAR:
git push
```

## 🎯 Remember

> **"Treat every commit as if it will be public forever."**
> **"When in doubt, DON'T commit it!"**

---

**Safe coding! 🔒**

