# 🔍 Codebase Audit & Cleanup Plan

**Tarikh Audit:** 20 Disember 2025  
**Status:** AUDIT SELESAI - READY FOR CLEANUP

---

## 📊 Executive Summary

### Project Overview
| Component | Files | Status |
|-----------|-------|--------|
| Backend (Python/FastAPI) | 487 files | ⚠️ Perlu cleanup |
| Mobile App (Flutter/Dart) | 139 files | ⚠️ Perlu optimization |
| Web Dashboard (Astro) | ~30 files | ⚠️ Ada duplicate themes |
| Documentation | 38 files | ⚠️ Banyak outdated docs |

### Skor Kesihatan Codebase: **6/10** ⚠️

---

## 🚨 CRITICAL ISSUES (Priority 1 - Immediate Fix)

### 1. **Duplicate Code - Cache Managers**
```
📁 Lokasi:
├── backend/app/ai_assistant/cache_manager.py (239 lines)
└── backend/app/ml_analytics/cache_manager.py (137 lines)
```
**Masalah:** Dua cache manager dengan functionality sama tapi implementation berbeza.

**Tindakan:**
- [ ] Consolidate ke satu unified cache manager di `app/core/cache_manager.py`
- [ ] Refactor semua imports ke unified version

---

### 2. **Duplicate Routers - Profiles**
```
📁 Lokasi:
├── backend/app/routers/profiles.py (239 lines) - ORM-based
└── backend/app/routers/profiles_supabase.py (219 lines) - Raw SQL
```
**Masalah:** Dua router dengan same prefix `/api/profiles` - confusing dan potential conflicts.

**Tindakan:**
- [ ] Tentukan approach: ORM atau Raw SQL
- [ ] Remove yang tak digunakan
- [ ] Consolidate ke satu router

---

### 3. **Duplicate Routers - Search**
```
📁 Lokasi:
├── backend/app/routers/search.py (801 lines) - Advanced search
└── backend/app/routers/search_simple.py (233 lines) - Simple search
```
**Masalah:** Dua search endpoint yang overlap functionality.

**Tindakan:**
- [ ] Merge ke satu router dengan optional complexity parameter
- [ ] Remove `search_simple.py` jika tak production

---

### 4. **Duplicate Services - Mobile App**
```
📁 Lokasi:
├── mobile_app/lib/services/backend_service.dart (162 lines)
└── mobile_app/lib/services/optimized_backend_service.dart (246 lines)
```
**Masalah:** Dua backend service implementations.

**Tindakan:**
- [ ] Keep `optimized_backend_service.dart` (better caching)
- [ ] Remove old `backend_service.dart`
- [ ] Update all imports

---

### 5. **Duplicate Main Entry - Mobile App**
```
📁 Lokasi:
├── mobile_app/lib/main.dart (108 lines)
└── mobile_app/lib/main_optimized.dart (137 lines)
```
**Masalah:** Confusing - which one is production?

**Tindakan:**
- [ ] Choose one as production entry
- [ ] Remove/archive the other
- [ ] Update `pubspec.yaml` main entry point

---

## ⚠️ HIGH PRIORITY ISSUES (Priority 2)

### 6. **AI Module Bloat**
```
📁 backend/app/ai_assistant/ - 31 FILES!
├── admin_db_assistant.py
├── cache_manager.py
├── circuit_breaker.py
├── clarification_system.py
├── config.py
├── conversation_memory.py
├── demo_agentic_features.py      ❌ Demo/test file in production
├── enhanced_supabase_bridge.py
├── gemini_client.py
├── history.py
├── intent_classifier.py
├── key_rotator.py
├── langchain_agent/
├── logger.py
├── manager.py
├── monitoring.py
├── orchestrator.py
├── permissions.py
├── plan_generator.py
├── pseudo_ai.py                  ❌ Mock/pseudo implementation
├── rate_limiter.py
├── request_validator.py
├── response_variation.py
├── schemas.py
├── service_bridge.py
├── supabase_bridge.py            ❌ Duplicate? enhanced_supabase_bridge.py
├── templates.py
├── template_manager.py
├── tools.py
├── tool_executor.py
└── tool_selector.py
```

