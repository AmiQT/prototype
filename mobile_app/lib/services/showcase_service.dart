import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import '../models/showcase_models.dart';
import '../models/post_creation_models.dart';
import '../utils/media_utils.dart';
import 'auth_service_supabase_ready.dart';

class ShowcaseService {
  static const String baseUrl =
      'https://c3168f89d034.ngrok-free.app'; // ngrok tunnel - ACTIVE ✅

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

  /// Create a new showcase post
  Future<void> createPost(Map<String, dynamic> postData) async {
    try {
      debugPrint('ShowcaseService: Creating post with Supabase...');
      debugPrint('ShowcaseService: Post data: ${json.encode(postData)}');

      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final requestBody = {
        'user_id': currentUserId,
        'title': postData['title'] ?? '',
        'description': postData['description'] ?? '',
        'content': postData['content'] ?? '',
        'category': postData['category'] ?? 'general',
        'tags': postData['tags'] ?? [],
        'skills_used': postData['skillsUsed'] ?? [],
        'media_urls': postData['mediaUrls'] ?? [],
        'media_types': postData['mediaTypes'] ?? [],
        'is_public': postData['isPublic'] ?? true,
        'allow_comments': postData['allowComments'] ?? true,
        'created_at': DateTime.now().toIso8601String(),
      };

      debugPrint('ShowcaseService: Request body: ${json.encode(requestBody)}');

      await _supabase.from('showcase_posts').insert(requestBody);

      debugPrint('ShowcaseService: Post created successfully with Supabase!');
    } catch (e) {
      debugPrint('Error creating showcase post: $e');
      rethrow;
    }
  }

  /// Get all showcase posts
  Future<List<Map<String, dynamic>>> getAllPosts() async {
    try {
      debugPrint('ShowcaseService: Fetching posts from Supabase...');

      final response = await _supabase
          .from('showcase_posts')
          .select('''
            *,
            profiles:user_id (
              name,
              profile_picture_url
            )
          ''')
          .eq('is_public', true)
          .order('created_at', ascending: false);

      debugPrint('ShowcaseService: Retrieved ${response.length} posts from Supabase');
      return response.map<Map<String, dynamic>>((post) => post).toList();
    } catch (e) {
      debugPrint('Error fetching showcase posts: $e');
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
      // First delete associated media files
      final postData = await _supabase
          .from('showcase_posts')
          .select('media_urls')
          .eq('id', postId)
          .single();
      
      if (postData['media_urls'] != null) {
        final mediaUrls = List<String>.from(postData['media_urls']);
        for (String url in mediaUrls) {
          // Extract file path from URL and delete from storage
          final fileName = url.split('/').last;
          await _supabase.storage.from('showcase-media').remove([fileName]);
        }
      }
      
      // Delete the post record
      await _supabase.from('showcase_posts').delete().eq('id', postId);
      
      debugPrint('ShowcaseService: Post deleted successfully: $postId');
      // await SupabaseConfig.from('showcase_posts')
      //     .delete()
      //     .eq('id', postId);
    } catch (e) {
      debugPrint('Error deleting showcase post: $e');
      rethrow;
    }
  }

