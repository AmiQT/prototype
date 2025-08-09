# Search Module Documentation

## Overview

The Search Module provides LinkedIn-like functionality for discovering and viewing user profiles within the Student Talent Profiling application. Users can search for students and lecturers, apply filters, view detailed profiles, and maintain search history.

## Architecture

### Core Components

1. **SearchService** (`mobile_app/lib/services/search_service.dart`)
   - Handles all search operations with Firebase integration
   - Implements real-time search with relevance scoring
   - Manages search history and filter options
   - Provides caching and performance optimizations

2. **Search Models** (`mobile_app/lib/models/search_models.dart`)
   - `SearchResult`: Combines user and profile data with relevance scoring
   - `SearchFilter`: Manages filter categories and selections
   - `SearchHistoryItem`: Stores search history with metadata
   - `SearchSuggestion`: Provides search suggestions and autocomplete

3. **Search UI Components** (`mobile_app/lib/widgets/search_widgets.dart`)
   - `SearchBarWidget`: Real-time search with history and suggestions
   - `FilterChipsWidget`: Active filter display and management
   - `UserResultCard`: LinkedIn-style user result cards
   - `SearchEmptyState`: Empty state handling

4. **Enhanced Search Screen** (`mobile_app/lib/screens/student/search/enhanced_search_screen.dart`)
   - Main search interface with filters and results
   - Real-time search with debouncing
   - Filter bottom sheet for advanced filtering

5. **Profile View Screen** (`mobile_app/lib/screens/shared/profile_view_screen.dart`)
   - Read-only profile viewing for other users
   - LinkedIn-style profile layout
   - Profile completeness indicators

## Features Implemented

### ✅ **Core Search Functionality**
- **Real-time Search**: Search-as-you-type with 300ms debouncing
- **Relevance Scoring**: Advanced algorithm considering multiple factors:
  - Name matches (highest priority)
  - Skills and interests matches
  - Department and program matches
  - Bio and headline matches
  - Profile completeness bonus
- **Multi-field Search**: Searches across name, bio, skills, department, etc.

### ✅ **Advanced Filtering**
- **Role Filter**: Student, Lecturer (Admin excluded as requested)
- **Department Filter**: Dynamic list from user data
- **Skills Filter**: Top 20 most common skills
- **Semester Filter**: Academic semester levels
- **Program Filter**: Academic programs
- **Multi-select**: Multiple filters can be applied simultaneously

### ✅ **Search History & Suggestions**
- **Persistent History**: Stored locally using SharedPreferences
- **Recent Searches**: Quick access to previous searches
- **Search Metadata**: Result count and applied filters stored
- **History Management**: Automatic cleanup of old entries

### ✅ **LinkedIn-like User Interface**
- **User Result Cards**: Profile picture, name, role, bio, skills preview
- **Profile Completeness**: Circular progress indicator
- **Role Badges**: Color-coded role indicators
- **Skills Preview**: Top 3 skills shown in results
- **Professional Layout**: Clean, modern design

### ✅ **Profile Viewing**
- **Read-only Profiles**: View other users' complete profiles
- **Comprehensive Display**: All profile sections (academic, skills, experience, projects, achievements)
- **Profile Completeness**: Visual indicator of profile completion
- **Contact Information**: Email and department display
- **Future-ready**: Messaging placeholder for future features

### ✅ **Performance Optimizations**
- **Debounced Search**: Prevents excessive API calls
- **Efficient Queries**: Optimized Firebase queries
- **Local Caching**: Search history and filters cached locally
- **Lazy Loading**: Results loaded on demand

## Technical Implementation

### Search Algorithm
```dart
// Relevance scoring factors:
- Name exact match: +20 points
- Name contains: +10 points
- Skills match: +3 points per skill
- Bio/headline match: +5 points
- Department match: +4 points
- Student ID match: +6 points
- Experience/project match: +2 points
- Profile completeness bonus: +0.1 per % complete
```

### Filter System
```dart
// Filter categories with dynamic options:
- Role: [Student, Lecturer]
- Department: Dynamic from user data
- Skills: Top 20 most common
- Semester: 1-8 (dynamic from profiles)
- Program: Dynamic from academic info
```

### Data Flow
1. User types in search bar
2. 300ms debounce timer triggers
3. SearchService queries Firebase users collection
4. For each user, fetch corresponding profile
5. Calculate relevance score and apply filters
6. Sort results by relevance
7. Display in UserResultCard components
8. Save search to history

## Integration Points

### Navigation Integration
- **Student Dashboard**: Enhanced search replaces basic search
- **Bottom Navigation**: Search tab uses EnhancedSearchScreen
- **Profile Navigation**: Results link to ProfileViewScreen

### Data Integration
- **UserModel**: Basic user information and role
- **ProfileModel**: Detailed profile data for search
- **Firebase Collections**: 'users' and 'profiles' collections
- **AuthService**: Current user context and permissions

## User Experience Features

### Search Experience
- **Instant Feedback**: Real-time search results
- **Smart Suggestions**: Search history-based suggestions
- **Filter Persistence**: Filters maintained during session
- **Clear Actions**: Easy filter clearing and search reset

### Profile Discovery
- **Rich Previews**: Comprehensive user cards
- **Quick Actions**: Direct profile navigation
- **Visual Indicators**: Role, completeness, activity status
- **Professional Layout**: LinkedIn-inspired design

### Error Handling
- **Network Errors**: Graceful error messages
- **Empty States**: Helpful empty state screens
- **Loading States**: Clear loading indicators
- **Retry Options**: User-friendly error recovery

## Future Enhancements (KIP)

### Planned Features
1. **Advanced Search**
   - Boolean search operators
   - Saved search queries
   - Search alerts and notifications

2. **Social Features**
   - Connection requests
   - Messaging system
   - Profile views tracking

3. **Analytics**
   - Search analytics dashboard
   - Popular search terms
   - User discovery patterns

4. **Performance**
   - Elasticsearch integration
   - Advanced caching strategies
   - Offline search capabilities

5. **AI Features**
   - Smart search suggestions
   - Profile recommendations
   - Skill-based matching

## Testing Strategy

### Unit Tests
- SearchService methods
- Relevance scoring algorithm
- Filter logic
- Search history management

### Widget Tests
- Search bar functionality
- Filter components
- User result cards
- Empty states

### Integration Tests
- End-to-end search flow
- Profile navigation
- Filter application
- Search history persistence

## Performance Metrics

### Target Performance
- **Search Response**: < 500ms for typical queries
- **Filter Application**: < 200ms
- **Profile Loading**: < 1s
- **History Access**: < 100ms

### Optimization Strategies
- Firebase query optimization
- Local caching implementation
- Debounced search requests
- Efficient state management

## Security Considerations

### Data Privacy
- **Profile Visibility**: All profiles public (as requested)
- **Search Logging**: Local history only
- **Data Access**: Role-based filtering (no admin profiles)

### Performance Security
- **Query Limits**: Reasonable result limits
- **Rate Limiting**: Debounced requests
- **Input Validation**: Search query sanitization

## Conclusion

The Search Module provides a comprehensive, LinkedIn-like search experience that enables users to discover and connect with other students and lecturers. The implementation focuses on performance, user experience, and scalability while maintaining clean architecture and code quality.

The module is designed to support future enhancements including social features, advanced analytics, and AI-powered recommendations, making it a solid foundation for the application's networking capabilities.
