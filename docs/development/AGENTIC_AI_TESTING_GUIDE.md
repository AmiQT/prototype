# 🚀 Agentic AI Testing Guide

**Quick guide untuk test agentic AI system terus dari API endpoints!**

---

## 📍 New Endpoints Added

### 1. **GET /api/ai/agentic/status**
Check system status dan capabilities.

**Request:**
```bash
curl -X GET "http://localhost:8000/api/ai/agentic/status"
```

**Response:**
```json
{
  "system": "Agentic AI Upgrade Complete",
  "version": "2.0.0",
  "status": "operational",
  "features": {
    "tool_calling": true,
    "structured_context": true,
    "conversation_memory": true,
    "database_access": true,
    "natural_language": true
  },
  "tools": {
    "available": ["query_students", "query_events", "get_system_stats", "query_analytics"],
    "count": 4
  },
  "config": {
    "openrouter_enabled": true,
    "ai_enabled": true,
    "model": "qwen/qwen3-30b-a3b:free"
  },
  "phases_completed": [
    "Phase 1: Keyword system removed",
    "Phase 2: Tool calling implemented",
    "Phase 3: Structured context added",
    "Phase 4: Database access enabled",
    "Phase 5: Testing & refinement done"
  ]
}
```

---

### 2. **POST /api/ai/agentic/test** ⭐
Full agentic system test dengan 4 test cases!

**Request:**
```bash
curl -X POST "http://localhost:8000/api/ai/agentic/test" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "test_summary": {
    "total_tests": 4,
    "passed": 4,
    "failed": 0,
    "success_rate": "100.0%",
    "tools_functional": true
  },
  "test_results": [
    {
      "test": "🎲 Random Student Selection (Tool Expected)",
      "command": "Pilih 1 student random",
      "success": true,
      "mode": "agentic",
      "iterations": 2,
      "tools_called": 1,
      "tool_names": ["query_students"],
      "expected_tools": true,
      "expectation_met": true,
      "message_preview": "Okay! Saya pilih Ahmad bin Ali 🎲...",
      "status": "✅ PASSED"
    },
    ...
  ],
  "system_status": "✅ OPERATIONAL",
  "message": "Agentic AI system fully operational! 🚀"
}
```

**What It Tests:**
- ✅ Tool calling (query_students)
- ✅ System stats (get_system_stats)
- ✅ Filtered search (with department)
- ✅ Conversational (no tools needed)

---

## 🎯 Testing Methods

### Option 1: Via API (Postman/Thunder Client)

1. **Check Status**
   - Method: GET
   - URL: `http://localhost:8000/api/ai/agentic/status`
   - Auth: None required

2. **Run Tests**
   - Method: POST
   - URL: `http://localhost:8000/api/ai/agentic/test`
   - Auth: Bearer Token (login first)
   - Body: None required

### Option 2: Via Browser/Frontend

**JavaScript Example:**
```javascript
// Check status
fetch('/api/ai/agentic/status')
  .then(r => r.json())
  .then(data => console.log('Status:', data));

// Run tests (need auth)
fetch('/api/ai/agentic/test', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
})
  .then(r => r.json())
  .then(data => {
    console.log('Tests:', data.test_summary);
    console.log('Results:', data.test_results);
  });
```

### Option 3: Via Python Requests

```python
import requests

# Status check
response = requests.get('http://localhost:8000/api/ai/agentic/status')
print(response.json())

# Run tests (need token)
token = "your_supabase_token"
response = requests.post(
    'http://localhost:8000/api/ai/agentic/test',
    headers={'Authorization': f'Bearer {token}'}
)
print(response.json())
```

---

## 📊 Test Results Breakdown

Each test result contains:

```json
{
  "test": "Test name with emoji",
  "command": "Actual command sent",
  "success": true/false,
  "mode": "agentic/conversational",
  "iterations": 2,              // Agentic loop iterations
  "tools_called": 1,            // Number of tools called
  "tool_names": ["tool_name"],  // Which tools were used
  "expected_tools": true,       // Did we expect tool calls?
  "expectation_met": true,      // Did it match expectation?
  "message_preview": "...",     // AI response preview
  "status": "✅ PASSED"
}
```

---

## 🔍 Interpreting Results

### ✅ Success Indicators:
- `success: true` - Command executed successfully
- `mode: "agentic"` - Used agentic loop with tools
- `tools_called > 0` - Tools were actually called
- `expectation_met: true` - Behavior matched expectations
- `iterations: 2` - Reasonable iteration count (max 5)

### ⚠️ Warning Signs:
- `mode: "conversational"` when tools expected - AI didn't call tools
- `iterations: 5` - Hit max iterations (task too complex)
- `tools_called: 0` when expected - Tools not working
- `expectation_met: false` - Unexpected behavior

### ❌ Errors:
- `success: false` - Command failed
- `error` field present - Exception occurred
- `status: "❌ ERROR"` - Critical failure

---

## 🎯 Quick Start Testing

### 1. Start Backend
```bash
cd backend
uvicorn main:app --reload
```

### 2. Check System Status
```bash
curl http://localhost:8000/api/ai/agentic/status
```

### 3. Login & Get Token
```bash
# Login via your auth system
# Get Supabase token
```

### 4. Run Tests
```bash
curl -X POST http://localhost:8000/api/ai/agentic/test \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 5. Check Results
Look for:
- `"system_status": "✅ OPERATIONAL"`
- `"success_rate": "100.0%"`
- `"tools_functional": true`

---

## 💡 Tips

1. **First Time Testing**
   - Run `/agentic/status` first to verify system is up
   - Check `openrouter_enabled: true` in status
   - Ensure you have valid API key in environment

2. **If Tests Fail**
   - Check OpenRouter API key
   - Verify database connection
   - Check logs for specific errors
   - Look at `error` field in failed tests

3. **Monitoring**
   - Watch backend logs for detailed flow
   - Look for `🔄 Agentic loop iteration` logs
   - Check `🔧 AI requested X tool calls` messages

4. **Performance**
   - Good: 1-2 iterations
   - Acceptable: 3-4 iterations
   - Investigate: 5 iterations (max)

---

## 🚀 Production Checklist

Before deploying:

- [ ] `/agentic/status` returns `"status": "operational"`
- [ ] `/agentic/test` shows 100% pass rate
- [ ] All 4 tools in available list
- [ ] OpenRouter enabled and working
- [ ] Database connection stable
- [ ] Logs show tool calls working
- [ ] Response times acceptable (<5s)
- [ ] Memory system tracking conversations

---

## 📝 Example Full Test Session

```bash
# 1. Check system
$ curl http://localhost:8000/api/ai/agentic/status
# Expected: status: "operational", 4 tools available

# 2. Run comprehensive tests
$ curl -X POST http://localhost:8000/api/ai/agentic/test \
  -H "Authorization: Bearer $TOKEN"
# Expected: 100% pass rate, all tools functional

# 3. Test individual command
$ curl -X POST http://localhost:8000/api/ai/command \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"command": "Pilih 1 student random", "context": {}}'
# Expected: Response with tool usage in data

# 4. Check memory
$ curl http://localhost:8000/api/ai/memory/stats
# Expected: Active sessions, tools tracked
```

---

**System is ready for production! 🎊**

*All testing integrated directly into main API - no external scripts needed!*

