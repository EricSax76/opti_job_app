import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:opti_job_app/modules/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/modules/ai/models/ai_job_offer_draft.dart';
import 'package:opti_job_app/modules/ai/models/ai_match_result.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class AiService {
  AiService({
    http.Client? client,
    FirebaseAuth? auth,
    String? baseUrl,
    Duration timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client(),
       _auth = auth ?? FirebaseAuth.instance,
       _baseUrl =
           baseUrl ?? const String.fromEnvironment('AI_BASE_URL', defaultValue: ''),
       _timeout = timeout;

  final http.Client _client;
  final FirebaseAuth _auth;
  final String _baseUrl;
  final Duration _timeout;

  Future<String> improveCurriculumSummary({
    required Curriculum curriculum,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    if (_baseUrl.trim().isEmpty) {
      throw const AiConfigurationException(
        'Falta configurar AI_BASE_URL (usa --dart-define=AI_BASE_URL=...).',
      );
    }

    final uri = Uri.parse('$_baseUrl/ai/improve-cv-summary');
    final token = await _auth.currentUser?.getIdToken();

    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final payload = <String, dynamic>{
      'cv': _compactCurriculum(curriculum),
      'locale': locale,
      'quality': quality,
    };

    late http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(_timeout);
    } on TimeoutException {
      throw const AiRequestException('Tiempo de espera agotado.');
    } catch (_) {
      throw const AiRequestException('No se pudo conectar con el servicio de IA.');
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

    final summary = decoded['summary'];
    if (summary is! String || summary.trim().isEmpty) {
      throw const AiRequestException('El servicio de IA no devolvió un resumen.');
    }

    return summary.trim();
  }

  Future<AiMatchResult> matchOfferCandidate({
    required Curriculum curriculum,
    required JobOffer offer,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    if (_baseUrl.trim().isEmpty) {
      throw const AiConfigurationException(
        'Falta configurar AI_BASE_URL (usa --dart-define=AI_BASE_URL=...).',
      );
    }

    final uri = Uri.parse('$_baseUrl/ai/match-offer-candidate');
    final token = await _auth.currentUser?.getIdToken();

    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final payload = <String, dynamic>{
      'cv': _compactCurriculum(curriculum),
      'offer': _compactOffer(offer),
      'locale': locale,
      'quality': quality,
    };

    late http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(_timeout);
    } on TimeoutException {
      throw const AiRequestException('Tiempo de espera agotado.');
    } catch (_) {
      throw const AiRequestException('No se pudo conectar con el servicio de IA.');
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

    try {
      return AiMatchResult.fromJson(decoded);
    } catch (_) {
      throw const AiRequestException('Respuesta inválida del servicio de IA.');
    }
  }

  Future<AiJobOfferDraft> generateJobOffer({
    required Map<String, dynamic> criteria,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    if (_baseUrl.trim().isEmpty) {
      throw const AiConfigurationException(
        'Falta configurar AI_BASE_URL (usa --dart-define=AI_BASE_URL=...).',
      );
    }

    final uri = Uri.parse('$_baseUrl/ai/generate-job-offer');
    final token = await _auth.currentUser?.getIdToken();

    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final payload = <String, dynamic>{
      'criteria': _compactCriteria(criteria),
      'locale': locale,
      'quality': quality,
    };

    late http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(_timeout);
    } on TimeoutException {
      throw const AiRequestException('Tiempo de espera agotado.');
    } catch (_) {
      throw const AiRequestException('No se pudo conectar con el servicio de IA.');
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

    try {
      return AiJobOfferDraft.fromJson(decoded);
    } catch (_) {
      throw const AiRequestException('Respuesta inválida del servicio de IA.');
    }
  }

  Map<String, dynamic> _compactCurriculum(Curriculum curriculum) {
    final trimmedSkills = curriculum.skills
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final uniqueSkills = <String>[];
    for (final skill in trimmedSkills) {
      final alreadyAdded = uniqueSkills.any(
        (value) => value.toLowerCase() == skill.toLowerCase(),
      );
      if (!alreadyAdded) uniqueSkills.add(skill);
      if (uniqueSkills.length >= 25) break;
    }

    List<Map<String, dynamic>> takeLastItems(List<dynamic> items, int max) {
      final start = items.length > max ? items.length - max : 0;
      return items
          .sublist(start)
          .whereType<Map<String, dynamic>>()
          .map((item) {
        String s(dynamic v, int limit) {
          final text = v is String ? v.trim() : '';
          return text.length <= limit ? text : text.substring(0, limit);
        }
        return <String, dynamic>{
          'title': s(item['title'], 80),
          'subtitle': s(item['subtitle'], 80),
          'period': s(item['period'], 40),
          'description': s(item['description'], 600),
        };
      }).toList();
    }

    final raw = curriculum.toJson();
    final experiences = (raw['experiences'] as List<dynamic>? ?? const []);
    final education = (raw['education'] as List<dynamic>? ?? const []);

    String truncate(String value, int max) =>
        value.length <= max ? value : value.substring(0, max);

    return <String, dynamic>{
      'headline': truncate(curriculum.headline.trim(), 120),
      'summary': truncate(curriculum.summary.trim(), 900),
      'skills': uniqueSkills,
      'experiences': takeLastItems(experiences, 3),
      'education': takeLastItems(education, 3),
      if (curriculum.updatedAt != null)
        'updated_at': curriculum.updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> _compactOffer(JobOffer offer) {
    String truncate(String value, int max) =>
        value.length <= max ? value : value.substring(0, max);

    return <String, dynamic>{
      'id': offer.id,
      'title': truncate(offer.title.trim(), 140),
      'location': truncate(offer.location.trim(), 120),
      'description': truncate(offer.description.trim(), 1600),
      if (offer.jobType != null) 'job_type': truncate(offer.jobType!.trim(), 60),
      if (offer.education != null)
        'education': truncate(offer.education!.trim(), 120),
      if (offer.keyIndicators != null)
        'key_indicators': truncate(offer.keyIndicators!.trim(), 600),
      if (offer.salaryMin != null) 'salary_min': offer.salaryMin,
      if (offer.salaryMax != null) 'salary_max': offer.salaryMax,
    };
  }

  Map<String, dynamic> _compactCriteria(Map<String, dynamic> criteria) {
    String? s(dynamic value, int max) {
      if (value is! String) return null;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return trimmed.length <= max ? trimmed : trimmed.substring(0, max);
    }

    List<String> list(dynamic value, int maxItems, int maxLen) {
      if (value is! List) return const [];
      final out = <String>[];
      for (final item in value) {
        if (item is! String) continue;
        final trimmed = item.trim();
        if (trimmed.isEmpty) continue;
        out.add(trimmed.length <= maxLen ? trimmed : trimmed.substring(0, maxLen));
        if (out.length >= maxItems) break;
      }
      return out;
    }

    return <String, dynamic>{
      if (s(criteria['role'], 80) case final v?) 'role': v,
      if (s(criteria['seniority'], 40) case final v?) 'seniority': v,
      if (s(criteria['companyName'], 80) case final v?) 'companyName': v,
      if (s(criteria['location'], 80) case final v?) 'location': v,
      if (s(criteria['jobType'], 40) case final v?) 'jobType': v,
      if (s(criteria['salaryMin'], 20) case final v?) 'salaryMin': v,
      if (s(criteria['salaryMax'], 20) case final v?) 'salaryMax': v,
      if (s(criteria['education'], 80) case final v?) 'education': v,
      if (s(criteria['tone'], 40) case final v?) 'tone': v,
      if (s(criteria['language'], 20) case final v?) 'language': v,
      if (s(criteria['about'], 600) case final v?) 'about': v,
      if (s(criteria['responsibilities'], 900) case final v?)
        'responsibilities': v,
      if (s(criteria['requirements'], 900) case final v?) 'requirements': v,
      if (s(criteria['benefits'], 600) case final v?) 'benefits': v,
      if (s(criteria['notes'], 400) case final v?) 'notes': v,
      'mustHaveSkills': list(criteria['mustHaveSkills'], 12, 40),
      'niceToHaveSkills': list(criteria['niceToHaveSkills'], 12, 40),
    };
  }
}
