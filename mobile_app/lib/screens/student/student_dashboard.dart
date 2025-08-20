import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../../services/supabase_auth_service.dart';
import '../../models/user_model.dart';
import 'profile/student_profile_screen.dart';
import 'showcase/showcase_screen.dart';
import 'search/enhanced_search_screen.dart';
import 'event_program/event_program_screen.dart';
import '../chat/chat_screen.dart';
// import '../debug/backend_test_screen.dart'; // Debug screen removed
import '../settings/settings_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ShowcaseScreen(),
    const EnhancedSearchScreen(),
    const EventProgramScreen(),
    const StudentProfileScreen(),
    const SettingsScreen(), // Add settings as 5th tab
  ];

  List<BottomNavigationBarItem> _getNavItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.home),
      BottomNavigationBarItem(
          icon: const Icon(Icons.search), label: l10n.discover),
      BottomNavigationBarItem(
          icon: const Icon(Icons.event_available), label: l10n.eventProgram),
      BottomNavigationBarItem(
          icon: const Icon(Icons.person), label: l10n.profile),
      const BottomNavigationBarItem(
          icon: Icon(Icons.settings), label: 'Settings'),
    ];
  }

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Basic initialization - specific data loading handled by individual screens
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
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
    final authService =
        Provider.of<SupabaseAuthService>(context, listen: false);
    final userRole = authService.currentUser?.role;
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _getNavItems(context),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[500],
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        iconSize: 28,
        elevation: 12,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Backend Test FAB (for testing)
          FloatingActionButton(
            heroTag: "backend_test_fab",
            mini: true,
            onPressed: () {
              // Backend test functionality removed - app now uses backend by default
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App is now using backend APIs!')),
              );
            },
            tooltip: 'Backend Test',
            backgroundColor: Colors.orange,
            child: const Icon(Icons.api),
          ),
          const SizedBox(height: 8),
          // Chat FAB
          if (userRole == UserRole.student || userRole == UserRole.lecturer)
            FloatingActionButton(
              heroTag: "student_dashboard_chat_fab",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatScreen()),
                );
              },
              tooltip: 'Chatbot',
              child: const Icon(Icons.chat),
            ),
        ],
      ),
    );
  }
}
