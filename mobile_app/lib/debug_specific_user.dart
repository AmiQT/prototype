import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Specific diagnostic for user OVzcnuGCaFZfbNxrxLsvlQsTnvr1
/// Run this to check the exact issue with your user document
void main() async {
  print('🔍 SPECIFIC USER DIAGNOSTIC');
  print('==========================\n');
  
  const targetUserId = 'OVzcnuGCaFZfbNxrxLsvlQsTnvr1';
  
  try {
    // Check current authenticated user
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      print('❌ ERROR: No user is currently authenticated');
      print('Please login to the app first');
      return;
    }
    
    print('✅ Current authenticated user: ${currentUser.uid}');
    print('📧 Email: ${currentUser.email}');
    
    if (currentUser.uid != targetUserId) {
      print('⚠️  WARNING: You are logged in as a different user!');
      print('   Expected: $targetUserId');
      print('   Actual: ${currentUser.uid}');
      print('   Please login with the correct account');
      return;
    }
    
    print('✅ Correct user is authenticated\n');
    
    // Check user document in Firestore
    print('🔍 Checking user document in Firestore...');
    final firestore = FirebaseFirestore.instance;
    
    try {
      final userDoc = await firestore.collection('users').doc(targetUserId).get();
      
      if (!userDoc.exists) {
        print('❌ CRITICAL: User document does NOT exist in Firestore!');
        print('   This is why you\'re getting permission errors.');
        print('   The security rules require a user document to exist.');
        print('\n🔧 SOLUTION: Use the Fix User Document tool in Settings');
        return;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      print('✅ User document exists!');
      print('📄 User document data:');
      userData.forEach((key, value) {
        print('   $key: $value');
      });
      
      // Check required fields for security rules
      final requiredFields = ['role', 'email', 'name', 'uid'];
      bool hasAllFields = true;
      
      print('\n🔍 Checking required fields for security rules:');
      for (final field in requiredFields) {
        if (userData.containsKey(field) && userData[field] != null && userData[field] != '') {
          print('   ✅ $field: ${userData[field]}');
        } else {
          print('   ❌ $field: MISSING or EMPTY');
          hasAllFields = false;
        }
      }
      
      if (!hasAllFields) {
        print('\n❌ PROBLEM: Missing required fields in user document');
        print('   This will cause security rule failures');
      } else {
        print('\n✅ All required fields present');
      }
      
      // Test specific security rule functions
      print('\n🧪 Testing security rule conditions:');
      
      // Test isAuthenticated() - should be true
      print('   ✅ isAuthenticated(): true (you are logged in)');
      
      // Test exists() check
      print('   ✅ exists(/databases/.../users/${targetUserId}): true');
      
      // Test role-based functions
      final userRole = userData['role'] as String?;
      if (userRole != null) {
        print('   ✅ User role: $userRole');
        
        switch (userRole) {
          case 'student':
            print('   ✅ isStudent(): should return true');
            break;
          case 'lecturer':
            print('   ✅ isLecturer(): should return true');
            break;
          case 'admin':
            print('   ✅ isAdmin(): should return true');
            break;
          default:
            print('   ⚠️  Unknown role: $userRole');
        }
      }
      
      // Test showcase_posts access
      print('\n🧪 Testing showcase_posts collection access...');
      try {
        final showcaseQuery = await firestore
            .collection('showcase_posts')
            .limit(1)
            .get();
        
        print('   ✅ SUCCESS: Can read showcase_posts collection');
        print('   Found ${showcaseQuery.docs.length} posts');
        
        if (showcaseQuery.docs.isNotEmpty) {
          final firstPost = showcaseQuery.docs.first.data();
          print('   Sample post data: ${firstPost.keys.join(', ')}');
        }
        
      } catch (e) {
        print('   ❌ FAILED: Cannot read showcase_posts collection');
        print('   Error: $e');
        
        if (e.toString().contains('permission-denied')) {
          print('\n🔍 PERMISSION DENIED ANALYSIS:');
          print('   This means the security rule is rejecting your request.');
          print('   Possible causes:');
          print('   1. User document structure doesn\'t match security rules');
          print('   2. Security rules have a bug');
          print('   3. Firestore indexes are missing');
        }
      }
      
      // Test events collection access
      print('\n🧪 Testing events collection access...');
      try {
        final eventsQuery = await firestore
            .collection('events')
            .limit(1)
            .get();
        
        print('   ✅ SUCCESS: Can read events collection');
        print('   Found ${eventsQuery.docs.length} events');
        
      } catch (e) {
        print('   ❌ FAILED: Cannot read events collection');
        print('   Error: $e');
      }
      
    } catch (e) {
      print('❌ ERROR accessing Firestore: $e');
    }
    
    print('\n🎯 SUMMARY:');
    print('==========');
    print('If you see any FAILED messages above, those explain the permission errors.');
    print('The most likely fix is to recreate your user document with the correct structure.');
    
  } catch (e) {
    print('❌ CRITICAL ERROR: $e');
  }
}
