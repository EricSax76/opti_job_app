class Candidate {
  const Candidate({
    required this.id,
    required this.name,
    required this.email,
    required this.uid,
    required this.role,
    this.token,
  });

  final int id;
  final String name;
  final String email;
  final String uid;
  final String role;
  final String? token;

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      role: json['role'] as String? ?? 'candidate',
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'uid': uid,
      'role': role,
      'token': token,
    };
  }

  Candidate copyWith({
    int? id,
    String? name,
    String? email,
    String? uid,
    String? role,
    String? token,
  }) {
    return Candidate(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      uid: uid ?? this.uid,
      role: role ?? this.role,
      token: token ?? this.token,
    );
  }
}
