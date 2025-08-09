import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/showcase_models.dart';
import '../models/post_creation_models.dart';
import '../utils/media_utils.dart';
import 'showcase_service.dart';

/// Comprehensive media upload manager for handling complex upload workflows
class MediaUploadManager {
  final ShowcaseService _showcaseService = ShowcaseService();

  // Upload state tracking
  final Map<String, PostCreationState> _uploadStates = {};
  final Map<String, StreamController<PostCreationState>> _stateControllers = {};

  // Singleton pattern
  static final MediaUploadManager _instance = MediaUploadManager._internal();
  factory MediaUploadManager() => _instance;
  MediaUploadManager._internal();

  /// Get upload state stream for a specific upload session
  Stream<PostCreationState> getUploadStateStream(String sessionId) {
    if (!_stateControllers.containsKey(sessionId)) {
      _stateControllers[sessionId] =
          StreamController<PostCreationState>.broadcast();
    }
    return _stateControllers[sessionId]!.stream;
  }

  /// Start a new upload session
  String startUploadSession() {
    final sessionId = 'upload_${DateTime.now().millisecondsSinceEpoch}';
    _uploadStates[sessionId] = PostCreationState();
    return sessionId;
  }

  /// Update upload state and notify listeners
  void _updateUploadState(String sessionId, PostCreationState state) {
    _uploadStates[sessionId] = state;
    final controller = _stateControllers[sessionId];
    if (controller != null && !controller.isClosed) {
      controller.add(state);
    }
  }

  /// Validate and prepare media files for upload
  Future<MediaValidationResult> validateMediaFiles(List<File> files) async {
    try {
      if (files.isEmpty) {
        return MediaValidationResult(
            isValid: false, error: 'No files selected');
      }

      if (files.length > 10) {
        return MediaValidationResult(
            isValid: false, error: 'Maximum 10 files allowed per post');
      }

      int totalSize = 0;
      for (final file in files) {
        final validation = await MediaUtils.validateMediaFile(file);
        if (!validation.isValid) {
          return validation;
        }
        totalSize += validation.fileSize ?? 0;
      }

      // Check total size limit (500MB)
      const maxTotalSize = 500 * 1024 * 1024;
      if (totalSize > maxTotalSize) {
        return MediaValidationResult(
          isValid: false,
          error: 'Total file size exceeds 500MB limit',
        );
      }

      return MediaValidationResult(isValid: true);
    } catch (e) {
      return MediaValidationResult(
        isValid: false,
        error: 'Error validating files: $e',
      );
    }
  }

  /// Upload media files with comprehensive progress tracking
  Future<PostCreationResult> uploadPost({
    required String sessionId,
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
  }) async {
    try {
      // Initialize upload state
      _updateUploadState(
          sessionId,
          PostCreationState(
            content: content,
            selectedMedia: mediaFiles,
            tags: tags,
            category: category,
            privacy: privacy,
            location: location,
            mentionedUsers: mentions.map((m) => m.userId).toList(),
            isUploading: true,
            uploadProgress: 0.0,
          ));

      // Validate media files
      if (mediaFiles.isNotEmpty) {
        final validation = await validateMediaFiles(mediaFiles);
        if (!validation.isValid) {
          _updateUploadState(
              sessionId,
              _uploadStates[sessionId]!.copyWith(
                isUploading: false,
                error: validation.error,
              ));
          return PostCreationResult.failure(error: validation.error!);
        }
      }

      // Create post with progress tracking
      final result = await _showcaseService.createShowcasePost(
        userId: userId,
        userName: userName,
        userProfileImage: userProfileImage,
        userRole: userRole,
        userDepartment: userDepartment,
        userHeadline: userHeadline,
        content: content,
        mediaFiles: mediaFiles,
        category: category,
        privacy: privacy,
        tags: tags,
        mentions: mentions,
        location: location,
        onUploadProgress: (progressMap) {
          // Calculate overall progress
          double totalProgress = 0.0;
          for (final progress in progressMap.values) {
            totalProgress += progress.progress;
          }
          final overallProgress =
              progressMap.isNotEmpty ? totalProgress / progressMap.length : 1.0;

          _updateUploadState(
              sessionId,
              _uploadStates[sessionId]!.copyWith(
                uploadProgress: overallProgress,
              ));
        },
      );

      // Update final state
      if (result.success) {
        _updateUploadState(
            sessionId,
            _uploadStates[sessionId]!.copyWith(
              isUploading: false,
              uploadProgress: 1.0,
              error: null,
            ));
      } else {
        _updateUploadState(
            sessionId,
            _uploadStates[sessionId]!.copyWith(
              isUploading: false,
              error: result.error,
            ));
      }

      return result;
    } catch (e) {
      _updateUploadState(
          sessionId,
          _uploadStates[sessionId]!.copyWith(
            isUploading: false,
            error: e.toString(),
          ));
      return PostCreationResult.failure(error: e.toString());
    }
  }

  /// Prepare media files for upload (compress, validate, generate thumbnails)
  Future<List<File>> prepareMediaFiles(List<File> files) async {
    final List<File> preparedFiles = [];

    try {
      for (final file in files) {
        final validation = await MediaUtils.validateMediaFile(file);
        if (!validation.isValid) {
          throw Exception('Invalid file: ${validation.error}');
        }

        File? preparedFile;

        if (validation.mediaType == 'image') {
          // Compress image
          preparedFile = await MediaUtils.compressImage(file);
          preparedFile ??= file; // Use original if compression fails
        } else if (validation.mediaType == 'video') {
          // Compress video
          preparedFile = await MediaUtils.compressVideo(file);
          preparedFile ??= file; // Use original if compression fails
        } else {
          preparedFile = file;
        }

        preparedFiles.add(preparedFile);
      }

      return preparedFiles;
    } catch (e) {
      debugPrint('Error preparing media files: $e');
      rethrow;
    }
  }

  /// Get upload statistics
  Map<String, dynamic> getUploadStats(String sessionId) {
    final state = _uploadStates[sessionId];
    if (state == null) return {};

    return {
      'totalFiles': state.selectedMedia.length,
      'uploadProgress': state.uploadProgress,
      'isUploading': state.isUploading,
      'hasError': state.hasError,
      'canPost': state.canPost,
      'postType': state.postType.toString().split('.').last,
    };
  }

  /// Cancel upload session
  void cancelUploadSession(String sessionId) {
    _updateUploadState(
        sessionId,
        _uploadStates[sessionId]!.copyWith(
          isUploading: false,
          error: 'Upload cancelled by user',
        ));
  }

  /// Clean up upload session
  void cleanupSession(String sessionId) {
    _uploadStates.remove(sessionId);
    final controller = _stateControllers[sessionId];
    if (controller != null) {
      controller.close();
      _stateControllers.remove(sessionId);
    }
  }

  /// Clean up all sessions
  void cleanupAllSessions() {
    _uploadStates.clear();
    for (final controller in _stateControllers.values) {
      controller.close();
    }
    _stateControllers.clear();
  }

  /// Get current upload state
  PostCreationState? getUploadState(String sessionId) {
    return _uploadStates[sessionId];
  }

  /// Check if session is uploading
  bool isSessionUploading(String sessionId) {
    final state = _uploadStates[sessionId];
    return state?.isUploading ?? false;
  }

  /// Get all active sessions
  List<String> getActiveSessions() {
    return _uploadStates.keys.toList();
  }

  /// Dispose resources
  void dispose() {
    cleanupAllSessions();
    _showcaseService.dispose();
  }
}
