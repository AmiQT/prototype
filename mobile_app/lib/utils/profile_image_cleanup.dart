import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'debug_config.dart';

class ProfileImageCleanup {
  static Future<void> cleanupPlaceholderUrls() async {
    try {
      DebugConfig.logInit('Starting cleanup of placeholder URLs...');

      // Get all profiles with placeholder URLs
      final response = await SupabaseConfig.client
          .from('profiles')
          .select('id, full_name, profile_image_url')
          .like('profile_image_url', '%placeholder.com%');

      if (response == null || response.isEmpty) {
        DebugConfig.logInfo('No placeholder URLs found');
        return;
      }

      DebugConfig.logInfo(
          'Found ${response.length} profiles with placeholder URLs');

      int cleanedCount = 0;
      for (final profile in response) {
        try {
          // Update profile to remove placeholder URL
          await SupabaseConfig.client
              .from('profiles')
              .update({'profile_image_url': null}).eq('id', profile['id']);

          DebugConfig.logInfo(
              'Cleaned up profile for ${profile['full_name']} (ID: ${profile['id']})');
          cleanedCount++;
        } catch (e) {
          DebugConfig.logWarning(
              'Failed to clean up profile ${profile['id']}: $e');
        }
      }

      DebugConfig.logInfo(
          'Cleanup completed successfully. Cleaned $cleanedCount profiles.');
    } catch (e) {
      DebugConfig.logError('Error during cleanup: $e');
    }
  }

  /// Check if URL is a placeholder
  static bool isPlaceholderUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    final placeholderDomains = [
      'via.placeholder.com',
      'placeholder.com',
      'dummyimage.com',
      'placehold.it',
    ];

    return placeholderDomains.any((domain) => url.contains(domain));
  }
}
