import 'package:postgres/postgres.dart';

class Company {
  const Company({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  final int id;
  final int userId;
  final String name;
  final String email;
  final String role;

  factory Company.fromRow(ResultRow row) {
    final data = row.toColumnMap();
    return Company(
      id: data['company_id'] is int
          ? data['company_id'] as int
          : int.parse(data['company_id'].toString()),
      userId: data['user_id'] is int
          ? data['user_id'] as int
          : int.parse(data['user_id'].toString()),
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'company',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_id': id,
      'user_id': userId,
      'name': name,
      'email': email,
      'role': role,
    };
  }
}
