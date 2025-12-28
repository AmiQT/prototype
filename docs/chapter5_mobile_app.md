## 5.2 Mobile Application Implementation

This section documents the implementation of the student-facing mobile application built using Flutter framework, designed for cross-platform compatibility (iOS and Android). The app focuses on providing students with tools for talent profiling, portfolio management, and AI-driven career guidance.

---

### 5.2.1 Mobile Login Screen

**[INSERT SCREENSHOT HERE]**

**FIGURE 5.2.1: Mobile App Login Screen**

Figure 5.2.1 illustrates the mobile login interface. The screen provides a clean, user-friendly entry point for students. It handles authentication via Supabase, including input validation for email and password, password visibility toggling, and automatic redirection logic. If a user logs in but hasn't completed their profile, the system intelligently redirects them to the "Profile Setup" flow instead of the main dashboard.

**Code Snippet:**

```dart
Future<void> _onSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Sign in with Supabase Auth
        final user = await authService.signInWithEmailAndPassword(email, password);
        
        // Profile Completion Check
        final hasCompletedProfile = await authService.hasCompletedProfile(user.uid);

        if (!hasCompletedProfile) {
          // Redirect to Profile Setup if profile is incomplete
          Navigator.pushReplacement(context, 
              MaterialPageRoute(builder: (_) => const ComprehensiveProfileSetupScreen()));
        } else {
          // Navigate to Dashboard
          Navigator.pushReplacement(context, 
              MaterialPageRoute(builder: (_) => const StudentDashboard()));
        }
      } catch (e) {
        ErrorHandler.showErrorSnackBar(context, e.toString());
      }
    }
}
```

This code snippet demonstrates the secure login process. It uses a centralized authentication service to authenticate credentials. Crucially, it implements a logic check to ensure data integrity: users must complete their profile setup before accessing the main application features, ensuring the system always has necessary student data for the AI profiling algorithms.

---

### 5.2.2 Student Dashboard

**[INSERT SCREENSHOT HERE]**

**FIGURE 5.2.2: Student Dashboard & Navigation**

Figure 5.2.2 displays the main student dashboard, which serves as the navigation hub for the application. It utilizes a persistent bottom navigation bar to switch between key modules: Home (Showcase), Discover (Search), AI Chat (Advisor), Events, and Profile. The dashboard maintains the state of each tab using an `IndexedStack`, ensuring smooth transitions and preventing unnecessary reloading of data.

**Code Snippet:**

```dart
class _StudentDashboardState extends State<StudentDashboard> {
  final List<Widget> _pages = [
    const ShowcaseScreen(),        // Home Feed
    const EnhancedSearchScreen(),  // Discovery
    const ChatScreen(),            // AI Advisor
    const EventProgramScreen(),    // Events
    const StudentProfileScreen(),  // User Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.event_available), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        // ...styling properties
      ),
    );
  }
}
```

The main dashboard interface implements the core navigation structure using Flutter's `BottomNavigationBar`. The `IndexedStack` widget is used for the body to preserve the state of each page (e.g., scroll position, input fields) when the user switches tabs, providing a native, high-performance user experience.

---

### 5.2.3 Student Profile Interface

**[INSERT SCREENSHOT HERE]**

**FIGURE 5.2.3: Student Profile Screen**

Figure 5.2.3 shows the comprehensive student profile interface. This screen visualizes the student's "Talent Profile," displaying their personal information, profile completeness score, aggregated statistics (Posts, Department, Semester), and bio. It features a collapsible header design (SliverAppBar) and tabbed content sections for "Posts", "About", and "Skills", allowing for an organized presentation of rich student data.

**Code Snippet:**

```dart
// Profile Completion Calculation Logic
double _calculateProfileCompletion() {
    int completedFields = 0;
    int totalFields = 8; 

    // Check availability of key data points
    if (_profile.bio?.isNotEmpty ?? false) completedFields++;
    if (_profile.skills.isNotEmpty) completedFields++;
    if (_profile.experiences.isNotEmpty) completedFields++;
    // ... other checks

    return (completedFields / totalFields) * 100;
}

// Enhanced Profile Image Builder
Widget _buildEnhancedProfileImage() {
    return Container(
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(blurRadius: 25, color: Colors.black26)],
        ),
        child: CircleAvatar(
            backgroundImage: NetworkImage(_profile.imageUrl),
            radius: 55,
            child: _profile.isComplete 
                ? Icon(Icons.verified, color: Colors.blue) 
                : null
        ),
    );
}
```

