import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:opti_job_app/features/ai/models/ai_exceptions.dart';

class FirebaseAiClient {
  FirebaseAiClient({
    required FirebaseAI firebaseAI,
    required FirebaseAuth auth,
    String? model,
  }) : _auth = auth,
       _modelName =
           model ??
           const String.fromEnvironment(
             'FIREBASE_AI_MODEL',
             defaultValue: 'gemini-2.0-flash',
           ),
       _firebaseAI = firebaseAI;

  final FirebaseAI _firebaseAI;
  final FirebaseAuth _auth;
  final String _modelName;
  static const Duration _requestTimeout = Duration(
    seconds: int.fromEnvironment(
      'FIREBASE_AI_TIMEOUT_SECONDS',
      defaultValue: 45,
    ),
  );

  GenerativeModel _model({GenerationConfig? generationConfig}) {
    return _firebaseAI.generativeModel(
      model: _modelName,
      generationConfig: generationConfig,
    );
  }

  Future<String> generateText(
    String prompt, {
    GenerationConfig? generationConfig,
  }) async {
    try {
      final response = await _generateContent(
        prompt,
        generationConfig: generationConfig,
      );
      final text = response.text?.trim() ?? '';
      if (text.isEmpty) {
        throw const AiRequestException('Respuesta vacía del servicio de IA.');
      }
      return text;
    } on TimeoutException {
      throw const AiRequestException(
        'La solicitud de IA tardó demasiado. Intenta nuevamente.',
      );
    } on FirebaseAIException catch (e) {
      throw AiRequestException(_mapFirebaseAiError(e));
    } on FirebaseException catch (e) {
      throw AiRequestException(_mapFirebaseCoreError(e));
    } catch (e, stackTrace) {
      _logUnexpectedError(error: e, stackTrace: stackTrace);
      throw const AiRequestException(
        'No se pudo completar la solicitud de IA.',
      );
    }
  }

  Future<Map<String, dynamic>> generateJson(
    String prompt, {
    Schema? responseSchema,
    GenerationConfig? generationConfig,
  }) async {
    final config = GenerationConfig(
      responseMimeType: 'application/json',
      responseSchema: responseSchema,
      maxOutputTokens: generationConfig?.maxOutputTokens,
      temperature: generationConfig?.temperature,
      topP: generationConfig?.topP,
      topK: generationConfig?.topK,
      presencePenalty: generationConfig?.presencePenalty,
      frequencyPenalty: generationConfig?.frequencyPenalty,
      candidateCount: generationConfig?.candidateCount,
      stopSequences: generationConfig?.stopSequences,
    );

    try {
      final response = await _generateContent(prompt, generationConfig: config);
      final raw = response.text?.trim() ?? '';
      if (raw.isEmpty) {
        throw const AiRequestException('Respuesta vacía del servicio de IA.');
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        throw AiRequestException('Respuesta inválida del servicio de IA: $raw');
      }

      if (decoded is String) {
        final inner = decoded.trim();
        if (inner.startsWith('{') || inner.startsWith('[')) {
          try {
            decoded = jsonDecode(inner);
          } catch (_) {
            // Fall through to validation below.
          }
        }
      }

      if (decoded is! Map<String, dynamic>) {
        throw AiRequestException('Respuesta inválida del servicio de IA: $raw');
      }

      return decoded;
    } on TimeoutException {
      throw const AiRequestException(
        'La solicitud de IA tardó demasiado. Intenta nuevamente.',
      );
    } on FirebaseAIException catch (e) {
      throw AiRequestException(_mapFirebaseAiError(e));
    } on FirebaseException catch (e) {
      throw AiRequestException(_mapFirebaseCoreError(e));
    } catch (e) {
      if (e is AiRequestException) rethrow;
      throw const AiRequestException(
        'No se pudo completar la solicitud de IA.',
      );
    }
  }

  Future<GenerateContentResponse> _generateContent(
    String prompt, {
    GenerationConfig? generationConfig,
  }) {
    return _model(
      generationConfig: generationConfig,
    ).generateContent([Content.text(prompt)]).timeout(_requestTimeout);
  }

  String _mapFirebaseAiError(FirebaseAIException e) {
    if (kDebugMode) {
      final uid = _auth.currentUser?.uid;
      debugPrint('[FirebaseAI] error: $e (uid=${uid ?? "anon"})');
    }

    return switch (e) {
      InvalidApiKey() =>
        'Firebase AI no está configurado correctamente (API key inválida).',
      ServiceApiNotEnabled() =>
        'La API de Firebase AI no está habilitada en este proyecto.',
      UnsupportedUserLocation() =>
        'Firebase AI no está disponible en tu ubicación.',
      QuotaExceeded() =>
        'Se alcanzó el límite de uso de IA. Intenta más tarde.',
      _ => 'Error del servicio de IA. Intenta nuevamente.',
    };
  }

  String _mapFirebaseCoreError(FirebaseException e) {
    if (kDebugMode) {
      final uid = _auth.currentUser?.uid;
      debugPrint(
        '[FirebaseAI] firebase error: ${e.plugin}:${e.code} ${e.message} '
        '(uid=${uid ?? "anon"})',
      );
    }

    final message = (e.message ?? '').toLowerCase();
    final isAppCheckIssue =
        e.plugin == 'firebase_app_check' || message.contains('app check');

    if (isAppCheckIssue) {
      return 'App Check no está configurado correctamente para IA.';
    }

    return switch (e.code) {
      'permission-denied' =>
        'No tienes permisos para usar el servicio de IA en este momento.',
      'unavailable' =>
        'El servicio de IA no está disponible temporalmente. Intenta nuevamente.',
      _ => 'No se pudo completar la solicitud de IA.',
    };
  }

  void _logUnexpectedError({
    required Object error,
    required StackTrace stackTrace,
  }) {
    if (!kDebugMode) return;
    final uid = _auth.currentUser?.uid;
    debugPrint(
      '[FirebaseAI] unexpected error: $error (uid=${uid ?? "anon"})\n'
      '$stackTrace',
    );
  }
}
