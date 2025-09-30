# 🚀 Setup Instructions

## Prerequisites

- Python 3.11+
- Node.js 18+ (for frontend)
- Git
- Supabase Account
- OpenRouter Account (optional, for AI features)

## 1. Clone Repository

```bash
git clone https://github.com/yourusername/prototype.git
cd prototype
```

## 2. Backend Setup

### Install Dependencies
```bash
cd backend
pip install -r requirements.txt
```

### Configure Environment Variables
```bash
# Copy example env file
cp ../.env.example .env

# Edit .env with your actual values
nano .env  # or use your preferred editor
```

**Required values:**
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_JWT_SECRET=your-jwt-secret
```

**Get Supabase credentials:**
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to Settings → API
4. Copy: Project URL, anon key, JWT Secret

### Run Backend
```bash
python main.py
```

Backend will run on `http://localhost:8000`

## 3. Frontend Setup

### Install Dependencies
```bash
cd web_dashboard
npm install
```

### Configure Supabase
Create `web_dashboard/js/config/env.js`:

```javascript
window.ENV = {
  SUPABASE_URL: 'https://your-project.supabase.co',
  SUPABASE_ANON_KEY: 'your-anon-key-here'
};
```

**IMPORTANT**: Add to `.gitignore`:
```bash
echo "web_dashboard/js/config/env.js" >> .gitignore
```

### Load Environment Script
Add to `index.html` (before other scripts):
```html
<script src="js/config/env.js"></script>
```

### Run Frontend
```bash
npm run dev
```

Frontend will run on `http://localhost:3000`

## 4. Database Setup

### Create Tables
Run migrations in Supabase SQL Editor:

```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  role TEXT DEFAULT 'student',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Add policies
CREATE POLICY "Users can view own data"
ON users FOR SELECT
USING (auth.uid() = id);
```

See `backend/migrations/` for full schema.

## 5. AI Assistant Setup (Optional)

### Get OpenRouter API Key
1. Go to [OpenRouter](https://openrouter.ai/)
2. Sign up and get API key
3. Add to `.env`:
```bash
OPENROUTER_API_KEY=your-key-here
AI_OPENROUTER_ENABLED=true
```

### Test AI
```bash
curl -X POST http://localhost:8000/api/ai/command \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"command": "Berapa jumlah pelajar?"}'
```

## 6. Deployment

### Vercel (Frontend)
```bash
cd web_dashboard
vercel --prod
```

Set environment variables in Vercel dashboard.

### Render (Backend)
1. Connect GitHub repo to Render
2. Select `backend` as root directory
3. Add environment variables
4. Deploy!

## 🧪 Testing

### Backend Health Check
```bash
curl http://localhost:8000/health
```

### Frontend Login
1. Open `http://localhost:3000`
2. Use test credentials (if seeded)
3. Check browser console for errors

## 🔧 Troubleshooting

### Backend won't start
- Check Python version: `python --version`
- Install dependencies: `pip install -r requirements.txt`
- Check `.env` file exists and has required values

### Frontend shows "Backend not configured"
- Check backend is running on port 8000
- Check CORS settings in `backend/main.py`
- Verify `ALLOWED_ORIGINS` includes your frontend URL

### Authentication fails
- Verify Supabase credentials are correct
- Check JWT secret matches Supabase project
- Enable RLS policies in Supabase

### AI Assistant not working
- Check `OPENROUTER_API_KEY` is set
- Verify API key is valid
- Check daily quota (50 requests/day for free tier)

## 📚 Next Steps

- Read [SECURITY.md](SECURITY.md) for security best practices
- Check [docs/](docs/) for detailed documentation
- See [backend/README.md](backend/README.md) for API reference

## 💬 Support

- GitHub Issues: [Report bugs](https://github.com/yourusername/prototype/issues)
- Documentation: [Full docs](docs/)
- Email: support@yourproject.com

---

**Happy coding! 🎉**