This code snippet highlights the profile logic. The profile completion algorithm dynamically computes a percentage score based on filled profile fields, gamifying the profile creation process to encourage students to provide complete data. The UI code demonstrates the use of visual cues, such as the verified badge, to reward complete profiles.

---

### 5.2.4 AI Chat Advisor (Gemini Integration)

**[INSERT SCREENSHOT HERE]**

**FIGURE 5.2.4: AI Chat Advisor Screen**

Figure 5.2.4 depicts the AI Chat Advisor screen, a central feature of the "Agentic AI" system. It allows students to converse with an AI assistant ("STAP Advisor") powered by Google's Gemini Pro model. The implementation supports real-time streaming responses, context-aware answers (using RAG for FSKTM-specific queries), and message history persistence.

**Code Snippet:**

```dart
Future<void> _sendMessage() async {
    // 1. Add User Message to UI
    setState(() => _messages.add(userMessage));

    // 2. Intelligent RAG Routing
    String? ragContext;
    if (_isFSKTMQuestion(content)) {
        // Fetch context from local dataset if query is domain-specific
        ragContext = await FSKTMDataService.getFSKTMContextForAIWithQuery(content);
    }

    // 3. Stream AI Response via Gemini Service
    await for (final partialContent in _geminiService.sendMessageStreaming(
        conversationId: _currentConversationId,
        content: content,
        ragContext: ragContext,
    )) {
        // Update UI in real-time as chunks arrive
        setState(() {
            _messages[lastIndex] = _messages[lastIndex].copyWith(content: partialContent);
        });
    }
}
```

This advanced implementation showcases the "Agentic" capabilities. The system doesn't just pass messages to the LLM; it first analyzes the intent (`_isFSKTMQuestion`). If the query relates to specific faculty matters (FSKTM), it retrieves relevant context via RAG (Retrieval-Augmented Generation) before querying the Gemini model. This ensures the AI provides accurate, institution-specific advice alongside general career guidance.

---

### 5.2.5 Showcase Feed & Social Features

**[INSERT SCREENSHOT HERE]**

**FIGURE 5.2.5: Student Showcase Feed**

Figure 5.2.5 illustrates the "Showcase Feed," a core social feature where students can post their achievements and projects. The implementation uses a "Smart Refresh" mechanism and real-time Supabase subscriptions to deliver instant updates without overloading the server. It supports rich media cards (GlassShowcaseCard) with interactive elements like likes, comments, and category filtering (e.g., Competition, Project, Activity).

**Code Snippet:**

```dart
// Smart Real-time Subscription Strategy
void _setupRealTimeSubscription() {
    // Cancel existing to prevent duplicates
    _postsSubscription?.cancel();

    // Listen to Supabase Realtime changes
    _postsSubscription = _showcaseService
        .getShowcasePostsRealtimeStream(limit: 6, category: _selectedCategory)
        .listen((posts) {
            
            // OPTIMIZATION: Only rebuild if data actually changed
            if (hasDeepChanges(_posts, posts)) {
                setState(() {
                    _posts = posts;
                    _isLoading = false;
                });
            }
        });
}
```

The code demonstrates a highly optimized real-time feed update strategy. Instead of blindly refreshing, it compares new data with existing state before triggering a UI rebuild. This ensures smooth scrolling performance while keeping content fresh, providing a modern social media experience for students.

---

### 5.2.6 Enhanced Search & Discovery

**[INSERT SCREENSHOT HERE]**

**FIGURE 5.2.6: Enhanced Search Screen**

