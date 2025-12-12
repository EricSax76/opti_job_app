import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final projectId =
      Platform.environment['FIREBASE_PROJECT_ID'] ?? 'infojobs-dev';
  final firestoreHost =
      Platform.environment['FIRESTORE_EMULATOR_HOST'] ?? 'localhost:8080';
  final authHost =
      Platform.environment['FIREBASE_AUTH_EMULATOR_HOST'] ?? 'localhost:9099';

  final firestoreUri = _buildBaseUri(firestoreHost, defaultPort: 8080);
  final authUri = _buildBaseUri(authHost, defaultPort: 9099);

  stdout.writeln(
    'Seeding Firebase emulators (project=$projectId, firestore=$firestoreUri, auth=$authUri)',
  );

  final seeder = FirestoreSeeder(
    firestoreBaseUri: firestoreUri,
    authBaseUri: authUri,
    projectId: projectId,
  );
  await seeder.seed();
  stdout.writeln('Firestore/Auth seed completed successfully.');
}

Uri _buildBaseUri(String host, {required int defaultPort}) {
  final parts = host.split(':');
  final hostname = parts.first;
  final port = parts.length > 1
      ? int.tryParse(parts[1]) ?? defaultPort
      : defaultPort;
  return Uri(scheme: 'http', host: hostname, port: port);
}

class FirestoreSeeder {
  FirestoreSeeder({
    required this.firestoreBaseUri,
    required this.authBaseUri,
    required this.projectId,
  });

  final Uri firestoreBaseUri;
  final Uri authBaseUri;
  final String projectId;

  final _candidateSeeds = [
    _UserSeed(
      id: 1001,
      email: 'lucia@app.dev',
      password: 'Secret123!',
      name: 'Lucía Ramos',
      headline: 'Data Analyst',
      city: 'Barcelona',
      collection: 'candidates',
    ),
    _UserSeed(
      id: 1002,
      email: 'diego@app.dev',
      password: 'Secret123!',
      name: 'Diego López',
      headline: 'Mobile Engineer',
      city: 'Madrid',
      collection: 'candidates',
    ),
  ];

  final _companySeeds = [
    _UserSeed(
      id: 2001,
      email: 'talent@optijob.dev',
      password: 'Secret123!',
      name: 'OptiJob Labs',
      headline: 'Scale-up en Barcelona',
      city: 'Barcelona',
      collection: 'companies',
    ),
    _UserSeed(
      id: 2002,
      email: 'hr@nexthire.dev',
      password: 'Secret123!',
      name: 'NextHire',
      headline: 'Consultora HR Tech',
      city: 'Madrid',
      collection: 'companies',
    ),
  ];

  Future<void> seed() async {
    final candidates = await _seedUsers(_candidateSeeds, role: 'candidate');
    final companies = await _seedUsers(_companySeeds, role: 'company');

    await Future.wait([
      _createOffer(
        id: 3001,
        title: 'Ingeniero Flutter Senior',
        description:
            'Lidera el desarrollo de aplicaciones móviles multiplataforma.',
        location: 'Remoto · España',
        jobType: 'Full remote',
        salaryMin: '45k',
        salaryMax: '55k',
        education: 'Grado en informática o similar',
        keyIndicators: 'Flutter, Firebase, BLoC',
        ownerUid: companies.first.uid,
      ),
      _createOffer(
        id: 3002,
        title: 'Data Engineer',
        description:
            'Construye pipelines batch y streaming para alimentar modelos de IA.',
        location: 'Madrid',
        jobType: 'Híbrido',
        salaryMin: '50k',
        salaryMax: '65k',
        education: 'Grado en ingeniería o matemáticas',
        keyIndicators: 'BigQuery, Airflow, Python',
        ownerUid: companies.last.uid,
      ),
      _createOffer(
        id: 3003,
        title: 'HR Tech Product Manager',
        description:
            'Define la estrategia del nuevo portal de talento impulsado por IA.',
        location: 'Barcelona',
        jobType: 'Presencial',
        salaryMin: '40k',
        salaryMax: '55k',
        education: 'ADE o similares',
        keyIndicators: 'Roadmapping, Stakeholder management',
        ownerUid: companies.first.uid,
      ),
    ]);

    stdout.writeln('\nUsuarios sembrados (correo / contraseña):');
    for (final user in [...candidates, ...companies]) {
      stdout.writeln(' - ${user.email} / ${user.password}');
    }
  }

