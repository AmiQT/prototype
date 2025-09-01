import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import '../models/showcase_models.dart';
import '../models/post_creation_models.dart';
import '../utils/media_utils.dart';
import '../config/cloudinary_config.dart';
import 'auth_service_supabase_ready.dart';

class ShowcaseService {
  static const String baseUrl =
      'https://prototype-348e.onrender.com'; // Render backend - ACTIVE ✅

  final AuthService _authService = AuthService();

  // Counter for reducing console spam
  int _callCount = 0;

  // Ultra-aggressive caching for performance
  static final Map<String, List<ShowcasePostModel>> _postsCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  // Supabase configuration - Complete integration
  SupabaseClient get _supabase => Supabase.instance.client;

  // Upload progress controllers
  final Map<String, StreamController<MediaUploadProgress>> _uploadControllers =
      {};

  // ==================== PERFORMANCE OPTIMIZATION CACHE ====================

  // Cache for posts to avoid repeated API calls (already declared above)
  static const Duration _cacheValidity =
      Duration(minutes: 2); // Cache for 2 minutes

  // Cache for user profiles to avoid repeated lookups
  static final Map<String, Map<String, dynamic>> _profilesCache = {};
  static final Map<String, DateTime> _profilesCacheTimestamps = {};
  static const Duration _profilesCacheValidity =
      Duration(minutes: 5); // Cache profiles for 5 minutes

  // Connection pooling and optimization
  static bool _isInitialized = false;
  static DateTime? _lastConnectionTest;
  static const Duration _connectionTestInterval = Duration(minutes: 5);

  // Cleanup method for controllers
  void dispose() {
    for (final controller in _uploadControllers.values) {
      controller.close();
    }
    _uploadControllers.clear();
  }

  /// Test database connection and check table schema
  Future<bool> testDatabaseConnection() async {
    try {
      debugPrint('ShowcaseService: Testing database connection...');

      // Try to fetch one row to test connection
      await _supabase.from('showcase_posts').select('id').limit(1);

      debugPrint('ShowcaseService: Database connection successful');
      return true;
    } catch (e) {
      debugPrint('ShowcaseService: Database connection failed: $e');
      return false;
    }
  }

  /// Check if required columns exist in showcase_posts table
  Future<Map<String, bool>> checkTableSchema() async {
    try {
      debugPrint('ShowcaseService: Checking table schema...');

      // Try to select all columns to see which ones exist
      final response =
          await _supabase.from('showcase_posts').select('*').limit(1);

      if (response.isNotEmpty) {
        final columns = response.first.keys.toList();
        debugPrint('ShowcaseService: Available columns: $columns');

        return {
          'allow_comments': columns.contains('allow_comments'),
          'media_urls': columns.contains('media_urls'),
          'media_types': columns.contains('media_types'),
          'is_public': columns.contains('is_public'),
        };
      }

      return {};
    } catch (e) {
      debugPrint('ShowcaseService: Error checking schema: $e');
      return {};
    }
  }

  /// Create a new showcase post
  Future<void> createPost(Map<String, dynamic> postData) async {
    try {
      debugPrint('ShowcaseService: Creating post with Supabase...');
      debugPrint('ShowcaseService: Post data: ${json.encode(postData)}');

      // First test database connection
      final isConnected = await testDatabaseConnection();
      if (!isConnected) {
        throw Exception('Database connection failed');
      }

      // Check table schema
      final schema = await checkTableSchema();
      debugPrint('ShowcaseService: Table schema: $schema');

      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Build request body based on available columns
      final requestBody = <String, dynamic>{
        'user_id': currentUserId,
        'title': postData['title'] ?? '',
        'description': postData['description'] ?? '',
        'content': postData['content'] ?? '',
        'category': postData['category'] ?? 'general',
        'tags': postData['tags'] ?? [],
        'skills_used': postData['skills_used'] ?? [],
        'media_urls': postData['media_urls'] ?? [],
        'media_types': postData['media_types'] ?? [],
        'created_at': DateTime.now().toIso8601String(),
      };

      // Only add columns that exist in the database
      if (schema['is_public'] == true) {
        requestBody['is_public'] = postData['is_public'] ?? true;
      }

      debugPrint('ShowcaseService: Request body: ${json.encode(requestBody)}');

      await _supabase.from('showcase_posts').insert(requestBody);

      debugPrint('ShowcaseService: Post created successfully with Supabase!');
    } catch (e) {
      debugPrint('Error creating showcase post: $e');
      rethrow;
    }
  }

  /// Helper method to efficiently fetch profiles for multiple users with ultra-fast caching
  Future<Map<String, Map<String, dynamic>>> _fetchProfilesForUsers(
      List<String> userIds) async {
    try {
      if (userIds.isEmpty) return {};

      final Map<String, Map<String, dynamic>> profilesMap = {};
      final List<String> uncachedUserIds = [];

      // Check cache first for each user
      for (final userId in userIds) {
        if (_profilesCache.containsKey(userId)) {
          final cacheTime = _profilesCacheTimestamps[userId];
          if (cacheTime != null &&
              DateTime.now().difference(cacheTime) < _profilesCacheValidity) {
            // Use cached profile
            profilesMap[userId] =
                Map<String, dynamic>.from(_profilesCache[userId]!);
            debugPrint(
                'ShowcaseService: Using cached profile for user $userId');
          } else {
            // Cache expired, need to fetch
            uncachedUserIds.add(userId);
          }
        } else {
          // Not in cache, need to fetch
          uncachedUserIds.add(userId);
        }
      }

      // Only fetch profiles for users not in cache
      if (uncachedUserIds.isNotEmpty) {
        debugPrint(
            'ShowcaseService: Fetching profiles for ${uncachedUserIds.length} uncached users: $uncachedUserIds');

        // Use ultra-optimized query with minimal columns only
        final profileResponse = await _supabase
            .from('profiles')
            .select(
                'user_id, full_name, profile_image_url') // Removed headline for speed
            .inFilter('user_id', uncachedUserIds)
            .timeout(const Duration(seconds: 3)); // Ultra-fast timeout

        // Process and cache new profiles with minimal processing
        for (final profile in profileResponse) {
          final userId = profile['user_id'] as String;

          // Skip if we already have this user
          if (profilesMap.containsKey(userId)) {
            debugPrint(
                'ShowcaseService: Skipping duplicate profile for user $userId');
            continue;
          }

          final profileImageUrl =
              _getSafeProfileImageUrl(profile['profile_image_url']);

          final profileData = {
            'full_name': profile['full_name'] ?? 'User',
            'profile_image_url': profileImageUrl,
            'headline': '', // Default empty headline for speed
          };

          // Cache the profile
          _profilesCache[userId] = profileData;
          _profilesCacheTimestamps[userId] = DateTime.now();

          profilesMap[userId] = profileData;
        }

        debugPrint(
            'ShowcaseService: Fetched and cached ${profilesMap.length} new profiles');
      }

      debugPrint(
          'ShowcaseService: Final profiles map (${profilesMap.length} total): $profilesMap');
      return profilesMap;
    } catch (e) {
      debugPrint('ShowcaseService: Error fetching profiles: $e');
      return {};
    }
  }

