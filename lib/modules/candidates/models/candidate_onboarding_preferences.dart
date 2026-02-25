class CandidateOnboardingPreferences {
  const CandidateOnboardingPreferences._();

  static const String noPreference = 'No tengo preferencia';

  static const List<String> modalityOptions = [
    'Remoto',
    'Híbrido',
    'Presencial',
  ];

  static const List<String> seniorityOptions = [
    'Junior',
    'Mid',
    'Senior',
    'Lead',
  ];

  static const List<String> startOfDayOptions = [
    'Foco individual',
    'Sincronización de equipo',
    noPreference,
  ];

  static const List<String> feedbackOptions = [
    'Feedback continuo',
    'Feedback por hitos',
    noPreference,
  ];

  static const List<String> structureOptions = [
    'Objetivos muy definidos',
    'Autonomía amplia',
    noPreference,
  ];

  static const List<String> taskPaceOptions = [
    'Bloques largos de concentración',
    'Tareas variadas y cambios',
    noPreference,
  ];
}
