import 'worksite.dart';

class User {
  final int id;
  final String fullName;
  final String username;
  final String role;
  final WorkSite? workSite;

  User({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
    this.workSite,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      username: json['username'] as String,
      role: json['role'] as String,
      workSite: json['workSite'] == null
          ? null
          : WorkSite.fromJson(json['workSite'] as Map<String, dynamic>),
    );
  }
}
