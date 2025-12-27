import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
           _normalizeBaseUrl(
             baseUrl ??
                 const String.fromEnvironment('AI_BASE_URL', defaultValue: ''),
           ),
       _timeout = timeout;

  final http.Client _client;
  final FirebaseAuth _auth;
  final String _baseUrl;
  final Duration _timeout;

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.replaceFirst(RegExp(r'/+$'), '');
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> payload,
  }) async {
    if (_baseUrl.trim().isEmpty) {
      throw const AiConfigurationException(
        'Falta configurar AI_BASE_URL (ej: flutter run --dart-define=AI_BASE_URL=https://tu-backend.com).',
      );
    }

    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$normalizedPath');
    final token = await _auth.currentUser?.getIdToken();

    if (kDebugMode) {
      debugPrint('[AI] POST $uri (auth=${token != null ? "yes" : "no"})');
    }

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

    final raw = response.body.trim();
    if (kDebugMode) {
      debugPrint('[AI] <- ${response.statusCode} (${raw.length} bytes)');
    }
    if (raw.isEmpty) {
      throw const AiRequestException('Respuesta vacía del servicio de IA.');
    }

    String snippet(String input, {int max = 220}) {
      final compact = input.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (compact.length <= max) return compact;
      return '${compact.substring(0, max)}…';
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiRequestException(
          'Error del servicio de IA (${response.statusCode}).',
        );
      }
      throw AiRequestException(
        'Respuesta inválida del servicio de IA: ${snippet(raw)}',
      );
    }

    if (decoded is String) {
      final inner = decoded.trim();
      if (inner.startsWith('{') || inner.startsWith('[')) {
        try {
          decoded = jsonDecode(inner);
        } catch (_) {
          // Keep original decoded value; validation below will throw.
        }
      }
    }

    if (decoded is! Map<String, dynamic>) {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiRequestException(
          'Error del servicio de IA (${response.statusCode}).',
        );
      }
      throw AiRequestException(
        'Respuesta inválida del servicio de IA: ${snippet(raw)}',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = (decoded['error'] is String)
          ? (decoded['error'] as String).trim()
          : '';
      if (error.isNotEmpty) {
        throw AiRequestException(
          'Error del servicio de IA (${response.statusCode}): $error',
        );
      }
      throw AiRequestException(
        'Error del servicio de IA (${response.statusCode}).',
      );
    }

    return decoded;
  }
}
