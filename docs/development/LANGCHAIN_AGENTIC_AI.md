# LangChain Agentic AI - Panduan Implementasi

## 📋 Ringkasan

Projek ini telah di-upgrade untuk menggunakan **LangChain + LangGraph** sebagai backend AI chatbot. Ini memberikan:

- ✅ **Lebih stabil** - Built-in error handling dan retry
- ✅ **Agentic mode** - AI boleh buat keputusan dan panggil tools sendiri
- ✅ **Conversation memory** - Ingat konteks perbualan
- ✅ **Production-ready** - Telah diuji dengan Gemini API

---

## 🏗️ Struktur Fail

```
backend/app/ai_assistant/langchain_agent/
├── __init__.py          # Module exports
├── agent.py             # LangGraph agent utama
├── tools.py             # Tool definitions (query students, events, etc.)
├── prompts.py           # System prompts dalam BM
└── memory.py            # Conversation memory management

backend/app/routers/
├── ai_assistant.py      # Legacy API (masih boleh guna)
└── ai_langchain.py      # NEW: LangChain v2 API
```

---

## 🔌 API Endpoints

### LangChain v2 (Recommended)

| Endpoint | Method | Fungsi |
|----------|--------|--------|
| `/api/ai/v2/command` | POST | Process AI command (async) |
| `/api/ai/v2/command/sync` | POST | Process AI command (sync) |
| `/api/ai/v2/health` | GET | Check agent health |
| `/api/ai/v2/session/{id}` | DELETE | Clear session memory |
| `/api/ai/v2/sessions` | GET | List user sessions |

### Request Format

```json
{
  "command": "Berapa pelajar dalam sistem?",
  "session_id": "optional-session-id",
  "context": {
    "page": "/dashboard"
  }
}
```

### Response Format

```json
{
  "success": true,
  "message": "Ada 150 pelajar dalam sistem...",
  "session_id": "session_user123",
  "tool_calls": [
    {"name": "get_system_stats", "args": {}}
  ],
  "source": "langchain_agent"
}
```

---

## 🛠️ Tools yang Tersedia

### Database Tools

| Tool | Fungsi |
|------|--------|
| `query_students` | Cari pelajar (filter: jabatan, CGPA, random) |
| `query_events` | Cari acara (upcoming, jenis) |
| `get_system_stats` | Statistik keseluruhan sistem |
| `query_analytics` | Analitik terperinci (CGPA distribution, etc.) |

### NLP Tools (NEW!)

| Tool | Fungsi |
|------|--------|
| `semantic_search_students` | Cari pelajar dengan semantic search (NLP) |
| `analyze_text` | Analisis teks (entiti, sentimen, bahasa) |
| `extract_malaysian_entities` | Ekstrak entiti khusus Malaysia (nama, universiti, jabatan) |
| `answer_from_knowledge` | Jawab soalan menggunakan RAG system |

---

## 🧠 Modul NLP

### Struktur

```
backend/app/nlp/
├── __init__.py          # Module exports
├── core.py              # spaCy NLP processor
├── entities.py          # Malaysian entity extractor
├── semantic_search.py   # Sentence Transformers + FAISS
├── malay_processor.py   # Bahasa Melayu processor
└── rag.py               # RAG (Retrieval-Augmented Generation)
```

### Features

| Feature | Library | Fungsi |
|---------|---------|--------|
| NER | spaCy | Kenal pasti entiti (nama, organisasi, tarikh) |
| Semantic Search | sentence-transformers + FAISS | Cari berdasarkan makna, bukan keyword |
| Malay NLP | Custom | Stopwords BM, stemming asas, code-switching |
| Malaysian Entities | Regex + Rules | Nama Malaysia, universiti, nombor matrik |
| RAG | LangChain | Jawab soalan berdasarkan dokumen |

### Contoh Penggunaan

```python
from app.nlp import NLPProcessor, SemanticSearchEngine, MalayNLPProcessor

# NLP Analysis
nlp = NLPProcessor()
entities = nlp.extract_entities("Ahmad bin Ali dari UTHM")

# Semantic Search
search = SemanticSearchEngine()
search.index_documents(["Pelajar Computer Science", "Pelajar Civil Engineering"])
results = search.search("IT student")  # Akan match dengan CS

# Malay Processing
malay = MalayNLPProcessor()
sentiment = malay.analyze_sentiment("Projek ini sangat bagus!")
# Output: {"sentiment": "positive", "score": 0.8}
```

---

## 🚀 Cara Guna

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt

# Download spaCy model
python -m spacy download en_core_web_sm
```

### 2. Set Environment Variable

```bash
# .env
GEMINI_API_KEY=your-api-key-here
```

### 3. Test API

```bash
# Health check
curl http://localhost:8000/api/ai/v2/health

# Send command
curl -X POST http://localhost:8000/api/ai/v2/command \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"command": "Berapa pelajar dalam sistem?"}'
```

---

## 🔄 Migration dari Legacy API

Web dashboard telah di-update untuk menggunakan `/api/ai/v2/command` secara automatik.

Jika anda mahu guna legacy API, ubah endpoint dalam `Chatbot.astro`:

```javascript
// NEW (LangChain v2)
const AI_ENDPOINT = `${BACKEND_URL}/api/ai/v2/command`;

// LEGACY (jika perlu fallback)
// const AI_ENDPOINT = `${BACKEND_URL}/api/ai/command`;
```

---

## 🐛 Troubleshooting

### Error: "GEMINI_API_KEY tidak ditetapkan"

Pastikan `.env` file ada dan mengandungi:
```
GEMINI_API_KEY=your-key-here
```

### Error: Rate Limit

LangChain mempunyai built-in retry. Jika masih error:
- Tunggu beberapa saat
- Check quota Gemini API anda

### Agent tidak respond

1. Check health endpoint: `/api/ai/v2/health`
2. Semak logs backend
3. Pastikan database connection OK

---

## 📊 Perbandingan: Legacy vs LangChain

| Aspek | Legacy (Gemini Direct) | LangChain v2 |
|-------|------------------------|--------------|
| Stability | ⚠️ Manual error handling | ✅ Built-in retry |
| Tool Calling | ⚠️ Custom implementation | ✅ Native support |
| Memory | ⚠️ Basic | ✅ Checkpointing |
| Multi-turn | ⚠️ Manual | ✅ Automatic |
| Production | ⚠️ Fragile | ✅ Battle-tested |

---

## 🎯 Next Steps

1. **Add more tools** - Boleh tambah tools lain seperti:
   - `query_achievements` - Cari pencapaian
   - `query_showcase` - Cari showcase posts
   - `generate_report` - Jana laporan PDF

2. ~~**Implement RAG**~~ ✅ - Sudah siap!

3. **Add streaming** - Untuk respons real-time

4. **Fine-tune Malay NLP** - Tambah vocabulary dan patterns

---

## 📦 Dependencies NLP

```
# requirements.txt
spacy>=3.7.0
sentence-transformers>=2.2.0
faiss-cpu>=1.7.4
```

---

*Dokumentasi ini dikemaskini: December 2025*