**Tindakan:**
- [ ] Remove `demo_agentic_features.py` (test file)
- [ ] Remove `pseudo_ai.py` jika tak digunakan production
- [ ] Consolidate `supabase_bridge.py` dan `enhanced_supabase_bridge.py`
- [ ] Reorganize ke subfolders:
  ```
  ai_assistant/
  ├── core/           (manager, orchestrator, schemas)
  ├── agents/         (langchain_agent)
  ├── memory/         (conversation_memory, history)
  ├── tools/          (tools, tool_executor, tool_selector)
  ├── robustness/     (circuit_breaker, rate_limiter, cache)
  └── bridges/        (supabase_bridge, service_bridge)
  ```

---

### 7. **Duplicate AI Routers**
```
📁 Lokasi:
├── backend/app/routers/ai_assistant.py (526 lines) - Legacy Gemini
└── backend/app/routers/ai_langchain.py (281 lines) - LangChain v2
```
**Masalah:** Dua AI endpoints (`/api/ai` dan `/api/ai/v2`)

**Tindakan:**
- [ ] Decide production AI: Gemini direct atau LangChain
- [ ] Deprecate legacy gradually with feature flags
- [ ] Eventually remove legacy

---

### 8. **Web Dashboard - Triple Theme Implementation**
```
📁 web_dashboard_astro/src/pages/
├── aurora/     (analytics, index, settings, users)
├── brutal/     (analytics, index, settings, users)
└── dashboard/  (analytics, events, index, settings, users)
```
**Masalah:** 3 different theme implementations dengan duplicate pages!

**Tindakan:**
- [ ] Pick ONE production theme
- [ ] Remove unused theme folders
- [ ] Atau: Implement proper theme switching system

---

### 9. **Sidebar Component Duplication**
```
📁 web_dashboard_astro/src/components/
├── Sidebar.astro
├── SidebarV2.astro
└── SidebarV3.astro
```
**Tindakan:**
- [ ] Keep only production version
- [ ] Remove V1, V2 jika tak digunakan

---

## 📋 MEDIUM PRIORITY ISSUES (Priority 3)

### 10. **Excessive Documentation**
```
📁 docs/ - 38 markdown files!
├── archive/           (16 outdated files)
├── backend/           (2 files)
├── development/       (10 files)
├── setup/             (3 files)
└── root level         (7 files)
```

**Tindakan:**
- [ ] Review `archive/` - delete truly obsolete docs
- [ ] Consolidate similar docs:
  - ML docs: 6 files → 1-2 files
  - AI docs: 5+ files → 2-3 files
  - Setup docs: Keep updated versions only
- [ ] Create single `README.md` per component

---

### 11. **Mobile App Services Bloat**
```
📁 mobile_app/lib/services/ - 29 service files!
```
**Masalah:** Too many fine-grained services.

**Tindakan:**
- [ ] Group related services:
  - `search_*.dart` (4 files) → `search/` folder
  - `notification_*.dart` (3 files) → `notifications/` folder
  - `cache_*.dart` → merge to one

---

### 12. **Unused/Dead Code Indicators**

**Comments indicating incomplete work:**
```
- "# TODO: Fix when Achievement model is confirmed" (2 locations)
- "# generate: true  # Temporarily disabled to fix build issues"
- "// TODO: Implement mobile menu"
```

**Tindakan:**
- [ ] Grep semua TODO/FIXME
- [ ] Address atau remove stale TODOs

---

### 13. **Requirements.txt Issues**
```python
# Commented but still present:
# redis>=4.5.0
# pandas>=2.0.0
# scikit-learn>=1.3.0  # Actually used above!
# numpy>=1.24.0        # Actually used above!
```

**Tindakan:**
- [ ] Remove commented duplicates
- [ ] Clean up requirements file

---

## 🔧 OPTIMIZATION OPPORTUNITIES

