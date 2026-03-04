class AiBiasPrompts {
  static String checkJobOfferBias({
    required String title,
    required String description,
    required String locale,
  }) {
    return '''
Analiza la siguiente oferta de empleo en busca de sesgos discriminatorios.

El objetivo es asegurar el cumplimiento de las normativas de igualdad y transparencia, en especial lo estipulado por el AI Act europeo y regulaciones de no discriminación laboral. 

Requisitos:
- Idioma de respuesta: Mismo del locale indicado ($locale). Responde SIEMPRE en castellano para es-ES.
- Identifica cualquier lenguaje que denote:
  - Sesgo de género (uso exclusivo del masculino genérico de forma reiterada, requerir "candidatos agresivos", "ninjas", o "rockstars" o perfil fuertemente estereotipado).
  - Sesgo de edad (pedir "gente joven", "ambiente universitario", "recién graduado" excluendo explícitamente mayores).
  - Peticiones ilegales (preguntar por historial salarial, estado civil, o cargas familiares).
  - Sesgos raciales, culturales o por capacidades (exigir "nativo" en idiomas sin justificación en vez de "bilingüe/C2", requerir estado físico sin justificación técnica).

- Devuelve JSON válido con (en el idioma indicado):
  - score (entero 0..100): 100 significa oferta perfectamente redactada, inclusiva y neutral. Resta puntos por cada sesgo detectado.
  - issues (lista de strings, vacía si score es 100): una lista concisa de los problemas encontrados y sugerencias breves de cómo reescribir la frase afectada. Si la oferta pide "historial salarial", esto es un red flag grave (resta al menos 50 puntos).

Título de la oferta:
$title

Descripción de la oferta:
$description
''';
  }
}
