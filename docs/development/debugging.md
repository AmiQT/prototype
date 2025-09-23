# 🐛 Debugging & Troubleshooting Guide

Comprehensive guide to debugging common issues across all components of the Student Talent Profiling App.

## 🎯 **Quick Debug Checklist**

When something goes wrong, check these first:

1. **✅ Are all services running?**
   - Backend API: http://localhost:8000/health
   - Supabase project: Active and configured
   - Mobile app: Connected to correct backend

2. **✅ Environment variables set correctly?**
   - DATABASE_URL, SUPABASE_URL, API keys
   - Check .env files in backend/
   - Verify config in mobile app

3. **✅ Network connectivity?**
   - Internet connection stable
   - Firewall not blocking requests
   - CORS configured properly

---

## 🔧 **Backend Issues**

### **Database Connection Failed**

**Symptoms:**
```
sqlalchemy.exc.OperationalError: could not connect to server
```

**Solutions:**
```bash
# 1. Check DATABASE_URL format
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:5432/postgres

# 2. Verify Supabase project status
# Go to Supabase dashboard, ensure project is active

# 3. Test connection manually
psql "postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:5432/postgres"

# 4. Check network/firewall
ping db.[REF].supabase.co
```

### **Authentication Errors**

**Symptoms:**
```
401 Unauthorized: Invalid authentication token
```

**Solutions:**
```python
# 1. Check JWT token format
# Should be: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# 2. Verify Supabase JWT secret
SUPABASE_JWT_SECRET=your-jwt-secret-from-supabase

# 3. Check token expiry
# Tokens expire - client should refresh automatically

# 4. Debug authentication middleware
import jwt
decoded = jwt.decode(token, verify=False)
print(f"Token payload: {decoded}")
```

### **Slow API Responses**

**Symptoms:**
- API responses > 2 seconds
- Timeout errors

**Solutions:**
```python
# 1. Check database query performance
# Add logging to identify slow queries
import time
start = time.time()
result = await db.fetch_all(query)
duration = time.time() - start
if duration > 0.5:
    logger.warning(f"Slow query took {duration:.2f}s: {query}")

# 2. Enable query logging in PostgreSQL
# Add to connection string: ?log_statement=all

# 3. Check indexes
EXPLAIN ANALYZE SELECT * FROM showcase_posts WHERE category = 'technical';

# 4. Monitor connection pool
# Check pool status in logs
```

### **Memory Issues**

**Symptoms:**
```
MemoryError: Out of memory
```

**Solutions:**
```python
# 1. Check for memory leaks
import psutil
process = psutil.Process()
print(f"Memory usage: {process.memory_info().rss / 1024 / 1024:.1f} MB")

# 2. Optimize database connections
# Use connection pooling properly
engine = create_async_engine(
    DATABASE_URL,
    pool_size=20,
    max_overflow=10,
    pool_pre_ping=True
)

# 3. Clear caches periodically
# Implement cache cleanup strategy

# 4. Use pagination for large datasets
# Don't load all data at once
```

---

## 📱 **Mobile App Issues**

### **Supabase Connection Failed**

**Symptoms:**
```
SupabaseRealtimeError: WebSocket connection failed
```

**Solutions:**
```dart
// 1. Check configuration
// lib/config/supabase_config.dart
class SupabaseConfig {
  static const String url = 'https://[PROJECT_REF].supabase.co';
  static const String anonKey = 'eyJ...';
}

// 2. Verify internet connectivity
final connectivity = await Connectivity().checkConnectivity();
if (connectivity == ConnectivityResult.none) {
  // Handle offline state
}

// 3. Test connection manually
try {
  final response = await SupabaseConfig.client
      .from('users')
      .select('id')
      .limit(1);
  debugPrint('Connection test successful');
} catch (e) {
  debugPrint('Connection test failed: $e');
}

// 4. Check project status
// Go to Supabase dashboard, verify project is not paused
```

### **Authentication Not Working**

**Symptoms:**
- Login fails silently
- User not redirected after login

