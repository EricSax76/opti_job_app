import 'dart:convert';

class AiPrompts {
  static String matchCandidate({
    required Map<String, dynamic> cv,
    required Map<String, dynamic> offer,
    required String locale,
    required String quality,
  }) {
    return '''
Evalúa el encaje entre un candidato y una oferta de empleo.

Requisitos:
- Idioma: Español (es-ES). Responde SIEMPRE en castellano y NO uses inglés.
- Locale de referencia: $locale
- Calidad: $quality
- Devuelve JSON válido con (en castellano):
  - score (0..100)
  - reasons (3..7 strings)
  - summary (opcional, 1-2 frases)
  - recommendations (3..6 strings): recomendaciones concretas para el candidato
    (qué mejorar, qué destacar, qué añadir al CV/portfolio, cómo adaptar la postulación).
- No inventes habilidades/experiencias no presentes en el CV o la oferta.
- Enfócate en ayudar al candidato: identifica gaps y acciones sugeridas.

CV (JSON): ${jsonEncode(cv)}
Oferta (JSON): ${jsonEncode(offer)}
''';
  }

  static String matchCompany({
    required Map<String, dynamic> cv,
    required Map<String, dynamic> offer,
    required String locale,
    required String quality,
  }) {
    return '''
Evalúa el encaje entre un candidato y una oferta de empleo desde la perspectiva de una empresa (reclutador).

Requisitos:
- Idioma: Español (es-ES). Responde SIEMPRE en castellano y NO uses inglés.
- Locale de referencia: $locale
- Calidad: $quality
- Devuelve JSON válido con (en castellano):
  - score (0..100)
  - reasons (3..7 strings): puntos clave del encaje para la empresa (fortalezas, fit con requisitos, evidencias).
  - recommendations (3..6 strings): acciones para la empresa (preguntas de entrevista, validaciones, red flags a comprobar).
  - summary (opcional, 1-2 frases).
- No inventes habilidades/experiencias no presentes en el CV o la oferta.
- Enfócate en lo importante para la empresa: impacto, seniority, señales de riesgo, gaps críticos, y verificaciones concretas.

CV (JSON): ${jsonEncode(cv)}
Oferta (JSON): ${jsonEncode(offer)}
''';
  }

  static String generateJobOffer({
    required Map<String, dynamic> criteria,
    required String locale,
    required String quality,
  }) {
    return '''
Genera un borrador de oferta de empleo en base a los criterios.

Requisitos:
- Idioma/locale: $locale (escribe todo el texto en este idioma; para es-ES, en castellano)
- Calidad: $quality
- Devuelve JSON válido con los campos:
  - title (string, requerido)
  - description (string, requerido)
  - location (string, requerido)
  - job_type, salary_min, salary_max, education, key_indicators (opcionales)
- No inventes datos concretos (salario, ubicación exacta, tecnologías) si no están en los criterios.
- description debe ser clara y lista para publicar (puede incluir secciones y bullets en texto).

Criterios (JSON): ${jsonEncode(criteria)}
''';
  }

  static String improveSummary({
    required Map<String, dynamic> cv,
    required String locale,
    required String quality,
  }) {
    final cvJson = jsonEncode(cv);
    return '''
Reescribe y mejora el resumen profesional del CV.

Requisitos:
- Idioma/locale: $locale
- Calidad: $quality
- Devuelve SOLO el texto final del resumen (sin JSON, sin comillas, sin Markdown).
- 60–120 palabras.
- No inventes datos; si falta información, generaliza sin afirmar cosas específicas.

CV (JSON):
$cvJson
''';
  }

  static String extractCvData({
    required String cvText,
    String locale = 'es-ES',
  }) {
    return '''
Analiza el siguiente texto extraído de un documento de CV y extrae la información estructurada.

Requisitos:
- Idioma de salida: El mismo del CV o $locale.
- Devuelve JSON válido con la estructura:
  - personal: { name, email, phone, location, summary }
  - experience: lista de { role, company, date_range, description } (extrae las más relevantes)
  - education: lista de { degree, school, date_range }
  - skills: lista de strings (habilidades técnicas y blandas)
  - languages: lista de strings

Texto del CV:
$cvText
''';
  }

  static String improveCoverLetter({
    required String coverLetterText,
    required Map<String, dynamic> cv,
    required String locale,
    required String quality,
  }) {
    final cvJson = jsonEncode(cv);
    return '''
Reescribe y mejora esta carta de presentación basándote en el CV del candidato.

Requisitos:
- Idioma/locale: $locale
- Calidad: $quality
- Devuelve SOLO el texto final de la carta (sin JSON, sin comillas, sin Markdown).
- Tono profesional pero cercano.
- Estructura:
  - Breve introducción.
  - Párrafo conectando la experiencia del CV con la oferta (aunque no tengamos la oferta, destaca fortalezas generales).
  - Párrafo mostrando motivación.
  - Cierre con llamada a la acción (ej. "concertar una entrevista").
- No inventes datos; si falta información, generaliza.

CV del candidato (JSON):
$cvJson

Carta de presentación original:
$coverLetterText
''';
  }
}
