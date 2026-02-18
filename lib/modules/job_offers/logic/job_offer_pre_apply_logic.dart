enum JobOfferApplicationVerdictLevel { recommended, caution, notRecommended }

class JobOfferApplicationVerdict {
  const JobOfferApplicationVerdict({
    required this.level,
    required this.title,
    required this.description,
    required this.actionLabel,
  });

  final JobOfferApplicationVerdictLevel level;
  final String title;
  final String description;
  final String actionLabel;
}

class JobOfferPreApplyLogic {
  const JobOfferPreApplyLogic._();

  static JobOfferApplicationVerdict buildVerdict({required int score}) {
    if (score >= 70) {
      return const JobOfferApplicationVerdict(
        level: JobOfferApplicationVerdictLevel.recommended,
        title: 'Postulación recomendada',
        description:
            'Tu perfil encaja bien con esta oferta según el análisis de CV y requisitos.',
        actionLabel: 'Postularme ahora',
      );
    }
    if (score >= 50) {
      return const JobOfferApplicationVerdict(
        level: JobOfferApplicationVerdictLevel.caution,
        title: 'Postulación viable con cautela',
        description:
            'El encaje es parcial. Revisa los puntos de mejora antes de enviar.',
        actionLabel: 'Postularme con cautela',
      );
    }
    return const JobOfferApplicationVerdict(
      level: JobOfferApplicationVerdictLevel.notRecommended,
      title: 'Postulación no recomendada',
      description:
          'El encaje actual es bajo. Puede ser mejor reforzar el perfil antes de postular.',
      actionLabel: 'Postularme de todos modos',
    );
  }
}
