enum UserRole { student, lecturer, admin }

class UserProfile {
  final String id;
  final String? fullName;
  final String? email;
  final UserRole role;

  const UserProfile({
    required this.id,
    this.fullName,
    this.email,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      role: UserRole.values.byName((json['role'] as String?) ?? 'student'),
    );
  }

  bool get isStaff => role == UserRole.lecturer || role == UserRole.admin;
}
