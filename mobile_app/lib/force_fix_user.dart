import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// EMERGENCY FIX for user OVzcnuGCaFZfbNxrxLsvlQsTnvr1
/// This will force-create your user document with the exact structure needed
void main() async {
  print('🚨 EMERGENCY USER DOCUMENT FIX');
  print('==============================\n');
  
  const targetUserId = 'OVzcnuGCaFZfbNxrxLsvlQsTnvr1';
  
  try {
    // Check current authenticated user
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      print('❌ ERROR: No user is currently authenticated');
      print('Please login to the app first');
      return;
    }
    
    if (currentUser.uid != targetUserId) {
      print('⚠️  WARNING: You are logged in as a different user!');
      print('   Expected: $targetUserId');
      print('   Actual: ${currentUser.uid}');
      print('   Please login with the correct account');
      return;
    }
    
    print('✅ Correct user authenticated: ${currentUser.uid}');
    print('📧 Email: ${currentUser.email}\n');
    
    // Force create user document with exact structure needed for security rules
    print('🔧 Force-creating user document...');
    
    final userData = {
      'id': currentUser.uid,
      'uid': currentUser.uid,
      'email': currentUser.email ?? '',
      'name': currentUser.displayName?.isNotEmpty == true
          ? currentUser.displayName!
          : currentUser.email?.split('@')[0] ?? 'User',
      'role': 'student', // CRITICAL: This field is required by security rules
      'studentId': '',
      'department': '',
      'createdAt': DateTime.now().toIso8601String(),
      'lastLoginAt': DateTime.now().toIso8601String(),
      'isActive': true,
      'profileCompleted': false,
      'photoURL': currentUser.photoURL ?? '',
      'phoneNumber': currentUser.phoneNumber ?? '',
    };
    
    print('📄 Creating user document with data:');
    userData.forEach((key, value) {
      print('   $key: $value');
    });
    
    // Force create the document
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set(userData, SetOptions(merge: false)); // Use merge: false to overwrite completely
    
    print('\n✅ User document created!');
    
    // Wait for propagation
    print('⏳ Waiting for Firestore propagation...');
    await Future.delayed(const Duration(seconds: 3));
    
    // Verify creation
    print('🔍 Verifying document creation...');
    final verifyDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    
    if (verifyDoc.exists) {
      final verifyData = verifyDoc.data() as Map<String, dynamic>;
      print('✅ SUCCESS: User document verified!');
      print('📄 Verified data:');
      verifyData.forEach((key, value) {
        print('   $key: $value');
      });
      
      // Test showcase_posts access immediately
      print('\n🧪 Testing showcase_posts access...');
      try {
        final showcaseQuery = await FirebaseFirestore.instance
            .collection('showcase_posts')
            .limit(1)
            .get();
        
        print('✅ SUCCESS: Can now access showcase_posts!');
        print('   Found ${showcaseQuery.docs.length} posts');
        
      } catch (e) {
        print('❌ STILL FAILED: showcase_posts access failed');
        print('   Error: $e');
        print('   This might be a security rule issue or caching problem');
      }
      
      // Test events access
      print('\n🧪 Testing events access...');
      try {
        final eventsQuery = await FirebaseFirestore.instance
            .collection('events')
            .limit(1)
            .get();
        
        print('✅ SUCCESS: Can now access events!');
        print('   Found ${eventsQuery.docs.length} events');
        
      } catch (e) {
        print('❌ STILL FAILED: events access failed');
        print('   Error: $e');
      }
      
    } else {
      print('❌ CRITICAL: Document creation failed!');
      print('   This indicates a serious Firestore connectivity issue');
    }
    
    print('\n🎯 NEXT STEPS:');
    print('==============');
    print('1. Restart your Flutter app completely');
    print('2. Try accessing the Events and Showcase feeds');
    print('3. If still getting errors, there might be a security rule issue');
    print('4. Check the Flutter console for any remaining permission errors');
    
  } catch (e) {
    print('❌ CRITICAL ERROR: $e');
    print('\nThis error suggests:');
    print('1. Network connectivity issues');
    print('2. Firebase configuration problems');
    print('3. Authentication token issues');
  }
}