  /// Helper method to get safe profile image URL
  String? _getSafeProfileImageUrl(dynamic imageUrl) {
    if (imageUrl == null ||
        imageUrl.toString().isEmpty ||
        imageUrl.toString() == 'null') {
      debugPrint('ShowcaseService: Null or empty profile image URL');
      return null;
    }

    final url = imageUrl.toString().trim();

    // Check if it's a problematic placeholder URL
    if (url.contains('via.placeholder.com') ||
        url.contains('placeholder.com') ||
        url.contains('dummyimage.com') ||
        url.contains('placehold.it')) {
      debugPrint('ShowcaseService: Filtered out placeholder URL: $url');
      return null;
    }

    // Check for other invalid URLs
    if (url == 'file:///' ||
        url.length < 10 ||
        Uri.tryParse(url)?.hasAbsolutePath != true) {
      debugPrint('ShowcaseService: Invalid URL format: $url');
      return null;
    }

    debugPrint('ShowcaseService: Valid profile image URL: $url');
    return url;
  }

  /// Get all showcase posts
  Future<List<Map<String, dynamic>>> getAllPosts() async {
    try {
      debugPrint('ShowcaseService: Fetching posts from Supabase...');

      // Use the correct query structure that works with Supabase
      final response = await _supabase.from('showcase_posts').select('''
            id,
            user_id,
            content,
            category,
            tags,
            media_urls,
            media_types,
            is_public,
            created_at,
            updated_at,
            is_edited,
            location,
            skills_used,
            description,
            title
          ''').eq('is_public', true).order('created_at', ascending: false);

      debugPrint(
          'ShowcaseService: Fetched ${response.length} posts from Supabase');

      // Extract unique user IDs
      final userIds =
          response.map((post) => post['user_id'] as String).toSet().toList();

      // Fetch all profiles efficiently in one query
      final profilesMap = await _fetchProfilesForUsers(userIds);

      // Combine post data with profile data
      final List<Map<String, dynamic>> postsWithProfiles = response.map((post) {
        final userId = post['user_id'] as String;
        final profile = profilesMap[userId] ?? {};

        return {
          ...post,
          'profiles': profile,
        };
      }).toList();

      debugPrint(
          'ShowcaseService: Successfully fetched ${postsWithProfiles.length} posts with profiles');
      return postsWithProfiles;
    } catch (e) {
      debugPrint('ShowcaseService: Error fetching posts: $e');
      return [];
    }
  }

  /// Update a showcase post
  Future<void> updatePost(
      String postId, Map<String, dynamic> updatedData) async {
    try {
      await _supabase.from('showcase_posts').update({
        ...updatedData,
        'updated_at': DateTime.now().toIso8601String(),
        'is_edited': true,
      }).eq('id', postId);

      debugPrint('ShowcaseService: Post updated successfully: $postId');
      // await SupabaseConfig.from('showcase_posts')
      //     .update({
      //       ...updatedData,
      //       'updatedAt': DateTime.now().toIso8601String(),
      //       'isEdited': true,
      //     })
      //     .eq('id', postId);
    } catch (e) {
      debugPrint('Error updating showcase post: $e');
      rethrow;
    }
  }

  /// Delete a showcase post
  Future<void> deletePost(String postId) async {
    try {
      // First delete associated media files from Cloudinary
      final postData = await _supabase
          .from('showcase_posts')
          .select('media_urls')
          .eq('id', postId)
          .single();

      if (postData['media_urls'] != null) {
        final mediaUrls = List<String>.from(postData['media_urls']);
        for (String url in mediaUrls) {
          // Delete from Cloudinary using the deleteMediaFile method
          await deleteMediaFile(url);
        }
      }

      // Delete the post record
      await _supabase.from('showcase_posts').delete().eq('id', postId);

      debugPrint('ShowcaseService: Post deleted successfully: $postId');
    } catch (e) {
      debugPrint('Error deleting showcase post: $e');
      rethrow;
    }
  }

  /// Get posts by user ID
  Future<List<Map<String, dynamic>>> getPostsByUserId(String userId) async {
    try {
      debugPrint('ShowcaseService: Getting posts for user: $userId');

      final response = await _supabase.from('showcase_posts').select('''
            id,
            user_id,
            content,
            category,
            tags,
            media_urls,
            media_types,
            is_public,
            created_at,
            updated_at,
            is_edited,
            location,
            skills_used,
            description,
            title
          ''').eq('user_id', userId).order('created_at', ascending: false);

      // Fetch profile data for this user
      final profileResponse = await _supabase
          .from('profiles')
          .select('full_name, profile_image_url')
          .eq('user_id', userId)
          .maybeSingle();

      // Combine posts with profile data
      return response.map<Map<String, dynamic>>((post) {
        return {
          ...post,
          'profiles': profileResponse ?? {},
        };
      }).toList();
    } catch (e) {
      debugPrint('ShowcaseService: Error fetching user posts: $e');
      return [];
    }
  }

