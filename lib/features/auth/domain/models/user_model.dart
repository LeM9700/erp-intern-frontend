enum UserRole {
  admin('ADMIN'),
  intern('INTERN');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String s) {
    return UserRole.values.firstWhere(
      (e) => e.value == s.toUpperCase(),
      orElse: () => UserRole.intern,
    );
  }
}

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: UserRole.fromString(json['role'] as String),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role.value,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  bool get isAdmin => role == UserRole.admin;
  bool get isIntern => role == UserRole.intern;
}
