# 📱 Mobile App Setup Guide

Complete guide to set up the Flutter mobile application.

## 🎯 **Overview**

The mobile app is built with Flutter and connects to:
- **Supabase**: Authentication and real-time database
- **Custom Backend**: Advanced features and analytics  
- **Cloudinary**: Optimized media storage

## ⚡ **Quick Setup (10 Minutes)**

### **1. Prerequisites**
```bash
# Install Flutter SDK
- Flutter 3.19+ 
- Dart 3.3+
- Android Studio / Xcode
- VS Code with Flutter extension
```

### **2. Clone & Install**
```bash
# Navigate to mobile app
cd mobile_app

# Install dependencies
flutter pub get

# Check setup
flutter doctor
```

### **3. Configuration**
```dart
// lib/config/supabase_config.dart
class SupabaseConfig {
  static const String url = 'https://[YOUR_PROJECT_REF].supabase.co';
  static const String anonKey = 'eyJ...';
  
  // Backend API (if using custom backend)
  static const String backendUrl = 'https://your-backend.render.com';
}
```

### **4. Run App**
```bash
# Run on Android
flutter run

# Run on iOS
flutter run -d ios

# Run on web
flutter run -d chrome
```

---

## 📋 **Project Structure**

```
mobile_app/
├── lib/
│   ├── config/          # Configuration files
│   ├── models/          # Data models  
│   ├── screens/         # UI screens
│   ├── services/        # API services
│   ├── providers/       # State management
│   ├── widgets/         # Reusable UI components
│   └── utils/           # Utility functions
├── assets/              # Images, icons, data
├── android/             # Android-specific code
├── ios/                 # iOS-specific code
└── web/                 # Web-specific files
```

---

## 🔧 **Key Features Implementation**

### **Authentication Flow**
```dart
// lib/services/supabase_auth_service.dart
class SupabaseAuthService extends ChangeNotifier {
  Future<UserModel?> signInWithEmail(String email, String password) async {
    final response = await SupabaseConfig.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (response.user != null) {
      return UserModel.fromSupabaseUser(response.user!);
    }
    return null;
  }
}
```

### **Real-time Data Sync**
```dart
// lib/services/showcase_service.dart  
class ShowcaseService {
  Stream<List<ShowcasePostModel>> getPostsStream() {
    return SupabaseConfig.client
        .from('showcase_posts')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .map((item) => ShowcasePostModel.fromJson(item))
            .toList());
  }
}
```

### **Media Upload**
```dart
// lib/services/media_service.dart
class MediaService {
  Future<String> uploadImage(File imageFile) async {
    // Upload to Cloudinary via backend API
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${SupabaseConfig.backendUrl}/media/upload/image'),
    );
    
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
    ));
    
    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final data = json.decode(responseData);
    
    return data['url'];
  }
}
```

---

## 🎨 **UI/UX Features**

### **Dark Mode Support**
```dart
// lib/config/app_theme.dart
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3),
      brightness: Brightness.light,
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3),
      brightness: Brightness.dark,
    ),
  );
}
```

### **Modern UI Components**
```dart
// lib/widgets/modern/modern_post_card.dart
class ModernPostCard extends StatelessWidget {
  final ShowcasePostModel post;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Post header with user info
          // Post content
          // Media gallery
          // Engagement buttons (like, comment, share)
        ],
      ),
    );
  }
}
```

---

## ⚡ **Performance Optimizations**

### **Intelligent Caching**
```dart
// lib/services/cache_service.dart
class CacheService {
  static final Map<String, dynamic> _cache = {};
  static const Duration _cacheValidity = Duration(minutes: 2);
  
  static bool isCacheValid(String key) {
    final cacheTime = _cacheTimestamps[key];
    if (cacheTime == null) return false;
    
    return DateTime.now().difference(cacheTime) < _cacheValidity;
  }
  
  static void setCache(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }
}
```

