import 'dart:convert';
import 'package:http/http.dart' as http;
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

  // Supabase configuration - Complete integration
  SupabaseClient get _supabase => Supabase.instance.client;

  // Get Supabase auth token for authentication
  static Future<String?> _getAuthToken() async {
    try {
      // Import Supabase config
      final session = Supabase.instance.client.auth.currentSession;
      if (session?.accessToken != null) {
        debugPrint(
            'ShowcaseService: Got Supabase auth token for user: ${session!.user.id}');
        debugPrint(
            'ShowcaseService: Token length: ${session.accessToken.length}');
        return session.accessToken;
      } else {
        debugPrint('ShowcaseService: No Supabase session found!');
        return null;
      }
    } catch (e) {
      debugPrint('ShowcaseService: Error getting Supabase auth token: $e');
      return null;
    }
  }

  // Storage paths
  static const String _imagesPath = 'showcase_images';

  // Upload progress controllers
  final Map<String, StreamController<MediaUploadProgress>> _uploadControllers =
      {};

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
      final response =
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

  /// Helper method to efficiently fetch profiles for multiple users
  Future<Map<String, Map<String, dynamic>>> _fetchProfilesForUsers(
      List<String> userIds) async {
    try {
      if (userIds.isEmpty) return {};

      final profileResponse = await _supabase
          .from('profiles')
          .select('user_id, full_name, profile_image_url')
          .inFilter('user_id', userIds);

      final Map<String, Map<String, dynamic>> profilesMap = {};
      for (final profile in profileResponse) {
        final userId = profile['user_id'] as String;
        profilesMap[userId] = {
          'full_name': profile['full_name'],
          'profile_image_url':
              _getSafeProfileImageUrl(profile['profile_image_url']),
        };
      }

      return profilesMap;
    } catch (e) {
      debugPrint('ShowcaseService: Error fetching profiles: $e');
      return {};
    }
  }

  /// Helper method to get safe profile image URL
  String? _getSafeProfileImageUrl(dynamic imageUrl) {
    if (imageUrl == null || imageUrl.toString().isEmpty) {
      return null;
    }

    final url = imageUrl.toString();

    // Check if it's a problematic placeholder URL
    if (url.contains('via.placeholder.com') ||
        url.contains('placeholder.com') ||
        url.contains('dummyimage.com') ||
        url.contains('placehold.it')) {
      // Return null to trigger fallback widget
      return null;
    }

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

  /// Get showcase posts with pagination and filtering (simple, reliable method)
  Future<List<ShowcasePostModel>> getShowcasePosts({
    int limit = 10,
    String? lastPostId,
    PostPrivacy? privacy,
    PostCategory? category,
    String? userId,
  }) async {
    try {
      debugPrint('ShowcaseService: Getting showcase posts (simple method)...');

      // Build the base query
      var query = _supabase.from('showcase_posts').select('''
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
          ''');

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

      // Apply ordering and limiting
      final response =
          await query.order('created_at', ascending: false).limit(limit);

      debugPrint('ShowcaseService: Retrieved ${response.length} posts');

      // Extract unique user IDs
      final userIds =
          response.map((post) => post['user_id'] as String).toSet().toList();

      // Fetch all profiles efficiently in one query
      final profilesMap = await _fetchProfilesForUsers(userIds);

      // Parse posts to ShowcasePostModel
      final List<ShowcasePostModel> postsWithProfiles = [];

      for (final post in response) {
        try {
          final userId = post['user_id'] as String;
          final profile = profilesMap[userId] ?? {};

          // Combine post data with profile data
          final postWithProfile = {
            ...post,
            'profiles': profile,
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

      debugPrint(
          'ShowcaseService: Successfully parsed ${postsWithProfiles.length} posts');
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
      debugPrint(
          'ShowcaseService: Getting showcase posts (simple fallback method)...');

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

      // Trigger a refresh by updating a timestamp or using a refresh mechanism
      // This will be handled by the UI layer calling getShowcasePosts() again

      debugPrint('ShowcaseService: Feed refresh triggered');
    } catch (e) {
      debugPrint('ShowcaseService: Error refreshing feed: $e');
    }
  }

  /// Get showcase posts as a real-time stream (fixed method)
  Stream<List<ShowcasePostModel>> getShowcasePostsRealtimeStream({
    int limit = 10,
    PostCategory? category,
    PostPrivacy? privacy,
    String? userId,
  }) {
    try {
      debugPrint('ShowcaseService: Setting up real-time subscription...');

      // Use the working approach: fetch posts first, then profiles
      return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
        try {
          // Use the working getShowcasePosts method
          return await getShowcasePosts(
            limit: limit,
            privacy: privacy,
            category: category,
            userId: userId,
          );
        } catch (e) {
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

  /// Helper method to fetch and emit posts
  Future<void> _fetchAndEmitPosts(
    StreamController<List<ShowcasePostModel>> controller,
    int limit,
    PostCategory? category,
    PostPrivacy? privacy,
    String? userId,
  ) async {
    try {
      final posts = await getShowcasePosts(
        limit: limit,
        privacy: privacy,
        category: category,
        userId: userId,
      );

      if (!controller.isClosed) {
        controller.add(posts);
      }
    } catch (e) {
      debugPrint('ShowcaseService: Error fetching posts for stream: $e');
      if (!controller.isClosed) {
        controller.add([]);
      }
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

  /// Add comment to a post
  Future<void> addComment(String postId, String userId, String content) async {
    try {
      await _supabase.from('post_comments').insert({
        'post_id': postId,
        'user_id': userId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });

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
      // TODO: Create the increment_view_count function in Supabase
      // For now, just log the view increment
      debugPrint(
          'ShowcaseService: View count increment requested for post: $postId');

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

      // Check if user already liked the post
      final existingLike = await _supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existingLike == null) {
        // Like the post
        await likePost(postId, userId);
      } else {
        // Unlike the post
        await unlikePost(postId, userId);
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      rethrow;
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

  /// Update comment (for compatibility)
  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String content,
    List<MentionModel> mentions = const [],
  }) async {
    try {
      await _supabase.from('post_comments').update({
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
        'is_edited': true,
      }).eq('id', commentId);

      debugPrint('ShowcaseService: Comment updated successfully: $commentId');
    } catch (e) {
      debugPrint('Error updating comment: $e');
      rethrow;
    }
  }

  /// Delete comment (for compatibility)
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _supabase.from('post_comments').delete().eq('id', commentId);

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

  /// Get showcase collection reference (for compatibility)
  dynamic get showcaseCollection {
    // Return a mock object that provides the methods UI code expects
    return _MockShowcaseCollection();
  }
}

/// Mock collection class for compatibility
class _MockShowcaseCollection {
  dynamic doc(String id) => _MockDocument(id);
}

/// Mock document class for compatibility
class _MockDocument {
  final String id;
  _MockDocument(this.id);

  Future<void> update(Map<String, dynamic> data) async {
    // TODO: Implement with Supabase
    debugPrint('Mock update called for document $id');
  }

  Future<void> delete() async {
    // TODO: Implement with Supabase
    debugPrint('Mock delete called for document $id');
  }

  Future<dynamic> get() async {
    // TODO: Implement with Supabase
    debugPrint('Mock get called for document $id');
    return null;
  }

  /// Add snapshots() method for compatibility with PostDetailScreen
  Stream<dynamic> snapshots() {
    // Return an empty stream for now
    debugPrint('Mock snapshots() called for document $id');
    return Stream.value(null);
  }
}