  /// Get posts by user ID
  Future<List<Map<String, dynamic>>> getPostsByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('showcase_posts')
          .select('''
            *,
            profiles:user_id (
              name,
              profile_picture_url
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return response.map<Map<String, dynamic>>((post) => post).toList();
      // final response = await SupabaseConfig.from('showcase_posts')
      //     .select()
      //     .eq('userId', userId)
      //     .order('createdAt', ascending: false);
      // return response.map((post) => post as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error fetching user posts: $e');
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

      // Upload to storage
      final downloadUrl = await _uploadFileToStorage(
        file: processedFile,
        path: _imagesPath,
        fileName: '$mediaId.${processedFile.path.split('.').last}',
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

  /// Upload file to Supabase Storage with progress tracking
  Future<String> _uploadFileToStorage({
    required File file,
    required String path,
    required String fileName,
    Function(double progress)? onProgress,
  }) async {
    try {
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_${fileName}';
      
      // Upload file to Supabase Storage
      await _supabase.storage.from('showcase-media').upload(uniqueFileName, file);
      
      // Get public URL
      final publicUrl = _supabase.storage.from('showcase-media').getPublicUrl(uniqueFileName);
      
      debugPrint('ShowcaseService: File uploaded successfully to: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading file to storage: $e');
      rethrow;
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

  /// Create showcase post with media using backend API
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

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      // Upload media files first
      List<MediaModel> uploadedMedia = [];
      if (mediaFiles.isNotEmpty) {
        uploadedMedia = await uploadMediaFiles(
          files: mediaFiles,
          userId: _authService.currentUserId ?? 'anonymous',
          onProgress: (mediaId, progress) {
            debugPrint(
                'Upload progress for $mediaId: ${(progress * 100).toStringAsFixed(1)}%');
          },
        );
      }

      // Create post data
      final postData = {
        'content': content,
        'type': type.toString().split('.').last,
        'category': category.toString().split('.').last,
        'privacy': privacy.toString().split('.').last,
        'tags': tags,
        'mentions': mentions.map((m) => m.toJson()).toList(),
        'mediaUrls': uploadedMedia.map((m) => m.url).toList(),
        'mediaTypes': uploadedMedia.map((m) => m.type).toList(),
        'location': location,
        'isPublic': privacy == PostPrivacy.public,
        'allowComments': true,
      };

      // Create post via backend API
      await createPost(postData);

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

  /// Get showcase posts with pagination and filtering
  Future<List<ShowcasePostModel>> getShowcasePosts({
    int limit = 10,
    String? lastPostId,
    PostPrivacy? privacy,
    PostCategory? category,
    String? userId,
  }) async {
    try {
      final response = await _supabase
          .from('showcase_posts')
          .select('''
            *,
            profiles:user_id (
              name,
              profile_picture_url
            )
          ''')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(limit);
      
      return response.map<ShowcasePostModel>((post) => 
          ShowcasePostModel.fromJson(post)).toList();
      // final response = await SupabaseConfig.from('showcase_posts')
      //     .select()
      //     .order('createdAt', ascending: false)
      //     .limit(limit);
      // return response.map((post) =>
      //     ShowcasePostModel.fromJson(post as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting showcase posts: $e');
      return [];
    }
  }

  /// Get showcase posts as a stream
  Stream<List<ShowcasePostModel>> getShowcasePostsStream({
    int limit = 10,
    PostPrivacy? privacy,
    PostCategory? category,
    String? userId,
  }) {
    try {
      dynamic query = _supabase
          .from('showcase_posts')
          .select('''
            *,
            profiles:user_id (
              name,
              profile_picture_url
            )
          ''');

      // Apply filters before ordering and limiting
      if (privacy != null) {
        query = query.eq('is_public', privacy == PostPrivacy.public);
      }
      if (category != null) {
        query = query.eq('category', category.toString().split('.').last);
      }
      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      // Apply ordering and limiting after filters
      final finalQuery = query.order('created_at', ascending: false).limit(limit);

      return finalQuery.asStream().map((data) => 
        data.map<ShowcasePostModel>((post) => 
          ShowcasePostModel.fromJson(post)).toList());
    } catch (e) {
      debugPrint('Error getting showcase posts stream: $e');
      return Stream.value([]);
    }
  }

  /// Delete media file from storage
  Future<void> deleteMediaFile(String mediaUrl) async {
    try {
      // Extract filename from URL
      final uri = Uri.parse(mediaUrl);
      final fileName = uri.pathSegments.last;
      
      // Delete from Supabase Storage
      await _supabase.storage.from('showcase-media').remove([fileName]);
      
      debugPrint('ShowcaseService: Media file deleted successfully: $fileName');
    } catch (e) {
      debugPrint('Error deleting media file: $e');
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
  // These methods were previously using Firebase transactions and need to be migrated

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
      
      debugPrint('ShowcaseService: Comment added successfully to post: $postId');
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
      // Use RPC function to increment view count atomically
      await _supabase.rpc('increment_view_count', params: {'post_id': postId});
      
      debugPrint('ShowcaseService: View count incremented for post: $postId');
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
      final response = await _supabase.from('post_comments').insert({
        'post_id': postId,
        'user_id': userId,
        'content': content,
        'parent_comment_id': parentCommentId,
        'mentions': mentions.map((m) => m.toJson()).toList(),
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();
      
      final commentId = response['id'].toString();
      debugPrint('ShowcaseService: Extended comment added successfully: $commentId');
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
      await _supabase
          .from('post_comments')
          .update({
            'content': content,
            'updated_at': DateTime.now().toIso8601String(),
            'is_edited': true,
          })
          .eq('id', commentId);
      
      debugPrint('ShowcaseService: Comment updated successfully: $commentId');
    } catch (e) {
      debugPrint('Error updating comment: $e');
      rethrow;
    }
  }

  /// Delete comment (for compatibility)
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _supabase
          .from('post_comments')
          .delete()
          .eq('id', commentId);
      
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
}
