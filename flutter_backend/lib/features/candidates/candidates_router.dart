import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../config/logger.dart';
import '../../data/repositories/candidate_repository.dart';
import '../../utils/response.dart';

class CandidatesRouter {
  CandidatesRouter(
    this._repository, {
    required this.jwtSecret,
  });

  final CandidateRepository _repository;
  final String jwtSecret;

  Router get router {
    final router = Router();
    router.post('/', _handleRegister);
    router.post('/login', _handleLogin);
    router.get('/', _handleList);
    router.get('/<id|[0-9]+>', _handleGetById);
    return router;
  }

  Future<Response> _handleRegister(Request request) async {
    final body = await request.readAsString();
    final payload = jsonDecode(body) as Map<String, dynamic>;

    final name = payload['name'] as String?;
    final email = payload['email'] as String?;
    final password = payload['password'] as String?;

    if (name == null || email == null || password == null) {
      return jsonError('name, email y password son obligatorios');
    }

    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    try {
      final candidate = await _repository.createCandidate(
        name: name,
        email: email,
        passwordHash: hashedPassword,
      );

      return jsonResponse(
        {
          'message': 'Candidato registrado correctamente',
          'candidate': candidate.toJson(),
        },
        statusCode: 201,
      );
    } on PostgreSQLException catch (error) {
      final message = error.code == '23505'
          ? 'El email ya está registrado'
          : 'Error al registrar el candidato';
      return jsonError(message, statusCode: 400);
    }
  }

  Future<Response> _handleLogin(Request request) async {
    final body = await request.readAsString();
    final payload = jsonDecode(body) as Map<String, dynamic>;

    final email = payload['email'] as String?;
    final password = payload['password'] as String?;

    if (email == null || password == null) {
      return jsonError('email y password son obligatorios');
    }

    final user = await _repository.findUserByEmail(email);
    if (user == null || !BCrypt.checkpw(password, user.passwordHash)) {
      return jsonError('Email o contraseña incorrectos', statusCode: 401);
    }

    final candidate = await _repository.findCandidateByUserId(user.id);
    if (candidate == null) {
      appLogger.warning('Usuario sin candidato vinculado: ${user.id}');
      return jsonError('Cuenta inválida', statusCode: 400);
    }

    final jwt = JWT(
      {
        'sub': user.id,
        'role': user.role,
        'email': user.email,
      },
    );

    final token = jwt.sign(
      SecretKey(jwtSecret),
      expiresIn: const Duration(hours: 12),
    );

    final responseBody = candidate.toJson()
      ..addAll({
        'token': token,
      });

    return jsonResponse({
      'message': 'Login exitoso',
      'candidate': responseBody,
    });
  }

  Future<Response> _handleList(Request request) async {
    final candidates = await _repository.findAll();
    return jsonResponse(
      candidates.map((candidate) => candidate.toJson()).toList(),
    );
  }

  Future<Response> _handleGetById(Request request, String id) async {
    final candidate = await _repository.findById(int.parse(id));
    if (candidate == null) {
      return jsonError('Candidato no encontrado', statusCode: 404);
    }
    return jsonResponse(candidate.toJson());
  }
}
