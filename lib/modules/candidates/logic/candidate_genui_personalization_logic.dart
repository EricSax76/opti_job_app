import 'package:opti_job_app/modules/candidates/models/candidate.dart';

class CandidateGenUiCopy {
  const CandidateGenUiCopy({
    required this.title,
    required this.subtitle,
    this.assistiveHint,
  });

  final String title;
  final String subtitle;
  final String? assistiveHint;
}

class CandidateGenUiPersonalizationLogic {
  const CandidateGenUiPersonalizationLogic._();

  static CandidateGenUiCopy build({
    required String candidateName,
    required Candidate? candidate,
    required int displayedOfferCount,
    required bool hasActiveFilters,
  }) {
    final safeName = _sanitizeToken(candidateName, fallback: 'Candidato');
    final onboarding = candidate?.onboardingProfile;
    final safeRole = _sanitizeToken(onboarding?.targetRole);
    final safeModality = _sanitizeToken(onboarding?.preferredModality);
    final safeLocation = _sanitizeToken(onboarding?.preferredLocation);

    final title = 'Hola, $safeName';

    if (displayedOfferCount <= 0) {
      if (hasActiveFilters) {
        return CandidateGenUiCopy(
          title: title,
          subtitle: _clip(
            'Ahora mismo no hay coincidencias con tus filtros. Ajusta requisitos para ampliar resultados.',
            maxChars: 140,
          ),
          assistiveHint:
              'Consejo: amplía ubicación o modalidad para desbloquear más vacantes.',
        );
      }
      return CandidateGenUiCopy(
        title: title,
        subtitle: _clip(
          'No hay ofertas activas para tu perfil en este momento. Te avisaremos cuando aparezcan nuevas vacantes.',
          maxChars: 140,
        ),
        assistiveHint:
            'Mantén actualizado tu perfil para mejorar el matching automático.',
      );
    }

    final contextualBits = <String>[
      if (safeRole != null) 'rol $safeRole',
      if (safeModality != null) 'modalidad $safeModality',
      if (safeLocation != null) 'zona $safeLocation',
    ];

    final subtitle = contextualBits.isEmpty
        ? 'Te mostramos $displayedOfferCount ofertas priorizadas por encaje con tus habilidades.'
        : 'Te mostramos $displayedOfferCount ofertas priorizadas para ${contextualBits.join(', ')}.';

    final hasCoverLetter = candidate?.hasCoverLetter == true;
    final hasVideoCurriculum = candidate?.hasVideoCurriculum == true;
    final assistiveHint = (!hasCoverLetter || !hasVideoCurriculum)
        ? 'Tip: completar carta de presentación y video CV puede mejorar tu posición en el ranking.'
        : 'Tu perfil está completo. Revisa primero las vacantes con mejor ajuste.';

    return CandidateGenUiCopy(
      title: _clip(title, maxChars: 48),
      subtitle: _clip(subtitle, maxChars: 150),
      assistiveHint: _clip(assistiveHint, maxChars: 130),
    );
  }
}

String _clip(String value, {required int maxChars}) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= maxChars) return normalized;
  return '${normalized.substring(0, maxChars - 1)}…';
}

String? _sanitizeToken(String? raw, {String? fallback}) {
  final normalized = (raw ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) return fallback;
  final safe = normalized.replaceAll(
    RegExp(r'[^a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ /_-]'),
    '',
  );
  final collapsed = safe.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (collapsed.isEmpty) return fallback;
  return collapsed;
}
