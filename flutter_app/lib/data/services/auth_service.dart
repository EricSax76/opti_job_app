import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:infojobs_flutter_app/data/models/auth_session.dart';
import 'package:infojobs_flutter_app/data/models/candidate.dart';
import 'package:infojobs_flutter_app/data/models/company.dart';
import 'package:infojobs_flutter_app/data/services/api_client.dart';
import 'package:infojobs_flutter_app/data/services/token_storage.dart';
import 'package:infojobs_flutter_app/utils/app_exception.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(tokenStorageProvider);
  return AuthService(client, storage);
});

class AuthService {
  AuthService(this._client, this._tokenStorage);

  final Dio _client;
  final TokenStorage _tokenStorage;

  Future<Candidate> loginCandidate({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _login(
        email: email,
        password: password,
        role: 'candidate',
      );
      await _tokenStorage.save(result.session);
      final profile = result.profile ?? <String, dynamic>{};
      return Candidate.fromJson(
        profile['profile'] as Map<String, dynamic>? ?? profile,
      );
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
      await _client.post<Map<String, dynamic>>(
        '/candidates',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );
      return loginCandidate(email: email, password: password);
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
      final result = await _login(
        email: email,
        password: password,
        role: 'recruiter',
      );
      await _tokenStorage.save(result.session);
      final profile = result.profile ?? <String, dynamic>{};
      return Company.fromJson(
        profile['profile'] as Map<String, dynamic>? ?? profile,
      );
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
      await _client.post<Map<String, dynamic>>(
        '/companies',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );
      return loginCompany(email: email, password: password);
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

  Future<void> logout() async {
    await _tokenStorage.clear();
  }

  Future<({AuthSession session, Map<String, dynamic>? profile})> _login({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        'role': role,
      },
    );

    final data = response.data ?? <String, dynamic>{};
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    final expiresIn = (data['expiresIn'] as num?)?.toInt() ?? 0;

    if (accessToken == null || refreshToken == null) {
      throw const FormatException('Missing token payload');
    }

    final profileResponse = await _client.get<Map<String, dynamic>>(
      '/auth/me',
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
    final profileData = profileResponse.data ?? <String, dynamic>{};
    final userId = profileData['sub'] as String? ??
        (profileData['profile'] as Map<String, dynamic>?)?['id'] as String? ??
        '';

    if (userId.isEmpty) {
      throw const FormatException('Missing user identifier');
    }

    return (
      session: AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresIn: expiresIn,
        role: role,
        userId: userId,
      ),
      profile: profileData,
    );
  }
}
