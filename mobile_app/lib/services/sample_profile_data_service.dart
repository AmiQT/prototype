import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/profile_model.dart';
import '../models/user_model.dart';
import '../models/academic_info_model.dart';
import '../models/experience_model.dart';
import '../models/project_model.dart';

class SampleProfileDataService {
  final CollectionReference profilesCollection =
      FirebaseFirestore.instance.collection('profiles');
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference sampleUsersCollection =
      FirebaseFirestore.instance.collection('sample_users');

  Future<void> createSampleData() async {
    try {
      debugPrint('SampleProfileDataService: Creating sample profile data...');

      // Sample users and profiles
      final sampleData = [
        {
          'user': {
            'uid': 'sample_user_1',
            'name': 'Ahmad Rahman',
            'email': 'ahmad.rahman@uthm.edu.my',
            'role': 'student',
            'department': 'Computer Science',
            'studentId': 'CS20001',
            'profileCompleted': true,
          },
          'profile': {
            'fullName': 'Ahmad Rahman bin Abdullah',
            'phoneNumber': '+60123456789',
            'bio':
                'Passionate computer science student with interests in AI and machine learning. Always eager to learn new technologies.',
            'headline': 'AI Enthusiast | Final Year CS Student',
            'skills': [
              'Python',
              'Java',
              'Machine Learning',
              'React',
              'Flutter'
            ],
            'interests': [
              'Artificial Intelligence',
              'Data Science',
              'Mobile Development',
              'Gaming'
            ],
            'academicInfo': {
              'studentId': 'CS20001',
              'program': 'Bachelor of Computer Science',
              'department': 'Computer Science',
              'faculty':
                  'Faculty of Computer Science and Information Technology',
              'currentSemester': 7,
              'cgpa': 3.75,
              'enrollmentDate': DateTime.now()
                  .subtract(const Duration(days: 1095))
                  .toIso8601String(),
            },
            'experiences': [
              {
                'title': 'Software Development Intern',
                'company': 'TechCorp Malaysia',
                'location': 'Kuala Lumpur',
                'startDate': DateTime.now()
                    .subtract(const Duration(days: 120))
                    .toIso8601String(),
                'endDate': DateTime.now()
                    .subtract(const Duration(days: 30))
                    .toIso8601String(),
                'description':
                    'Developed mobile applications using Flutter and integrated REST APIs.',
                'skills': ['Flutter', 'Dart', 'REST API'],
              }
            ],
            'projects': [
              {
                'title': 'Smart Campus Navigation App',
                'description':
                    'Mobile app to help students navigate the campus using AR technology.',
                'technologies': ['Flutter', 'ARCore', 'Firebase'],
                'startDate': DateTime.now()
                    .subtract(const Duration(days: 180))
                    .toIso8601String(),
                'endDate': DateTime.now()
                    .subtract(const Duration(days: 60))
                    .toIso8601String(),
                'status': 'completed',
              }
            ],
          }
        },
        {
          'user': {
            'uid': 'sample_user_2',
            'name': 'Siti Nurhaliza',
            'email': 'siti.nurhaliza@uthm.edu.my',
            'role': 'student',
            'department': 'Information Technology',
            'studentId': 'IT20002',
            'profileCompleted': true,
          },
          'profile': {
            'fullName': 'Siti Nurhaliza binti Ahmad',
            'phoneNumber': '+60198765432',
            'bio':
                'IT student specializing in cybersecurity and network administration. Love solving complex security challenges.',
            'headline': 'Cybersecurity Specialist | IT Student',
            'skills': [
              'Cybersecurity',
              'Network Administration',
              'Python',
              'Linux',
              'Ethical Hacking'
            ],
            'interests': [
              'Information Security',
              'Penetration Testing',
              'Cloud Computing',
              'IoT Security'
            ],
            'academicInfo': {
              'studentId': 'IT20002',
              'program': 'Bachelor of Information Technology',
              'department': 'Information Technology',
              'faculty':
                  'Faculty of Computer Science and Information Technology',
              'currentSemester': 6,
              'cgpa': 3.85,
              'enrollmentDate': DateTime.now()
                  .subtract(const Duration(days: 1000))
                  .toIso8601String(),
            },
            'experiences': [
              {
                'title': 'Cybersecurity Analyst Intern',
                'company': 'SecureNet Solutions',
                'location': 'Johor Bahru',
                'startDate': DateTime.now()
                    .subtract(const Duration(days: 90))
                    .toIso8601String(),
                'endDate': DateTime.now()
                    .subtract(const Duration(days: 15))
                    .toIso8601String(),
                'description':
                    'Conducted security assessments and vulnerability testing for client networks.',
                'skills': [
                  'Penetration Testing',
                  'Vulnerability Assessment',
                  'Network Security'
                ],
              }
            ],
            'projects': [
              {
                'title': 'Network Security Monitoring System',
                'description':
                    'Real-time network monitoring system with intrusion detection capabilities.',
                'technologies': ['Python', 'Wireshark', 'Snort', 'ELK Stack'],
                'startDate': DateTime.now()
                    .subtract(const Duration(days: 200))
                    .toIso8601String(),
                'endDate': DateTime.now()
                    .subtract(const Duration(days: 45))
                    .toIso8601String(),
                'status': 'completed',
              }
            ],
          }
        },
        {
          'user': {
            'uid': 'sample_user_3',
            'name': 'Dr. Farah Aisyah',
            'email': 'farah.aisyah@uthm.edu.my',
            'role': 'lecturer',
            'department': 'Computer Science',
            'profileCompleted': true,
          },
          'profile': {
            'fullName': 'Dr. Farah Aisyah binti Mohamed',
            'phoneNumber': '+60123334444',
            'bio':
                'Senior lecturer specializing in artificial intelligence and machine learning. PhD in Computer Science with 10+ years of research experience.',
            'headline':
                'AI Researcher | Senior Lecturer | PhD in Computer Science',
            'skills': [
              'Machine Learning',
              'Deep Learning',
              'Python',
              'Research',
              'Academic Writing',
              'TensorFlow'
            ],
            'interests': [
              'Artificial Intelligence',
              'Natural Language Processing',
              'Computer Vision',
              'Educational Technology'
            ],
            'academicInfo': {
              'program': 'PhD in Computer Science',
              'department': 'Computer Science',
              'faculty':
                  'Faculty of Computer Science and Information Technology',
              'specialization': 'Artificial Intelligence',
            },
            'experiences': [
              {
                'title': 'Senior Lecturer',
                'company': 'Universiti Tun Hussein Onn Malaysia',
                'location': 'Johor',
                'startDate': DateTime.now()
                    .subtract(const Duration(days: 1825))
                    .toIso8601String(),
                'description':
                    'Teaching AI and ML courses, supervising research projects, and conducting research in NLP.',
                'skills': [
                  'Teaching',
                  'Research Supervision',
                  'Curriculum Development'
                ],
              }
            ],
            'projects': [
              {
                'title': 'Malay Language Sentiment Analysis',
                'description':
                    'Research project on developing sentiment analysis models for Malay language text.',
                'technologies': [
                  'Python',
                  'TensorFlow',
                  'NLTK',
                  'Transformers'
                ],
                'startDate': DateTime.now()
                    .subtract(const Duration(days: 365))
                    .toIso8601String(),
                'status': 'ongoing',
              }
            ],
          }
        },
        {
          'user': {
            'uid': 'sample_user_4',
            'name': 'Muhammad Haziq',
            'email': 'haziq.muhammad@uthm.edu.my',
            'role': 'student',
            'department': 'Software Engineering',
            'studentId': 'SE20003',
            'profileCompleted': true,
          },
          'profile': {
            'fullName': 'Muhammad Haziq bin Ismail',
            'phoneNumber': '+60187654321',
            'bio':
                'Software engineering student passionate about web development and cloud technologies. Active in coding competitions.',
            'headline': 'Full Stack Developer | Software Engineering Student',
            'skills': [
              'JavaScript',
              'React',
              'Node.js',
              'AWS',
              'Docker',
              'MongoDB'
            ],
            'interests': [
              'Web Development',
              'Cloud Computing',
              'DevOps',
              'Competitive Programming'
            ],
            'academicInfo': {
              'studentId': 'SE20003',
              'program': 'Bachelor of Software Engineering',
              'department': 'Software Engineering',
              'faculty':
                  'Faculty of Computer Science and Information Technology',
              'currentSemester': 5,
              'cgpa': 3.65,
              'enrollmentDate': DateTime.now()
                  .subtract(const Duration(days: 900))
                  .toIso8601String(),
            },
            'experiences': [
              {
                'title': 'Full Stack Developer Intern',
                'company': 'WebTech Solutions',
                'location': 'Kuala Lumpur',
                'startDate': DateTime.now()
                    .subtract(const Duration(days: 100))
                    .toIso8601String(),
                'endDate': DateTime.now()
                    .subtract(const Duration(days: 20))
                    .toIso8601String(),
                'description':
                    'Developed web applications using React and Node.js, deployed on AWS.',
                'skills': ['React', 'Node.js', 'AWS', 'MongoDB'],
              }
            ],
            'projects': [
              {
                'title': 'E-Commerce Platform',
                'description':
                    'Full-stack e-commerce platform with payment integration and admin dashboard.',
                'technologies': ['React', 'Node.js', 'MongoDB', 'Stripe API'],
                'startDate': DateTime.now()
                    .subtract(const Duration(days: 150))
                    .toIso8601String(),
                'endDate': DateTime.now()
                    .subtract(const Duration(days: 30))
                    .toIso8601String(),
                'status': 'completed',
              }
            ],
          }
        },
      ];

      // Create sample users and profiles
      for (final data in sampleData) {
        await _createUserAndProfile(data);
      }

      debugPrint('SampleProfileDataService: Sample data created successfully!');
    } catch (e) {
      debugPrint('SampleProfileDataService: Error creating sample data: $e');
      throw Exception('Failed to create sample data: $e');
    }
  }

