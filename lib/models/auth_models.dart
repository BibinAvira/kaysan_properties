/// Maps to the user object returned by `/register/`, `/login/` (nested
/// under `user`), and `/profile/` on the auth microservice.
///
/// `id` and `createdAt` are only ever present on `/login/` and `/profile/`
/// responses (register's 201 response omits them), so both are nullable.
class UserModel {
  const UserModel({
    this.id,
    required this.username,
    this.email,
    this.phone,
    this.fullName,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int?,
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  final int? id;
  final String username;
  final String? email;
  final String? phone;
  final String? fullName;
  final DateTime? createdAt;

  UserModel copyWith({
    String? email,
    String? phone,
    String? fullName,
  }) {
    return UserModel(
      id: id,
      username: username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt,
    );
  }
}