**Solutions:**
```dart
// 1. Debug auth service
class SupabaseAuthService {
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      debugPrint('Attempting login for: $email');
      
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      debugPrint('Auth response: ${response.user?.id}');
      
      if (response.user != null) {
        // Success
        return UserModel.fromSupabaseUser(response.user!);
      }
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
    return null;
  }
}

// 2. Check user exists in database
// Verify user was created in Supabase Auth dashboard

// 3. Check auth state persistence
final session = SupabaseConfig.client.auth.currentSession;
debugPrint('Current session: ${session?.user?.id}');
```

### **Data Not Loading/Updating**

**Symptoms:**
- Empty lists in UI
- Data doesn't refresh

**Solutions:**
```dart
// 1. Debug service calls
class ShowcaseService {
  Future<List<ShowcasePostModel>> getPosts() async {
    try {
      debugPrint('Fetching posts from API...');
      
      final response = await SupabaseConfig.client
          .from('showcase_posts')
          .select('*')
          .order('created_at', ascending: false)
          .limit(20);
      
      debugPrint('Received ${response.length} posts');
      
      return response
          .map((item) => ShowcasePostModel.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      rethrow;
    }
  }
}

// 2. Check data models
// Ensure JSON parsing is working correctly
try {
  final post = ShowcasePostModel.fromJson(jsonData);
} catch (e) {
  debugPrint('JSON parsing error: $e');
  debugPrint('Raw JSON: $jsonData');
}

// 3. Clear app cache
// Sometimes cached data causes issues
await CacheService.clearAllCaches();

// 4. Check network requests
// Enable network debugging in development
```

### **UI Not Updating**

**Symptoms:**
- State changes don't reflect in UI
- Widgets not rebuilding

**Solutions:**
```dart
// 1. Check Provider setup
class AuthProvider extends ChangeNotifier {
  void updateUser(UserModel user) {
    _currentUser = user;
    notifyListeners(); // Don't forget this!
  }
}

// 2. Verify widget listening to provider
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    return Text(authProvider.currentUser?.name ?? 'Not logged in');
  },
)

// 3. Check setState usage
class _MyWidgetState extends State<MyWidget> {
  void updateData() {
    setState(() {
      // Update state variables here
    });
  }
}

// 4. Use Flutter Inspector
// In VS Code: Ctrl+Shift+P -> "Flutter: Open Flutter Inspector"
```

---

## 🌐 **Web Dashboard Issues**

### **API Calls Failing**

**Symptoms:**
```javascript
CORS error: Access to fetch blocked by CORS policy
```

**Solutions:**
```javascript
// 1. Check CORS configuration in backend
// FastAPI should allow frontend origin

// 2. Verify API endpoint URLs
const API_BASE_URL = 'https://your-backend.render.com';
const response = await fetch(`${API_BASE_URL}/api/showcase`);

// 3. Add proper headers
const response = await fetch('/api/users', {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  },
});

// 4. Handle errors properly
if (!response.ok) {
  console.error(`API error: ${response.status} ${response.statusText}`);
  const errorData = await response.text();
  console.error('Error details:', errorData);
}
```

### **Authentication Issues**

**Symptoms:**
- User not staying logged in
- Token expired errors

**Solutions:**
```javascript
// 1. Check token storage
const token = localStorage.getItem('supabase.auth.token');
if (!token) {
  // Redirect to login
  window.location.href = '/login.html';
}

// 2. Verify token format and expiry
try {
  const payload = JSON.parse(atob(token.split('.')[1]));
  const expiry = new Date(payload.exp * 1000);
  
  if (expiry < new Date()) {
    console.warn('Token expired');
    // Refresh token or redirect to login
  }
} catch (e) {
  console.error('Invalid token format:', e);
}

// 3. Implement token refresh
async function refreshToken() {
  try {
    const response = await supabase.auth.refreshSession();
    if (response.data.session) {
      localStorage.setItem('supabase.auth.token', 
                          response.data.session.access_token);
    }
  } catch (e) {
    console.error('Token refresh failed:', e);
    // Redirect to login
  }
}
```

---

## 🔍 **Advanced Debugging**

### **Performance Issues**

**Backend Profiling:**
```python
# Add performance middleware
import time
from fastapi import Request

@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    
    response.headers["X-Process-Time"] = str(process_time)
    
    if process_time > 1.0:
        logger.warning(f"Slow request: {request.url} took {process_time:.2f}s")
    
    return response
```

