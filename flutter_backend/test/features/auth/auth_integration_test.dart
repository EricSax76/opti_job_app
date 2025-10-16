import 'dart:convert';

import 'package:infojobs_flutter_backend/config/env.dart';
import 'package:infojobs_flutter_backend/data/datasource/database.dart';
import 'package:infojobs_flutter_backend/data/repositories/user_repository.dart';
import 'package:infojobs_flutter_backend/features/auth/auth_router.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late DatabaseManager db;
  late DbUserRepository repository;
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

  Future<void> deleteUser(String email) async {
    const sql = 'DELETE FROM users WHERE email = @email';
    await db.run(
      (session) => session.execute(
        Sql.named(sql),
        parameters: {'email': email},
      ),
    );
  }

  setUpAll(() {
    final env = AppEnvironment.load(filename: '.env');
    db = DatabaseManager(env);
    repository = DbUserRepository(db);
    handler = AuthRouter(
      repository,
      jwtSecret: env.jwtSecret,
    ).router.call;
  });

  tearDown(() async {
    // Limpia las cuentas de prueba que pudiéramos haber creado
    await deleteUser('integration_new@example.com');
    await deleteUser('integration_duplicate@example.com');
    await deleteUser('integration_login@example.com');
  });

  tearDownAll(() async {
    await db.close();
  });

  group('AuthRouter (DB integration)', () {
    test('register returns 201 and expected body', () async {
      await deleteUser('integration_new@example.com');

      final response = await post('/register', {
        'name': 'Integration User',
        'email': 'integration_new@example.com',
        'password': 'secret123',
        'role': 'candidate',
      });

      expect(response.statusCode, 201);
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['message'], 'Usuario registrado correctamente');
      expect(body['user'], isA<Map<String, dynamic>>());
      expect(body['user']['email'], 'integration_new@example.com');
    });

    test('register duplicate email returns 400', () async {
      await deleteUser('integration_duplicate@example.com');

      final basePayload = {
        'name': 'Existing User',
        'email': 'integration_duplicate@example.com',
        'password': 'secret123',
        'role': 'candidate',
      };

      final first = await post('/register', basePayload);
      expect(first.statusCode, 201);

      final duplicate = await post('/register', basePayload);
      expect(duplicate.statusCode, 400);
      final body =
          jsonDecode(await duplicate.readAsString()) as Map<String, dynamic>;
      expect(body['error'], 'El email ya está registrado');
    });

    test('login with valid credentials returns token', () async {
      await deleteUser('integration_login@example.com');

      final registerResponse = await post('/register', {
        'name': 'Login User',
        'email': 'integration_login@example.com',
        'password': 'secret123',
        'role': 'candidate',
      });
      expect(registerResponse.statusCode, 201);

      final response = await post('/login', {
        'email': 'integration_login@example.com',
        'password': 'secret123',
      });
      expect(response.statusCode, 200);
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['message'], 'Login exitoso');
      expect(body['token'], isNotEmpty);
      expect(body['user']['email'], 'integration_login@example.com');
    });

    test('login with wrong password returns 401', () async {
      await deleteUser('integration_login@example.com');
      final registerResponse = await post('/register', {
        'name': 'Login User',
        'email': 'integration_login@example.com',
        'password': 'secret123',
        'role': 'candidate',
      });
      expect(registerResponse.statusCode, 201);

      final response = await post('/login', {
        'email': 'integration_login@example.com',
        'password': 'wrong',
      });

      expect(response.statusCode, 401);
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['error'], 'Credenciales inválidas');
    });
  });
}
