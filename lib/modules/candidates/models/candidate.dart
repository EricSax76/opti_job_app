class Candidate {
  const Candidate({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.uid,
    required this.role,
    this.avatarUrl,
    this.token,
  });

  final int id;
  final String name;
  final String lastName;
  final String email;
  final String uid;
  final String role;
  final String? avatarUrl;
  final String? token;

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      role: json['role'] as String? ?? 'candidate',
      avatarUrl: json['avatar_url'] as String?,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'last_name': lastName,
      'email': email,
      'uid': uid,
      'role': role,
      'avatar_url': avatarUrl,
      'token': token,
    };
  }

  Candidate copyWith({
    int? id,
    String? name,
    String? lastName,
    String? email,
    String? uid,
    String? role,
    String? avatarUrl,
    String? token,
  }) {
    return Candidate(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      uid: uid ?? this.uid,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      token: token ?? this.token,
    );
  }
}
