# Quick Reference: AI Chatbot Bahasa Melayu

## 🎯 Ringkasan Pantas

AI chatbot sistem UTHM kini **RESPOND DALAM BAHASA MELAYU SECARA DEFAULT** untuk pengguna Malaysia.

## 📍 Fail-Fail Penting

| Fail | Purpose | Lokasi |
|------|---------|--------|
| `manager.py` | System prompt & main logic | `backend/app/ai_assistant/manager.py` |
| `clarification_system.py` | Clarification dalam BM | `backend/app/ai_assistant/clarification_system.py` |
| `response_variation.py` | Response templates BM | `backend/app/ai_assistant/response_variation.py` |
| `template_manager.py` | Template management | `backend/app/ai_assistant/template_manager.py` |

## 🔑 Key Settings

### Environment Variables
```bash
# .env file
AI_ASSISTANT_ENABLED=true
AI_GEMINI_ENABLED=true
GEMINI_API_KEY=your_api_key_here
```

### System Prompt Location
```python
# backend/app/ai_assistant/manager.py
# Lines ~200-280

messages = [
    {
        "role": "system",
        "content": f"""Anda adalah pembantu AI agentic untuk sistem papan pemuka UTHM.
        
IDENTITI TERAS:
- ANDA MESTI RESPOND DALAM BAHASA MELAYU SECARA DEFAULT
...
"""
    }
]
```

## 🗣️ Contoh Response Patterns

### ✅ BETUL (Malay Default)
```
User: "Berapa student ada?"
AI: "Ada 250 pelajar dalam sistem. 150 lelaki dan 100 perempuan."

User: "Show me FSKTM students"
AI: "Baiklah, ini pelajar dari FSKTM..."

User: "sekalai lagi"
AI: "Okay, saya ulang sekali lagi..."
```

### ❌ SALAH (English Default - Old)
```
User: "Berapa student ada?"
AI: "I found 250 students in the system."
[Not natural for Malaysian users!]
```

## 🧪 Testing

### Run Test Script
```bash
cd backend
python test_ai_malay.py
```

### Manual Test via API
```bash
# Test dengan curl
curl -X POST http://localhost:8000/api/ai/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"message": "Berapa student dalam sistem?"}'
```

### Expected Response
```json
{
  "success": true,
  "message": "Ada 250 pelajar dalam sistem...",
  "source": "gemini",
  "data": {
    "tools_used": ["get_system_stats"],
    "mode": "conversational"
  }
}
```

## 💡 Common Patterns

### Greeting
```python
"Hai! Apa khabar? Saya AI assistant UTHM sedia nak tolong."
"Wah bestnya jumpa awak! 😊"
```

### Query Results
```python
"Saya jumpa {count} pelajar yang awak cari."
"Baiklah, ini senarai acara yang akan datang..."
```

### Confirmation
```python
"Okay! Saya dah proses permintaan awak."
"Tqvm! Dah done proses tadi."
```

### Clarification
```python
"Awak tanya pasal pelajar, tapi tak specify jabatan..."
"Boleh awak terangkan lagi?"
```

## 🔧 Troubleshooting

### Problem: AI respond dalam English
**Solution**: 
1. Check system prompt dalam `manager.py`
2. Verify line yang ada "ANDA MESTI RESPOND DALAM BAHASA MELAYU"
3. Restart backend server

### Problem: Response tidak natural
**Solution**:
1. Update templates dalam `response_variation.py`
2. Add more Malay expressions
3. Test dengan `test_ai_malay.py`

### Problem: Clarification dalam English
**Solution**:
1. Check `clarification_system.py`
2. Update clarification templates
3. Verify `self.clarification_templates` dictionary

## 📝 Adding New Templates

### 1. Response Template
```python
# backend/app/ai_assistant/response_variation.py

ResponseTemplate(
    template_id="new_template_001",
    template_type=ResponseTemplateType.YOUR_TYPE,
    content="Response dalam Bahasa Melayu...",
    tags=["friendly", "helpful"],
    weight=1.0
)
```

### 2. Clarification Template
```python
# backend/app/ai_assistant/clarification_system.py

self.clarification_templates['new_case'] = {
    'question': "Soalan dalam Bahasa Melayu?",
    'suggestion': "Cadangan dalam Bahasa Melayu."
}
```

## 🌟 Best Practices

### DO ✅
- Guna Bahasa Melayu yang natural dan casual
- Support code-switching (campuran BM-English)
- Use expressions: "wah bestnya", "okay lah", "tqvm"
- Match user's tone and style
- Add emoji bila sesuai: 😊 🎉 📅

### DON'T ❌
- Jangan paksa formal Malay sahaja
- Jangan response full English (unless user requests)
- Jangan ignore context dari previous messages
- Jangan guna template yang kaku dan robot-like

## 🚀 Quick Commands

```bash
# Start backend
cd backend
uvicorn main:app --reload

# Test AI Malay
python test_ai_malay.py

# Check logs
tail -f logs/ai_assistant.log

# Restart with new config
# 1. Update .env or code
# 2. Restart server
# 3. Test dengan test_ai_malay.py
```

## 📚 Further Reading

- Full Documentation: `docs/development/AI_BAHASA_MELAYU_DEFAULT.md`
- System Prompt: `backend/app/ai_assistant/manager.py` (lines 200-280)
- Response Templates: `backend/app/ai_assistant/response_variation.py`
- Clarification System: `backend/app/ai_assistant/clarification_system.py`

## 💬 Support

Jika ada masalah atau soalan:
1. Check documentation dalam `docs/development/`
2. Run test script: `python test_ai_malay.py`
3. Check logs untuk error messages
4. Verify environment variables dalam `.env`

---

**Last Updated**: November 5, 2025
**Status**: ✅ Active & Production Ready
