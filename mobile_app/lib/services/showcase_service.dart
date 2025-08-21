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

  // Supabase configuration - Firebase removed
  // TODO: Implement with Supabase tables and storage

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
      debugPrint(
          'ShowcaseService: Attempting to create post at $baseUrl/api/showcase/');
      debugPrint('ShowcaseService: Post data: ${json.encode(postData)}');

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final requestBody = {
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
      };

      debugPrint('ShowcaseService: Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/showcase/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode(requestBody),
      );

      debugPrint('ShowcaseService: Response status: ${response.statusCode}');
      debugPrint('ShowcaseService: Response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            'Failed to create post: ${response.statusCode} - ${response.body}');
      } else {
        debugPrint('ShowcaseService: Post created successfully!');
      }
    } catch (e) {
      debugPrint('Error creating showcase post: $e');
      rethrow;
    }
  }

  /// Get all showcase posts
  Future<List<Map<String, dynamic>>> getAllPosts() async {
    try {
      debugPrint(
          'ShowcaseService: Attempting to fetch posts from $baseUrl/api/showcase/');

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/showcase/'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> posts = json.decode(response.body);
        return posts.map((post) => post as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to fetch posts: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching showcase posts: $e');
      return [];
    }
  }

  /// Update a showcase post
  Future<void> updatePost(
      String postId, Map<String, dynamic> updatedData) async {
    try {
      // TODO: Implement with Supabase
      debugPrint('Post update not yet implemented with Supabase: $postId');
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
      // TODO: Implement with Supabase
      debugPrint('Post deletion not yet implemented with Supabase: $postId');
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
      // TODO: Implement with Supabase
      debugPrint('Get user posts not yet implemented with Supabase: $userId');
      return [];
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
      // TODO: Implement with Supabase Storage
      debugPrint('File upload not yet implemented with Supabase Storage');
      // final response = await SupabaseConfig.storage
      //     .from(path)
      //     .upload(fileName, file);
      // return SupabaseConfig.storage.from(path).getPublicUrl(fileName);
      return 'placeholder_url'; // Temporary placeholder
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
      // TODO: Implement with Supabase
      debugPrint('Get showcase posts not yet implemented with Supabase');
      return [];
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
      // TODO: Implement with Supabase
      debugPrint('Showcase posts stream not yet implemented with Supabase');
      return Stream.value([]);
      // final response = await SupabaseConfig.from('showcase_posts')
      //     .select()
      //     .order('createdAt', ascending: false)
      //     .limit(limit);
      // return Stream.value(response.map((post) =>
      //     ShowcasePostModel.fromJson(post as Map<String, dynamic>)).toList());
    } catch (e) {
      debugPrint('Error getting showcase posts stream: $e');
      return Stream.value([]);
    }
  }

  /// Delete media file from storage
  Future<void> deleteMediaFile(String mediaUrl) async {
    try {
      // TODO: Implement with Supabase Storage
      debugPrint(
          'Media file deletion not yet implemented with Supabase Storage');
      // await SupabaseConfig.storage.from('showcase_media').remove([mediaUrl]);
    } catch (e) {
      debugPrint('Error deleting media file: $e');
      // Don't rethrow - file might already be deleted
    }
  }

  /// Delete showcase post via backend API
  Future<void> deleteShowcasePost(String postId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/showcase/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('ShowcaseService: Post deleted successfully: $postId');
      } else if (response.statusCode == 404) {
        throw Exception('Post not found or not authorized');
      } else {
        throw Exception(
            'Failed to delete post: ${response.statusCode} - ${response.body}');
      }
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

  // TODO: Implement all social interaction methods with Supabase
  // These methods were previously using Firebase transactions and need to be migrated

  /// Like a post
  Future<void> likePost(String postId, String userId) async {
    try {
      // TODO: Implement with Supabase
      debugPrint('Like post not yet implemented with Supabase');
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
      // TODO: Implement with Supabase
      debugPrint('Unlike post not yet implemented with Supabase');
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
      // TODO: Implement with Supabase
      debugPrint('Add comment not yet implemented with Supabase');
      // await SupabaseConfig.from('comments').insert({
      //   'postId': postId,
      //   'userId': userId,
      //   'content': content,
      //   'createdAt': DateTime.now().toIso8601String(),
      // });
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  /// Share a post
  Future<void> sharePost(String postId, String userId) async {
    try {
      // TODO: Implement with Supabase
      debugPrint('Share post not yet implemented with Supabase');
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
      // TODO: Implement with Supabase
      debugPrint('Increment view count not yet implemented with Supabase');
      // await SupabaseConfig.from('showcase_posts')
      //     .update({'viewCount': SupabaseConfig.sql('viewCount + 1')})
      //     .eq('id', postId);
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
      rethrow;
    }
  }

  // ==================== COMPATIBILITY METHODS ====================
  // These methods are added for compatibility with existing UI code

  /// Toggle like on a post (alias for likePost/unlikePost)
  Future<void> toggleLike(String postId, String userId) async {
    try {
      // TODO: Check if user already liked the post
      await likePost(postId, userId);
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
      await addComment(postId, userId, content);
      return 'comment_id'; // TODO: Return actual comment ID
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
      // TODO: Implement with Supabase
      debugPrint('Update comment not yet implemented with Supabase');
    } catch (e) {
      debugPrint('Error updating comment: $e');
      rethrow;
    }
  }

  /// Delete comment (for compatibility)
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      // TODO: Implement with Supabase
      debugPrint('Delete comment not yet implemented with Supabase');
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      rethrow;
    }
  }

  /// Toggle comment like (for compatibility)
  Future<void> toggleCommentLike(
      String postId, String commentId, String userId) async {
    try {
      // TODO: Implement with Supabase
      debugPrint('Toggle comment like not yet implemented with Supabase');
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
