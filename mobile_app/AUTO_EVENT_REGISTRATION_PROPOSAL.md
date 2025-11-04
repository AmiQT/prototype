# 🚀 AUTO EVENT REGISTRATION SYSTEM - PROPOSAL & IMPLEMENTATION

**Date**: 3 November 2025  
**Feature**: Automatic Event Registration with Profile Data Pre-fill  
**Status**: 📋 Proposal & Implementation Guide

---

## 🎯 OBJECTIVE

**User Request**: 
> "Macam mana kalau user nak register event direct dalam app? Boleh tak kita allow system auto fetch data based on profile dan register dalam app tanpa user isi form semula?"

**Goal**: Enable **1-click event registration** dengan data diambil automatically dari user profile.

---

## 📊 CURRENT STATE ANALYSIS

### ✅ What We Already Have

#### 1. **Database Structure** (READY!)
```sql
-- event_participations table ALREADY EXISTS ✅
CREATE TABLE event_participations (
    id UUID PRIMARY KEY,
    event_id UUID REFERENCES events(id),
    user_id UUID REFERENCES users(id),
    registration_date TIMESTAMP,
    attendance_status VARCHAR,      -- "registered", "attended", "no_show"
    feedback_rating INTEGER,         -- 1-5 rating
    feedback_comment TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

#### 2. **User Profile Data** (COMPREHENSIVE!)
Profile contains ALL information we need:
```dart
class ProfileModel {
  // Basic Info
  String fullName;           ✅ Name
  String? phoneNumber;       ✅ Phone
  String? address;           ✅ Address
  String? bio;               ✅ Bio
  
  // Academic Info
  AcademicInfoModel? academicInfo {
    String studentId;        ✅ Student ID/Matrix Number
    String program;          ✅ Program of study
    String department;       ✅ Department
    String faculty;          ✅ Faculty
    int currentSemester;     ✅ Semester
    double? cgpa;            ✅ CGPA
  }
  
  // Skills & Experience
  List<String> skills;       ✅ Technical skills
  List<String> interests;    ✅ Interests
  List<ExperienceModel> experiences;  ✅ Past experience
  List<ProjectModel> projects;        ✅ Projects
}
```

#### 3. **Current Registration Flow** (BASIC)
```dart
// Current implementation in ModernEventDetailScreen
Future<void> _registerForEvent() async {
  if (widget.event.registerUrl.isEmpty) {
    // Show "not available" message
    return;
  }
  
  // Opens external URL
  await launchUrl(url, mode: LaunchMode.externalApplication);
}
```

**Issue**: Opens external link, no in-app tracking, no profile integration! ❌

---

## 💡 PROPOSED SOLUTION

### Architecture: 3-Layer Auto-Registration System

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INTERFACE                            │
│                                                                  │
│  Event Detail Screen                                            │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  [Register Now] ← 1-Click Button                       │    │
│  │                                                         │    │
│  │  Shows:                                                 │    │
│  │  ✓ Your info will be auto-filled from profile         │    │
│  │  ✓ Registration confirmation                           │    │
│  │  ✓ Success animation                                   │    │
│  └────────────────────────────────────────────────────────┘    │
│                             ↓                                   │
│  Confirmation Dialog (Optional)                                │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Review your details:                                   │    │
│  │  • Name: Ahmad bin Ali                                 │    │
│  │  • Student ID: B12345                                  │    │
│  │  • Phone: 012-345-6789                                 │    │
│  │  • Program: Software Engineering                       │    │
│  │                                                         │    │
│  │  [Confirm Registration] [Cancel]                       │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                     SERVICE LAYER                                │
│                                                                  │
│  EventService.registerForEvent()                                │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  1. Fetch Current User Profile                         │    │
│  │  2. Extract Required Data                              │    │
│  │  3. Check Event Capacity                               │    │
│  │  4. Check Already Registered                           │    │
│  │  5. Create Registration Record                         │    │
│  │  6. Send Notification                                  │    │
│  │  7. Update UI                                          │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                      DATABASE                                    │
│                                                                  │
│  INSERT INTO event_participations                               │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  id: uuid                                              │    │
│  │  event_id: event_id                                    │    │
│  │  user_id: current_user_id                              │    │
│  │  registration_date: NOW()                              │    │
│  │  attendance_status: 'registered'                       │    │
│  │  participant_data: {                                   │    │
│  │    fullName, studentId, phone,                        │    │
│  │    program, department, skills                         │    │
│  │  }                                                      │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔧 IMPLEMENTATION

### Step 1: Update EventModel

Add fields untuk support registration tracking:

```dart
// lib/models/event_model.dart
class EventModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final List<String> favoriteUserIds;
  final String registerUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // NEW FIELDS for registration
  final DateTime? eventDate;              // ← ADD
  final String? location;                 // ← ADD
  final String? venue;                    // ← ADD
  final int? maxParticipants;             // ← ADD
  final int? currentParticipants;         // ← ADD
  final DateTime? registrationDeadline;   // ← ADD
  final bool? registrationOpen;           // ← ADD
  final List<String>? requirements;       // ← ADD (what students need)
  final List<String>? skillsGained;       // ← ADD (what they'll learn)
  final List<String>? targetAudience;     // ← ADD (who should attend)

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.favoriteUserIds,
    required this.registerUrl,
    required this.createdAt,
    required this.updatedAt,
    // New parameters
    this.eventDate,
    this.location,
    this.venue,
    this.maxParticipants,
    this.currentParticipants,
    this.registrationDeadline,
    this.registrationOpen,
    this.requirements,
    this.skillsGained,
    this.targetAudience,
  });

  // Helper methods
  bool get canRegister {
    if (registrationOpen == false) return false;
    if (registrationDeadline != null && 
        DateTime.now().isAfter(registrationDeadline!)) return false;
    if (maxParticipants != null && currentParticipants != null &&
        currentParticipants! >= maxParticipants!) return false;
    return true;
  }
  
  int get spotsLeft {
    if (maxParticipants == null || currentParticipants == null) return -1;
    return maxParticipants! - currentParticipants!;
  }
}
```

### Step 2: Create EventRegistrationModel

Model untuk store registration data:

```dart
// lib/models/event_registration_model.dart
class EventRegistrationModel {
  final String id;
  final String eventId;
  final String userId;
  final DateTime registrationDate;
  final String attendanceStatus; // "registered", "attended", "no_show"
  
