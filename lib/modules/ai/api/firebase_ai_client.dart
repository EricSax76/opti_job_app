import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:opti_job_app/modules/ai/models/ai_exceptions.dart';

class FirebaseAiClient {
  FirebaseAiClient({FirebaseAI? firebaseAI, FirebaseAuth? auth, String? model})
    : _auth = auth ?? FirebaseAuth.instance,
      _modelName =
          model ??
          const String.fromEnvironment(
            'FIREBASE_AI_MODEL',
            defaultValue: 'gemini-2.0-flash',
          ),
      _firebaseAI = firebaseAI ?? _createFirebaseAI(auth: auth);

  final FirebaseAI _firebaseAI;
  final FirebaseAuth _auth;
  final String _modelName;

  static FirebaseAI _createFirebaseAI({FirebaseAuth? auth}) {
    const backend = String.fromEnvironment(
      'FIREBASE_AI_BACKEND',
      defaultValue: 'vertex',
    ); // 'vertex' | 'google'

    if (backend == 'google') {
      return FirebaseAI.googleAI(
        auth: auth ?? FirebaseAuth.instance,
        appCheck: FirebaseAppCheck.instance,
      );
    }

    const location = String.fromEnvironment(
      'FIREBASE_AI_LOCATION',
      defaultValue: 'europe-southwest1',
    );
    return FirebaseAI.vertexAI(
      auth: auth ?? FirebaseAuth.instance,
      location: location,
      appCheck: FirebaseAppCheck.instance,
    );
  }

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
      final response = await _model(
        generationConfig: generationConfig,
      ).generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      if (text.isEmpty) {
        throw const AiRequestException('Respuesta vacía del servicio de IA.');
      }
      return text;
    } on FirebaseAIException catch (e) {
      throw AiRequestException(_mapFirebaseAiError(e));
    } catch (_) {
      throw const AiRequestException(
        'No se pudo completar la solicitud de IA.',
      );
    }
  }

  Future<Map<String, dynamic>> generateJson(
    String prompt, {
    required Schema responseSchema,
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
      final response = await _model(
        generationConfig: config,
      ).generateContent([Content.text(prompt)]);
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
    } on FirebaseAIException catch (e) {
      throw AiRequestException(_mapFirebaseAiError(e));
    } catch (e) {
      if (e is AiRequestException) rethrow;
      throw const AiRequestException(
        'No se pudo completar la solicitud de IA.',
      );
    }
  }

  String _mapFirebaseAiError(FirebaseAIException e) {
    if (kDebugMode) {
      final uid = _auth.currentUser?.uid;
      debugPrint('[FirebaseAI] error: $e (uid=${uid ?? "anon"})');
    }

    return switch (e) {
      InvalidApiKey() =>
        'Firebase AI no está configurado correctamente (API key inválida).',
      UnsupportedUserLocation() =>
        'Firebase AI no está disponible en tu ubicación.',
      _ => 'Error del servicio de IA. Intenta nuevamente.',
    };
  }
}
