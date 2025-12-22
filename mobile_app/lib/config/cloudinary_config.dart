import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryConfig {
  // Cloudinary credentials - FIXED ✅
  // Get these from your Cloudinary Dashboard
  static const String _cloudName = 'dih1pbzsc';
  static const String _apiKey = '848267728692813';
  static const String _apiSecret = 'sDERekcUBCAlKLCKr9_Y2sudEG4';

  // Upload preset name - UPDATED ✅
  // Using the STAP-media preset with Unsigned mode
  static const String _uploadPreset = 'STAP-media';

  /// Upload image to Cloudinary using unsigned upload
  static Future<String> uploadImage({
    required String filePath,
    required String userId,
    String? folder,
    Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('CloudinaryConfig: Uploading image to Cloudinary...');

      // Read file as bytes
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // Create multipart request
      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add upload preset for unsigned uploads
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder ?? 'showcase_media/$userId';

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.path.split('/').last,
        ),
      );

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        final secureUrl = jsonResponse['secure_url'] as String;
        debugPrint('CloudinaryConfig: Image uploaded successfully: $secureUrl');
        return secureUrl;
      } else {
        throw Exception(
            'Upload failed: ${jsonResponse['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Failed to upload image to Cloudinary: $e');
    }
  }

  /// Upload video to Cloudinary
  static Future<String> uploadVideo({
    required String filePath,
    required String userId,
    String? folder,
    Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('CloudinaryConfig: Uploading video to Cloudinary...');

      // Read file as bytes
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // Create multipart request
      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/video/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add upload preset for unsigned uploads
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder ?? 'showcase_media/$userId';

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.path.split('/').last,
        ),
      );

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        final secureUrl = jsonResponse['secure_url'] as String;
        debugPrint('CloudinaryConfig: Video uploaded successfully: $secureUrl');
        return secureUrl;
      } else {
        throw Exception(
            'Upload failed: ${jsonResponse['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Failed to upload video to Cloudinary: $e');
    }
  }

  /// Upload image from bytes (for web/XFile compatibility)
  static Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String filename,
    required String userId,
    String? folder,
    Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('CloudinaryConfig: Uploading image bytes to Cloudinary...');

      // Create multipart request
      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add upload preset for unsigned uploads
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder ?? 'showcase_media/$userId';

      // Add file from bytes
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        final secureUrl = jsonResponse['secure_url'] as String;
        debugPrint(
            'CloudinaryConfig: Image bytes uploaded successfully: $secureUrl');
        return secureUrl;
      } else {
        throw Exception(
            'Upload failed: ${jsonResponse['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Failed to upload image bytes to Cloudinary: $e');
    }
  }

  /// Upload video from bytes (for web/XFile compatibility)
  static Future<String> uploadVideoBytes({
    required Uint8List bytes,
    required String filename,
    required String userId,
    String? folder,
    Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('CloudinaryConfig: Uploading video bytes to Cloudinary...');

      // Create multipart request
      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/video/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add upload preset for unsigned uploads
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder ?? 'showcase_media/$userId';

      // Add file from bytes
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        final secureUrl = jsonResponse['secure_url'] as String;
        debugPrint(
            'CloudinaryConfig: Video bytes uploaded successfully: $secureUrl');
        return secureUrl;
      } else {
        throw Exception(
            'Upload failed: ${jsonResponse['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Failed to upload video bytes to Cloudinary: $e');
    }
  }

  /// Delete file from Cloudinary using Admin API
  static Future<bool> deleteFile(String publicId) async {
    try {
      debugPrint('CloudinaryConfig: Deleting file from Cloudinary: $publicId');

      // Create delete request with authentication
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateSignature(publicId, timestamp);

      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy');
      final request = http.MultipartRequest('POST', uri);

      // Add authentication fields
      request.fields['public_id'] = publicId;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['api_key'] = _apiKey;
      request.fields['signature'] = signature;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200 && jsonResponse['result'] == 'ok') {
        debugPrint('CloudinaryConfig: File deleted successfully: $publicId');
        return true;
      } else {
        debugPrint(
            'CloudinaryConfig: Failed to delete file: ${jsonResponse['error']}');
        return false;
      }
    } catch (e) {
      debugPrint('CloudinaryConfig: Error deleting file: $e');
      return false;
    }
  }

  /// Generate signature for Cloudinary Admin API
  static String _generateSignature(String publicId, int timestamp) {
    // This is a simplified signature generation
    // In production, you should use proper HMAC-SHA1
    final params =
        'public_id=$publicId&timestamp=$timestamp&api_key=$_apiKey&api_secret=$_apiSecret';
    return params.hashCode.toString();
  }

  /// Get optimized image URL
  static String getOptimizedImageUrl(
    String originalUrl, {
    int width = 800,
    int height = 600,
    String quality = 'auto',
  }) {
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl;
    }

    // Add transformation parameters
    final baseUrl = originalUrl.split('/upload/')[0];
    final imagePath = originalUrl.split('/upload/')[1];

    return '$baseUrl/upload/c_fill,w_$width,h_$height,q_$quality/$imagePath';
  }

  /// Get thumbnail URL
  static String getThumbnailUrl(
    String originalUrl, {
    int width = 200,
    int height = 200,
  }) {
    return getOptimizedImageUrl(originalUrl, width: width, height: height);
  }

  /// Extract public ID from Cloudinary URL
  static String? getPublicId(String cloudinaryUrl) {
    if (!cloudinaryUrl.contains('cloudinary.com')) {
      return null;
    }

    try {
      final parts = cloudinaryUrl.split('/upload/');
      if (parts.length > 1) {
        final pathParts = parts[1].split('/');
        if (pathParts.length > 1) {
          return pathParts[1]; // Return the public ID
        }
      }
    } catch (e) {
      debugPrint('Error extracting public ID: $e');
    }

    return null;
  }
}
