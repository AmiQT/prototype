import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'network_service.dart';

class ImageOptimizationService {
  static final ImageOptimizationService _instance = ImageOptimizationService._internal();
  factory ImageOptimizationService() => _instance;
  ImageOptimizationService._internal();

  final NetworkService _networkService = NetworkService();
  Directory? _cacheDir;

  Future<void> initialize() async {
    final tempDir = await getTemporaryDirectory();
    _cacheDir = Directory('${tempDir.path}/image_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    debugPrint('🖼️ Image optimization service initialized');
  }

  // Optimize image based on network conditions
  Future<File> optimizeImage(File originalFile) async {
    if (_cacheDir == null) await initialize();

    try {
      // Read original image
      final bytes = await originalFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      
      if (originalImage == null) {
        throw Exception('Could not decode image');
      }

      // Get optimization settings based on network
      final settings = _getOptimizationSettings();
      
      // Resize image if needed
      img.Image optimizedImage = originalImage;
      
      if (originalImage.width > settings.maxWidth || originalImage.height > settings.maxHeight) {
        optimizedImage = img.copyResize(
          originalImage,
          width: settings.maxWidth,
          height: settings.maxHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode with appropriate quality
      final optimizedBytes = img.encodeJpg(optimizedImage, quality: settings.quality);
      
      // Save optimized image
      final optimizedFile = File('${_cacheDir!.path}/optimized_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await optimizedFile.writeAsBytes(optimizedBytes);
      
      final originalSize = bytes.length;
      final optimizedSize = optimizedBytes.length;
      final compressionRatio = ((originalSize - optimizedSize) / originalSize * 100).toStringAsFixed(1);
      
      debugPrint('🖼️ Image optimized: ${_formatBytes(originalSize)} → ${_formatBytes(optimizedSize)} ($compressionRatio% reduction)');
      
      return optimizedFile;
    } catch (e) {
      debugPrint('🖼️ Image optimization failed: $e');
      return originalFile; // Return original if optimization fails
    }
  }

  // Get optimization settings based on network
  ImageOptimizationSettings _getOptimizationSettings() {
    if (_networkService.isOnWifi) {
      return ImageOptimizationSettings.highQuality();
    } else {
      return ImageOptimizationSettings.mobileOptimized();
    }
  }

  // Create thumbnail for mobile data
  Future<File> createThumbnail(File originalFile, {int size = 150}) async {
    if (_cacheDir == null) await initialize();

    try {
      final bytes = await originalFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      
      if (originalImage == null) {
        throw Exception('Could not decode image');
      }

      // Create square thumbnail
      final thumbnail = img.copyResizeCropSquare(originalImage, size: size);
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 70);
      
      // Save thumbnail
      final thumbnailFile = File('${_cacheDir!.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await thumbnailFile.writeAsBytes(thumbnailBytes);
      
      debugPrint('🖼️ Thumbnail created: ${_formatBytes(thumbnailBytes.length)}');
      
      return thumbnailFile;
    } catch (e) {
      debugPrint('🖼️ Thumbnail creation failed: $e');
      return originalFile;
    }
  }

  // Progressive image loading for mobile data
  Future<List<File>> createProgressiveImages(File originalFile) async {
    if (_cacheDir == null) await initialize();

    try {
      final bytes = await originalFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      
      if (originalImage == null) {
        throw Exception('Could not decode image');
      }

      final List<File> progressiveImages = [];
      
      // Create low quality preview (for immediate display)
      final lowQuality = img.copyResize(originalImage, width: 100);
      final lowQualityBytes = img.encodeJpg(lowQuality, quality: 30);
      final lowQualityFile = File('${_cacheDir!.path}/low_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await lowQualityFile.writeAsBytes(lowQualityBytes);
      progressiveImages.add(lowQualityFile);
      
      // Create medium quality (for mobile data)
      if (_networkService.isOnMobile) {
        final mediumQuality = img.copyResize(originalImage, width: 400);
        final mediumQualityBytes = img.encodeJpg(mediumQuality, quality: 60);
        final mediumQualityFile = File('${_cacheDir!.path}/med_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await mediumQualityFile.writeAsBytes(mediumQualityBytes);
        progressiveImages.add(mediumQualityFile);
      }
      
      // Add original for WiFi
      if (_networkService.isOnWifi) {
        progressiveImages.add(originalFile);
      }
      
      debugPrint('🖼️ Created ${progressiveImages.length} progressive images');
      
      return progressiveImages;
    } catch (e) {
      debugPrint('🖼️ Progressive image creation failed: $e');
      return [originalFile];
    }
  }

  // Cache image with hash-based naming
  Future<File?> cacheImage(String url) async {
    if (_cacheDir == null) await initialize();

    try {
      // Generate cache key from URL
      final urlHash = md5.convert(utf8.encode(url)).toString();
      final cachedFile = File('${_cacheDir!.path}/cached_$urlHash.jpg');
      
      // Return cached file if exists
      if (await cachedFile.exists()) {
        debugPrint('🖼️ Image cache hit: $url');
        return cachedFile;
      }
      
      // Download and cache image
      // Note: You'll need to implement the actual download logic
      debugPrint('🖼️ Image cache miss: $url');
      return null;
    } catch (e) {
      debugPrint('🖼️ Image caching failed: $e');
      return null;
    }
  }

  // Clean old cached images
  Future<void> cleanCache({Duration maxAge = const Duration(days: 7)}) async {
    if (_cacheDir == null) await initialize();

    try {
      final files = await _cacheDir!.list().toList();
      final cutoffTime = DateTime.now().subtract(maxAge);
      int deletedCount = 0;
      int totalSize = 0;

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
          
          if (stat.modified.isBefore(cutoffTime)) {
            await file.delete();
            deletedCount++;
          }
        }
      }

      debugPrint('🖼️ Cache cleaned: $deletedCount files deleted, ${_formatBytes(totalSize)} total cache size');
    } catch (e) {
      debugPrint('🖼️ Cache cleaning failed: $e');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

// Image optimization settings
class ImageOptimizationSettings {
  final int maxWidth;
  final int maxHeight;
  final int quality;

  ImageOptimizationSettings({
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
  });

  factory ImageOptimizationSettings.highQuality() {
    return ImageOptimizationSettings(
      maxWidth: 1920,
      maxHeight: 1080,
      quality: 85,
    );
  }

  factory ImageOptimizationSettings.mobileOptimized() {
    return ImageOptimizationSettings(
      maxWidth: 800,
      maxHeight: 600,
      quality: 60,
    );
  }

  factory ImageOptimizationSettings.thumbnail() {
    return ImageOptimizationSettings(
      maxWidth: 200,
      maxHeight: 200,
      quality: 70,
    );
  }
}