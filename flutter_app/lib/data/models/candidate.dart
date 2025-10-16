class Candidate {
  const Candidate({
    required this.id,
    required this.name,
    required this.email,
    this.headline,
    this.location,
    this.skills = const [],
  });

  final String id;
  final String name;
  final String email;
  final String? headline;
  final String? location;
  final List<String> skills;

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      headline: json['headline'] as String?,
      location: json['location'] as String?,
      skills: (json['skills'] as List<dynamic>? ?? [])
          .map((skill) => skill.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'headline': headline,
      'location': location,
      'skills': skills,
    };
  }

  Candidate copyWith({
    String? id,
    String? name,
    String? email,
    String? headline,
    String? location,
    List<String>? skills,
  }) {
    return Candidate(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      headline: headline ?? this.headline,
      location: location ?? this.location,
      skills: skills ?? this.skills,
    );
  }
}
