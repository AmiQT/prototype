import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import '../models/showcase_models.dart';
import '../models/post_creation_models.dart';
import '../utils/media_utils.dart';
import '../models/user_model.dart';
import '../models/profile_model.dart';

class ShowcaseService {
  final CollectionReference showcaseCollection =
      FirebaseFirestore.instance.collection('showcase_posts');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Storage paths
  static const String _imagesPath = 'showcase_images';
  static const String _videosPath = 'showcase_videos';
  static const String _thumbnailsPath = 'showcase_thumbnails';

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
      await showcaseCollection.add({
        ...postData,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'likes': [],
        'comments': [],
      });
    } catch (e) {
      debugPrint('Error creating showcase post: $e');
      rethrow;
    }
  }

  /// Get all showcase posts
  Future<List<Map<String, dynamic>>> getAllPosts() async {
    try {
      final querySnapshot =
          await showcaseCollection.orderBy('createdAt', descending: true).get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      debugPrint('Error fetching showcase posts: $e');
      return [];
    }
  }

  /// Upload post image to Firebase Storage
  Future<String> uploadPostImage(String userId, File file) async {
    try {
      final fileName =
          'showcase_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('showcase_images')
          .child(fileName);

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading showcase image: $e');
      rethrow;
    }
  }

  /// Delete a showcase post
  Future<void> deletePost(String postId) async {
    try {
      await showcaseCollection.doc(postId).delete();
    } catch (e) {
      debugPrint('Error deleting showcase post: $e');
      rethrow;
    }
  }

  /// Get posts by user ID
  Future<List<Map<String, dynamic>>> getPostsByUserId(String userId) async {
    try {
      final querySnapshot = await showcaseCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
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

      File? processedFile;
      File? thumbnailFile;
      String? thumbnailUrl;

      // Process based on media type
      if (validation.mediaType == 'image') {
        // Compress image
        processedFile = await MediaUtils.compressImage(file);
        processedFile ??= file; // Use original if compression fails
      } else if (validation.mediaType == 'video') {
        // Compress video
        processedFile = await MediaUtils.compressVideo(file);
        processedFile ??= file; // Use original if compression fails

        // Generate thumbnail
        thumbnailFile = await MediaUtils.generateVideoThumbnail(file);
        if (thumbnailFile != null) {
          thumbnailUrl = await _uploadFileToStorage(
            file: thumbnailFile,
            path: _thumbnailsPath,
            fileName: 'thumb_$mediaId.jpg',
            onProgress: null, // No progress for thumbnail
          );
        }
      }

      if (processedFile == null) {
        throw Exception('Failed to process media file');
      }

      // Upload main media file
      final storagePath =
          validation.mediaType == 'image' ? _imagesPath : _videosPath;
      final extension = file.path.split('.').last;
      final fileName =
          '${mediaId}_${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      final downloadUrl = await _uploadFileToStorage(
        file: processedFile,
        path: storagePath,
        fileName: fileName,
        onProgress: onProgress,
      );

      // Create MediaModel
      return MediaModel(
        id: mediaId,
        url: downloadUrl,
        type: validation.mediaType!,
        thumbnailUrl: thumbnailUrl,
        duration: validation.duration,
        aspectRatio: validation.aspectRatio,
        fileSize: validation.fileSize,
        uploadedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error uploading single media file: $e');
      return null;
    }
  }

  /// Upload file to Firebase Storage with progress tracking
  Future<String> _uploadFileToStorage({
    required File file,
    required String path,
    required String fileName,
    Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child(path).child(fileName);
      final uploadTask = ref.putFile(file);

      // Track upload progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
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

  /// Create showcase post with media
  Future<PostCreationResult> createShowcasePost({
    required String userId,
    required String userName,
    String? userProfileImage,
    String? userRole,
    String? userDepartment,
    String? userHeadline,
    required String content,
    List<File> mediaFiles = const [],
    PostCategory category = PostCategory.general,
    PostPrivacy privacy = PostPrivacy.public,
    List<String> tags = const [],
    List<MentionModel> mentions = const [],
    String? location,
    Function(Map<String, MediaUploadProgress> progressMap)? onUploadProgress,
  }) async {
    try {
      // Upload media files if any
      List<MediaModel> uploadedMedia = [];
      if (mediaFiles.isNotEmpty) {
        uploadedMedia = await batchUploadMedia(
          files: mediaFiles,
          userId: userId,
          onBatchProgress: onUploadProgress,
        );
      }

      // Determine post type
      PostType postType = PostType.text;
      if (uploadedMedia.isNotEmpty && content.trim().isNotEmpty) {
        postType = PostType.mixed;
      } else if (uploadedMedia.isNotEmpty) {
        final hasVideos = uploadedMedia.any((m) => m.type == 'video');
        postType = hasVideos ? PostType.video : PostType.image;
      }

      // Create post model
      final post = ShowcasePostModel(
        id: '', // Will be set by Firestore
        userId: userId,
        userName: userName,
        userProfileImage: userProfileImage,
        userRole: userRole,
        userDepartment: userDepartment,
        userHeadline: userHeadline,
        content: content,
        type: postType,
        category: category,
        privacy: privacy,
        media: uploadedMedia,
        tags: tags,
        mentions: mentions,
        location: location,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      final docRef = await showcaseCollection.add(post.toJson());
      final savedPost = post.copyWith(id: docRef.id);

      return PostCreationResult.success(
        postId: docRef.id,
        post: savedPost,
      );
    } catch (e) {
      debugPrint('Error creating showcase post: $e');
      return PostCreationResult.failure(error: e.toString());
    }
  }

  /// Get showcase posts with real-time updates
  Stream<List<ShowcasePostModel>> getShowcasePostsStream({
    int limit = 20,
    String? lastPostId,
    PostPrivacy? privacy,
    PostCategory? category,
    String? userId,
  }) {
    try {
      Query query = showcaseCollection.orderBy('createdAt', descending: true);

      // Apply filters
      if (privacy != null) {
        query = query.where('privacy',
            isEqualTo: privacy.toString().split('.').last);
      }
      if (category != null) {
        query = query.where('category',
            isEqualTo: category.toString().split('.').last);
      }
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      // Apply pagination
      if (lastPostId != null) {
        query = query.startAfter([lastPostId]);
      }

      query = query.limit(limit);

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return ShowcasePostModel.fromJson(data);
        }).toList();
      });
    } catch (e) {
      debugPrint('Error getting showcase posts stream: $e');
      return Stream.value([]);
    }
  }

  /// Delete media file from storage
  Future<void> deleteMediaFile(String mediaUrl) async {
    try {
      final ref = _storage.refFromURL(mediaUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting media file: $e');
      // Don't rethrow - file might already be deleted
    }
  }

  /// Delete post and associated media
  Future<void> deletePostWithMedia(String postId) async {
    try {
      // Get post data first
      final doc = await showcaseCollection.doc(postId).get();
      if (!doc.exists) return;

      final post = ShowcasePostModel.fromJson({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      });

      // Delete associated media files
      for (final media in post.media) {
        await deleteMediaFile(media.url);
        if (media.thumbnailUrl != null) {
          await deleteMediaFile(media.thumbnailUrl!);
        }
      }

      // Delete post document
      await showcaseCollection.doc(postId).delete();
    } catch (e) {
      debugPrint('Error deleting post with media: $e');
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

  /// Toggle like on a post
  Future<void> toggleLike(String postId, String userId) async {
    try {
      final postRef = showcaseCollection.doc(postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final data = postDoc.data() as Map<String, dynamic>;
        final likes = List<String>.from(data['likes'] ?? []);

        if (likes.contains(userId)) {
          // Unlike
          likes.remove(userId);
        } else {
          // Like
          likes.add(userId);
        }

        transaction.update(postRef, {
          'likes': likes,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('Like toggled successfully for post: $postId');
    } catch (e) {
      debugPrint('Error toggling like: $e');
      rethrow;
    }
  }

  /// Add a comment to a post
  Future<String> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userProfileImage,
    required String content,
    String? parentCommentId,
    List<MentionModel> mentions = const [],
  }) async {
    try {
      final commentId = FirebaseFirestore.instance.collection('temp').doc().id;

      final comment = CommentModel(
        id: commentId,
        postId: postId,
        userId: userId,
        userName: userName,
        userProfileImage: userProfileImage,
        content: content,
        parentCommentId: parentCommentId,
        mentions: mentions,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final postRef = showcaseCollection.doc(postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final data = postDoc.data() as Map<String, dynamic>;
        final comments =
            List<Map<String, dynamic>>.from(data['comments'] ?? []);

        comments.add(comment.toJson());

        transaction.update(postRef, {
          'comments': comments,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('Comment added successfully: $commentId');
      return commentId;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  /// Update a comment
  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String content,
    List<MentionModel> mentions = const [],
  }) async {
    try {
      final postRef = showcaseCollection.doc(postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final data = postDoc.data() as Map<String, dynamic>;
        final comments =
            List<Map<String, dynamic>>.from(data['comments'] ?? []);

        final commentIndex = comments.indexWhere((c) => c['id'] == commentId);
        if (commentIndex == -1) {
          throw Exception('Comment not found');
        }

        comments[commentIndex] = {
          ...comments[commentIndex],
          'content': content,
          'mentions': mentions.map((m) => m.toJson()).toList(),
          'updatedAt': DateTime.now().toIso8601String(),
          'isEdited': true,
        };

        transaction.update(postRef, {
          'comments': comments,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('Comment updated successfully: $commentId');
    } catch (e) {
      debugPrint('Error updating comment: $e');
      rethrow;
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      final postRef = showcaseCollection.doc(postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final data = postDoc.data() as Map<String, dynamic>;
        final comments =
            List<Map<String, dynamic>>.from(data['comments'] ?? []);

        // Remove the comment and its replies
        comments.removeWhere(
            (c) => c['id'] == commentId || c['parentCommentId'] == commentId);

        transaction.update(postRef, {
          'comments': comments,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('Comment deleted successfully: $commentId');
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      rethrow;
    }
  }

  /// Toggle like on a comment
  Future<void> toggleCommentLike(
      String postId, String commentId, String userId) async {
    try {
      final postRef = showcaseCollection.doc(postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final data = postDoc.data() as Map<String, dynamic>;
        final comments =
            List<Map<String, dynamic>>.from(data['comments'] ?? []);

        final commentIndex = comments.indexWhere((c) => c['id'] == commentId);
        if (commentIndex == -1) {
          throw Exception('Comment not found');
        }

        final likes = List<String>.from(comments[commentIndex]['likes'] ?? []);

        if (likes.contains(userId)) {
          likes.remove(userId);
        } else {
          likes.add(userId);
        }

        comments[commentIndex] = {
          ...comments[commentIndex],
          'likes': likes,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        transaction.update(postRef, {
          'comments': comments,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('Comment like toggled successfully: $commentId');
    } catch (e) {
      debugPrint('Error toggling comment like: $e');
      rethrow;
    }
  }

  /// Add share to a post
  Future<void> sharePost(String postId, String userId) async {
    try {
      final postRef = showcaseCollection.doc(postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final data = postDoc.data() as Map<String, dynamic>;
        final shares = List<String>.from(data['shares'] ?? []);

        if (!shares.contains(userId)) {
          shares.add(userId);

          transaction.update(postRef, {
            'shares': shares,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      debugPrint('Post shared successfully: $postId');
    } catch (e) {
      debugPrint('Error sharing post: $e');
      rethrow;
    }
  }

  /// Increment view count
  Future<void> incrementViewCount(String postId) async {
    try {
      final postRef = showcaseCollection.doc(postId);

      await postRef.update({
        'viewCount': FieldValue.increment(1),
      });

      debugPrint('View count incremented for post: $postId');
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
      // Don't rethrow for view count errors
    }
  }
}