  Future<List<_SeededUser>> _seedUsers(
    List<_UserSeed> seeds, {
    required String role,
  }) async {
    final seededUsers = <_SeededUser>[];
    for (final seed in seeds) {
      final uid = await _createAuthUser(seed);
      final doc = {
        'id': seed.id,
        'uid': uid,
        'name': seed.name,
        'email': seed.email,
        'role': role,
        'headline': seed.headline,
        'city': seed.city,
        'created_at': DateTime.now().toUtc(),
      };
      await _createDoc(collection: seed.collection, docId: uid, data: doc);
      seededUsers.add(
        _SeededUser(
          uid: uid,
          email: seed.email,
          password: seed.password,
          collection: seed.collection,
        ),
      );
    }
    return seededUsers;
  }

  Future<String> _createAuthUser(_UserSeed seed) async {
    final uri = authBaseUri.replace(
      path: '/identitytoolkit.googleapis.com/v1/accounts:signUp',
      queryParameters: {'key': 'demo-key'},
    );
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': seed.email,
        'password': seed.password,
        'displayName': seed.name,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode >= 300) {
      stderr.writeln(
        'Failed to create auth user ${seed.email}: ${response.statusCode} ${response.body}',
      );
      throw Exception('Auth seed failed');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['localId'] as String;
  }

  Future<void> _createOffer({
    required int id,
    required String title,
    required String description,
    required String location,
    required String jobType,
    required String salaryMin,
    required String salaryMax,
    required String education,
    required String keyIndicators,
    required String ownerUid,
  }) async {
    await _createDoc(
      collection: 'jobOffers',
      docId: 'job_$id',
      data: {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        'job_type': jobType,
        'salary_min': salaryMin,
        'salary_max': salaryMax,
        'education': education,
        'key_indicators': keyIndicators,
        'owner_uid': ownerUid,
        'created_at': DateTime.now().toUtc(),
      },
    );
  }

  Future<void> _createDoc({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final uri = firestoreBaseUri.replace(
      path: '/v1/projects/$projectId/databases/(default)/documents/$collection',
      queryParameters: {'documentId': docId},
    );
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fields': _encodeFields(data)}),
    );

    if (response.statusCode >= 300) {
      stderr.writeln(
        'Failed to seed $collection/$docId: ${response.statusCode} ${response.body}',
      );
      throw Exception('Firestore seed failed');
    }
  }

  Map<String, dynamic> _encodeFields(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _encodeValue(value)));
  }

  Map<String, dynamic> _encodeValue(dynamic value) {
    if (value == null) return {'nullValue': null};
    if (value is int) {
      return {'integerValue': value.toString()};
    }
    if (value is double) {
      return {'doubleValue': value};
    }
    if (value is bool) {
      return {'booleanValue': value};
    }
    if (value is DateTime) {
      return {'timestampValue': value.toIso8601String()};
    }
    if (value is List) {
      return {
        'arrayValue': {'values': value.map(_encodeValue).toList()},
      };
    }
    if (value is Map<String, dynamic>) {
      return {
        'mapValue': {'fields': _encodeFields(value)},
      };
    }
    return {'stringValue': value.toString()};
  }
}

class _UserSeed {
  const _UserSeed({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.headline,
    required this.city,
    required this.collection,
  });

  final int id;
  final String email;
  final String password;
  final String name;
  final String headline;
  final String city;
  final String collection;
}

class _SeededUser {
  const _SeededUser({
    required this.uid,
    required this.email,
    required this.password,
    required this.collection,
  });

  final String uid;
  final String email;
  final String password;
  final String collection;
}