**Mobile Performance:**
```dart
// Profile widget performance
import 'package:flutter/scheduler.dart';

class PerformanceProfiler {
  static void startProfiling(String operation) {
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        if (timing.duration > const Duration(milliseconds: 16)) {
          debugPrint('Slow frame: ${timing.duration.inMilliseconds}ms');
        }
      }
    });
  }
}
```

### **Memory Debugging**

**Backend Memory:**
```python
import tracemalloc

# Start tracing
tracemalloc.start()

# Your code here

# Get current memory usage
current, peak = tracemalloc.get_traced_memory()
print(f"Current memory usage: {current / 1024 / 1024:.1f} MB")
print(f"Peak memory usage: {peak / 1024 / 1024:.1f} MB")

tracemalloc.stop()
```

**Mobile Memory:**
```dart
// Monitor memory usage
import 'dart:developer' as developer;

void monitorMemory() {
  developer.Timeline.startSync('MemoryCheck');
  
  // Your code here
  
  developer.Timeline.finishSync();
  
  // Check memory in Observatory/DevTools
}
```

---

## 🛠️ **Development Tools**

### **Useful Commands**

**Backend:**
```bash
# View logs in real-time
tail -f backend.log

# Check database connections
ps aux | grep postgres

# Test API endpoints
curl -X GET http://localhost:8000/health
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'

# Database queries
psql $DATABASE_URL -c "SELECT COUNT(*) FROM users;"
```

**Mobile:**
```bash
# Flutter debugging
flutter logs                    # View device logs
flutter doctor                  # Check setup
flutter clean && flutter run    # Clean rebuild

# Performance profiling
flutter run --profile          # Profile mode
flutter run --release         # Release mode testing
```

**Web:**
```bash
# Browser debugging
# Open DevTools (F12)
# Check Console for errors
# Check Network tab for failed requests
# Check Application tab for localStorage/sessionStorage

# Test responsive design
# DevTools -> Device Toolbar (Ctrl+Shift+M)
```

### **Logging Best Practices**

**Structured Logging:**
```python
import logging
import json

class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_data = {
            'timestamp': record.created,
            'level': record.levelname,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno,
        }
        return json.dumps(log_data)

# Setup logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
handler = logging.StreamHandler()
handler.setFormatter(JSONFormatter())
logger.addHandler(handler)
```

---

## 🚨 **Emergency Procedures**

### **System Down**

1. **Check Status Page**
   - Backend: https://your-backend.render.com/health
   - Supabase: https://status.supabase.com

2. **Restart Services**
   ```bash
   # Backend restart (if self-hosted)
   systemctl restart backend-service
   
   # Or via deployment platform
   # Render: Trigger manual deploy
   # Railway: railway up
   ```

3. **Rollback if Needed**
   ```bash
   git revert <commit-hash>
   git push origin main
   # Redeploy
   ```

### **Database Issues**

1. **Check Connection Pool**
   ```sql
   SELECT * FROM pg_stat_activity;
   ```

2. **Emergency Maintenance Mode**
   ```python
   # Add to main.py
   MAINTENANCE_MODE = os.getenv("MAINTENANCE_MODE", "false").lower() == "true"
   
   @app.middleware("http")
   async def maintenance_check(request: Request, call_next):
       if MAINTENANCE_MODE:
           return JSONResponse(
               status_code=503,
               content={"message": "System under maintenance"}
           )
       return await call_next(request)
   ```

---

## 📞 **Getting Help**

### **Log Collection**
Before asking for help, collect:

1. **Error messages** (full stack traces)
2. **Log files** (backend, mobile, web console)
3. **System information** (OS, versions, environment)
4. **Steps to reproduce** (detailed)
5. **Expected vs actual behavior**

### **Useful Resources**

- **Supabase Docs**: https://supabase.com/docs
- **FastAPI Docs**: https://fastapi.tiangolo.com
- **Flutter Docs**: https://flutter.dev/docs
- **Stack Overflow**: Tag with specific technologies

### **Development Team Contacts**

For urgent production issues:
- **Backend Issues**: Check backend logs and restart service
- **Database Issues**: Contact Supabase support
- **Mobile Issues**: Check app store console

---

Remember: Most issues are configuration or environment problems. Check the basics first! 🚀
