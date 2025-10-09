import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:infojobs_flutter_app/data/models/candidate.dart';
import 'package:infojobs_flutter_app/data/models/company.dart';
import 'package:infojobs_flutter_app/data/services/api_client.dart';
import 'package:infojobs_flutter_app/utils/app_exception.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthService(client);
});

class AuthService {
  AuthService(this._client);

  final Dio _client;

  Future<Candidate> loginCandidate({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/candidates/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      final data = response.data ?? <String, dynamic>{};
      final candidateJson = data['candidate'] as Map<String, dynamic>? ??
          data['candidato'] as Map<String, dynamic>?;

      if (candidateJson == null || candidateJson.isEmpty) {
        throw const FormatException('Missing candidate payload');
      }

      return Candidate.fromJson(candidateJson);
    } on DioException catch (error) {
      throw AuthException(
        _extractErrorMessage(
          error,
          'No se pudo iniciar sesión. Verifica tus credenciales.',
        ),
      );
    }
  }

  Future<Candidate> registerCandidate({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/candidates',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      final data = response.data ?? <String, dynamic>{};
      final candidateEnvelope = data['candidate'] as Map<String, dynamic>? ??
          data['candidato'] as Map<String, dynamic>?;
      final candidateJson =
          candidateEnvelope?['user'] as Map<String, dynamic>? ??
              candidateEnvelope;

      if (candidateJson == null || candidateJson.isEmpty) {
        throw const FormatException('Missing candidate payload');
      }

      return Candidate.fromJson(candidateJson);
    } on DioException catch (error) {
      throw AuthException(
        _extractErrorMessage(
          error,
          'No se pudo completar el registro.',
        ),
      );
    }
  }

  Future<Company> loginCompany({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/companies/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      final data = response.data ?? <String, dynamic>{};
      final companyJson = data['company'] as Map<String, dynamic>? ??
          data['empresa'] as Map<String, dynamic>?;

      if (companyJson == null || companyJson.isEmpty) {
        throw const FormatException('Missing company payload');
      }

      return Company.fromJson(companyJson);
    } on DioException catch (error) {
      throw AuthException(
        _extractErrorMessage(
          error,
          'No se pudo iniciar sesión.',
        ),
      );
    }
  }

  Future<Company> registerCompany({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/companies',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );
      final data = response.data ?? <String, dynamic>{};
      final companyEnvelope = data['company'] as Map<String, dynamic>? ??
          data['empresa'] as Map<String, dynamic>?;
      final companyJson =
          companyEnvelope?['user'] as Map<String, dynamic>? ?? companyEnvelope;

      if (companyJson == null || companyJson.isEmpty) {
        throw const FormatException('Missing company payload');
      }

      return Company.fromJson(companyJson);
    } on DioException catch (error) {
      throw AuthException(
        _extractErrorMessage(
          error,
          'No se pudo completar el registro.',
        ),
      );
    }
  }

  String _extractErrorMessage(
    DioException error,
    String fallback,
  ) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    } else if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return fallback;
  }
}
