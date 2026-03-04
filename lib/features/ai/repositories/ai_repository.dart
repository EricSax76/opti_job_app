import 'package:opti_job_app/features/ai/models/ai_service.dart';
import 'package:opti_job_app/features/ai/models/ai_job_offer_draft.dart';
import 'package:opti_job_app/features/ai/models/ai_match_result.dart';
import 'package:opti_job_app/features/ai/services/ai_skills_matching_service.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/skills/models/skill.dart';

class AiRepository {
  AiRepository(this._service);

  final AiService _service;

  Future<String> improveCurriculumSummary({
    required Curriculum curriculum,
    String locale = 'es-ES',
  }) {
    return _service.improveCurriculumSummary(
      curriculum: curriculum,
      locale: locale,
    );
  }

  Future<AiMatchResult> matchOfferCandidate({
    required Curriculum curriculum,
    required JobOffer offer,
    String locale = 'es-ES',
  }) async {
    final baseResult = await _service.matchOfferCandidate(
      curriculum: curriculum,
      offer: offer,
      locale: locale,
    );
    return _withSemanticSkills(
      baseResult: baseResult,
      curriculum: curriculum,
      offer: offer,
    );
  }

  Future<AiMatchResult> matchOfferCandidateForCompany({
    required Curriculum curriculum,
    required JobOffer offer,
    String locale = 'es-ES',
  }) async {
    final baseResult = await _service.matchOfferCandidateForCompany(
      curriculum: curriculum,
      offer: offer,
      locale: locale,
    );
    return _withSemanticSkills(
      baseResult: baseResult,
      curriculum: curriculum,
      offer: offer,
    );
  }

  Future<AiJobOfferDraft> generateJobOffer({
    required Map<String, dynamic> criteria,
    String locale = 'es-ES',
    String quality = 'flash',
  }) {
    return _service.generateJobOffer(
      criteria: criteria,
      locale: locale,
      quality: quality,
    );
  }

  Future<String> improveCoverLetter({
    required Curriculum curriculum,
    required String coverLetterText,
    String locale = 'es-ES',
    String quality = 'flash',
  }) {
    return _service.improveCoverLetter(
      curriculum: curriculum,
      coverLetterText: coverLetterText,
      locale: locale,
      quality: quality,
    );
  }

  Future<AiMatchResult> _withSemanticSkills({
    required AiMatchResult baseResult,
    required Curriculum curriculum,
    required JobOffer offer,
  }) async {
    if (offer.requiredSkills.isEmpty && offer.preferredSkills.isEmpty) {
      return baseResult;
    }

    final candidateSkills = _buildCandidateSkills(curriculum);
    if (candidateSkills.isEmpty) {
      return baseResult.copyWith(
        skillsOverlap:
            baseResult.skillsOverlap ??
            const SkillsOverlap(matched: [], missing: [], adjacent: []),
      );
    }

    final semantic = await _service.evaluateSemanticSkills(
      candidateSkills: candidateSkills,
      requiredSkills: offer.requiredSkills,
      preferredSkills: offer.preferredSkills,
    );

    final mergedOverlap = _mergeOverlap(baseResult.skillsOverlap, semantic);
    final blendedScore = _blendScores(baseResult.score, semantic.score);
    final mergedReasons = _mergeReasons(baseResult.reasons, semantic);
    final skillRoadmap = _buildSkillRoadmap(
      offer: offer,
      overlap: mergedOverlap,
    );
    final projectedScore = _projectScore(blendedScore, roadmap: skillRoadmap);
    final explanation = _mergeExplanation(
      baseResult: baseResult,
      semantic: semantic,
      blendedScore: blendedScore,
      projectedScore: projectedScore,
    );

    return baseResult.copyWith(
      score: blendedScore,
      reasons: mergedReasons,
      explanation: explanation,
      skillsOverlap: mergedOverlap,
      skillRoadmap: skillRoadmap,
      projectedScore: projectedScore,
    );
  }

  List<Skill> _buildCandidateSkills(Curriculum curriculum) {
    final combined = <Skill>[
      ...curriculum.structuredSkills,
      ...curriculum.skills
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty)
          .map(
            (name) => Skill(
              skillId: _skillIdFromName(name),
              name: name,
              level: SkillLevel.intermediate,
              yearsOfExperience: 0,
            ),
          ),
    ];

