import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/candidate.dart';
import '../models/company.dart';
import 'api_client.dart';

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
    final response = await _client.post<Map<String, dynamic>>(
      '/candidates/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    final data = response.data ?? <String, dynamic>{};
    final candidateJson =
        data['candidate'] as Map<String, dynamic>? ?? data;
    return Candidate.fromJson(candidateJson);
  }

  Future<Candidate> registerCandidate({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/candidates',
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );

    final data = response.data ?? <String, dynamic>{};
    final candidateJson = (data['candidate'] as Map<String, dynamic>? ?? {})
        ['user'] as Map<String, dynamic>? ??
        data['candidate'] as Map<String, dynamic>? ??
        data;
    return Candidate.fromJson(candidateJson);
  }

  Future<Company> loginCompany({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/companies/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    final data = response.data ?? <String, dynamic>{};
    final companyJson =
        data['company'] as Map<String, dynamic>? ?? data;
    return Company.fromJson(companyJson);
  }

  Future<Company> registerCompany({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/companies',
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
    final data = response.data ?? <String, dynamic>{};
    final companyJson = (data['company'] as Map<String, dynamic>? ?? {})
        ['user'] as Map<String, dynamic>? ??
        data['company'] as Map<String, dynamic>? ??
        data;
    return Company.fromJson(companyJson);
  }
}
