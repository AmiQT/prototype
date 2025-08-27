import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../../services/supabase_auth_service.dart';

import 'profile/student_profile_screen.dart';
import 'showcase/showcase_screen.dart';
import 'search/enhanced_search_screen.dart';
import 'event_program/event_program_screen.dart';
import '../chat/chat_screen.dart';

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
    const ChatScreen(), // AI Chatbot in center
    const EventProgramScreen(),
    const StudentProfileScreen(),
  ];

  List<BottomNavigationBarItem> _getNavItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.home),
      BottomNavigationBarItem(
          icon: const Icon(Icons.search), label: l10n.discover),
      const BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble), label: 'AI Chat'), // AI Chat in center
      BottomNavigationBarItem(
          icon: const Icon(Icons.event_available), label: l10n.eventProgram),
      BottomNavigationBarItem(
          icon: const Icon(Icons.person), label: l10n.profile),
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
      await Future.delayed(
          const Duration(milliseconds: 500)); // Simulate loading
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
    // User role check removed since FloatingActionButton was removed
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        iconSize: 28,
        elevation: 12,
      ),
    );
  }
}