    final deduped = <String, Skill>{};
    for (final skill in combined) {
      final key = skill.name.trim().toLowerCase();
      if (key.isEmpty) continue;
      deduped.putIfAbsent(key, () => skill);
    }
    return deduped.values.toList(growable: false);
  }

  SkillsOverlap _mergeOverlap(
    SkillsOverlap? existing,
    SemanticSkillsMatch semantic,
  ) {
    final mergedMatched = <String>{
      ...?existing?.matched,
      ...semantic.overlap.matched,
    };
    final mergedMissing = <String>{
      ...?existing?.missing,
      ...semantic.overlap.missing,
    };
    final mergedAdjacent = <String>{
      ...?existing?.adjacent,
      ...semantic.overlap.adjacent,
    };

    return SkillsOverlap(
      matched: mergedMatched.toList(growable: false)..sort(),
      missing: mergedMissing.toList(growable: false)..sort(),
      adjacent: mergedAdjacent.toList(growable: false)..sort(),
    );
  }

  int _blendScores(int aiScore, int semanticScore) {
    final blended = (aiScore * 0.75) + (semanticScore * 0.25);
    return blended.round().clamp(0, 100);
  }

  List<String> _mergeReasons(
    List<String> existing,
    SemanticSkillsMatch semantic,
  ) {
    final reasons = <String>{...existing};
    reasons.addAll(semantic.evidence.take(3));
    return reasons.toList(growable: false);
  }

  String _mergeExplanation({
    required AiMatchResult baseResult,
    required SemanticSkillsMatch semantic,
    required int blendedScore,
    required int projectedScore,
  }) {
    final base = baseResult.explanation.trim();
    final semanticBlock = StringBuffer()
      ..write(
        'Ajuste semántico de habilidades: IA base ${baseResult.score}/100, ',
      )
      ..write('motor semántico ${semantic.score}/100, ')
      ..write('score final $blendedScore/100.');

    if (semantic.overlap.adjacent.isNotEmpty) {
      semanticBlock
        ..write(' Habilidades adyacentes consideradas: ')
        ..write(semantic.overlap.adjacent.take(4).join(', '))
        ..write('.');
    }
    if (projectedScore > blendedScore) {
      semanticBlock.write(
        ' Si completas las recomendaciones prioritarias, el score estimado puede subir hasta $projectedScore/100.',
      );
    }

    if (base.isEmpty) return semanticBlock.toString();
    return '$base\n\n${semanticBlock.toString()}';
  }

  int _projectScore(
    int blendedScore, {
    required List<SkillImpactRecommendation> roadmap,
  }) {
    if (roadmap.isEmpty) return blendedScore;
    final potentialDelta = roadmap
        .take(3)
        .fold<int>(0, (acc, item) => acc + item.estimatedScoreDelta);
    final projected = blendedScore + potentialDelta;
    return projected.clamp(0, 100);
  }

  List<SkillImpactRecommendation> _buildSkillRoadmap({
    required JobOffer offer,
    required SkillsOverlap overlap,
  }) {
    if (overlap.missing.isEmpty && overlap.adjacent.isEmpty) {
      return const [];
    }

    final requiredByNormalized = <String, String>{
      for (final skill in offer.requiredSkills)
        _normalizeSkillName(skill.name): skill.name.trim(),
    };
    final preferredByNormalized = <String, String>{
      for (final skill in offer.preferredSkills)
        _normalizeSkillName(skill.name): skill.name.trim(),
    };
    final adjacentByRequired = _adjacentByRequired(overlap.adjacent);
    final seen = <String>{};
    final roadmap = <SkillImpactRecommendation>[];

    void addRecommendation({
      required String skill,
      required bool isRequired,
      String? adjacentEvidence,
    }) {
      final normalized = _normalizeSkillName(skill);
      if (normalized.isEmpty || !seen.add(normalized)) return;

      final hasAdjacentBase =
          adjacentEvidence != null && adjacentEvidence.trim().isNotEmpty;
      final delta = isRequired
          ? (hasAdjacentBase ? 6 : 8)
          : (hasAdjacentBase ? 3 : 5);
      final rationale = isRequired
          ? 'Competencia clave para cumplir requisitos obligatorios del puesto.'
          : 'Competencia preferente que mejora afinidad y ranking final.';

      roadmap.add(
        SkillImpactRecommendation(
          skill: skill.trim(),
          estimatedScoreDelta: delta,
          rationale: rationale,
          currentAdjacentEvidence: adjacentEvidence,
          priority: isRequired ? 1 : 2,
        ),
      );
    }

    for (final missing in overlap.missing) {
      final normalized = _normalizeSkillName(missing);
      if (normalized.isEmpty) continue;
      final requiredSkill = requiredByNormalized[normalized];
      if (requiredSkill != null) {
        addRecommendation(
          skill: requiredSkill,
          isRequired: true,
          adjacentEvidence: adjacentByRequired[normalized],
        );
        continue;
      }
      final preferredSkill = preferredByNormalized[normalized];
      if (preferredSkill != null) {
        addRecommendation(
          skill: preferredSkill,
          isRequired: false,
          adjacentEvidence: adjacentByRequired[normalized],
        );
      }
    }

    for (final entry in adjacentByRequired.entries) {
      if (seen.contains(entry.key)) continue;
      final requiredSkill = requiredByNormalized[entry.key];
      if (requiredSkill != null) {
        addRecommendation(
          skill: requiredSkill,
          isRequired: true,
          adjacentEvidence: entry.value,
        );
      }
    }

    roadmap.sort((a, b) {
      final priorityComparison = a.priority.compareTo(b.priority);
      if (priorityComparison != 0) return priorityComparison;
      return b.estimatedScoreDelta.compareTo(a.estimatedScoreDelta);
    });
    return roadmap.take(6).toList(growable: false);
  }

  Map<String, String> _adjacentByRequired(List<String> adjacent) {
    final result = <String, String>{};
    for (final line in adjacent) {
      final parts = line.split('↔');
      if (parts.length != 2) continue;
      final requiredSkill = parts.first.trim();
      final evidence = parts.last.trim();
      final key = _normalizeSkillName(requiredSkill);
      if (key.isEmpty || evidence.isEmpty) continue;
      result.putIfAbsent(key, () => evidence);
    }
    return result;
  }

  String _normalizeSkillName(String raw) {
    return raw.trim().toLowerCase();
  }

  String _skillIdFromName(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
