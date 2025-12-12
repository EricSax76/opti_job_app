class Candidate {
  const Candidate({
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

  factory Candidate.fromRow(ResultRow row) {
    final data = row.toColumnMap();
    return Candidate(
      id: data['candidate_id'] is int
          ? data['candidate_id'] as int
          : int.parse(data['candidate_id'].toString()),
      userId: data['user_id'] is int
          ? data['user_id'] as int
          : int.parse(data['user_id'].toString()),
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'candidate',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidate_id': id,
      'user_id': userId,
      'name': name,
      'email': email,
      'role': role,
    };
  }
}