Figure 5.2.6 shows the "Enhanced Search" screen, designed to help students discover peers, mentors, and projects. It features a debounced search input, history tracking, and a "Modern Filter Bottom Sheet" for granular filtering by role (Student/Lecturer), skills, semester, and CGPA. The UI follows a glassmorphic design language ("GlassContainer") for a premium aesthetic.

**Code Snippet:**

```dart
Future<void> _performSearch(String query) async {
    // 1. Gather active filters
    final selectedFilters = _availableFilters.values
        .expand((filters) => filters)
        .where((filter) => filter.isSelected)
        .toList();

    // 2. Track usage for analytics
    await _searchService.trackFilterUsage(
        query: query, userId: _currentUserId
    );

    // 3. Execute search against Supabase View
    final results = await _searchService.searchUsersAndProfiles(
        query: query,
        filters: selectedFilters,
    );
    
    setState(() => _searchResults = results);
}
```

This snippet highlights the sophisticated search logic. It combines text queries with complex filter objects before sending the request to the backend. Additionally, it integrates usage tracking to allow administrators to analyze search trends and understand what skills or profiles are most in demand within the university ecosystem.

---

### 5.2.7 Event Program Management

**[INSERT SCREENSHOT HERE]**

**FIGURE 5.2.7: Event Program Screen**

Figure 5.2.7 displays the "Event Program" screen, where students can browse and register for campus activities. The interface employs advanced animations (`FadeTransition`, `SlideTransition`) for a polished user experience. It supports searching, category filtering, and "Favoriting" events. The event cards display key details like date, location, and registration status.

**Code Snippet:**

```dart
// Animation Initialization
void _initializeAnimations() {
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3), // Slide up from bottom
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOut),
    );
}

// Event Loading Logic
Future<void> _loadEvents() async {
    final events = await _eventService.streamAllEvents().first;
    setState(() {
        _allEvents = events;
        _filteredEvents = events;
    });
    // Trigger entrance animations
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
}
```

The presented code focuses on the visual polish of the application. By initializing and controlling explicit animation controllers, the app delivers a cinematic entrance effect for event cards. This attention to UI/UX details (micro-interactions) significantly enhances the perceived quality of the application for student users.

---

### 5.2.8 Achievements Portfolio

**[INSERT SCREENSHOT HERE]**

**FIGURE 5.2.8: Achievements Management Screen**

Figure 5.2.8 shows the "Achievements Portfolio" screen, allowing students to verify and showcase their accomplishments (academic, co-curricular, leadership). It features a toggleable Grid/List view and a comprehensive "Add Achievement" modal that handles form inputs, date selection, and file uploads (Certificate/Image) to the cloud storage.

**Code Snippet:**

```dart
Future<void> _saveAchievement() async {
    if (!_formKey.currentState!.validate()) return;

    // Secure File Uploads
    if (_selectedCertificate != null) {
        certificateUrl = await achievementService.uploadCertificate(
            _currentUser!.id, _selectedCertificate!
        );
    }

    final achievement = AchievementModel(
        userId: _currentUser!.id,
        title: _titleController.text,
        type: _selectedType, // e.g., Academic, Leadership
        points: achievementService.getDefaultPoints(_selectedType),
        isVerified: false, // Default to pending verification
        // ... metadata
    );

    // Save to Database
    await achievementService.createAchievement(achievement);
}
```

This code snippet illustrates the end-to-end process of adding a new achievement. It handles secure file uploads for proof of achievement (certificates), automatically assigns "Talent Points" based on the achievement type, and sets the initial verification status to "Pending." This workflow is crucial for the "Talent Profiling" aspect, building a verified repository of student successes.

### 5.2.9 Supabase Authentication Service

**Purpose:** This core service module handles all user authentication lifecycle, including sign-in, registration, session management, and profile completion tracking.

**Code Snippet:**