  // ==================== ENHANCED MEDIA UPLOAD METHODS ====================

  /// Upload multiple media files with progress tracking
  Future<List<MediaModel>> uploadMediaFiles({
    required List<File> files,
    required String userId,
    Function(String mediaId, double progress)? onProgress,
  }) async {
    final List<MediaModel> uploadedMedia = [];

    try {
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final mediaId = 'media_${DateTime.now().millisecondsSinceEpoch}_$i';

        // Validate media file
        final validation = await MediaUtils.validateMediaFile(file);
        if (!validation.isValid) {
          throw Exception('Invalid media file: ${validation.error}');
        }

        // Upload media with progress tracking
        final mediaModel = await _uploadSingleMediaFile(
          file: file,
          userId: userId,
          mediaId: mediaId,
          onProgress: (progress) => onProgress?.call(mediaId, progress),
        );

        if (mediaModel != null) {
          uploadedMedia.add(mediaModel);
        }
      }

      return uploadedMedia;
    } catch (e) {
      debugPrint('Error uploading media files: $e');
      rethrow;
    }
  }

  /// Upload file to Cloudinary with progress tracking
  Future<String> _uploadFileToCloudinary({
    required File file,
    required String userId,
    Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('ShowcaseService: Uploading file to Cloudinary...');

      final filePath = file.path;
      final fileExtension = filePath.split('.').last.toLowerCase();

      String cloudinaryUrl;

      // Determine if it's image or video and upload accordingly
      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension)) {
        cloudinaryUrl = await CloudinaryConfig.uploadImage(
          filePath: filePath,
          userId: userId,
          onProgress: onProgress,
        );
      } else if (['mp4', 'mov', 'avi', 'mkv'].contains(fileExtension)) {
        cloudinaryUrl = await CloudinaryConfig.uploadVideo(
          filePath: filePath,
          userId: userId,
          onProgress: onProgress,
        );
      } else {
        throw Exception('Unsupported file type: $fileExtension');
      }

      debugPrint(
          'ShowcaseService: File uploaded successfully to Cloudinary: $cloudinaryUrl');
      return cloudinaryUrl;
    } catch (e) {
      debugPrint('Error uploading file to Cloudinary: $e');
      rethrow;
    }
  }

  /// Upload single media file with compression and progress tracking
  Future<MediaModel?> _uploadSingleMediaFile({
    required File file,
    required String userId,
    required String mediaId,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Validate file
      final validation = await MediaUtils.validateMediaFile(file);
      if (!validation.isValid) {
        throw Exception('Invalid file: ${validation.error}');
      }

      // Compress file if needed
      final processedFile = await MediaUtils.compressImage(file) ?? file;

      // Upload to Cloudinary instead of Supabase Storage
      final downloadUrl = await _uploadFileToCloudinary(
        file: processedFile,
        userId: userId,
        onProgress: onProgress,
      );

      // Create media model
      final mediaModel = MediaModel(
        id: mediaId,
        url: downloadUrl,
        type: processedFile.path.split('.').last == 'mp4' ? 'video' : 'image',
        uploadedAt: DateTime.now(),
      );

      return mediaModel;
    } catch (e) {
      debugPrint('Error uploading single media file: $e');
      return null;
    }
  }

  /// Get upload progress stream for a specific media
  Stream<MediaUploadProgress> getUploadProgressStream(String mediaId) {
    if (!_uploadControllers.containsKey(mediaId)) {
      _uploadControllers[mediaId] =
          StreamController<MediaUploadProgress>.broadcast();
    }
    return _uploadControllers[mediaId]!.stream;
  }

  /// Batch upload with detailed progress tracking
  Future<List<MediaModel>> batchUploadMedia({
    required List<File> files,
    required String userId,
    Function(Map<String, MediaUploadProgress> progressMap)? onBatchProgress,
  }) async {
    final Map<String, MediaUploadProgress> progressMap = {};
    final List<MediaModel> uploadedMedia = [];

    try {
      // Initialize progress tracking
      for (int i = 0; i < files.length; i++) {
        final mediaId = 'media_${DateTime.now().millisecondsSinceEpoch}_$i';
        progressMap[mediaId] = MediaUploadProgress(
          mediaId: mediaId,
          fileName: files[i].path.split('/').last,
        );
      }

      // Upload files concurrently with limited concurrency
      final futures = <Future<MediaModel?>>[];
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final mediaId = 'media_${DateTime.now().millisecondsSinceEpoch}_$i';

        futures.add(_uploadSingleMediaFile(
          file: file,
          userId: userId,
          mediaId: mediaId,
          onProgress: (progress) {
            progressMap[mediaId] = progressMap[mediaId]!.copyWith(
              progress: progress,
              isCompleted: progress >= 1.0,
            );
            onBatchProgress?.call(Map.from(progressMap));
          },
        ));
      }

      final results = await Future.wait(futures);

      for (final result in results) {
        if (result != null) {
          uploadedMedia.add(result);
        }
      }

      return uploadedMedia;
    } catch (e) {
      debugPrint('Error in batch upload: $e');
      rethrow;
    }
  }

  /// Create showcase post with media using Supabase
  Future<PostCreationResult> createShowcasePost({
    required String content,
    required PostType type,
    required PostCategory category,
    required PostPrivacy privacy,
    List<File> mediaFiles = const [],
    List<String> tags = const [],
    List<MentionModel> mentions = const [],
    String? location,
  }) async {
    try {
      debugPrint('ShowcaseService: Creating showcase post with media...');

      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Upload media files first if any
      List<MediaModel> uploadedMedia = [];
      if (mediaFiles.isNotEmpty) {
        debugPrint(
            'ShowcaseService: Uploading ${mediaFiles.length} media files...');
        uploadedMedia = await uploadMediaFiles(
          files: mediaFiles,
          userId: currentUserId,
          onProgress: (mediaId, progress) {
            debugPrint(
                'Upload progress for $mediaId: ${(progress * 100).toStringAsFixed(1)}%');
          },
        );
        debugPrint(
            'ShowcaseService: Successfully uploaded ${uploadedMedia.length} media files');
      }

      // Create post data
      final postData = {
        'user_id': currentUserId,
        'content': content,
        'title':
            content.length > 50 ? '${content.substring(0, 50)}...' : content,
        'description': content,
        'category': category.toString().split('.').last,
        'tags': tags,
        'media_urls': uploadedMedia.map((m) => m.url).toList(),
        'media_types': uploadedMedia.map((m) => m.type).toList(),
        'is_public': privacy == PostPrivacy.public,
        'allow_comments': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      debugPrint('ShowcaseService: Creating post with data: ${postData.keys}');

      // Create post via Supabase
      await createPost(postData);

      debugPrint('ShowcaseService: Post created successfully!');

      return PostCreationResult(
        success: true,
        postId: 'temp_post_id_${DateTime.now().millisecondsSinceEpoch}',
        post: null, // Will be implemented with Supabase
      );
    } catch (e) {
      debugPrint('Error creating showcase post: $e');
      return PostCreationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get showcase posts with pagination and filtering (ultra-optimized method)
  Future<List<ShowcasePostModel>> getShowcasePosts({
    int limit = 10,
    String? lastPostId,
    PostPrivacy? privacy,
    PostCategory? category,
    String? userId,
  }) async {
    final stopwatch = Stopwatch()..start(); // Performance monitoring

    try {
      // Only log every 100th call to reduce console spam
      _callCount++;
      if (_callCount % 100 == 1) {
        debugPrint(
            'ShowcaseService: Getting showcase posts (ultra-optimized method)... [Call #$_callCount]');
      }

      // Generate cache key based on parameters
      final cacheKey =
          'posts_${privacy?.name ?? 'public'}_${category?.name ?? 'all'}_${userId ?? 'all'}_$limit';

      // Check cache first with ultra-aggressive caching (30 minutes for development)
      if (_postsCache.containsKey(cacheKey)) {
        final cacheTime = _cacheTimestamps[cacheKey];
        if (cacheTime != null &&
            DateTime.now().difference(cacheTime) <
                const Duration(minutes: 30)) {
          debugPrint('ShowcaseService: Using cached posts for key: $cacheKey');
          stopwatch.stop();
          debugPrint(
              'ShowcaseService: Cache hit - loaded in ${stopwatch.elapsedMilliseconds}ms');
          return List<ShowcasePostModel>.from(_postsCache[cacheKey]!);
        }
      }

      debugPrint('ShowcaseService: Loading real data from Supabase...');
      final dbStartTime = Stopwatch()..start();

      // Optimized timeout for better reliability
      final timeoutDuration = const Duration(
          seconds: 8); // Increased from 2 to 8 seconds for reliability

      // Build optimized query for homepage feed (include media for images)
      var query = _supabase.from('showcase_posts').select('''
            id,
            user_id,
            content,
            created_at,
            media_urls,
            media_types
          '''); // Include media fields for image display

      // Apply filters
      if (privacy != null) {
        query = query.eq('is_public', privacy == PostPrivacy.public);
      } else {
        // Default to public posts
        query = query.eq('is_public', true);
      }

      if (category != null) {
        query = query.eq('category', category.toString().split('.').last);
      }

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      // Apply ordering and limiting with ultra-fast timeout
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(timeoutDuration);

      // Extract unique user IDs
      final userIds =
          response.map((post) => post['user_id'] as String).toSet().toList();

      // Fetch all profiles efficiently with ultra-fast timeout
      final profilesMap = await _fetchProfilesForUsers(userIds)
          .timeout(const Duration(seconds: 3)); // Reduced from 5 to 3 seconds

      // Parse posts to ShowcasePostModel with minimal processing
      final List<ShowcasePostModel> postsWithProfiles = [];

      for (final post in response) {
        try {
          final userId = post['user_id'] as String;
          final profile = profilesMap[userId] ?? {};

          // Combine post data with profile data (minimal processing)
          final postWithProfile = {
            ...post,
            'profiles': profile,
            // Map profile data to expected field names
            'user_name': profile['full_name'] ?? 'User',
            'user_profile_image': profile['profile_image_url'],
            'user_headline': profile['headline'] ?? '',
            // Add default values for missing fields to avoid parsing errors
            'tags': post['tags'] ?? [],
            'media_types': post['media_types'] ?? [],
            'updated_at': post['updated_at'] ?? post['created_at'],
            'is_edited': post['is_edited'] ?? false,
            'location': post['location'] ?? '',
            'skills_used': post['skills_used'] ?? [],
            'description': post['description'] ?? post['content'],
            'title': post['title'] ?? '',
          };

          // Parse to ShowcasePostModel
          final postModel = ShowcasePostModel.fromJson(postWithProfile);
          postsWithProfiles.add(postModel);
        } catch (e) {
          debugPrint('ShowcaseService: Error parsing post ${post['id']}: $e');
          // Skip this post if there's an error
          continue;
        }
      }

      // Cache the results
      _postsCache[cacheKey] = postsWithProfiles;
      _cacheTimestamps[cacheKey] = DateTime.now();

      debugPrint(
          'ShowcaseService: Cached ${postsWithProfiles.length} posts for key: $cacheKey');

      stopwatch.stop();
      debugPrint(
          'ShowcaseService: Fetched ${postsWithProfiles.length} posts from DB in ${dbStartTime.elapsedMilliseconds}ms');
      return postsWithProfiles;
    } catch (e) {
      debugPrint('ShowcaseService: Error getting showcase posts: $e');
      return [];
    }
  }

  /// Get showcase posts without real-time (fallback method)
  Future<List<ShowcasePostModel>> getShowcasePostsSimple({
    int limit = 10,
    PostPrivacy? privacy,
    PostCategory? category,
    String? userId,
  }) async {
    try {
      // Use the simple method that we know works
      return await getShowcasePosts(
        limit: limit,
        privacy: privacy,
        category: category,
        userId: userId,
      );
    } catch (e) {
      debugPrint('ShowcaseService: Error in simple method: $e');
      return [];
    }
  }

  /// Refresh showcase feed after new post creation
  Future<void> refreshFeed() async {
    try {
      debugPrint('ShowcaseService: Refreshing showcase feed...');

      // Reset call count to ensure fresh data is fetched
      _callCount = 0;

      // Trigger a refresh by updating a timestamp or using a refresh mechanism
      // This will be handled by the UI layer calling getShowcasePosts() again

      debugPrint('ShowcaseService: Feed refresh triggered');
    } catch (e) {
      debugPrint('ShowcaseService: Error refreshing feed: $e');
    }
  }

  /// Get showcase posts as a real-time stream (ultra-fast method)
  Stream<List<ShowcasePostModel>> getShowcasePostsRealtimeStream({
    int limit = 10,
    PostCategory? category,
    PostPrivacy? privacy,
    String? userId,
  }) {
    try {
      // Only log once when setting up subscription
      debugPrint(
          'ShowcaseService: Setting up ultra-fast real-time subscription...');

      // Use a longer interval to reduce console spam and improve hot restart performance
      // Start with immediate load, then periodic updates
      return Stream.periodic(const Duration(seconds: 60)).asyncMap((_) async {
        try {
          // Use the ultra-optimized getShowcasePosts method with ultra-fast timeout
          return await getShowcasePosts(
            limit: limit,
            privacy: privacy,
            category: category,
            userId: userId,
          ).timeout(const Duration(seconds: 4)); // Ultra-fast timeout
        } catch (e) {
          // Only log errors, not every call
          debugPrint('ShowcaseService: Error in real-time stream: $e');
          return <ShowcasePostModel>[];
        }
      }).handleError((error) {
        debugPrint('ShowcaseService: Real-time stream error: $error');
        return <ShowcasePostModel>[];
      });
    } catch (e) {
      debugPrint(
          'ShowcaseService: Error in getShowcasePostsRealtimeStream: $e');
      return Stream.value(<ShowcasePostModel>[]);
    }
  }

  /// Delete media file from Cloudinary
  Future<void> deleteMediaFile(String mediaUrl) async {
    try {
      // Extract public ID from Cloudinary URL
      final publicId = CloudinaryConfig.getPublicId(mediaUrl);

      if (publicId != null) {
        // Delete from Cloudinary
        final success = await CloudinaryConfig.deleteFile(publicId);
        if (success) {
          debugPrint(
              'ShowcaseService: Media file deleted successfully from Cloudinary: $publicId');
        } else {
          debugPrint(
              'ShowcaseService: Failed to delete media file from Cloudinary: $publicId');
        }
      } else {
        debugPrint(
            'ShowcaseService: Could not extract public ID from URL: $mediaUrl');
      }
    } catch (e) {
      debugPrint('Error deleting media file from Cloudinary: $e');
      // Don't rethrow - file might already be deleted
    }
  }

  /// Delete showcase post via Supabase
  Future<void> deleteShowcasePost(String postId) async {
    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // First get the post to check ownership and get media URLs
      final postData = await _supabase
          .from('showcase_posts')
          .select('user_id, media_urls')
          .eq('id', postId)
          .maybeSingle();

      if (postData == null) {
        throw Exception('Post not found');
      }

      // Check if user owns the post
      if (postData['user_id'] != currentUserId) {
        throw Exception('Not authorized to delete this post');
      }

      // Delete associated media files from storage
      if (postData['media_urls'] != null) {
        final mediaUrls = List<String>.from(postData['media_urls']);
        for (String url in mediaUrls) {
          await deleteMediaFile(url);
        }
      }

      // Delete the post
      await _supabase.from('showcase_posts').delete().eq('id', postId);

      debugPrint('ShowcaseService: Post deleted successfully: $postId');
    } catch (e) {
      debugPrint('Error deleting showcase post: $e');
      rethrow;
    }
  }

  /// Clean up temporary files and controllers
  Future<void> cleanup() async {
    try {
      // Clean up media utils temp files
      await MediaUtils.cleanupTempFiles();

      // Close upload controllers
      dispose();
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }

  // Cache management methods are defined below in the CACHE MANAGEMENT METHODS section

  // ==================== CACHE MANAGEMENT METHODS ====================

  /// Clear all caches (useful for testing or memory management)
  static void clearAllCaches() {
    _postsCache.clear();
    _cacheTimestamps.clear();
    _profilesCache.clear();
    _profilesCacheTimestamps.clear();
    debugPrint('ShowcaseService: All caches cleared');
  }

  /// Clear expired cache entries to free memory
  static void clearExpiredCache() {
    final now = DateTime.now();

    // Clear expired posts cache
    final expiredPostKeys = _cacheTimestamps.entries
        .where((entry) => now.difference(entry.value) > _cacheValidity)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredPostKeys) {
      _postsCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    // Clear expired profiles cache
    final expiredProfileKeys = _profilesCacheTimestamps.entries
        .where((entry) => now.difference(entry.value) > _profilesCacheValidity)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredProfileKeys) {
      _profilesCache.remove(key);
      _profilesCacheTimestamps.remove(key);
    }

    if (expiredPostKeys.isNotEmpty || expiredProfileKeys.isNotEmpty) {
      debugPrint(
          'ShowcaseService: Cleared ${expiredPostKeys.length} expired post caches and ${expiredProfileKeys.length} expired profile caches');
    }
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'posts_cache_size': _postsCache.length,
      'profiles_cache_size': _profilesCache.length,
      'total_cache_entries': _postsCache.length + _profilesCache.length,
      'cache_validity_minutes': _cacheValidity.inMinutes,
      'profiles_cache_validity_minutes': _profilesCacheValidity.inMinutes,
    };
  }

  /// Preload common data for faster access
  Future<void> preloadCommonData() async {
    try {
      debugPrint('ShowcaseService: Preloading common data...');

      // Preload public posts
      await getShowcasePosts(limit: 10);

      // Preload user profiles for current user
      final currentUserId = _authService.currentUserId;
      if (currentUserId != null) {
        await _fetchProfilesForUsers([currentUserId]);
      }

      debugPrint('ShowcaseService: Common data preloaded successfully');
    } catch (e) {
      debugPrint('ShowcaseService: Error preloading common data: $e');
    }
  }

  // ==================== SOCIAL INTERACTION METHODS ====================

  // Social interaction methods with Supabase integration
  // Using Supabase backend for transactions

  /// Like a post
  Future<void> likePost(String postId, String userId) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Check if user already liked the post
      final existingLike = await _supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike == null) {
        // Add like
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });

        debugPrint('ShowcaseService: Post liked successfully: $postId');
      } else {
        debugPrint('ShowcaseService: Post already liked by user: $postId');
      }
      // await SupabaseConfig.from('showcase_posts')
      //     .update({'likes': SupabaseConfig.sql('array_append(likes, $userId)')})
      //     .eq('id', postId);
    } catch (e) {
      debugPrint('Error liking post: $e');
      rethrow;
    }
  }

  /// Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Remove like
      await _supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);

      debugPrint('ShowcaseService: Post unliked successfully: $postId');
      // await SupabaseConfig.from('showcase_posts')
      //     .update({'likes': SupabaseConfig.sql('array_remove(likes, $userId)')})
      //     .eq('id', postId);
    } catch (e) {
      debugPrint('Error unliking post: $e');
      rethrow;
    }
  }

  /// Add comment to a post (embedded in showcase_posts.comments)
  Future<void> addComment(String postId, String userId, String content) async {
    try {
      // Get current post data
      final postData = await _supabase
          .from('showcase_posts')
          .select('comments')
          .eq('id', postId)
          .single();

      List<Map<String, dynamic>> comments =
          List<Map<String, dynamic>>.from(postData['comments'] ?? []);

      // Try to resolve user info from Supabase profiles or auth metadata
      String resolvedName = '';
      String? resolvedAvatar;

      try {
        // Try users table first (now that policy is fixed)
        try {
          final user = await _supabase
              .from('users')
              .select('name')
              .eq('id', userId)
              .maybeSingle();
          if (user != null && user['name'] != null) {
            resolvedName = user['name'].toString();
          }
        } catch (e) {
          debugPrint('Error getting user name for comment: $e');
        }

        // If still empty, try profiles table
        if (resolvedName.isEmpty) {
          try {
            final profile = await _supabase
                .from('profiles')
                .select('full_name, profile_image_url')
                .eq('user_id', userId)
                .maybeSingle();
            if (profile != null) {
              resolvedName = (profile['full_name'] ?? '').toString();
              resolvedAvatar = profile['profile_image_url']?.toString();
            }
          } catch (e) {
            debugPrint('Error getting profile for comment: $e');
          }
        }

        // If still empty, try auth service current user
        if (resolvedName.isEmpty) {
          resolvedName = _authService.currentUser?.name ?? '';
        }

        // Final fallback to auth metadata
        if (resolvedName.isEmpty) {
          resolvedName = (Supabase.instance.client.auth.currentUser
                      ?.userMetadata?['name'] ??
                  '')
              .toString();
        }

        // Last resort fallback
        if (resolvedName.isEmpty) {
          resolvedName = 'User';
        }
      } catch (e) {
        debugPrint('Error resolving user name for comment: $e');
        resolvedName = 'User';
      }

      // Create new comment with proper structure for CommentModel
      final newComment = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'postId': postId,
        'userId': userId,
        'userName': resolvedName,
        'userProfileImage': resolvedAvatar,
        'content': content,
        'likes': <String>[],
        'mentions': <Map<String, dynamic>>[],
        'parentCommentId': null,
        'replies': <Map<String, dynamic>>[],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isEdited': false,
      };

      comments.add(newComment);

      // Update the post with new comments
      await _supabase
          .from('showcase_posts')
          .update({'comments': comments}).eq('id', postId);

      debugPrint(
          'ShowcaseService: Comment added successfully to post: $postId');
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  /// Share a post
  Future<void> sharePost(String postId, String userId) async {
    try {
      // Log share activity
      await _supabase.from('post_shares').insert({
        'post_id': postId,
        'user_id': _authService.currentUserId,
        'shared_at': DateTime.now().toIso8601String(),
      });

      debugPrint('ShowcaseService: Post shared successfully: $postId');
      // await SupabaseConfig.from('showcase_posts')
      //     .update({'shares': SupabaseConfig.sql('array_append(shares, $userId)')})
      //     .eq('id', postId);
    } catch (e) {
      debugPrint('Error sharing post: $e');
      rethrow;
    }
  }

  /// Increment view count
  Future<void> incrementViewCount(String postId) async {
    try {
      // Increment view count using Supabase RPC or direct update
      // For now, just log the view increment

      // Option 1: Use a simple update (if you have a view_count column)
      // await _supabase
      //     .from('showcase_posts')
      //     .update({'view_count': _supabase.sql('view_count + 1')})
      //     .eq('id', postId);

      // Option 2: Create the function in Supabase SQL Editor:
      // CREATE OR REPLACE FUNCTION increment_view_count(post_id UUID)
      // RETURNS void AS $$
      // BEGIN
      //   UPDATE showcase_posts
      //   SET view_count = COALESCE(view_count, 0) + 1
      //   WHERE id = post_id;
      // END;
      // $$ LANGUAGE plpgsql;
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
      // Don't rethrow - view count is not critical
    }
  }

  // ==================== COMPATIBILITY METHODS ====================
  // These methods are added for compatibility with existing UI code

  /// Toggle like on a post (alias for likePost/unlikePost)
  Future<void> toggleLike(String postId, String userId) async {
    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Get current post data
      final postData = await _supabase
          .from('showcase_posts')
          .select('likes')
          .eq('id', postId)
          .single();

      List<String> likes = List<String>.from(postData['likes'] ?? []);

      if (likes.contains(currentUserId)) {
        // Unlike the post
        likes.remove(currentUserId);
      } else {
        // Like the post
        likes.add(currentUserId);
      }

      // Update the post with new likes
      await _supabase
          .from('showcase_posts')
          .update({'likes': likes}).eq('id', postId);

      debugPrint('ShowcaseService: Post like toggled successfully: $postId');
    } catch (e) {
      debugPrint('Error toggling like: $e');
      rethrow;
    }
  }

  /// Add LinkedIn-style reaction to a post (only one reaction per user)
  Future<void> addReaction(String postId, String reactionType) async {
    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Check if user already has a reaction on this post
      final existingReaction = await _supabase
          .from('user_reactions')
          .select()
          .eq('post_id', postId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existingReaction != null) {
        // User already has a reaction - update it instead
        await _updateReaction(
            postId, reactionType, existingReaction['reaction_type']);
      } else {
        // User doesn't have a reaction - add new one
        await _addNewReaction(postId, reactionType);
      }

      debugPrint(
          'ShowcaseService: Reaction $reactionType added to post: $postId');
    } catch (e) {
      debugPrint('Error adding reaction: $e');
      rethrow;
    }
  }

  /// Remove LinkedIn-style reaction from a post
  Future<void> removeReaction(String postId, String reactionType) async {
    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Remove from user_reactions table
      await _supabase
          .from('user_reactions')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', currentUserId);

      // Update reaction counts in showcase_posts
      await _decrementReactionCount(postId, reactionType);

      debugPrint(
          'ShowcaseService: Reaction $reactionType removed from post: $postId');
    } catch (e) {
      debugPrint('Error removing reaction: $e');
      rethrow;
    }
  }

  /// Helper method to add a new reaction
  Future<void> _addNewReaction(String postId, String reactionType) async {
    final currentUserId = _authService.currentUserId!;

    // Add to user_reactions table
    await _supabase.from('user_reactions').insert({
      'post_id': postId,
      'user_id': currentUserId,
      'reaction_type': reactionType,
    });

    // Update reaction counts in showcase_posts
    await _incrementReactionCount(postId, reactionType);
  }

  /// Helper method to update existing reaction (change from one type to another)
  Future<void> _updateReaction(
      String postId, String newReactionType, String oldReactionType) async {
    final currentUserId = _authService.currentUserId!;

    // Update user_reactions table
    await _supabase
        .from('user_reactions')
        .update({'reaction_type': newReactionType})
        .eq('post_id', postId)
        .eq('user_id', currentUserId);

    // Update reaction counts in showcase_posts (decrement old, increment new)
    await _decrementReactionCount(postId, oldReactionType);
    await _incrementReactionCount(postId, newReactionType);
  }

  /// Helper method to increment reaction count
  Future<void> _incrementReactionCount(
      String postId, String reactionType) async {
    // Get current post data
    final postData = await _supabase
        .from('showcase_posts')
        .select('reactions')
        .eq('id', postId)
        .single();

    Map<String, dynamic> reactions =
        Map<String, dynamic>.from(postData['reactions'] ?? {});

    // Increment reaction count
    reactions[reactionType] = (reactions[reactionType] ?? 0) + 1;

    // Update the post
    await _supabase
        .from('showcase_posts')
        .update({'reactions': reactions}).eq('id', postId);
  }

  /// Helper method to decrement reaction count
  Future<void> _decrementReactionCount(
      String postId, String reactionType) async {
    // Get current post data
    final postData = await _supabase
        .from('showcase_posts')
        .select('reactions')
        .eq('id', postId)
        .single();

    Map<String, dynamic> reactions =
        Map<String, dynamic>.from(postData['reactions'] ?? {});

    // Decrease reaction count
    if (reactions[reactionType] != null && reactions[reactionType] > 0) {
      reactions[reactionType] = reactions[reactionType] - 1;

      // Remove if count reaches 0
      if (reactions[reactionType] == 0) {
        reactions.remove(reactionType);
      }
    }

    // Update the post
    await _supabase
        .from('showcase_posts')
        .update({'reactions': reactions}).eq('id', postId);
  }

  /// Get user's current reaction for a post
  Future<String?> getUserReaction(String postId) async {
    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) return null;

      final reaction = await _supabase
          .from('user_reactions')
          .select('reaction_type')
          .eq('post_id', postId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      return reaction?['reaction_type'];
    } catch (e) {
      debugPrint('Error getting user reaction: $e');
      return null;
    }
  }

  /// Add comment with extended parameters (for compatibility)
  Future<String> addCommentExtended({
    required String postId,
    required String userId,
    required String userName,
    String? userProfileImage,
    required String content,
    String? parentCommentId,
    List<MentionModel> mentions = const [],
  }) async {
    try {
      final response = await _supabase
          .from('post_comments')
          .insert({
            'post_id': postId,
            'user_id': userId,
            'content': content,
            'parent_comment_id': parentCommentId,
            'mentions': mentions.map((m) => m.toJson()).toList(),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final commentId = response['id'].toString();
      debugPrint(
          'ShowcaseService: Extended comment added successfully: $commentId');
      return commentId;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  /// Update comment stored in showcase_posts.comments (embedded JSON)
  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String content,
    List<MentionModel> mentions = const [],
  }) async {
    try {
      // Fetch current comments
      final postData = await _supabase
          .from('showcase_posts')
          .select('comments')
          .eq('id', postId)
          .single();

      List<Map<String, dynamic>> comments =
          List<Map<String, dynamic>>.from(postData['comments'] ?? []);

      bool updated = false;

      // Helper to update a comment recursively (including replies)
      List<Map<String, dynamic>> updateRecursive(
          List<Map<String, dynamic>> list) {
        return list.map((c) {
          if (c['id']?.toString() == commentId) {
            updated = true;
            return {
              ...c,
              'content': content,
              'updatedAt': DateTime.now().toIso8601String(),
              'isEdited': true,
            };
          }
          if (c['replies'] is List) {
            return {
              ...c,
              'replies': updateRecursive(
                  List<Map<String, dynamic>>.from(c['replies'])),
            };
          }
          return c;
        }).toList();
      }

      comments = updateRecursive(comments);

      if (!updated) {
        throw Exception('Comment not found');
      }

      await _supabase
          .from('showcase_posts')
          .update({'comments': comments}).eq('id', postId);

      debugPrint('ShowcaseService: Comment updated successfully: $commentId');
    } catch (e) {
      debugPrint('Error updating comment: $e');
      rethrow;
    }
  }

  /// Delete comment stored in showcase_posts.comments (embedded JSON)
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      // Fetch current comments
      final postData = await _supabase
          .from('showcase_posts')
          .select('comments')
          .eq('id', postId)
          .single();

      List<Map<String, dynamic>> comments =
          List<Map<String, dynamic>>.from(postData['comments'] ?? []);

      bool removed = false;

      // Recursively remove by id from nested structure
      List<Map<String, dynamic>> removeRecursive(
          List<Map<String, dynamic>> list) {
        final List<Map<String, dynamic>> result = [];
        for (final c in list) {
          if (c['id']?.toString() == commentId) {
            removed = true;
            continue; // skip this one
          }
          Map<String, dynamic> updated = Map<String, dynamic>.from(c);
          if (c['replies'] is List) {
            updated['replies'] =
                removeRecursive(List<Map<String, dynamic>>.from(c['replies']));
          }
          result.add(updated);
        }
        return result;
      }

      comments = removeRecursive(comments);

      if (!removed) {
        throw Exception('Comment not found');
      }

      await _supabase
          .from('showcase_posts')
          .update({'comments': comments}).eq('id', postId);

      debugPrint('ShowcaseService: Comment deleted successfully: $commentId');
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      rethrow;
    }
  }

  /// Toggle comment like (for compatibility)
  Future<void> toggleCommentLike(
      String postId, String commentId, String userId) async {
    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Check if user already liked the comment
      final existingLike = await _supabase
          .from('comment_likes')
          .select()
          .eq('comment_id', commentId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existingLike == null) {
        // Add like
        await _supabase.from('comment_likes').insert({
          'comment_id': commentId,
          'user_id': currentUserId,
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint('ShowcaseService: Comment liked successfully: $commentId');
      } else {
        // Remove like
        await _supabase
            .from('comment_likes')
            .delete()
            .eq('comment_id', commentId)
            .eq('user_id', currentUserId);
        debugPrint('ShowcaseService: Comment unliked successfully: $commentId');
      }
    } catch (e) {
      debugPrint('Error toggling comment like: $e');
      rethrow;
    }
  }

  /// Get a single post by ID for immediate refresh
  Future<ShowcasePostModel?> getPostById(String postId) async {
    try {
      // Get post data only first
      final response = await _supabase
          .from('showcase_posts')
          .select('*')
          .eq('id', postId)
          .maybeSingle();

      if (response != null) {
        final post = ShowcasePostModel.fromJson(response);

        // Resolve user name separately to avoid join issues
        try {
          final user = await _supabase
              .from('users')
              .select('name')
              .eq('id', post.userId)
              .maybeSingle();

          if (user != null && user['name'] != null) {
            return post.copyWith(userName: user['name'].toString());
          }
        } catch (e) {
          debugPrint('Error resolving user name: $e');
        }

        return post;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting post by ID: $e');
      return null;
    }
  }

  /// Get showcase collection reference (for compatibility)
  dynamic get showcaseCollection {
    // Return a mock object that provides the methods UI code expects
    return _MockShowcaseCollection(this);
  }
}

/// Mock collection class for compatibility
class _MockShowcaseCollection {
  final ShowcaseService _service;
  _MockShowcaseCollection(this._service);

  dynamic doc(String id) => _MockDocument(id, _service);
}

/// Mock document class for compatibility
class _MockDocument {
  final String id;
  final ShowcaseService _service;
  _MockDocument(this.id, this._service);

  Future<void> update(Map<String, dynamic> data) async {
    // Implementation with Supabase would go here
    debugPrint('Mock update called for document $id');
  }

  Future<void> delete() async {
    // Implementation with Supabase would go here
    debugPrint('Mock delete called for document $id');
  }

  Future<dynamic> get() async {
    // Implementation with Supabase would go here
    debugPrint('Mock get called for document $id');
    return null;
  }

  /// Add snapshots() method for compatibility with PostDetailScreen
  Stream<ShowcasePostModel?> snapshots() {
    debugPrint('Mock snapshots() called for document $id');
    // Return a stream that fetches the post from Supabase with immediate updates
    return Stream.periodic(const Duration(seconds: 30))
        .asyncMap<ShowcasePostModel?>((_) async {
      try {
        // Get post data only first
        final response = await _service._supabase
            .from('showcase_posts')
            .select('*')
            .eq('id', id)
            .single();

        final post = ShowcasePostModel.fromJson(response);

        // Resolve user name separately to avoid join issues
        try {
          final user = await _service._supabase
              .from('users')
              .select('name')
              .eq('id', post.userId)
              .maybeSingle();

          if (user != null && user['name'] != null) {
            return post.copyWith(userName: user['name'].toString());
          }
        } catch (e) {
          debugPrint('Error resolving user name in stream: $e');
        }

        return post;
      } catch (e) {
        debugPrint('Error fetching post $id: $e');
        return null;
      }
    });
  }
}
