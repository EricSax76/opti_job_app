class AiSkillsPrompts {
  static const String extractSkills = '''
Extract a structured list of skills from the following text. 
For each skill, identify the name, proficiency level (beginner, intermediate, advanced, expert), and estimated years of experience.
Return only a JSON array of objects with the keys: skillId, name, level, yearsOfExperience.
''';

  static const String matchSkills = '''
Compare the candidate's skills with the job requirements.
Focus on:
1. Exact matches.
2. Semantic similarities (e.g., 'React' and 'React.js').
3. Adjacent skills that could compensate for missing ones.

Provide a detailed explanation in natural language (Spanish) justifying the score based on skills.
No emotional analysis. No biometric references.
''';

  static const String systemCompliance = '''
// PROHIBIDO POR AI ACT UE: Ningún análisis de IA, reconocimiento emocional, 
// ni procesamiento biométrico en videoentrevistas. 
// Proporcionar siempre una explicación clara y basada en evidencias.
''';
}