### 14. **Large Files That Need Refactoring**
| File | Lines | Action |
|------|-------|--------|
| `routers/search.py` | 801 | Split into smaller modules |
| `routers/ai_assistant.py` | 526 | Extract helpers |
| `ai_assistant/circuit_breaker.py` | 243 | OK size |
| `ai_assistant/cache_manager.py` | 239 | Merge with ml_analytics version |

---

### 15. **Import Optimization**
Backend files may have unused imports. Consider:
- [ ] Run `autoflake` to remove unused imports
- [ ] Run `isort` to organize imports

---

### 16. **Logging Consistency**
Mix of:
- `print()` statements (should remove)
- `logger.info()` 
- `debugPrint()` in Dart

**Tindakan:**
- [ ] Replace all `print()` with proper logging
- [ ] Standardize log levels

---

## 📁 PROPOSED NEW STRUCTURE

### Backend
```
backend/app/
├── core/
│   ├── config.py
│   ├── database.py
│   ├── cache.py          # Unified cache manager
│   └── security.py
├── ai/
│   ├── agents/
│   ├── tools/
│   ├── memory/
│   ├── robustness/
│   └── schemas.py
├── api/
│   ├── v1/
│   │   ├── auth.py
│   │   ├── users.py
│   │   ├── profiles.py   # Single consolidated
│   │   ├── search.py     # Single consolidated
│   │   ├── events.py
│   │   ├── showcase.py
│   │   └── ai.py
│   └── deps.py           # Common dependencies
├── models/
├── services/
└── ml/
```

### Mobile App
```
mobile_app/lib/
├── core/
│   ├── config/
│   ├── services/         # Core services only
│   └── utils/
├── features/
│   ├── auth/
│   ├── chat/
│   ├── profile/
│   ├── search/
│   │   └── services/     # Feature-specific services
│   └── showcase/
├── shared/
│   ├── widgets/
│   └── models/
└── main.dart             # Single entry point
```

### Web Dashboard
```
web_dashboard_astro/src/
├── components/
│   ├── Sidebar.astro     # Single version
│   └── ...
├── layouts/
├── lib/
├── pages/
│   ├── index.astro
│   ├── login.astro
│   └── dashboard/        # Single theme
├── services/
└── styles/
```

---

## ✅ CLEANUP EXECUTION CHECKLIST

### Phase 1: Critical (Immediate - 1 day)
- [ ] Consolidate cache managers
- [ ] Remove duplicate profiles router
- [ ] Remove `search_simple.py`
- [ ] Choose one main.dart
- [ ] Remove demo/test files from production

### Phase 2: High Priority (1-2 days)
- [ ] Restructure ai_assistant folder
- [ ] Choose production theme for web dashboard
- [ ] Remove sidebar duplicates
- [ ] Consolidate backend services in mobile app

### Phase 3: Medium Priority (3-5 days)
- [ ] Archive/delete old documentation
- [ ] Reorganize mobile app services
- [ ] Address all TODOs
- [ ] Clean requirements.txt

### Phase 4: Optimization (Ongoing)
- [ ] Replace print() with logging
- [ ] Run linters and formatters
- [ ] Add proper error handling
- [ ] Write missing tests

---

## 📈 Expected Benefits After Cleanup

| Metric | Before | After (Expected) |
|--------|--------|------------------|
| Backend Python files | 487 | ~350 (-28%) |
| Mobile Dart files | 139 | ~100 (-28%) |
| Documentation files | 38 | ~15 (-60%) |
| Duplicate code | HIGH | MINIMAL |
| Codebase health score | 6/10 | 8.5/10 |
| Build time | Baseline | -20% faster |
| Onboarding time | Long | Significantly shorter |

---

## 🔜 Next Steps

1. **Review this plan** dengan team
2. **Create backup branch** sebelum cleanup
3. **Execute Phase 1** (critical fixes)
4. **Test thoroughly** selepas each phase
5. **Update documentation** selepas cleanup

---

*Generated by Codebase Audit Tool - December 20, 2025*