  // Auto-filled from profile
  final String fullName;
  final String studentId;
  final String? phone;
  final String? email;
  final String program;
  final String department;
  final String faculty;
  final List<String> relevantSkills;
  
  // Optional feedback (after event)
  final int? feedbackRating;      // 1-5 stars
  final String? feedbackComment;
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  EventRegistrationModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.registrationDate,
    required this.attendanceStatus,
    required this.fullName,
    required this.studentId,
    this.phone,
    this.email,
    required this.program,
    required this.department,
    required this.faculty,
    this.relevantSkills = const [],
    this.feedbackRating,
    this.feedbackComment,
    required this.createdAt,
    this.updatedAt,
  });

  factory EventRegistrationModel.fromJson(Map<String, dynamic> json) {
    return EventRegistrationModel(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? '',
      userId: json['user_id'] ?? '',
      registrationDate: json['registration_date'] != null
          ? DateTime.parse(json['registration_date'])
          : DateTime.now(),
      attendanceStatus: json['attendance_status'] ?? 'registered',
      fullName: json['full_name'] ?? '',
      studentId: json['student_id'] ?? '',
      phone: json['phone'],
      email: json['email'],
      program: json['program'] ?? '',
      department: json['department'] ?? '',
      faculty: json['faculty'] ?? '',
      relevantSkills: List<String>.from(json['relevant_skills'] ?? []),
      feedbackRating: json['feedback_rating'],
      feedbackComment: json['feedback_comment'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'registration_date': registrationDate.toIso8601String(),
      'attendance_status': attendanceStatus,
      'full_name': fullName,
      'student_id': studentId,
      'phone': phone,
      'email': email,
      'program': program,
      'department': department,
      'faculty': faculty,
      'relevant_skills': relevantSkills,
      'feedback_rating': feedbackRating,
      'feedback_comment': feedbackComment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
```

### Step 3: Enhance EventService

Add registration methods:

```dart
// lib/services/event_service.dart
class EventService {
  // ... existing code ...

  /// Register current user for an event (AUTO-FILL from profile)
  Future<EventRegistrationModel> registerForEvent({
    required String eventId,
    required String userId,
    required ProfileModel userProfile,
  }) async {
    try {
      debugPrint('EventService: Registering user $userId for event $eventId');
      
      // 1. Check if already registered
      final alreadyRegistered = await isRegisteredForEvent(eventId, userId);
      if (alreadyRegistered) {
        throw Exception('You are already registered for this event');
      }
      
      // 2. Get event details
      final event = await getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found');
      }
      
      // 3. Validate registration is open
      if (!event.canRegister) {
        throw Exception('Registration is closed for this event');
      }
      
      // 4. Extract relevant skills based on event requirements
      final relevantSkills = _extractRelevantSkills(
        userProfile.skills,
        event.skillsGained ?? [],
      );
      
      // 5. Create registration record (AUTO-FILLED!)
      final registrationId = 'reg_${DateTime.now().millisecondsSinceEpoch}';
      final registration = EventRegistrationModel(
        id: registrationId,
        eventId: eventId,
        userId: userId,
        registrationDate: DateTime.now(),
        attendanceStatus: 'registered',
        // AUTO-FILLED from profile ✨
        fullName: userProfile.fullName,
        studentId: userProfile.academicInfo?.studentId ?? 
                   userProfile.studentId ?? '',
        phone: userProfile.phoneNumber ?? userProfile.phone,
        email: null, // Get from user model if available
        program: userProfile.academicInfo?.program ?? '',
        department: userProfile.academicInfo?.department ?? 
                    userProfile.department ?? '',
        faculty: userProfile.academicInfo?.faculty ?? 
                 userProfile.faculty ?? '',
        relevantSkills: relevantSkills,
        createdAt: DateTime.now(),
      );
      
      // 6. Save to database
      await _saveRegistrationToDatabase(registration);
      
      // 7. Increment participant count
      await _incrementEventParticipants(eventId);
      
      // 8. Send notification
      await AutoNotificationService.onEventRegistered(
        userId: userId,
        eventTitle: event.title,
        eventId: eventId,
        eventDate: event.eventDate,
      );
      
      debugPrint('EventService: Registration successful!');
      return registration;
      
    } catch (e) {
      debugPrint('❌ Error registering for event: $e');
      throw Exception('Failed to register for event: $e');
    }
  }

  /// Check if user is already registered
  Future<bool> isRegisteredForEvent(String eventId, String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('event_participations')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      debugPrint('EventService: Error checking registration: $e');
      return false;
    }
  }

  /// Get user's registered events
  Future<List<EventModel>> getRegisteredEvents(String userId) async {
    try {
      // Get event IDs user registered for
      final response = await SupabaseConfig.client
          .from('event_participations')
          .select('event_id')
          .eq('user_id', userId)
          .order('registration_date', ascending: false);
      
      final eventIds = response.map((e) => e['event_id'] as String).toList();
      
      if (eventIds.isEmpty) return [];
      
      // Fetch full event details
      final events = <EventModel>[];
      for (final eventId in eventIds) {
        final event = await getEventById(eventId);
        if (event != null) {
          events.add(event);
        }
      }
      
      return events;
    } catch (e) {
      debugPrint('EventService: Error getting registered events: $e');
      return [];
    }
  }

  /// Cancel registration
  Future<void> cancelRegistration(String eventId, String userId) async {
    try {
      // Delete from event_participations
      await SupabaseConfig.client
          .from('event_participations')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
      
      // Decrement participant count
      await _decrementEventParticipants(eventId);
      
      debugPrint('EventService: Registration cancelled');
    } catch (e) {
      debugPrint('EventService: Error cancelling registration: $e');
      throw Exception('Failed to cancel registration');
    }
  }

  // === PRIVATE HELPER METHODS ===

  Future<void> _saveRegistrationToDatabase(
      EventRegistrationModel registration) async {
    try {
      await SupabaseConfig.client
          .from('event_participations')
          .insert({
        'id': registration.id,
        'event_id': registration.eventId,
        'user_id': registration.userId,
        'registration_date': registration.registrationDate.toIso8601String(),
        'attendance_status': registration.attendanceStatus,
        'created_at': registration.createdAt.toIso8601String(),
        // Store participant data as JSONB
        'participant_data': {
          'full_name': registration.fullName,
          'student_id': registration.studentId,
          'phone': registration.phone,
          'program': registration.program,
          'department': registration.department,
          'faculty': registration.faculty,
          'relevant_skills': registration.relevantSkills,
        },
      });
    } catch (e) {
      debugPrint('EventService: Database save error: $e');
      throw Exception('Failed to save registration to database');
    }
  }

  Future<void> _incrementEventParticipants(String eventId) async {
    try {
      // Increment current_participants count
      await SupabaseConfig.client.rpc('increment_event_participants', 
        params: {'event_id': eventId}
      );
    } catch (e) {
      debugPrint('EventService: Error incrementing participants: $e');
      // Non-critical, don't throw
    }
  }

  Future<void> _decrementEventParticipants(String eventId) async {
    try {
      await SupabaseConfig.client.rpc('decrement_event_participants',
        params: {'event_id': eventId}
      );
    } catch (e) {
      debugPrint('EventService: Error decrementing participants: $e');
    }
  }

  List<String> _extractRelevantSkills(
    List<String> userSkills,
    List<String> eventSkills,
  ) {
    // Find matching skills between user and event
    final relevant = <String>[];
    for (final skill in userSkills) {
      if (eventSkills.any((es) => 
        es.toLowerCase().contains(skill.toLowerCase()) ||
        skill.toLowerCase().contains(es.toLowerCase())
      )) {
        relevant.add(skill);
      }
    }
    return relevant;
  }
}
```

### Step 4: Update UI (ModernEventDetailScreen)

Replace simple URL launch with smart registration:

```dart
// lib/screens/student/event_program/modern_event_detail_screen.dart
class _ModernEventDetailScreenState extends State<ModernEventDetailScreen> {
  final EventService _eventService = EventService();
  final ProfileService _profileService = ProfileService();
  
  bool _isRegistered = false;  // ← ADD
  bool _isRegistering = false; // ← ADD
  ProfileModel? _userProfile;  // ← ADD
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    if (_userId == null) return;
    
    try {
      // Check if already registered
      _isRegistered = await _eventService.isRegisteredForEvent(
        widget.event.id,
        _userId!,
      );
      
      // Load user profile for auto-fill
      _userProfile = await _profileService.getProfileByUserId(_userId!);
      
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Widget _buildRegisterButton() {
    // Check if user can register
    if (!widget.event.canRegister) {
      return _buildDisabledButton('Registration Closed');
    }
    
    if (_isRegistered) {
      return _buildRegisteredButton();
    }
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isRegistering ? null : _registerForEvent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
        icon: _isRegistering
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.how_to_reg_rounded, color: Colors.white),
        label: Text(
          _isRegistering ? 'Registering...' : 'Register Now (Auto-fill)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  Widget _buildRegisteredButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.successColor, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppTheme.successColor),
          const SizedBox(width: AppTheme.spaceXs),
          Text(
            'You are registered! ✓',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _registerForEvent() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to register')),
      );
      return;
    }
    
    if (_userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your profile first'),
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmationDialog(),
    );

    if (confirm != true) return;

    setState(() {
      _isRegistering = true;
    });

    try {
      // AUTO-REGISTER with profile data! 🎉
      final registration = await _eventService.registerForEvent(
        eventId: widget.event.id,
        userId: _userId!,
        userProfile: _userProfile!,
      );

      setState(() {
        _isRegistered = true;
        _isRegistering = false;
      });

      if (mounted) {
        // Show success with animation
        _showSuccessAnimation();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Successfully registered! Check your email for details.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRegistering = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildConfirmationDialog() {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          const Text('Confirm Registration'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Register for: ${widget.event.title}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Your details will be auto-filled from your profile:'),
          const SizedBox(height: 12),
          _buildDetailRow('Name', _userProfile!.fullName),
          _buildDetailRow('Student ID', 
            _userProfile!.academicInfo?.studentId ?? 'N/A'),
          _buildDetailRow('Phone', _userProfile!.phoneNumber ?? 'N/A'),
          _buildDetailRow('Program', 
            _userProfile!.academicInfo?.program ?? 'N/A'),
          const SizedBox(height: 16),
          if (widget.event.spotsLeft > 0)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, size: 16, color: AppTheme.warningColor),
                  const SizedBox(width: 8),
                  Text(
                    'Only ${widget.event.spotsLeft} spots left!',
                    style: TextStyle(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: const Text('Confirm Registration'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context);
        });
        
        return Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Icon(
                        Icons.check_circle,
                        color: AppTheme.successColor,
                        size: 80,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Registration Successful!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

---

## 🗄️ DATABASE UPDATES

### Required Changes to `events` table:

```sql
-- Add missing columns for event management
ALTER TABLE events 
  ADD COLUMN IF NOT EXISTS max_participants INTEGER,
  ADD COLUMN IF NOT EXISTS current_participants INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS registration_deadline TIMESTAMP,
  ADD COLUMN IF NOT EXISTS registration_open BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS requirements JSONB,
  ADD COLUMN IF NOT EXISTS skills_gained JSONB,
  ADD COLUMN IF NOT EXISTS target_audience JSONB,
  ADD COLUMN IF NOT EXISTS venue VARCHAR(255);
```

### Create helper functions:

```sql
-- Function to increment participant count
CREATE OR REPLACE FUNCTION increment_event_participants(event_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE events 
  SET current_participants = COALESCE(current_participants, 0) + 1,
      updated_at = NOW()
  WHERE id = event_id;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement participant count
CREATE OR REPLACE FUNCTION decrement_event_participants(event_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE events 
  SET current_participants = GREATEST(COALESCE(current_participants, 0) - 1, 0),
      updated_at = NOW()
  WHERE id = event_id;
END;
$$ LANGUAGE plpgsql;
```

### Update `event_participations` table:

```sql
-- Add participant_data column to store auto-filled info
ALTER TABLE event_participations
  ADD COLUMN IF NOT EXISTS participant_data JSONB;
  
-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_event_participations_user 
  ON event_participations(user_id);
CREATE INDEX IF NOT EXISTS idx_event_participations_event 
  ON event_participations(event_id);
```

---

## 📱 NEW FEATURES UNLOCKED

### 1. **My Registered Events Screen**

```dart
// lib/screens/student/event_program/my_registered_events_screen.dart
class MyRegisteredEventsScreen extends StatefulWidget {
  const MyRegisteredEventsScreen({super.key});

  @override
  State<MyRegisteredEventsScreen> createState() =>
      _MyRegisteredEventsScreenState();
}

class _MyRegisteredEventsScreenState
    extends State<MyRegisteredEventsScreen> {
  final EventService _eventService = EventService();
  List<EventModel> _registeredEvents = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadRegisteredEvents();
  }

  Future<void> _loadRegisteredEvents() async {
    _userId = SupabaseConfig.auth.currentUser?.id;
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final events = await _eventService.getRegisteredEvents(_userId!);
      setState(() {
        _registeredEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading registered events: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Registered Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRegisteredEvents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _registeredEvents.isEmpty
              ? _buildEmptyState()
              : _buildEventList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No registered events yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Browse events and register to see them here',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Browse Events'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _registeredEvents.length,
      itemBuilder: (context, index) {
        final event = _registeredEvents[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(EventModel event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ModernEventDetailScreen(event: event),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppTheme.successColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'REGISTERED',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (event.eventDate != null)
                    Text(
                      _formatDate(event.eventDate!),
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (event.location != null)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      event.location!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelRegistration(event),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Cancel Registration'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelRegistration(EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Registration'),
        content: Text(
          'Are you sure you want to cancel your registration for "${event.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _eventService.cancelRegistration(event.id, _userId!);
      
      setState(() {
        _registeredEvents.removeWhere((e) => e.id == event.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration cancelled successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
```

### 2. **Auto-Notification Service Enhancement**

```dart
// lib/services/auto_notification_service.dart
class AutoNotificationService {
  // ... existing code ...

  /// Create notification when user registers for event
  static Future<void> onEventRegistered({
    required String userId,
    required String eventTitle,
    required String eventId,
    DateTime? eventDate,
  }) async {
    try {
      await _notificationService.createNotification(
        title: 'Event Registration Confirmed! 🎉',
        message:
            'You\'ve successfully registered for "$eventTitle". '
            '${eventDate != null ? "Event date: ${_formatDate(eventDate)}" : "Check your email for details."}',
        type: NotificationType.event,
        userId: userId,
        data: {
          'eventId': eventId,
          'eventTitle': eventTitle,
          'action': 'registered',
          'eventDate': eventDate?.toIso8601String(),
        },
        actionUrl: '/events/$eventId',
      );

      debugPrint('AutoNotificationService: Event registration notification sent');
    } catch (e) {
      debugPrint('AutoNotificationService: Error sending notification: $e');
    }
  }

  /// Reminder notification before event (24 hours before)
  static Future<void> sendEventReminder({
    required String userId,
    required String eventTitle,
    required String eventId,
    required DateTime eventDate,
  }) async {
    try {
      await _notificationService.createNotification(
        title: 'Event Reminder ⏰',
        message:
            'Reminder: "$eventTitle" is tomorrow! Don\'t forget to attend.',
        type: NotificationType.reminder,
        userId: userId,
        data: {
          'eventId': eventId,
          'eventTitle': eventTitle,
          'action': 'reminder',
          'eventDate': eventDate.toIso8601String(),
        },
        actionUrl: '/events/$eventId',
      );
    } catch (e) {
      debugPrint('AutoNotificationService: Error sending reminder: $e');
    }
  }

  static String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
```

---

## 🎨 USER EXPERIENCE FLOW

### Before (Old Way - Manual):
```
1. User taps "Register" button
2. App opens external URL in browser
3. User manually fills form:
   - Name ✍️
   - Student ID ✍️
   - Phone ✍️
   - Email ✍️
   - Program ✍️
   - Department ✍️
4. Submit form
5. Wait for confirmation email
6. No tracking in app ❌
```

### After (New Way - AUTO):
```
1. User taps "Register Now (Auto-fill)" button
2. App shows confirmation dialog with PRE-FILLED data:
   ✓ Name (from profile)
   ✓ Student ID (from profile)
   ✓ Phone (from profile)
   ✓ Program (from profile)
   ✓ Department (from profile)
3. User confirms (1 click)
4. Instant registration ⚡
5. Success animation 🎉
6. Notification sent 📱
7. Event added to "My Registered Events" ✅
8. Can manage/cancel registration in app ✅
```

**Time saved**: ~5 minutes per registration!  
**User experience**: Much better! 🚀

---

## 📊 BENEFITS

### For Students:
✅ **1-Click Registration** - No more forms!  
✅ **Auto-filled Data** - Profile data used automatically  
✅ **Track Registrations** - See all events in one place  
✅ **Cancel Anytime** - Manage registrations in-app  
✅ **Get Reminders** - Notifications before events  
✅ **View History** - Past event attendance  

### For System:
✅ **Data Accuracy** - Profile data is verified  
✅ **Analytics** - Track registration patterns  
✅ **Capacity Management** - Real-time participant counts  
✅ **Skills Matching** - Recommend relevant events  
✅ **Attendance Tracking** - Mark attendance after event  

### For Organizers:
✅ **Real Participants** - Verified student data  
✅ **Export Data** - Get participant list  
✅ **Communication** - Contact registered users  
✅ **Analytics** - See registration stats  

---

## 🚀 IMPLEMENTATION TIMELINE

### Phase 1: Core Features (2-3 days)
- [ ] Update EventModel with new fields
- [ ] Create EventRegistrationModel
- [ ] Add registration methods to EventService
- [ ] Update database schema
- [ ] Update ModernEventDetailScreen UI

### Phase 2: Enhanced Features (2 days)
- [ ] Create My Registered Events screen
- [ ] Add cancel registration feature
- [ ] Implement notifications
- [ ] Add participant count tracking

### Phase 3: Polish & Testing (1-2 days)
- [ ] Add loading animations
- [ ] Implement error handling
- [ ] Test all edge cases
- [ ] Add unit tests

**Total estimated time**: 5-7 days

---

## 🧪 TESTING CHECKLIST

- [ ] Register for event with complete profile
- [ ] Register for event with incomplete profile
- [ ] Try registering twice for same event
- [ ] Try registering when event is full
- [ ] Try registering after deadline
- [ ] Cancel registration
- [ ] View registered events list
- [ ] Verify participant count updates
- [ ] Test notification delivery
- [ ] Test with poor network connection

---

## 🎯 CONCLUSION

**ANSWER to your question**:

> "Macam mana kalau user nak register event direct dalam app?"

✅ **YES, BOLEH!** We can implement **1-click auto-registration**!

> "Boleh tak kita allow system auto fetch data based on profile?"

✅ **YES, SANGAT BOLEH!** System will auto-fill:
- Name
- Student ID
- Phone
- Email
- Program
- Department
- Faculty
- Relevant skills

> "Nak automate flow la senang kata?"

✅ **YES, FULLY AUTOMATED!** User just clicks once, everything else is automatic!

### Key Points:
1. ✅ **Database ready** - `event_participations` table exists
2. ✅ **Profile data comprehensive** - All fields we need
3. ✅ **Easy implementation** - Clear architecture
4. ✅ **Great UX** - Much faster than manual forms
5. ✅ **Full featured** - Registration, cancellation, tracking, notifications

**Recommendation**: **GO FOR IT!** This feature will significantly improve user experience dan very practical untuk students! 🚀

---

**Want me to start implementing? Let me know which phase to begin with!** 💪
