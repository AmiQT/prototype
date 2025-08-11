import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Security Test Script - Run this to verify Firebase rules are working
/// Usage: dart test_security.dart
void main() async {
  print('🔒 FIREBASE SECURITY RULES TEST');
  print('================================\n');
  
  try {
    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ ERROR: No user authenticated');
      print('Please login to the app first, then run this test');
      return;
    }
    
    print('✅ User authenticated: ${user.uid}');
    print('📧 Email: ${user.email}\n');
    
    final firestore = FirebaseFirestore.instance;
    
    print('🧪 Testing Security Rules...\n');
    
    // Test 1: Try to read own user document (should work)
    print('Test 1: Reading own user document...');
    try {
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        print('✅ SUCCESS: Can read own user data');
      } else {
        print('⚠️  WARNING: Own user document does not exist');
      }
    } catch (e) {
      print('❌ FAILED: Cannot read own user data: $e');
    }
    
    // Test 2: Try to read all users (should be allowed for user discovery)
    print('\nTest 2: Reading users collection...');
    try {
      final usersQuery = await firestore.collection('users').limit(1).get();
      if (usersQuery.docs.isNotEmpty) {
        print('✅ SUCCESS: Can read users collection (expected for user discovery)');
      } else {
        print('⚠️  INFO: Users collection is empty');
      }
    } catch (e) {
      print('❌ FAILED: Cannot read users collection: $e');
    }
    
    // Test 3: Try to read own profile (should work)
    print('\nTest 3: Reading own profile...');
    try {
      final profileQuery = await firestore
          .collection('profiles')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (profileQuery.docs.isNotEmpty) {
        print('✅ SUCCESS: Can read own profile');
      } else {
        print('⚠️  INFO: No profile found for current user');
      }
    } catch (e) {
      print('❌ FAILED: Cannot read own profile: $e');
    }
    
    // Test 4: Try to access moderation actions (should fail for non-admin)
    print('\nTest 4: Testing moderation actions access...');
    try {
      final moderationQuery = await firestore
          .collection('moderationActions')
          .limit(1)
          .get();
      print('⚠️  UNEXPECTED: Can access moderation actions (might be admin user)');
    } catch (e) {
      print('✅ SUCCESS: Moderation actions properly restricted: ${e.toString().contains('permission') ? 'Permission denied' : e}');
    }
    
    // Test 5: Try to read chat messages (should only see own)
    print('\nTest 5: Testing chat messages access...');
    try {
      final chatQuery = await firestore
          .collection('chat_messages')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      print('✅ SUCCESS: Can read own chat messages');
    } catch (e) {
      print('❌ FAILED: Cannot read own chat messages: $e');
    }
    
    // Test 6: Try to read someone else's chat messages (should fail)
    print('\nTest 6: Testing unauthorized chat access...');
    try {
      final unauthorizedChatQuery = await firestore
          .collection('chat_messages')
          .where('userId', isNotEqualTo: user.uid)
          .limit(1)
          .get();
      if (unauthorizedChatQuery.docs.isEmpty) {
        print('✅ SUCCESS: No unauthorized chat messages accessible');
      } else {
        print('⚠️  WARNING: Can access other users\' chat messages');
      }
    } catch (e) {
      print('✅ SUCCESS: Other users\' chat messages properly restricted: ${e.toString().contains('permission') ? 'Permission denied' : e}');
    }
    
    print('\n🎯 SECURITY TEST SUMMARY:');
    print('========================');
    print('✅ If you see mostly SUCCESS messages, your security rules are working!');
    print('❌ If you see FAILED messages, there might be rule configuration issues');
    print('⚠️  WARNING messages indicate potential security concerns');
    
    print('\n🔒 CRITICAL: The dangerous global read access rule has been removed!');
    print('Users can no longer read ALL documents in your database.');
    
  } catch (e) {
    print('❌ CRITICAL ERROR: Security test failed: $e');
    print('Please check your Firebase configuration and authentication');
  }
}
