import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../data/repositories/company_repository.dart';
import '../../utils/response.dart';

class CompaniesRouter {
  CompaniesRouter(
    this._repository, {
    required this.jwtSecret,
  });

  final CompanyRepository _repository;
  final String jwtSecret;

  Router get router {
    final router = Router();
    router.post('/', _handleRegister);
    router.post('/login', _handleLogin);
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

    try {
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
      final company = await _repository.createCompany(
        name: name,
        email: email,
        passwordHash: hashedPassword,
      );

      return jsonResponse(
        {
          'message': 'Empresa registrada correctamente',
          'company': company.toJson(),
        },
        statusCode: 201,
      );
    } on PostgreSQLException catch (error) {
      final message = error.code == '23505'
          ? 'El email ya está registrado'
          : 'Error al registrar la empresa';
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

    final company = await _repository.findCompanyByUserId(user.id);
    if (company == null) {
      return jsonError('Cuenta inválida', statusCode: 400);
    }

    final token = JWT(
      {
        'sub': user.id,
        'role': user.role,
        'email': user.email,
      },
    ).sign(
      SecretKey(jwtSecret),
      expiresIn: const Duration(hours: 12),
    );

    final responseBody = company.toJson()
      ..addAll({'token': token});

    return jsonResponse({
      'message': 'Login exitoso',
      'company': responseBody,
    });
  }
}
