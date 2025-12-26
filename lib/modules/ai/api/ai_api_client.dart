import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:opti_job_app/modules/ai/models/ai_exceptions.dart';

class AiApiClient {
  AiApiClient({
    http.Client? client,
    FirebaseAuth? auth,
    String? baseUrl,
    Duration timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client(),
       _auth = auth ?? FirebaseAuth.instance,
       _baseUrl =
           baseUrl ??
           const String.fromEnvironment('AI_BASE_URL', defaultValue: ''),
       _timeout = timeout;

  final http.Client _client;
  final FirebaseAuth _auth;
  final String _baseUrl;
  final Duration _timeout;

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> payload,
  }) async {
    if (_baseUrl.trim().isEmpty) {
      throw const AiConfigurationException(
        'Falta configurar AI_BASE_URL (usa --dart-define=AI_BASE_URL=...).',
      );
    }

    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$normalizedPath');
    final token = await _auth.currentUser?.getIdToken();

    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    late http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(_timeout);
    } on TimeoutException {
      throw const AiRequestException('Tiempo de espera agotado.');
    } catch (_) {
      throw const AiRequestException(
        'No se pudo conectar con el servicio de IA.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiRequestException(
        'Error del servicio de IA (${response.statusCode}).',
      );
    }

    final raw = response.body.trim();
    if (raw.isEmpty) {
      throw const AiRequestException('Respuesta vacía del servicio de IA.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const AiRequestException('Respuesta inválida del servicio de IA.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const AiRequestException('Respuesta inválida del servicio de IA.');
    }

    return decoded;
  }
}
