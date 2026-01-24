import 'dart:typed_data';

import 'package:opti_job_app/features/ai/api/document_parser.dart';
import 'package:opti_job_app/features/ai/api/firebase_ai_client.dart';
import 'package:opti_job_app/features/ai/prompts/ai_prompts.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class CvAnalysisService {
  final FirebaseAiClient _aiClient;

  CvAnalysisService({FirebaseAiClient? aiClient})
    : _aiClient = aiClient ?? FirebaseAiClient();

  Future<CvAnalysisResult> analyzeCvFile(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      // 1. Extraer texto del documento
      String text = '';
      if (fileName.toLowerCase().endsWith('.docx')) {
        text = DocumentParser.extractTextFromDocx(bytes);
      }
      // (Aquí podrías añadir lógica para PDF si integras un paquete compatible)

      if (text.isEmpty) {
        throw Exception(
          'No se pudo leer el texto del archivo. Asegúrate de que sea un .docx válido.',
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
    final personal = json['personal'] as Map<String, dynamic>? ?? {};

    final skills = List<String>.from(json['skills'] ?? []);

    final experiences = (json['experience'] as List? ?? [])
        .map(
          (e) => CurriculumItem(
            title: e['role'] ?? '',
            subtitle: e['company'] ?? '',
            period: e['date_range'] ?? '',
            description: e['description'] ?? '',
          ),
        )
        .toList();

    final education = (json['education'] as List? ?? [])
        .map(
          (e) => CurriculumItem(
            title: e['degree'] ?? '',
            subtitle: e['school'] ?? '',
            period: e['date_range'] ?? '',
            description: '',
          ),
        )
        .toList();

    return CvAnalysisResult(
      summary: personal['summary'] ?? '',
      phone: personal['phone'] ?? '',
      location: personal['location'] ?? '',
      skills: skills,
      experiences: experiences,
      education: education,
    );
  }
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
}
