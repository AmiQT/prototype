# Student Talent Profiling App - Prototype

End-to-end platform for UTHM student talent profiling that ships a Python FastAPI backend, a Flutter mobile client, and a Supabase-powered web dashboard.

> **Security first:** this repository ships without secrets. Populate your own `.env` files before running any service and never commit credentials.

## Highlights
- Unified talent profiling experience across mobile, web, and backend services.
- Supabase authentication, PostgreSQL data layer, and Cloudinary media pipeline.
- **Agentic AI assistant with Bahasa Melayu as default response language** - Natural NLP for Malaysian users with tool calling, conversation memory, and Gemini integration.
- Rich analytics dashboards, showcase management, and student achievements tracking.
- Comprehensive docs for setup, migration, deployment, and troubleshooting.

## Repository Layout
```
prototype/
|-- backend/                # FastAPI application, routers, AI assistant, Alembic scripts
|-- mobile_app/             # Flutter app with Supabase auth, showcase, chat, analytics
|-- web_dashboard/          # Static dashboard (HTML/CSS/JS) + Supabase integration scripts
|-- api/                    # Lightweight Vercel serverless handler (health + test endpoints)
|-- assets/                 # Branding assets (cover, logo, favicon)
|-- data/                   # Sample JSON datasets for local testing
|-- docs/                   # Deep-dive guides (architecture, AI upgrades, troubleshooting)
|-- functions/              # Placeholder for cloud functions (ESLint config included)
|-- .github/workflows/      # Deployment pipelines for backend and web dashboard
|-- PRE-COMMIT-CHECKLIST.md # Manual checklist before pushing changes
|-- SECURITY.md             # Security baseline and hardening tips
|-- SETUP.md                # Repository-wide setup walkthrough
```

## System Architecture
```
Supabase Auth + PostgreSQL
          |
          v
FastAPI backend (backend/)
    |    \
    |     \__ Cloudinary media services
    |
    +--> Flutter mobile app (mobile_app/)
    |
    +--> Web dashboard (web_dashboard/)

Agentic AI layer (backend/app/ai_assistant)
    |- Conversation memory + templates
    |- Tool calling (Supabase, analytics, showcase ops)
    |- Gemini/OpenRouter client
```

## Core Components

### Backend (FastAPI + Supabase)
- Modern FastAPI project with routers for auth, profiles, events, showcase, analytics, media, and AI assistant (`backend/app/routers`).
- SQLAlchemy ORM with Alembic migrations (`backend/migrations`) targeting Supabase PostgreSQL.
- Supabase JWT verification (`backend/app/auth/supabase_auth.py`) and Cloudinary integration for media uploads.
- **Agentic AI assistant (`backend/app/ai_assistant/`) with Bahasa Melayu default responses** - Natural language processing for Malaysian users with conversation memory, response variation, tool execution, and Supabase bridging. See `docs/development/AI_BAHASA_MELAYU_DEFAULT.md` for details.
- Health probes (`/` and `/health`), and test endpoints for media uploads.
- Dependencies defined in `backend/requirements.txt`; run with Python 3.11+.

```
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python main.py
# Server: http://localhost:8000
```

### Mobile App (Flutter)
- Cross-platform Flutter client (`mobile_app/`) covering onboarding, profile setup, showcase feeds, chat, notifications, analytics, and offline caching.
- Service layer integrates Supabase (`supabase_flutter`), media uploads, AI chat, and search optimisations (`lib/services/`).
- Feature-rich screen modules for students, lecturers, shared views, and settings (`lib/screens/`).
- Configuration via `assets/.env` and `lib/config/`; linting rules in `analysis_options.yaml`.

```
cd mobile_app
flutter pub get
flutter run   # Choose desired device/emulator
```

### Web Dashboard (Static + Supabase)
- Static HTML dashboard (`web_dashboard/`) with modular JS architecture for analytics, user management, events, and AI assistant tools.
- Environment generator (`npm run generate-env`) writes `js/config/env.js` from project `.env`.
- Dev server powered by `live-server`; deployment presets via `netlify.toml` and `vercel.json`.

```
cd web_dashboard
npm install
npm run generate-env   # writes js/config/env.js
npm run dev            # http://127.0.0.1:8080/login.html
```

### Serverless Edge API
- `api/index.py` exposes a minimal HTTP handler for Vercel-style deployments (health checks, smoke endpoints).

## Environment & Secrets
Create `.env` files (see `backend/.env.example` and `web_dashboard/js/config/env.example.js`). Key variables include:
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_JWT_SECRET`
- `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`
- `OPENROUTER_API_KEY`, `AI_OPENROUTER_ENABLED`
- `BACKEND_URL`, `ALLOWED_ORIGINS`, `ENABLE_AI_ASSISTANT`, `ENABLE_ANALYTICS`

Keep `.env` files untracked and rotate credentials regularly.

## Sample Data, Assets, & Tools
- `data/` contains curated JSON datasets (FSKTM profile information, knowledge base, website scrape) for local demos.
- `assets/` stores the cover graphic and university branding used across surfaces.

## Documentation Hub
- [SETUP.md](SETUP.md): high-level setup, Supabase configuration, deployment pointers.
- [SECURITY.md](SECURITY.md): hardening checklist and secret management.
- [PRE-COMMIT-CHECKLIST.md](PRE-COMMIT-CHECKLIST.md): manual QA list before pushing.
- `docs/`:
  - `backend/` (Cloudinary setup, database reset guide)
  - `development/` (architecture, performance, debugging, agentic AI upgrade playbooks)
    - **`AI_BAHASA_MELAYU_DEFAULT.md`**: Complete guide for AI chatbot Bahasa Melayu implementation
    - **`AI_MALAY_QUICK_REFERENCE.md`**: Quick reference for developers working with Malay AI responses
  - `fixes/`, `setup/`, `status/` (historical notes, migration logs, roadmap)
  - `UPGRADE_AGENTIC_AI_FEATURES.md` for the full AI assistant upgrade narrative

## Deployment & Automation
- `.github/workflows/` orchestrates backend, web, and pages deployments.
- `backend/render.yaml` and `backend/railway.json` document infra-as-code targets.
- `web_dashboard/netlify.toml` + `vercel.json` cover static hosting pipelines.
- Container support via `backend/Dockerfile`.

## Testing & Troubleshooting
- Backend smoke scripts (`backend/test_final.py`) and health endpoints (`/health`).
- Web dashboard ships manual JS test harnesses (`web_dashboard/js/tests/`).
- Mobile app uses `flutter_test` and `mockito`; enable with `flutter test`.
- Refer to `docs/development/debugging.md` and `docs/development/performance.md` for deeper diagnostics.

## Contribution Workflow
- Follow the pre-commit checklist, run formatters/lints where applicable, and keep secrets out of version control.
- Use feature branches and document major architecture decisions within `docs/status/` or ADR notes.

## License
- Project artifacts currently inherit module-specific licenses (web dashboard is MIT via `package.json`). Clarify repository-wide licensing before public release.

---

Happy building! Open an issue or start a discussion before significant architecture changes, and keep the Supabase + FastAPI hybrid story strong.
