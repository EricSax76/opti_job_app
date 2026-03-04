import 'package:flutter/foundation.dart';
import 'package:opti_job_app/features/ai/api/document_parser.dart';
import 'package:opti_job_app/features/ai/api/firebase_ai_client.dart';
import 'package:opti_job_app/features/ai/prompts/ai_prompts.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class CvAnalysisService {
  final FirebaseAiClient _aiClient;

  CvAnalysisService({required FirebaseAiClient aiClient})
    : _aiClient = aiClient;

  Future<CvAnalysisResult> analyzeCvFile(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      // 1. Extraer texto del documento
      String text = '';
      final lowerFileName = fileName.toLowerCase();
      if (lowerFileName.endsWith('.docx')) {
        text = await compute(_extractTextFromDocx, bytes);
      } else if (lowerFileName.endsWith('.pdf')) {
        text = await compute(_extractTextFromPdf, bytes);
      }

      if (text.isEmpty) {
        throw Exception(
          'No se pudo leer el texto del archivo. Usa un PDF/DOCX con texto seleccionable.',
        );
      }

      // 2. Consultar a la IA
      final prompt = AiPrompts.extractCvData(cvText: text);
      final json = await _aiClient.generateJson(prompt, responseSchema: null);

      // 3. Mapear respuesta
      return _mapJsonToResult(json);
    } catch (e) {
      throw Exception('Error al analizar CV: $e');
    }
  }

  CvAnalysisResult _mapJsonToResult(Map<String, dynamic> json) {
    final personal = _asStringMap(json['personal']);

    final skills = (json['skills'] as List? ?? const [])
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    final experiences = (json['experience'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => CurriculumItem(
            title: _asTrimmedString(e['role']),
            subtitle: _asTrimmedString(e['company']),
            period: _asTrimmedString(e['date_range']),
            description: _asTrimmedString(e['description']),
          ),
        )
        .where(_hasMeaningfulItemData)
        .toList();

    final education = (json['education'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => CurriculumItem(
            title: _asTrimmedString(e['degree']),
            subtitle: _asTrimmedString(e['school']),
            period: _asTrimmedString(e['date_range']),
            description: '',
          ),
        )
        .where(_hasMeaningfulItemData)
        .toList();

    return CvAnalysisResult(
      summary: _asTrimmedString(personal['summary']),
      phone: _asTrimmedString(personal['phone']),
      location: _asTrimmedString(personal['location']),
      skills: skills,
      experiences: experiences,
      education: education,
    );
  }

  Map<String, dynamic> _asStringMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const <String, dynamic>{};
  }

  String _asTrimmedString(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static bool _hasMeaningfulItemData(CurriculumItem item) {
    return item.title.trim().isNotEmpty ||
        item.subtitle.trim().isNotEmpty ||
        item.period.trim().isNotEmpty ||
        item.description.trim().isNotEmpty;
  }
}

String _extractTextFromDocx(Uint8List bytes) {
  return DocumentParser.extractTextFromDocx(bytes);
}

String _extractTextFromPdf(Uint8List bytes) {
  return DocumentParser.extractTextFromPdf(bytes);
}

class CvAnalysisResult {
  final String summary;
  final String phone;
  final String location;
  final List<String> skills;
  final List<CurriculumItem> experiences;
  final List<CurriculumItem> education;

  CvAnalysisResult({
    required this.summary,
    required this.phone,
    required this.location,
    required this.skills,
    required this.experiences,
    required this.education,
  });

  bool get hasExtractedData {
    return summary.trim().isNotEmpty ||
        phone.trim().isNotEmpty ||
        location.trim().isNotEmpty ||
        skills.isNotEmpty ||
        experiences.isNotEmpty ||
        education.isNotEmpty;
  }
}