  Future<void> _createUserAndProfile(Map<String, dynamic> data) async {
    final userData = data['user'] as Map<String, dynamic>;
    final profileData = data['profile'] as Map<String, dynamic>;

    // Create user
    final user = UserModel(
      id: userData['uid'], // Use uid as id
      uid: userData['uid'],
      name: userData['name'],
      email: userData['email'],
      role:
          userData['role'] == 'student' ? UserRole.student : UserRole.lecturer,
      department: userData['department'],
      studentId: userData['studentId'], // This can be null for lecturers
      profileCompleted: userData['profileCompleted'],
      createdAt: DateTime.now(),
    );

    // Save user to sample_users collection instead of users
    await sampleUsersCollection.doc(user.uid).set(user.toJson());

    // Create academic info
    final academicInfoData =
        profileData['academicInfo'] as Map<String, dynamic>;
    final academicInfo = AcademicInfoModel(
      studentId: academicInfoData['studentId'] ??
          userData['studentId'] ??
          '', // Use studentId from user data or empty string
      program: academicInfoData['program'],
      department: academicInfoData['department'],
      faculty: academicInfoData['faculty'],
      currentSemester: academicInfoData['currentSemester'] ??
          0, // Default to 0 for lecturers
      cgpa: academicInfoData['cgpa']?.toDouble() ??
          0.0, // Default to 0.0 for lecturers
      specialization: academicInfoData['specialization'],
      enrollmentDate: academicInfoData['enrollmentDate'] != null
          ? DateTime.parse(academicInfoData['enrollmentDate'])
          : DateTime.now(),
    );

    // Create experiences
    final experiencesData = profileData['experiences'] as List<dynamic>? ?? [];
    final experiences = experiencesData
        .map((exp) => ExperienceModel(
              id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
              title: exp['title'],
              company: exp['company'],
              location: exp['location'],
              startDate: DateTime.parse(exp['startDate']),
              endDate: exp['endDate'] != null
                  ? DateTime.parse(exp['endDate'])
                  : null,
              description: exp['description'],
              skills: List<String>.from(exp['skills'] ?? []),
            ))
        .toList();

    // Create projects
    final projectsData = profileData['projects'] as List<dynamic>? ?? [];
    final projects = projectsData
        .map((proj) => ProjectModel(
              id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
              title: proj['title'],
              description: proj['description'],
              technologies: List<String>.from(proj['technologies'] ?? []),
              startDate: DateTime.parse(proj['startDate']),
              endDate: proj['endDate'] != null
                  ? DateTime.parse(proj['endDate'])
                  : null,
              isOngoing: proj['status'] == 'ongoing',
            ))
        .toList();

    // Create profile
    final profile = ProfileModel(
      id: userData['uid'], // Use userId as document ID
      userId: userData['uid'],
      fullName: profileData['fullName'],
      phoneNumber: profileData['phoneNumber'],
      bio: profileData['bio'],
      headline: profileData['headline'],
      academicInfo: academicInfo,
      skills: List<String>.from(profileData['skills'] ?? []),
      interests: List<String>.from(profileData['interests'] ?? []),
      experiences: experiences,
      projects: projects,
      achievements: [], // Empty for now
      isProfileComplete: true,
      completedSections: [
        'basic',
        'academic',
        'skills',
        'interests',
        'experience',
        'projects'
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save profile to Firestore using userId as document ID
    await profilesCollection.doc(userData['uid']).set(profile.toJson());

    debugPrint(
        'SampleProfileDataService: Created user and profile for ${user.name}');
  }

  Future<void> clearSampleData() async {
    try {
      debugPrint('SampleProfileDataService: Clearing sample data...');

      // Delete sample users
      final sampleUserIds = [
        'sample_user_1',
        'sample_user_2',
        'sample_user_3',
        'sample_user_4'
      ];

      for (final userId in sampleUserIds) {
        await sampleUsersCollection.doc(userId).delete();
        await profilesCollection
            .doc(userId)
            .delete(); // Use userId as document ID
      }

      debugPrint('SampleProfileDataService: Sample data cleared successfully!');
    } catch (e) {
      debugPrint('SampleProfileDataService: Error clearing sample data: $e');
      throw Exception('Failed to clear sample data: $e');
    }
  }
}
