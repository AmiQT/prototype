class AcademicInfoModel {
  final String studentId;
  final String program;
  final String department;
  final String faculty;
  final int currentSemester;
  final double? cgpa;
  final int? totalCredits;
  final int? completedCredits;
  final DateTime enrollmentDate;
  final DateTime? expectedGraduation;
  final String? specialization;
  final List<String> minors;

  AcademicInfoModel({
    required this.studentId,
    required this.program,
    required this.department,
    required this.faculty,
    required this.currentSemester,
    this.cgpa,
    this.totalCredits,
    this.completedCredits,
    required this.enrollmentDate,
    this.expectedGraduation,
    this.specialization,
    this.minors = const [],
  });

  factory AcademicInfoModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return AcademicInfoModel(
      studentId: json['studentId'] ?? '',
      program: json['program'] ?? '',
      department: json['department'] ?? '',
      faculty: json['faculty'] ?? '',
      currentSemester: json['currentSemester'] ?? 1,
      cgpa: json['cgpa']?.toDouble(),
      totalCredits: json['totalCredits'],
      completedCredits: json['completedCredits'],
      enrollmentDate: parseDateTime(json['enrollmentDate']),
      expectedGraduation: json['expectedGraduation'] != null 
          ? parseDateTime(json['expectedGraduation']) 
          : null,
      specialization: json['specialization'],
      minors: List<String>.from(json['minors'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'program': program,
      'department': department,
      'faculty': faculty,
      'currentSemester': currentSemester,
      'cgpa': cgpa,
      'totalCredits': totalCredits,
      'completedCredits': completedCredits,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'expectedGraduation': expectedGraduation?.toIso8601String(),
      'specialization': specialization,
      'minors': minors,
    };
  }

  AcademicInfoModel copyWith({
    String? studentId,
    String? program,
    String? department,
    String? faculty,
    int? currentSemester,
    double? cgpa,
    int? totalCredits,
    int? completedCredits,
    DateTime? enrollmentDate,
    DateTime? expectedGraduation,
    String? specialization,
    List<String>? minors,
  }) {
    return AcademicInfoModel(
      studentId: studentId ?? this.studentId,
      program: program ?? this.program,
      department: department ?? this.department,
      faculty: faculty ?? this.faculty,
      currentSemester: currentSemester ?? this.currentSemester,
      cgpa: cgpa ?? this.cgpa,
      totalCredits: totalCredits ?? this.totalCredits,
      completedCredits: completedCredits ?? this.completedCredits,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      expectedGraduation: expectedGraduation ?? this.expectedGraduation,
      specialization: specialization ?? this.specialization,
      minors: minors ?? this.minors,
    );
  }
}
