import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/profile_service.dart';
import '../../models/profile_model.dart';

class MigrateProfileDocumentsScreen extends StatefulWidget {
  const MigrateProfileDocumentsScreen({super.key});

  @override
  State<MigrateProfileDocumentsScreen> createState() => _MigrateProfileDocumentsScreenState();
}

class _MigrateProfileDocumentsScreenState extends State<MigrateProfileDocumentsScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = false;
  String _status = '';
  List<Map<String, dynamic>> _profilesFound = [];

  @override
  void initState() {
    super.initState();
    _checkCurrentStatus();
  }

  Future<void> _checkCurrentStatus() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking profile documents...';
      _profilesFound.clear();
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

      final userId = user.uid;
      print('🔍 DEBUG: Checking profile for user ${userId}');

      // Check if profile exists with userId as document ID (new structure)
      final newProfileDoc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(userId)
          .get();

      if (newProfileDoc.exists) {
        setState(() {
          _status = '✅ Profile already migrated!\nProfile found with correct document ID structure.';
          _isLoading = false;
        });
        return;
      }

      // Search for profiles with this userId in the data (old structure)
      final oldProfilesQuery = await FirebaseFirestore.instance
          .collection('profiles')
          .where('userId', isEqualTo: userId)
          .get();

      if (oldProfilesQuery.docs.isEmpty) {
        setState(() {
          _status = '⚠️ No profile found for current user.\nYou may need to complete profile setup first.';
          _isLoading = false;
        });
        return;
      }

      // Found old structure profiles
      for (final doc in oldProfilesQuery.docs) {
        final data = doc.data();
        _profilesFound.add({
          'documentId': doc.id,
          'userId': data['userId'],
          'name': data['fullName'] ?? 'Unknown',
          'data': data,
        });
      }

      setState(() {
        _status = '🔄 Found ${_profilesFound.length} profile(s) that need migration!\n'
            'These profiles use the old document ID structure and need to be migrated.';
        _isLoading = false;
      });

    } catch (e) {
      print('❌ DEBUG: Error checking status: $e');
      setState(() {
        _status = '❌ Error checking status: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _migrateProfiles() async {
    setState(() {
      _isLoading = true;
      _status = 'Migrating profiles...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _status = '❌ No user authenticated';
          _isLoading = false;
        });
        return;
      }

      final userId = user.uid;
      int migratedCount = 0;

      for (final profileInfo in _profilesFound) {
        final oldDocId = profileInfo['documentId'] as String;
        final profileData = profileInfo['data'] as Map<String, dynamic>;

        print('🔄 Migrating profile from $oldDocId to $userId');

        // Create new document with userId as document ID
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(userId)
            .set(profileData);

        // Delete old document
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(oldDocId)
            .delete();

        migratedCount++;
        print('✅ Migrated profile $migratedCount/${_profilesFound.length}');
      }

      setState(() {
        _status = '✅ Migration completed successfully!\n'
            'Migrated $migratedCount profile(s).\n'
            'Profile should now be visible in the app.';
        _isLoading = false;
        _profilesFound.clear();
      });

    } catch (e) {
      print('❌ DEBUG: Error migrating profiles: $e');
      setState(() {
        _status = '❌ Error migrating profiles: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Migrate Profile Documents'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Profile Migration Tool',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This tool migrates profile documents from the old structure (random document IDs) to the new structure (userId as document ID). This fixes the "No profile found" issue.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
            if (_profilesFound.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Profiles Found:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _profilesFound.length,
                  itemBuilder: (context, index) {
                    final profile = _profilesFound[index];
                    return Card(
                      child: ListTile(
                        title: Text(profile['name'] as String),
                        subtitle: Text('Document ID: ${profile['documentId']}\nUser ID: ${profile['userId']}'),
                        leading: const Icon(Icons.person),
                      ),
                    );
                  },
                ),
              ),
            ],
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
                    onPressed: _isLoading || _profilesFound.isEmpty ? null : _migrateProfiles,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Migrate Profiles'),
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
          ],
        ),
      ),
    );
  }
}