### **Optimized Image Loading**
```dart
// lib/widgets/optimized_image.dart
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder: (context, url) => const ShimmerWidget(),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      fit: BoxFit.cover,
    );
  }
}
```

---

## 🚀 **User Roles & Features**

### **Student Features**
```dart
// Student-specific screens
├── StudentDashboard        # Overview, stats, recent posts
├── ProfileSetupScreen      # Complete academic profile
├── ShowcaseCreateScreen    # Create talent posts
├── AchievementScreen       # Upload certifications
├── EventsScreen            # Browse and join events
└── SearchScreen            # Find other students/lecturers
```

### **Lecturer Features**
```dart
// Lecturer-specific screens
├── LecturerDashboard       # Student overview, analytics
├── StudentSearchScreen     # Advanced student search
├── FeedbackScreen          # Provide feedback on posts
├── EventManagementScreen   # Create and manage events
└── ReportsScreen           # Generate progress reports
```

### **Admin Features**
```dart
// Admin-specific screens  
├── AdminDashboard          # System overview, metrics
├── UserManagementScreen    # Manage all users
├── ContentModerationScreen # Moderate posts/comments
├── AnalyticsScreen         # Detailed system analytics
└── SettingsScreen          # System configuration
```

---

## 📊 **State Management**

### **Provider Pattern**
```dart
// lib/providers/auth_provider.dart
class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentUser = await SupabaseAuthService.signIn(email, password);
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### **Provider Setup**
```dart
// main.dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ShowcaseProvider()),
      ],
      child: MyApp(),
    ),
  );
}
```

---

## 🧪 **Testing**

### **Unit Tests**
```bash
# Run unit tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### **Widget Tests**
```dart
// test/widget_test.dart
testWidgets('Login screen displays correctly', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  
  expect(find.text('Email'), findsOneWidget);
  expect(find.text('Password'), findsOneWidget);
  expect(find.text('Sign In'), findsOneWidget);
});
```

### **Integration Tests**
```bash
# Run integration tests
flutter drive --target=test_driver/app.dart
```

---

## 📱 **Platform-Specific Setup**

### **Android**
```bash
# Update android/app/build.gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}

# Add permissions in android/app/src/main/AndroidManifest.xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### **iOS**
```bash
# Update ios/Runner/Info.plist
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to upload photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images</string>
```

---

## 🐛 **Troubleshooting**

### **Common Issues**

**"Supabase connection failed"**
```dart
// Check configuration
- Verify SUPABASE_URL and ANON_KEY
- Ensure project is active on Supabase
- Check internet connection
```

**"Build failed on Android"**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

**"Hot reload not working"**
```bash
# Stop and restart
r    # Hot reload
R    # Hot restart
q    # Quit
```

**"State not updating"**
```dart
// Ensure notifyListeners() is called
class MyProvider extends ChangeNotifier {
  void updateData() {
    // Update logic
    notifyListeners(); // Don't forget this!
  }
}
```

---

## 🔄 **Development Workflow**

1. **Start Development**
   ```bash
   flutter run --hot
   # Enable hot reload for faster development
   ```

2. **State Changes**
   ```bash
   flutter pub get        # After adding new dependencies
   flutter clean          # If facing build issues
   ```

3. **Testing**
   ```bash
   flutter test           # Run unit tests
   flutter analyze        # Check for issues
   ```

4. **Build for Release**
   ```bash
   flutter build apk      # Android APK
   flutter build ios      # iOS build
   flutter build web      # Web build
   ```

---

## 🚀 **Next Steps**

After setup:
1. **Test Authentication**: Try login/signup flow
2. **Explore Features**: Navigate through different screens
3. **Test Real-time**: Create posts and see live updates
4. **Check Performance**: Monitor app responsiveness

Need help? Check the [Debugging Guide](../development/debugging.md) or [Architecture Guide](../development/architecture.md).
