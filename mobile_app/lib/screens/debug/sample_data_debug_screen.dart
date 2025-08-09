import 'package:flutter/material.dart';
import '../../services/sample_profile_data_service.dart';

class SampleDataDebugScreen extends StatefulWidget {
  const SampleDataDebugScreen({super.key});

  @override
  State<SampleDataDebugScreen> createState() => _SampleDataDebugScreenState();
}

class _SampleDataDebugScreenState extends State<SampleDataDebugScreen> {
  final SampleProfileDataService _profileDataService =
      SampleProfileDataService();
  bool _isLoading = false;

  Future<void> _createProfileSampleData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _profileDataService.createSampleData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sample profile data created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error creating sample data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearProfileSampleData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _profileDataService.clearSampleData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Sample profile data cleared successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error clearing sample data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Data Manager'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sample Data Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create or clear sample data for testing the search module with realistic profiles.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Profile Data Section
            _buildSectionCard(
              title: '👥 Profile Data',
              description:
                  'Sample users and profiles for testing search functionality',
              items: [
                _buildDataItem(
                  '4 Sample Users',
                  'Ahmad Rahman (CS Student), Siti Nurhaliza (IT Student), Dr. Farah (Lecturer), Muhammad Haziq (SE Student)',
                ),
                _buildDataItem(
                  'Complete Profiles',
                  'Full academic info, skills, experiences, and projects',
                ),
                _buildDataItem(
                  'Realistic Data',
                  'UTHM-specific departments, programs, and Malaysian names',
                ),
              ],
              actions: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createProfileSampleData,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _clearProfileSampleData,
                  icon: const Icon(Icons.delete),
                  label: const Text('Clear Data'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing...'),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        'Note',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sample data includes 4 realistic profiles with Malaysian names and UTHM-specific information. Perfect for testing search, filtering, and profile viewing functionality. After creating sample data, try searching for "Ahmad", "Siti", "Dr. Farah", or "Haziq".',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String description,
    required List<Widget> items,
    required List<Widget> actions,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ...items,
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: actions,
          ),
        ],
      ),
    );
  }

  Widget _buildDataItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
