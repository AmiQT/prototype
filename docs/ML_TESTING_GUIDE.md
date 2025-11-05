# 🧪 ML Implementation - Quick Test Guide

**Status:** Server running on http://localhost:8000  
**Gemini:** Connected and initialized  
**Cache:** Ready  

---

## ✅ Test 1: Health Check

**What it does:** Verifies ML system is running and configured

**In Browser:**
```
http://localhost:8000/api/ml/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "gemini_api_configured": true,
  "model": "gemini-2.0-flash-exp",
  "cache": {
    "size": 0,
    "max_size": 1000,
    "hit_rate": "0.0%"
  },
  "message": "ML Analytics service is operational"
}
```

**✅ Passed if:** status = "healthy"

---

## ✅ Test 2: Get System Stats

**What it does:** Shows cache performance and ML configuration

**In Browser:**
```
http://localhost:8000/api/ml/stats
```

**Expected Response:**
```json
{
  "cache": {
    "size": 0,
    "max_size": 1000,
    "hits": 0,
    "misses": 0,
    "hit_rate": "0.0%",
    "total_requests": 0
  },
  "configuration": {
    "model": "gemini-2.0-flash-exp",
    "cache_ttl_hours": 24,
    "cache_max_size": 1000,
    "batch_size": 10
  },
  "gemini_api_configured": true
}
```

**✅ Passed if:** cache_max_size = 1000 and model shows "gemini-2.0-flash-exp"

---

## ✅ Test 3: Get Recommendations

**What it does:** Shows actions for different risk levels

**In Browser:**
```
http://localhost:8000/api/ml/recommendations/medium
```

**Expected Response:**
```json
{
  "risk_level": "medium",
  "emoji": "🟡",
  "recommended_actions": [
    "Reach out this week",
    "Understand concerns",
    "Offer relevant support",
    "Schedule follow-up"
  ]
}
```

**Test all three:**
- `http://localhost:8000/api/ml/recommendations/low` → 🟢
- `http://localhost:8000/api/ml/recommendations/medium` → 🟡
- `http://localhost:8000/api/ml/recommendations/high` → 🔴

**✅ Passed if:** All three return different emoji and actions

---

## 🧪 Test 4: Predict Student Risk (with sample data)

**What it does:** Makes a prediction for a test student

**Using Python (in terminal):**

```python
import requests
import json

# Sample student data
student = {
    "id": "TEST001",
    "name": "Test Student",
    "email": "test@campus.edu",
    "cgpa": 3.5,
    "academic_score": 0.85,
    "events_attended": 5,
    "events_organized": 1,
    "engagement_score": 0.75,
    "last_activity": "2025-11-05T10:00:00Z",
    "activity_trend": 0.9,
    "days_since_activity": 1,
    "profile_completion": 0.90,
    "bio_filled": True,
    "skills_filled": True,
    "connections": 30,
    "followers": 15,
    "social_score": 0.8,
    "messages_sent": 25,
    "posts_created": 5,
    "interactions": 50,
}

# Make request
url = "http://localhost:8000/api/ml/student/TEST001/predict"
response = requests.post(url, json=student)
print(json.dumps(response.json(), indent=2))
```

**Expected Response:**
```json
{
  "student_id": "TEST001",
  "risk_score": 0.15,
  "risk_level": "low",
  "risk_emoji": "🟢",
  "risk_factors": [...],
  "strengths": [...],
  "recommendations": [...],
  "performance_metrics": {...},
  "confidence": 0.82,
  "gemini_insights": {...}
}
```

**✅ Passed if:**
- risk_score is between 0 and 1
- risk_level is one of: low, medium, high
- confidence is between 0.7 and 0.85

---

## 🧪 Test 5: Cache Performance

**What it does:** Test that caching is working

**Step 1:** Make prediction (creates cache entry)
```python
# Use same code as Test 4
response1 = requests.post(url, json=student)
print("First request:", response1.elapsed.total_seconds(), "seconds")
```

**Step 2:** Check stats BEFORE second request
```python
stats_url = "http://localhost:8000/api/ml/stats"
response = requests.get(stats_url)
print(json.dumps(response.json(), indent=2))
```

Should show:
```
"hits": 0,
"misses": 1,
"hit_rate": "0%"
```

**Step 3:** Make same prediction again
```python
response2 = requests.post(url, json=student)
print("Second request:", response2.elapsed.total_seconds(), "seconds")
```

**Step 4:** Check stats AFTER second request
```python
response = requests.get(stats_url)
print(json.dumps(response.json(), indent=2))
```

Should show:
```
"hits": 1,
"misses": 1,
"hit_rate": "50.0%"
```

**✅ Passed if:**
- Second request is MUCH faster (200ms vs 2-5s)
- Cache stats show hits: 1, misses: 1, hit_rate: 50%

---

## 🧪 Test 6: Cache Invalidation

**What it does:** Test cache clearing

**Step 1:** Clear specific student cache
```python
url = "http://localhost:8000/api/ml/cache/invalidate?student_id=TEST001"
response = requests.post(url)
print(json.dumps(response.json(), indent=2))
```

Expected:
```json
{
  "status": "success",
  "message": "Cache invalidated for student TEST001"
}
```

