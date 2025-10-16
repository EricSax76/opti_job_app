import 'package:postgres/postgres.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.passwordHash,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String passwordHash;

  factory User.fromRow(ResultRow row) {
    final data = row.toColumnMap();
    return User(
      id: data['id'] is int
          ? data['id'] as int
          : int.parse(data['id'].toString()),
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? '',
      passwordHash: data['password_hash'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
    };
  }
}
