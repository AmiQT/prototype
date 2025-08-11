import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class FixUserDocumentScreen extends StatefulWidget {
  const FixUserDocumentScreen({super.key});

  @override
  State<FixUserDocumentScreen> createState() => _FixUserDocumentScreenState();
}

class _FixUserDocumentScreenState extends State<FixUserDocumentScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _status = '';
  Map<String, dynamic>? _userInfo;

  @override
  void initState() {
    super.initState();
    _checkCurrentStatus();
  }

  Future<void> _checkCurrentStatus() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking current status...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _status = '❌ No user is currently authenticated';
          _isLoading = false;
        });
        return;
      }

      // Get user info
      _userInfo = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'emailVerified': user.emailVerified,
      };

      print('🔍 DEBUG: Checking user document for ${user.uid}');

      // Check if user document exists
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        print('✅ DEBUG: User document exists with data: $userData');

        // Check for required fields
        final requiredFields = ['role', 'email', 'name', 'uid'];
        final missingFields = <String>[];

        for (final field in requiredFields) {
          if (!userData.containsKey(field) ||
              userData[field] == null ||
              userData[field] == '') {
            missingFields.add(field);
          }
        }

        if (missingFields.isNotEmpty) {
          setState(() {
            _status =
                '⚠️ User document exists but missing fields!\nMissing: ${missingFields.join(', ')}\nRole: ${userData['role']}\nThis may cause permission errors.';
            _isLoading = false;
          });
        } else {
          setState(() {
            _status =
                '✅ User document exists and complete!\nRole: ${userData['role']}\nName: ${userData['name']}\nEmail: ${userData['email']}';
            _isLoading = false;
          });

          // Test showcase access
          _testShowcaseAccess();
        }
      } else {
        print('❌ DEBUG: User document does NOT exist');
        setState(() {
          _status =
              '⚠️ User document is MISSING!\nThis is why you\'re getting permission errors.\nUser ID: ${user.uid}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ DEBUG: Error checking status: $e');
      setState(() {
        _status = '❌ Error checking status: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testShowcaseAccess() async {
    try {
      print('🧪 DEBUG: Testing showcase_posts access...');
      final showcaseQuery = await FirebaseFirestore.instance
          .collection('showcase_posts')
          .limit(1)
          .get();

      print(
          '✅ DEBUG: Showcase access successful! Found ${showcaseQuery.docs.length} posts');
      setState(() {
        _status = _status + '\n\n✅ Showcase access: WORKING';
      });
    } catch (e) {
      print('❌ DEBUG: Showcase access failed: $e');
      setState(() {
        _status = _status + '\n\n❌ Showcase access: FAILED\nError: $e';
      });
    }
  }

  Future<void> _fixUserDocument() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating user document...';
    });

    try {
      final success = await _authService.ensureUserDocumentExists();

      if (success) {
        setState(() {
          _status =
              '✅ User document created successfully!\nPermission errors should be fixed now.';
          _isLoading = false;
        });

        // Refresh status after a delay
        await Future.delayed(const Duration(seconds: 2));
        _checkCurrentStatus();
      } else {
        setState(() {
          _status =
              '❌ Failed to create user document.\nPlease check the console for errors.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error creating user document: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fix User Document'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Permission Error Fix',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'If you\'re seeing "permission-denied" errors, it\'s likely because your user document is missing from Firestore. This tool will help fix that.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_userInfo != null) ...[
              const Text(
                'Current User Info:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UID: ${_userInfo!['uid']}'),
                      Text('Email: ${_userInfo!['email']}'),
                      Text(
                          'Display Name: ${_userInfo!['displayName'] ?? 'Not set'}'),
                      Text('Email Verified: ${_userInfo!['emailVerified']}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            const Text(
              'Status:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    _status,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkCurrentStatus,
                    child: const Text('Check Status'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _fixUserDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Fix User Document'),
                  ),
                ),
              ],
            ),
            if (_isLoading) ...[
              const SizedBox(height: 20),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
            const SizedBox(height: 30),
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Click "Check Status" to see if your user document exists\n'
                      '2. If it shows "MISSING", click "Fix User Document"\n'
                      '3. After fixing, restart the app\n'
                      '4. The permission errors should be gone!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
