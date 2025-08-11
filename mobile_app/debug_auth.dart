import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Quick authentication and permission diagnostic script
/// Run this to check your authentication status and permissions
void main() async {
  print('🔍 FIREBASE AUTHENTICATION & PERMISSION DIAGNOSTIC');
  print('==================================================\n');
  
  try {
    // Check current user
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      print('❌ ERROR: No user is currently authenticated');
      print('Please login to the app first, then run this diagnostic');
      return;
    }
    
    print('✅ User authenticated successfully!');
    print('📧 Email: ${user.email}');
    print('🆔 User ID: ${user.uid}');
    print('✅ Email verified: ${user.emailVerified}');
    print('🕐 Created: ${user.metadata.creationTime}');
    print('🕐 Last sign in: ${user.metadata.lastSignInTime}\n');
    
    // Test basic Firestore access
    print('🧪 Testing Firestore Access...\n');
    
    final firestore = FirebaseFirestore.instance;
    
    // Test 1: Try to read own user document
    print('Test 1: Reading own user document...');
    try {
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        print('✅ SUCCESS: Can read own user data');
        print('   - Name: ${userData['name'] ?? 'Not set'}');
        print('   - Role: ${userData['role'] ?? 'Not set'}');
        print('   - Department: ${userData['department'] ?? 'Not set'}');
      } else {
        print('⚠️  WARNING: User document does not exist in Firestore');
        print('   This might be why you\'re getting permission errors!');
      }
    } catch (e) {
      print('❌ FAILED: Cannot read own user data');
      print('   Error: $e');
    }
    
    // Test 2: Try to read events collection
    print('\nTest 2: Reading events collection...');
    try {
      final eventsQuery = await firestore.collection('events').limit(1).get();
      print('✅ SUCCESS: Can read events collection');
      print('   Found ${eventsQuery.docs.length} events');
    } catch (e) {
      print('❌ FAILED: Cannot read events collection');
      print('   Error: $e');
    }
    
    // Test 3: Try to read users collection
    print('\nTest 3: Reading users collection...');
    try {
      final usersQuery = await firestore.collection('users').limit(1).get();
      print('✅ SUCCESS: Can read users collection');
      print('   Found ${usersQuery.docs.length} users');
    } catch (e) {
      print('❌ FAILED: Cannot read users collection');
      print('   Error: $e');
    }
    
    // Test 4: Check authentication token
    print('\nTest 4: Checking authentication token...');
    try {
      final token = await user.getIdToken();
      print('✅ SUCCESS: Authentication token is valid');
      print('   Token length: ${token.length} characters');
    } catch (e) {
      print('❌ FAILED: Cannot get authentication token');
      print('   Error: $e');
    }
    
    print('\n🎯 DIAGNOSTIC SUMMARY:');
    print('======================');
    print('If you see FAILED messages above, that explains the permission errors.');
    print('The most common causes are:');
    print('1. User document missing in Firestore users collection');
    print('2. Authentication token issues');
    print('3. Firebase rules not matching the user structure');
    
  } catch (e) {
    print('❌ CRITICAL ERROR: Diagnostic failed');
    print('Error: $e');
  }
}