```dart
// Session & Auth State Management
Future<void> initialize() async {
    final session = SupabaseConfig.auth.currentSession;
    if (session != null && !session.isExpired) {
        await _loadUserProfile(session.user.id);
    }

    // Listen to auth state changes
    SupabaseConfig.auth.onAuthStateChange.listen((data) {
        switch (data.event) {
            case AuthChangeEvent.signedIn:
                _loadUserProfile(data.session!.user.id);
                break;
            case AuthChangeEvent.signedOut:
                _currentUser = null;
                break;
            // ... other events
        }
    });
}

// Profile Completion Check
Future<bool> hasCompletedProfile(String userId) async {
    final response = await SupabaseConfig.client
        .from('profiles')
        .select('is_profile_complete')
        .eq('user_id', userId)
        .single();
    return response['is_profile_complete'] ?? false;
}
```

The authentication service acts as a singleton provider for authentication state across the app. It listens to Supabase authentication events to automatically load user profiles on sign-in and clear data on sign-out. The profile completion check is critical for the onboarding flow, ensuring new users are directed to complete their talent profile before accessing the main application.

---

### 5.2.10 Gemini AI Chat Service (Streaming)

**Purpose:** This service integrates with Google's Gemini Pro API to provide streaming AI responses, RAG context injection, and conversation memory management.

**Code Snippet:**

```dart
// Streaming Response with RAG Context
Stream<String> sendMessageStreaming({
    required String conversationId,
    required String content,
    String? ragContext, // Injected FSKTM knowledge
}) async* {
    // Build request with RAG context in system prompt
    final requestBody = await _buildGeminiRequest(content, history, ragContext);

    // Use SSE (Server-Sent Events) endpoint for streaming
    final request = http.Request('POST',
        Uri.parse('$_baseUrl/models/gemini-2.5-flash:streamGenerateContent?alt=sse&key=$_apiKey'));
    request.body = jsonEncode(requestBody);

    final streamedResponse = await client.send(request);
    final fullContent = StringBuffer();

    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        final text = _extractTextFromStreamChunk(chunk);
        if (text.isNotEmpty) {
            fullContent.write(text);
            yield fullContent.toString(); // Emit partial response to UI
        }
    }
}
```

The AI chat service implements real-time streaming using SSE (Server-Sent Events). As chunks of the AI response arrive, they are immediately yielded to the UI, creating a "typing" effect. The service also injects RAG context from the FSKTM knowledge base directly into the system prompt, enabling the AI to answer domain-specific questions accurately. Response caching is implemented for frequently asked questions to improve performance.

---

### 5.2.11 FSKTM RAG Data Service (Knowledge Base)

**Purpose:** This service implements a local Retrieval-Augmented Generation (RAG) system, loading FSKTM-specific data from JSON files and providing smart query expansion and chunk-based retrieval.

**Code Snippet:**

```dart
// Synonym Dictionary for Query Expansion (BM <-> EN)
static const Map<String, List<String>> _synonymDictionary = {
    'pensyarah': ['lecturer', 'pengajar'],
    'lecturer': ['pensyarah', 'pengajar'],
    'jabatan': ['department', 'dept'],
    // ... more synonyms
};

/// Get relevant chunks based on query with scoring
static Future<List<DocumentChunk>> getRelevantChunks(String query) async {
    final chunks = await _createChunks();
    final expandedQuery = expandQueryWithSynonyms(query.toLowerCase());

    for (final chunk in chunks) {
        double score = 0.0;
        // Keyword and fuzzy matching logic
        for (final keyword in chunk.keywords) {
            if (expandedQuery.contains(keyword)) score += 1.0;
            // Fuzzy match with Levenshtein distance
            if (_fuzzyMatchScore(queryWord, keyword) >= 0.7) {
                score += 0.5;
            }
        }
        // Add scored chunks to results
    }
    // Sort by relevance score
    return topScoredChunks;
}
```

The RAG data service is a sophisticated local implementation. It loads staff, programs, and faculty data from bundled JSON files. Key features include: 1) **Query Expansion** using a bilingual synonym dictionary (Malay <-> English), 2) **Document Chunking** for granular retrieval, and 3) **Fuzzy Matching** via Levenshtein distance to handle typos. This allows the AI advisor to accurately answer questions like "siapa pensyarah keselamatan?" even when phrased in Malay or with slight misspellings.

---

### 5.2.12 ToyyibPay Payment Service

