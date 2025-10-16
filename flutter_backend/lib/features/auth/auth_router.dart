import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../data/models/user.dart';
import '../../data/repositories/user_repository.dart';
import '../../utils/response.dart';

class AuthRouter {
  AuthRouter(
    this._repository, {
    required this.jwtSecret,
  });

  final UserRepository _repository;
  final String jwtSecret;

  Router get router {
    final router = Router();
    router.post('/register', _handleRegister);
    router.post('/login', _handleLogin);
    router.post('/logout', _handleLogout);
    return router;
  }

  Future<Response> _handleRegister(Request request) async {
    final payload = await _readJson(request);

    final name = payload['name'] as String?;
    final email = payload['email'] as String?;
    final password = payload['password'] as String?;
    final role = payload['role'] as String? ?? 'candidate';

    if (name == null || email == null || password == null) {
      return jsonError('name, email y password son obligatorios');
    }

    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    try {
      final user = await _repository.createUser(
        name: name,
        email: email,
        passwordHash: hashedPassword,
        role: role,
      );

      return jsonResponse(
        {
          'message': 'Usuario registrado correctamente',
          'user': user.toJson(),
        },
        statusCode: 201,
      );
    } on DuplicateEmailException {
      return jsonError('El email ya está registrado', statusCode: 400);
    } on UserRepositoryException catch (error) {
      return jsonError(error.message, statusCode: 500);
    }
  }

  Future<Response> _handleLogin(Request request) async {
    final payload = await _readJson(request);

    final email = payload['email'] as String?;
    final password = payload['password'] as String?;

    if (email == null || password == null) {
      return jsonError('email y password son obligatorios');
    }

    final user = await _repository.findByEmail(email);
    if (user == null || !_verifyPassword(password, user.passwordHash)) {
      return jsonError('Credenciales inválidas', statusCode: 401);
    }

    final token = _generateToken(user);

    return jsonResponse({
      'message': 'Login exitoso',
      'token': token,
      'user': user.toJson(),
    });
  }

  Future<Response> _handleLogout(Request request) async {
    return jsonResponse({
      'message': 'Logout exitoso',
    });
  }

  Future<Map<String, dynamic>> _readJson(Request request) async {
    final body = await request.readAsString();
    if (body.isEmpty) return {};
    return jsonDecode(body) as Map<String, dynamic>;
  }

  String _generateToken(User user) {
    final jwt = JWT(
      {
        'sub': user.id,
        'role': user.role,
        'email': user.email,
      },
    );

    return jwt.sign(
      SecretKey(jwtSecret),
      expiresIn: const Duration(hours: 12),
    );
  }

  bool _verifyPassword(String raw, String hash) {
    return BCrypt.checkpw(raw, hash);
  }
}
