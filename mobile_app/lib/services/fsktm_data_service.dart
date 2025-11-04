import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Enhanced local data service untuk FSKTM comprehensive information
/// No backend required - semua data local dalam JSON files
class FSKTMDataService {
  static Map<String, dynamic>? _cachedStaffData;
  static Map<String, dynamic>? _cachedKnowledgeBase;

  /// Load FSKTM staff data dari local JSON file
  static Future<Map<String, dynamic>> loadStaffData() async {
    if (_cachedStaffData != null) {
      return _cachedStaffData!;
    }

    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/fsktm_staff_data.json');
      _cachedStaffData = json.decode(jsonString);
      return _cachedStaffData!;
    } catch (e) {
      if (kDebugMode) print('Error loading FSKTM staff data: $e');
      return _getDefaultStaffData();
    }
  }

  /// Load comprehensive knowledge base dari local JSON file
  static Future<Map<String, dynamic>> loadKnowledgeBase() async {
    if (_cachedKnowledgeBase != null) {
      return _cachedKnowledgeBase!;
    }

    try {
      final String jsonString = await rootBundle
          .loadString('assets/data/fsktm_comprehensive_knowledge_base.json');
      _cachedKnowledgeBase = json.decode(jsonString);
      return _cachedKnowledgeBase!;
    } catch (e) {
      if (kDebugMode) print('Error loading FSKTM knowledge base: $e');
      return _getDefaultKnowledgeBase();
    }
  }

  /// ENHANCED: Generate comprehensive context string untuk AI chatbot
  static Future<String> getFSKTMContextForAI() async {
    final staffData = await loadStaffData();
    final knowledgeBase = await loadKnowledgeBase();

    final StringBuffer context = StringBuffer();

    // === QUICK ANSWERS (Priority untuk fast responses) ===
    if (knowledgeBase['quick_answers'] != null) {
      context.writeln('=== FSKTM QUICK ANSWERS ===');
      final quickAnswers = knowledgeBase['quick_answers'];
      quickAnswers.forEach((key, value) {
        context.writeln('$key: $value');
      });
      context.writeln('');
    }

    // === FACULTY IDENTITY ===
    if (knowledgeBase['faculty_identity'] != null) {
      final identity = knowledgeBase['faculty_identity'];
      context.writeln('=== FACULTY IDENTITY ===');
      context.writeln('Name: ${identity['official_name']['english']}');
      context.writeln('Malay: ${identity['official_name']['malay']}');
      context.writeln('Acronym: ${identity['official_name']['acronym']}');
      context.writeln('University: ${identity['university']}');
      context.writeln('Vision: ${identity['vision']}');
      context.writeln('Mission: ${identity['mission']}');
      context
          .writeln('Strategic Direction: ${identity['strategic_direction']}');
      context.writeln('');
    }

    // === ACADEMIC PROGRAMS ===
    if (knowledgeBase['academic_programs'] != null) {
      final programs = knowledgeBase['academic_programs'];
      context.writeln('=== ACADEMIC PROGRAMS ===');

      if (programs['undergraduate'] != null) {
        context.writeln('UNDERGRADUATE PROGRAMS:');
        final undergrad = programs['undergraduate']['programs'] as List;
        for (var program in undergrad) {
          context.writeln('- ${program['name']}');
          if (program['mqa_code'] != null) {
            context.writeln('  MQA Code: ${program['mqa_code']}');
          }
        }
      }

      if (programs['postgraduate'] != null) {
        context.writeln('POSTGRADUATE PROGRAMS:');
        final postgrad = programs['postgraduate']['programs'] as List;
        for (var program in postgrad) {
          context.writeln('- ${program['name']}');
        }
      }
      context.writeln('');
    }

    // === RESEARCH EXPERTISE ===
    if (knowledgeBase['research_expertise'] != null) {
      final research = knowledgeBase['research_expertise'];
      context.writeln('=== RESEARCH EXPERTISE ===');

      if (research['research_centers'] != null) {
        context.writeln('RESEARCH CENTERS:');
        final centers = research['research_centers']['centers'] as List;
        for (var center in centers) {
          context.writeln('- ${center['name']} (${center['acronym']})');
        }
      }

      if (research['focus_groups'] != null) {
        context.writeln('FOCUS GROUPS:');
        final groups = research['focus_groups']['groups'] as List;
        for (var group in groups) {
          context.writeln('- ${group['name']} (${group['acronym']})');
        }
      }
      context.writeln('');
    }

    // === CONTACT INFORMATION ===
    if (knowledgeBase['contact_information'] != null) {
      final contact = knowledgeBase['contact_information']['main_office'];
      context.writeln('=== CONTACT INFORMATION ===');
      context.writeln('Address: ${contact['address']}');
      context.writeln('Phone: ${contact['phone']}');
      context.writeln('Email: ${contact['email']}');
      context.writeln('Website: ${contact['website']}');
      context.writeln('');
    }

    // === STAFF DIRECTORY (from original data) ===
    final facultyInfo = staffData['faculty_info'];
    context.writeln('=== STAFF DIRECTORY ===');
    context.writeln('Total Staff: ${facultyInfo['total_staff']}');

    // Add departments
    final departments = staffData['departments'] as List;
    context.writeln('DEPARTMENTS:');
    for (var dept in departments) {
      context.writeln('- ${dept['name']} (${dept['name_en']})');
    }

    // Add ALL staff members (not just first 10) for better AI search
    context.writeln('STAFF MEMBERS:');
    final staff = staffData['staff'] as List;
    for (var member in staff) {
      context.writeln('${member['name']} - ${member['title']}');
      context.writeln('Department: ${member['department']}');
      context.writeln('Email: ${member['email']}');
      if (member['specialization'] != null) {
        context.writeln('Expertise: ${member['specialization']}');
      }
      context.writeln('---');
    }
    context.writeln('[Total: ${staff.length} staff members]');

    return context.toString();
  }

  /// NEW: Generate smart context dengan staff search
  static Future<String> getFSKTMContextForAIWithQuery(String query) async {
    final staffData = await loadStaffData();
    final knowledgeBase = await loadKnowledgeBase();

    final StringBuffer context = StringBuffer();

    // Add quick answers
    if (knowledgeBase['quick_answers'] != null) {
      context.writeln('=== FSKTM QUICK ANSWERS ===');
      final quickAnswers = knowledgeBase['quick_answers'];
      quickAnswers.forEach((key, value) {
        context.writeln('$key: $value');
      });
      context.writeln('');
    }

    // Add faculty identity
    if (knowledgeBase['faculty_identity'] != null) {
      final identity = knowledgeBase['faculty_identity'];
      context.writeln('=== FACULTY IDENTITY ===');
      context.writeln('Name: ${identity['official_name']['english']}');
      context.writeln('University: ${identity['university']}');
      context.writeln('');
    }

    // Smart staff search - detect nama dalam query
    final staff = staffData['staff'] as List;
    final lowerQuery = query.toLowerCase();
    
    // Search for staff mentioned in query
    final relevantStaff = staff.where((member) {
      final name = member['name'].toString().toLowerCase();
      final nameParts = name.split(' ');
      
      // Check if any part of name is in query
      return nameParts.any((part) => 
        part.length > 2 && lowerQuery.contains(part)
      );
    }).toList();

    // Add staff directory
    final facultyInfo = staffData['faculty_info'];
    context.writeln('=== STAFF DIRECTORY ===');
    context.writeln('Total Staff: ${facultyInfo['total_staff']}');
    
    final departments = staffData['departments'] as List;
    context.writeln('DEPARTMENTS:');
    for (var dept in departments) {
      context.writeln('- ${dept['name']} (${dept['name_en']})');
    }
    context.writeln('');

    if (relevantStaff.isNotEmpty) {
      // User mentioned specific staff - show them
      context.writeln('RELEVANT STAFF MEMBERS:');
      for (var member in relevantStaff) {
        context.writeln('${member['name']} - ${member['title']}');
        context.writeln('Department: ${member['department']}');
        context.writeln('Email: ${member['email']}');
        if (member['specialization'] != null) {
          context.writeln('Expertise: ${member['specialization']}');
        }
        context.writeln('---');
      }
    } else {
      // No specific staff mentioned - show summary list
      context.writeln('STAFF MEMBERS (${staff.length} total):');
      for (var member in staff) {
        context.writeln('${member['name']} - ${member['title']} (${member['department']})');
      }
      context.writeln('');
      context.writeln('[Note: For specific staff details, mention their name in your question]');
    }

    return context.toString();
  }

  /// ENHANCED: Search staff by name (unchanged - works with staff data)
  static Future<List<Map<String, dynamic>>> searchStaffByName(
      String query) async {
    final data = await loadStaffData();
    final staff = data['staff'] as List;

    final lowerQuery = query.toLowerCase();
    return staff
        .where((member) {
          final name = member['name'].toString().toLowerCase();
          return name.contains(lowerQuery);
        })
        .cast<Map<String, dynamic>>()
        .toList();
  }

  /// ENHANCED: Search staff by department (unchanged)
  static Future<List<Map<String, dynamic>>> searchStaffByDepartment(
      String department) async {
    final data = await loadStaffData();
    final staff = data['staff'] as List;

    final lowerDept = department.toLowerCase();
    return staff
        .where((member) {
          final memberDept = member['department'].toString().toLowerCase();
          return memberDept.contains(lowerDept);
        })
        .cast<Map<String, dynamic>>()
        .toList();
  }

  /// NEW: Search academic programs
  static Future<List<Map<String, dynamic>>> searchPrograms(String query) async {
    final kb = await loadKnowledgeBase();
    final programs = <Map<String, dynamic>>[];

    final lowerQuery = query.toLowerCase();

    // Search undergraduate programs
    if (kb['academic_programs']['undergraduate'] != null) {
      final undergrad =
          kb['academic_programs']['undergraduate']['programs'] as List;
      for (var program in undergrad) {
        if (program['name'].toString().toLowerCase().contains(lowerQuery)) {
          programs.add({...program, 'level': 'Undergraduate'});
        }
      }
    }

    // Search postgraduate programs
    if (kb['academic_programs']['postgraduate'] != null) {
      final postgrad =
          kb['academic_programs']['postgraduate']['programs'] as List;
      for (var program in postgrad) {
        if (program['name'].toString().toLowerCase().contains(lowerQuery)) {
          programs.add({...program, 'level': 'Postgraduate'});
        }
      }
    }

    return programs;
  }

  /// NEW: Get quick answer for common queries
  static Future<String?> getQuickAnswer(String query) async {
    final kb = await loadKnowledgeBase();
    final quickAnswers = kb['quick_answers'];

    final lowerQuery = query.toLowerCase();

    // Direct matches
    for (String key in quickAnswers.keys) {
      if (lowerQuery.contains(key.toLowerCase())) {
        return quickAnswers[key];
      }
    }

    // Fuzzy matches for common terms
    if (lowerQuery.contains('phone') ||
        lowerQuery.contains('telefon') ||
        lowerQuery.contains('contact')) {
      return quickAnswers['phone'];
    }
    if (lowerQuery.contains('email') || lowerQuery.contains('emel')) {
      return quickAnswers['email'];
    }
    if (lowerQuery.contains('address') || lowerQuery.contains('alamat')) {
      return quickAnswers['address'];
    }
    if (lowerQuery.contains('student') && lowerQuery.contains('total')) {
      return '${quickAnswers['total_students']} students in FSKTM';
    }

    return null;
  }

  /// ENHANCED: Get comprehensive faculty statistics
  static Future<Map<String, dynamic>> getFacultyStats() async {
    final staffData = await loadStaffData();
    final kb = await loadKnowledgeBase();

    final staff = staffData['staff'] as List;
    final departments = staffData['departments'] as List;

    // Count staff by department
    Map<String, int> staffByDept = {};
    for (var member in staff) {
      final dept = member['department'];
      staffByDept[dept] = (staffByDept[dept] ?? 0) + 1;
    }

    final quickAnswers = kb['quick_answers'];

    return {
      'total_staff': staff.length,
      'total_departments': departments.length,
      'total_students': quickAnswers['total_students'],
      'total_academicians': quickAnswers['total_academicians'],
      'total_programs': quickAnswers['total_programs'],
      'staff_by_department': staffByDept,
      'faculty_name': staffData['faculty_info']['name'],
      'university': staffData['faculty_info']['university'],
    };
  }

  /// ENHANCED: Check if query is FSKTM-related (expanded keywords)
  static bool isFSKTMQuery(String query) {
    final lowerQuery = query.toLowerCase();

    final fsktmKeywords = [
      // Staff & People
      'staff', 'lecturer', 'professor', 'dr.', 'prof.', 'pensyarah',
      'dekan', 'dean', 'ketua jabatan', 'head of department',

      // Faculty & Organization
      'fsktm', 'fakulti sains komputer', 'faculty of computer science',
      'jabatan', 'department', 'uthm', 'universiti tun hussein',

      // Academic Programs
      'program', 'course', 'degree', 'bachelor', 'master', 'phd', 'ijazah',
      'sarjana muda', 'sarjana', 'kedoktoran',

      // Departments & Fields
      'multimedia', 'kejuruteraan perisian', 'software engineering',
      'keselamatan maklumat', 'information security', 'sains komputer',
      'computer science', 'teknologi web', 'web technology',

      // Contact & Information
      'email lecturer', 'contact lecturer', 'phone', 'telefon', 'alamat',
      'address', 'website', 'vision', 'mission', 'visi', 'misi',

      // Queries
      'siapa lecturer', 'berapa ramai staff', 'senarai lecturer',
      'what is fsktm', 'apa itu fsktm', 'how many', 'berapa',
      'research', 'penyelidikan', 'center', 'pusat'
    ];

    return fsktmKeywords.any((keyword) => lowerQuery.contains(keyword));
  }

  /// LEGACY: Maintain backward compatibility
  static Future<Map<String, dynamic>> loadFSKTMData() async {
    return await loadStaffData();
  }

  /// Default staff data fallback
  static Map<String, dynamic> _getDefaultStaffData() {
    return {
      'faculty_info': {
        'name': 'Fakulti Sains Komputer dan Teknologi Maklumat',
        'acronym': 'FSKTM',
        'university': 'Universiti Tun Hussein Onn Malaysia (UTHM)',
        'total_staff': 0,
      },
      'departments': [],
      'staff': [],
    };
  }

  /// Default knowledge base fallback
  static Map<String, dynamic> _getDefaultKnowledgeBase() {
    return {
      'knowledge_base_info': {'title': 'FSKTM Knowledge Base'},
      'quick_answers': {
        'phone': '+607 453 3606',
        'email': 'fsktm@uthm.edu.my',
        'what_is_fsktm':
            'Faculty of Computer Science and Information Technology, UTHM'
      },
      'faculty_identity': {},
      'academic_programs': {},
      'research_expertise': {},
      'contact_information': {},
    };
  }
}
