# Rate Limiting & Error Handling - AI Chatbot

## 🚨 Masalah: 429 Resource Exhausted

### Punca
Error `429 Resource exhausted` dari Gemini API bermaksud:
- ✅ Sistem berfungsi dengan baik
- ❌ Mencapai had penggunaan API (rate limit atau quota)

### Gemini API Free Tier Limits
```
- 15 requests per minute (RPM)
- 1 million tokens per minute (TPM) 
- 1,500 requests per day (RPD)
```

## ✅ Penyelesaian Yang Diimplementasi

### 1. Retry Logic dengan Exponential Backoff

**Lokasi**: `backend/app/ai_assistant/gemini_client.py`

```python
# Automatic retry for rate limit errors
max_retries = 3
retry_delay = 2 seconds

Attempt 1: Immediate
Attempt 2: Wait 2s
Attempt 3: Wait 4s
Attempt 4: Return friendly error message
```

**Benefit**:
- Automatic recovery dari temporary rate limits
- User tidak perlu manually retry
- Graceful degradation dengan error message dalam BM

### 2. Client-Side Rate Limiter

**Lokasi**: `backend/app/ai_assistant/rate_limiter.py`

```python
# Preventive rate limiting
Max: 10 requests per 60 seconds per user
```

**Features**:
- Per-user tracking
- In-memory (fast)
- Provides wait time information
- Friendly error messages dalam Bahasa Melayu

**Integration**:
```python
# manager.py checks rate limit before calling Gemini
if not gemini_rate_limiter.can_make_request(user_id):
    return "Maaf, anda telah mencapai had penggunaan..."
```

### 3. Token Usage Optimization

**Optimizations**:

#### a. Reduced Conversation History
```python
# Before: limit=10 messages
# After:  limit=5 messages
structured_ctx = get_structured_context(session_id, limit=5)
```

#### b. Truncate Long Responses
```python
# Truncate AI responses in history to save tokens
if len(content) > 300:
    content = content[:300] + "..."
```

#### c. Efficient System Prompt
- System prompt ditulis efficiently
- Only essential context included
- Tools definition optimized

### 4. Graceful Error Handling

**Error Messages dalam Bahasa Melayu**:

```python
# Rate limit (429)
"Maaf, sistem AI sedang sibuk sekarang. Terlalu banyak permintaan dalam masa yang singkat. Sila cuba lagi dalam beberapa saat. 🙏"

# Client-side rate limit
"Maaf, anda telah mencapai had penggunaan. Sila tunggu {X} saat sebelum cuba lagi. 🙏"

# General error
"Maaf, ada masalah dengan sistem AI. Sila cuba lagi atau hubungi admin."
```

**Benefits**:
- User-friendly messages
- Natural Bahasa Melayu
- Clear instructions
- No technical jargon

## 📊 Monitoring

### Log Messages

```bash
# Successful request
✅ Rate limit OK for user_123: 3/10 in 60s

# Rate limited (client-side)
⚠️  Rate limit exceeded for user_123: 10/10 in 60s

# Gemini retry
⏳ Rate limit hit (429). Retrying in 2s... (attempt 1/3)

# Final failure
❌ Rate limit exceeded after 3 attempts
```

### Check Logs
```bash
# Backend logs
tail -f backend/logs/ai_assistant.log

# Or in real-time during development
python main.py
```

## 🔧 Configuration

### Adjust Rate Limits

**Edit `rate_limiter.py`**:
```python
# More restrictive (safer)
gemini_rate_limiter = SimpleRateLimiter(
    max_requests=5,   # Lower limit
    time_window=60
)

# More permissive (risky)
gemini_rate_limiter = SimpleRateLimiter(
    max_requests=15,  # Match Gemini limit
    time_window=60
)
```

### Adjust Retry Logic

**Edit `gemini_client.py`**:
```python
# More retries
max_retries = 5
retry_delay = 3  # seconds

# Fewer retries (faster fail)
max_retries = 2
retry_delay = 1
```

### Adjust Token Usage

**Edit `manager.py`**:
```python
# More history (more context, more tokens)
structured_ctx = get_structured_context(session_id, limit=10)

# Less history (less context, fewer tokens)
structured_ctx = get_structured_context(session_id, limit=3)

# Truncate length
if len(content) > 500:  # Longer allowed
    content = content[:500] + "..."
```

## 🧪 Testing

### Test Rate Limiter

```bash
cd backend
python -c "
from app.ai_assistant.rate_limiter import gemini_rate_limiter

# Simulate rapid requests
for i in range(15):
    can_request = gemini_rate_limiter.can_make_request('test_user')
    print(f'Request {i+1}: {can_request}')
    if not can_request:
        wait = gemini_rate_limiter.get_wait_time('test_user')
        print(f'Wait time: {wait:.1f}s')
"
```

Expected output:
```
Request 1-10: True
Request 11-15: False (rate limited)
Wait time: ~50-60s
```

### Test Retry Logic

1. Make rapid requests to trigger 429
2. Check logs for retry messages
3. Verify friendly error message after max retries

### Test Token Optimization

```bash
# Check conversation history size
curl http://localhost:8000/api/ai/history?limit=10

# Verify messages are truncated
```

## 📈 Best Practices

### For Users

1. **Wait Between Requests**: Don't spam the chatbot
2. **Be Patient**: System will retry automatically
3. **Read Error Messages**: They explain what to do
4. **Try Again Later**: If limit reached, wait a bit

### For Developers

1. **Monitor Logs**: Watch for patterns
2. **Adjust Limits**: Based on actual usage
3. **Optimize Prompts**: Keep system prompt concise
4. **Test Under Load**: Simulate multiple users
5. **Consider Upgrade**: If free tier insufficient

## 🚀 Upgrade Options

### If Free Tier Insufficient

**Option 1: Gemini Pro (Paid)**
- Higher rate limits
- Better performance
- More reliable

**Option 2: Multiple API Keys**
- Rotate between keys
- Distribute load
- Requires key management

**Option 3: Caching**
- Cache common responses
- Reduce API calls
- Faster responses

**Option 4: Queue System**
- Queue requests
- Process gradually
- Fair distribution

## 📚 References

- Gemini API Limits: https://ai.google.dev/pricing
- Rate Limit Error: https://cloud.google.com/vertex-ai/generative-ai/docs/error-code-429
- Our Implementation:
  - `backend/app/ai_assistant/rate_limiter.py`
  - `backend/app/ai_assistant/gemini_client.py`
  - `backend/app/ai_assistant/manager.py`

---

**Dikemaskini**: November 5, 2025
**Status**: ✅ Implemented & Active