**Purpose:** This service integrates with ToyyibPay, a Malaysian FPX payment gateway, to handle event registration fees.

**Code Snippet:**

```dart
Future<String?> createBill({
    required String billName,
    required double billAmount,
    required String userEmail,
    required String userName,
}) async {
    final requestBody = {
        'userSecretKey': ToyyibPayConfig.userSecretKey,
        'categoryCode': ToyyibPayConfig.categoryCode,
        'billName': billName.substring(0, 30), // API limit
        'billAmount': (billAmount * 100).toStringAsFixed(0), // In cents
        'billTo': userName,
        'billEmail': userEmail,
        'billPaymentChannel': '0', // 0 = FPX
    };

    final response = await http.post(
        Uri.parse(ToyyibPayConfig.createBill),
        body: requestBody,
    );

    if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data[0]['BillCode']; // Returns Bill ID for payment URL
    }
    return null;
}

String getPaymentUrl(String billCode) => '${ToyyibPayConfig.baseUrl}/$billCode';
```

The payment service provides a simple interface for creating payment bills. When a student registers for a paid event, this service generates a unique bill code via the ToyyibPay API. The returned code is then used to construct a payment URL, which is loaded in a WebView for the user to complete the FPX transaction. The amount is converted to cents as required by the API.

---

### 5.2.13 Media Upload Manager (Cloudinary Integration)

**Purpose:** This module handles the complex workflow of validating, compressing, and uploading media files (images/videos) to the Cloudinary CDN. It supports multi-file uploads, progress tracking via streams, and "XFile" compatibility for cross-platform support.

**Code Snippet:**

```dart
Future<PostCreationResult> uploadPostWithXFiles({
    required String sessionId,
    List<XFile> mediaFiles = const [],
    // ... params
}) async {
    // Initialize upload state stream
    _updateUploadState(sessionId, PostCreationState(isUploading: true, uploadProgress: 0.0));

    try {
        for (int i = 0; i < mediaFiles.length; i++) {
            // Smart Media Handling
            final xFile = mediaFiles[i];
            final bytes = await xFile.readAsBytes();
            
            // Direct Byte Upload to Cloudinary
            final uploadedUrl = await _uploadImageBytes(
                bytes: bytes, 
                filename: xFile.name,
                userId: userId
            );
            
            uploadedUrls.add(uploadedUrl);
            
            // Update granular progress
            _updateUploadState(sessionId, currentState.copyWith(
                uploadProgress: (i + 1) / mediaFiles.length * 0.8
            ));
        }
        // Create post with secured URLs...
    } catch (e) {
        // Handle errors...
    }
}
```

The media upload manager is robustly designed to handle large media files. It integrates directly with the Cloudinary API using raw byte uploads, bypassing the need for temporary local storage which improves performance on low-end devices. The singleton architecture ensures upload states can be tracked globally across the app, allowing users to navigate away while uploads continue in the background.

---

### 5.2.14 Notification Management Service

**Purpose:** This service manages the entire lifecycle of system notifications, including local storage, real-time syncing, and user preference filtering.

**Code Snippet:**

```dart
// Centralized Notification Creation
Future<void> createNotification({
    required String title,
    required NotificationType type,
    // ... params
}) async {
    // 1. Check User Preferences
    if (!_preferencesService.isTypeEnabled(type)) return;

    // 2. Local Storage (Inbox Style)
    _notifications.insert(0, notification);
    if (_notifications.length > _maxStoredNotifications) {
        _notifications.removeLast(); // Maintain fixed size
    }

    // 3. Persist to Cloud (Supabase)
    if (userId != null) {
        await SupabaseConfig.from('notifications').insert({
            'userId': userId,
            'title': title,
            'type': type.toString(),
            'isRead': false,
            // ...
        });
    }
    
    _notifyListeners();
}
```

The notification service implements a dual-layer storage strategy. Notifications are instantly stored locally for immediate UI updates, while simultaneously being synced to Supabase for persistence across devices. It also respects user privacy settings before generating alerts, ensuring a respectful user experience.

---

*End of Section 5.2 - Mobile Application Implementation*
