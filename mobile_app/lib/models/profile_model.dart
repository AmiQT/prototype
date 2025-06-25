// No Firestore import

class ProfileModel {
  final String id;
  final String userId;
  final String fullName;
  final String studentId;
  final String program;
  final String department;
  final int semester;
  final String? phoneNumber;
  final String? address;
  final String? bio;
  final String? profileImageUrl;
  final List<String> skills;
  final List<String> interests;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.studentId,
    required this.program,
    required this.department,
    required this.semester,
    this.phoneNumber,
    this.address,
    this.bio,
    this.profileImageUrl,
    required this.skills,
    required this.interests,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create ProfileModel from JSON
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      studentId: json['studentId'] ?? '',
      program: json['program'] ?? '',
      department: json['department'] ?? '',
      semester: json['semester'] ?? 1,
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      bio: json['bio'],
      profileImageUrl: json['profileImageUrl'],
      skills: List<String>.from(json['skills'] ?? []),
      interests: List<String>.from(json['interests'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Convert ProfileModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'studentId': studentId,
      'program': program,
      'department': department,
      'semester': semester,
      'phoneNumber': phoneNumber,
      'address': address,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'skills': skills,
      'interests': interests,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Convert ProfileModel to Map for local storage (keeping for compatibility)
  Map<String, dynamic> toFirestore() {
    return toJson();
  }

  // Factory constructor to create ProfileModel from local storage (keeping for compatibility)
  factory ProfileModel.fromFirestore(Map<String, dynamic> data) {
    return ProfileModel.fromJson(data);
  }

  // Create a copy of ProfileModel with updated fields
  ProfileModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? studentId,
    String? program,
    String? department,
    int? semester,
    String? phoneNumber,
    String? address,
    String? bio,
    String? profileImageUrl,
    List<String>? skills,
    List<String>? interests,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      studentId: studentId ?? this.studentId,
      program: program ?? this.program,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ProfileModel(id: $id, fullName: $fullName, studentId: $studentId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
