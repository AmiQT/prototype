#!/usr/bin/env python3
"""
Complete Firebase Removal Script
This script removes all Firebase dependencies from the Flutter project
"""

import os
import re
import shutil

# Files to completely remove
FILES_TO_REMOVE = [
    "mobile_app/firebase.json",
    "mobile_app/firestore.rules", 
    "mobile_app/firestore.dev.rules",
    "mobile_app/firestore.indexes.json",
    "mobile_app/lib/firebase_options.dart",
    "mobile_app/android/app/google-services.json",
    "firebase.json",
    "firestore.indexes.json", 
    ".firebaserc"
]

# Firebase imports to remove/comment out
FIREBASE_IMPORTS = [
    "import 'package:firebase_core/firebase_core.dart';",
    "import 'package:firebase_auth/firebase_auth.dart';",
    "import 'package:cloud_firestore/cloud_firestore.dart';",
    "import 'package:firebase_storage/firebase_storage.dart';",
    "import 'package:google_sign_in/google_sign_in.dart';",
    "import 'firebase_options.dart';"
]

# Services that need major refactoring (will be marked for Supabase migration)
SERVICES_TO_REFACTOR = [
    "mobile_app/lib/services/auth_service.dart",
    "mobile_app/lib/services/showcase_service.dart", 
    "mobile_app/lib/services/achievement_service.dart",
    "mobile_app/lib/services/notification_service.dart",
    "mobile_app/lib/services/enhanced_chat_service.dart",
    "mobile_app/lib/services/conversation_service.dart",
    "mobile_app/lib/services/content_moderation_service.dart",
    "mobile_app/lib/services/auto_notification_service.dart",
    "mobile_app/lib/services/settings_service.dart"
]

def remove_files():
    """Remove Firebase configuration files"""
    print("🗑️  Removing Firebase configuration files...")
    
    for file_path in FILES_TO_REMOVE:
        if os.path.exists(file_path):
            try:
                os.remove(file_path)
                print(f"   ✅ Removed: {file_path}")
            except Exception as e:
                print(f"   ❌ Failed to remove {file_path}: {e}")
        else:
            print(f"   ⚠️  File not found: {file_path}")

def comment_firebase_imports(file_path):
    """Comment out Firebase imports in a file"""
    if not os.path.exists(file_path):
        return False
        
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        modified = False
        for import_line in FIREBASE_IMPORTS:
            if import_line in content and not content.startswith('//'):
                content = content.replace(import_line, f"// {import_line} // REMOVED: Firebase migration")
                modified = True
        
        if modified:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
            
    except Exception as e:
        print(f"   ❌ Error processing {file_path}: {e}")
    
    return False

def add_migration_header(file_path):
    """Add migration notice to service files"""
    if not os.path.exists(file_path):
        return
        
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        migration_header = '''/*
 * 🚧 FIREBASE MIGRATION IN PROGRESS 🚧
 * This service is being migrated from Firebase to Supabase
 * Some functionality may be temporarily disabled
 * TODO: Complete Supabase integration
 */

'''
        
        if "🚧 FIREBASE MIGRATION IN PROGRESS 🚧" not in content:
            content = migration_header + content
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"   ✅ Added migration header to: {file_path}")
            
    except Exception as e:
        print(f"   ❌ Error adding header to {file_path}: {e}")

def process_dart_files():
    """Process all Dart files to remove Firebase imports"""
    print("\n📝 Processing Dart files...")
    
    dart_files = []
    for root, dirs, files in os.walk("mobile_app/lib"):
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    
    for file_path in dart_files:
        if comment_firebase_imports(file_path):
            print(f"   ✅ Updated imports in: {file_path}")
    
    # Add migration headers to service files
    print("\n🏷️  Adding migration headers to service files...")
    for service_file in SERVICES_TO_REFACTOR:
        add_migration_header(service_file)

def create_supabase_placeholder():
    """Create placeholder for Supabase configuration"""
    print("\n🔧 Creating Supabase configuration placeholder...")
    
    supabase_config = '''import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // TODO: Add your Supabase configuration
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}
'''
    
    try:
        os.makedirs("mobile_app/lib/config", exist_ok=True)
        with open("mobile_app/lib/config/supabase_config.dart", 'w') as f:
            f.write(supabase_config)
        print("   ✅ Created: mobile_app/lib/config/supabase_config.dart")
    except Exception as e:
        print(f"   ❌ Error creating Supabase config: {e}")

def main():
    print("🚀 Starting Firebase to Supabase Migration...")
    print("=" * 50)
    
    # Step 1: Remove Firebase files
    remove_files()
    
    # Step 2: Process Dart files
    process_dart_files()
    
    # Step 3: Create Supabase placeholder
    create_supabase_placeholder()
    
    print("\n" + "=" * 50)
    print("✅ Firebase removal completed!")
    print("\n📋 Next steps:")
    print("1. Update pubspec.yaml with the new dependencies")
    print("2. Run 'flutter pub get'")
    print("3. Configure Supabase settings")
    print("4. Update service files to use Supabase")
    print("5. Test the application")

if __name__ == "__main__":
    main()