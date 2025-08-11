import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

Future<void> main() async {
  print('🔄 Starting profile migration...');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    final firestore = FirebaseFirestore.instance;
    
    // Get all profiles
    print('📋 Fetching all profiles...');
    final profilesSnapshot = await firestore.collection('profiles').get();
    print('📋 Found ${profilesSnapshot.docs.length} profiles');

    int migratedCount = 0;
    int skippedCount = 0;

    for (final doc in profilesSnapshot.docs) {
      final data = doc.data();
      final docId = doc.id;
      final userId = data['userId'] as String?;

      if (userId == null || userId.isEmpty) {
        print('⚠️  Skipping profile ${docId}: no userId found');
        skippedCount++;
        continue;
      }

      // Check if document ID is already the userId
      if (docId == userId) {
        print('✅ Profile ${docId} already migrated');
        skippedCount++;
        continue;
      }

      print('🔄 Migrating profile from ${docId} to ${userId}');

      // Check if target document already exists
      final targetDoc = await firestore.collection('profiles').doc(userId).get();
      if (targetDoc.exists) {
        print('⚠️  Target document ${userId} already exists, deleting old document ${docId}');
        await firestore.collection('profiles').doc(docId).delete();
        skippedCount++;
        continue;
      }

      // Create new document with userId as document ID
      await firestore.collection('profiles').doc(userId).set(data);
      print('✅ Created new document with ID: ${userId}');

      // Delete old document
      await firestore.collection('profiles').doc(docId).delete();
      print('🗑️  Deleted old document: ${docId}');

      migratedCount++;
    }

    print('\n🎉 Migration completed!');
    print('📊 Migrated: ${migratedCount}');
    print('📊 Skipped: ${skippedCount}');
    print('📊 Total: ${profilesSnapshot.docs.length}');

  } catch (e) {
    print('❌ Error during migration: $e');
    exit(1);
  }
}
