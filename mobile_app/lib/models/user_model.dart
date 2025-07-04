enum UserRole { student, lecturer, admin }

class UserModel {
  final String id;
  final String uid; // Firebase UID
  final String email;
  final String password; // For local storage
  final String name;
  final UserRole role;
  final String? studentId; // For students
  final String? department;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  UserModel({
    required this.id,
    required this.uid,
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.studentId,
    this.department,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
  });

  // Factory constructor to create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      name: json['name'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.toString().split('.').last == json['role'],
        orElse: () => UserRole.student,
      ),
      studentId: json['studentId'],
      department: json['department'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      isActive: json['isActive'] ?? true,
    );
  }

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'email': email,
      'password': password,
      'name': name,
      'role': role.toString().split('.').last,
      'studentId': studentId,
      'department': department,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? id,
    String? uid,
    String? email,
    String? password,
    String? name,
    UserRole? role,
    String? studentId,
    String? department,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
      role: role ?? this.role,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
