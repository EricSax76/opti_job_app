import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:infojobs_flutter_backend/data/models/user.dart';
import 'package:infojobs_flutter_backend/data/repositories/user_repository.dart';
import 'package:infojobs_flutter_backend/features/auth/auth_router.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late FakeUserRepository repository;
  late Handler handler;

  Future<Response> post(String path, Map<String, Object?> body) {
    final request = Request(
      'POST',
      Uri.parse('http://localhost$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return Future.sync(() => handler(request));
  }

  setUp(() {
    repository = FakeUserRepository();
    handler = AuthRouter(
      repository,
      jwtSecret: 'test-secret',
    ).router.call;
  });

  group('AuthRouter register', () {
    test('creates user and hashes password', () async {
      final response = await post('/register', {
        'name': 'Ada Lovelace',
        'email': 'ada@example.com',
        'password': 's3cret',
      });

      expect(response.statusCode, 201);
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['message'], 'Usuario registrado correctamente');
      final user = body['user'] as Map<String, dynamic>;
      expect(user['name'], 'Ada Lovelace');
      expect(user, isNot(contains('password_hash')));

      final storedHash = repository.passwordFor('ada@example.com');
      expect(storedHash, isNotNull);
      expect(storedHash, isNot(equals('s3cret')));
      expect(BCrypt.checkpw('s3cret', storedHash!), isTrue);
    });

    test('rejects missing fields', () async {
      final response = await post('/register', {
        'email': 'grace@example.com',
      });

      expect(response.statusCode, 400);
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['error'], 'name, email y password son obligatorios');
    });

    test('rejects duplicated email', () async {
      await post('/register', {
        'name': 'Existing',
        'email': 'dup@example.com',
        'password': 'secret',
      });

      final response = await post('/register', {
        'name': 'Duplicated',
        'email': 'dup@example.com',
        'password': 'secret',
      });

      expect(response.statusCode, 400);
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['error'], 'El email ya está registrado');
    });
  });

  group('AuthRouter login', () {
    const email = 'user@example.com';
    const password = 'password123';

    setUp(() async {
      await repository.createUser(
        name: 'User',
        email: email,
        passwordHash: BCrypt.hashpw(password, BCrypt.gensalt()),
        role: 'candidate',
      );
    });

    test('returns token and user on success', () async {
      final response = await post('/login', {
        'email': email,
        'password': password,
      });

      expect(response.statusCode, 200);
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['message'], 'Login exitoso');
      expect(body['token'], isNotEmpty);
      final user = body['user'] as Map<String, dynamic>;
      expect(user['email'], email);
    });

    test('rejects invalid credentials', () async {
      final response = await post('/login', {
        'email': email,
        'password': 'wrong',
      });

      expect(response.statusCode, 401);
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['error'], 'Credenciales inválidas');
    });

    test('rejects missing fields', () async {
      final response = await post('/login', {
        'email': email,
      });

      expect(response.statusCode, 400);
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['error'], 'email y password son obligatorios');
    });
  });

  group('AuthRouter logout', () {
    test('returns success message', () async {
      final response = await post('/logout', {});

      expect(response.statusCode, 200);
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['message'], 'Logout exitoso');
    });
  });
}

class FakeUserRepository implements UserRepository {
  final Map<String, User> _users = {};
  int _idCounter = 1;

  @override
  Future<User> createUser({
    required String name,
    required String email,
    required String passwordHash,
    String role = 'candidate',
  }) async {
    if (_users.containsKey(email)) {
      throw const DuplicateEmailException();
    }
    final user = User(
      id: _idCounter++,
      name: name,
      email: email,
      role: role,
      passwordHash: passwordHash,
    );
    _users[email] = user;
    return user;
  }

  @override
  Future<User?> findByEmail(String email) async {
    return _users[email];
  }

  String? passwordFor(String email) => _users[email]?.passwordHash;
}