**Step 2:** Check stats (should reset)
```python
stats_url = "http://localhost:8000/api/ml/stats"
response = requests.get(stats_url)
print(json.dumps(response.json(), indent=2))
```

Should show:
```
"size": 0,
"hits": 0,
"misses": 0,
"hit_rate": "0%"
```

**✅ Passed if:** Cache size returns to 0 and hit rate resets

---

## 🧪 Test 7: Risk Levels

**What it does:** Test different risk scenarios

**Test with LOW risk student:**
```python
student_low = {
    "id": "LOWRISK",
    "name": "Good Student",
    "cgpa": 3.8,
    "academic_score": 0.95,
    "engagement_score": 0.85,
    "activity_trend": 0.9,
    "days_since_activity": 1,
    "profile_completion": 0.95,
    "connections": 40,
    "followers": 20,
}
# risk_score should be < 0.30
```

**Test with MEDIUM risk student:**
```python
student_med = {
    "id": "MEDRISK",
    "name": "Average Student",
    "cgpa": 2.5,
    "academic_score": 0.60,
    "engagement_score": 0.50,
    "activity_trend": 0.50,
    "days_since_activity": 14,
    "profile_completion": 0.70,
    "connections": 15,
}
# risk_score should be 0.30-0.60
```

**Test with HIGH risk student:**
```python
student_high = {
    "id": "HIGHRISK",
    "name": "At-Risk Student",
    "cgpa": 1.5,
    "academic_score": 0.30,
    "engagement_score": 0.15,
    "activity_trend": 0.10,
    "days_since_activity": 45,
    "profile_completion": 0.20,
    "connections": 3,
}
# risk_score should be > 0.60
```

**✅ Passed if:**
- LOW: risk_emoji = 🟢, risk_score < 0.30
- MEDIUM: risk_emoji = 🟡, risk_score 0.30-0.60
- HIGH: risk_emoji = 🔴, risk_score > 0.60

---

## 📊 Test Results Checklist

Print this and check off as you go:

```
□ Test 1: Health Check - PASSED
□ Test 2: System Stats - PASSED
□ Test 3: Recommendations (all 3) - PASSED
□ Test 4: Student Prediction - PASSED
□ Test 5: Cache Performance - PASSED
□ Test 6: Cache Invalidation - PASSED
□ Test 7: Risk Levels (all 3) - PASSED

✅ ALL TESTS PASSED - ML SYSTEM IS WORKING!
```

---

## 🐛 Troubleshooting

### Issue: "Connection refused"
- Verify server is running: `python main.py` in backend folder
- Check port: Should be 8000

### Issue: Health shows "degraded"
- Check `.env` has `GEMINI_API_KEY` set
- Restart server

### Issue: Prediction returns error
- Check student data has all required fields
- Look at server logs for error message
- Simplify data, try test data from Test 4

### Issue: Cache hit rate is 0%
- This is normal on first request
- Make multiple requests to same student_id
- Check hit_rate increases

### Issue: Gemini parse error
- This means Gemini returned invalid JSON
- Try reducing `ML_MAX_TOKENS` in `.env` from 500 to 300
- Restart server

---

## 📈 Next Steps After Testing

**If ALL tests pass:**
1. ✅ System is working correctly
2. Ready to integrate with real database
3. Ready to connect to frontend
4. Ready for production use

**To integrate with real data:**
1. Connect to your Supabase database
2. Query real student data
3. Format to match expected structure
4. Call `/api/ml/student/{id}/predict`
5. Display results in dashboard

**Example integration:**
```python
# In your backend API endpoint
from app.ml_analytics import MLPredictor

async def get_student_with_ml(student_id):
    # Get real student from database
    student = await db.get_student(student_id)
    
    # Get ML prediction
    predictor = MLPredictor()
    prediction = await predictor.predict_student_risk(student)
    
    # Return combined data
    return {
        "student": student,
        "ml_analysis": prediction
    }
```

---

## 🎓 Understanding the Output

**risk_score** (0 to 1)
- 0 = No risk
- 0.5 = Medium risk
- 1 = Very high risk

**confidence** (0.7 to 0.85)
- How sure the system is
- Higher = more reliable prediction
- Based on profile completeness

**risk_factors** (list of 3)
- What's causing the risk
- Prioritized by importance
- Action items to address

**strengths** (list of 2)
- What's going well
- Positive areas to reinforce
- Building blocks for support

**recommendations** (list of 3)
- What to do about it
- Specific, actionable steps
- Tailored to student profile

**performance_metrics**
- Breakdown by category
- Academic, Engagement, Activity, Profile, Social
- Each 0-1 scale with level description

---

## 💾 Save Test Results

Create a file `tests/ml_test_results.txt`:
```
ML Analytics Testing Results
Date: [TODAY]
Tester: [YOUR NAME]

Test 1 (Health): PASSED
Test 2 (Stats): PASSED
Test 3 (Recommendations): PASSED
Test 4 (Prediction): PASSED
Test 5 (Cache): PASSED
Test 6 (Invalidation): PASSED
Test 7 (Risk Levels): PASSED

Overall Status: ✅ ALL TESTS PASSED
System Ready for: Production Use

Notes:
- Cache is working well
- Predictions accurate
- Response times good
```

---

**Ready to test? Start with Test 1! 🚀**

