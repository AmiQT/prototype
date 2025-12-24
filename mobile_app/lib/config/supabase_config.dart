import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
// Removed debug config for production

class SupabaseConfig {
  // Supabase configuration
  static const String supabaseUrl = 'https://xibffemtpboiecpeynon.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhpYmZmZW10cGJvaWVjcGV5bm9uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU1ODkzOTYsImV4cCI6MjA3MTE2NTM5Nn0.mwQndhu5_uX26T-qTEOCiLya74DUD6Iw8vV3ffuA5mM';

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
      );

      if (kDebugMode) {
        // debugPrint('Supabase initialized successfully');
        // debugPrint('Supabase URL: $supabaseUrl');
        // debugPrint('Supabase Anon Key: ${supabaseAnonKey.substring(0, 20)}...');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to initialize Supabase: $e');
      }
      rethrow;
    }
  }

  static SupabaseClient get client {
    return Supabase.instance.client;
  }

  // Helper getters for common operations
  static GoTrueClient get auth => client.auth;
  static SupabaseQueryBuilder from(String table) => client.from(table);
  static SupabaseStorageClient get storage => client.storage;
}
