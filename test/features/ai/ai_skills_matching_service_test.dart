import 'package:flutter_test/flutter_test.dart';

import 'package:opti_job_app/features/ai/services/ai_skills_matching_service.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/skills/models/skill.dart';

void main() {
  group('AiSkillsMatchingService semantic matching', () {
    final service = AiSkillsMatchingService();

    test('detecta skills adyacentes y puntúa por encima de cero', () async {
      final result = await service.calculateSemanticMatch(
        candidateSkills: [_skill('React Native'), _skill('TypeScript')],
        requiredSkills: [_required('React'), _required('JavaScript')],
        preferredSkills: [_skill('Flutter')],
      );

      expect(result.overlap.adjacent, isNotEmpty);
      expect(result.overlap.missing.length, lessThan(2));
      expect(result.score, greaterThan(0));
    });

    test('prioriza coincidencias exactas frente a vacantes', () async {
      final exact = await service.calculateSemanticMatch(
        candidateSkills: [
          _skill('Flutter'),
          _skill('Dart'),
          _skill('Kubernetes'),
        ],
        requiredSkills: [_required('Flutter'), _required('Dart')],
        preferredSkills: [_skill('Kubernetes')],
      );

      final weak = await service.calculateSemanticMatch(
        candidateSkills: [_skill('English')],
        requiredSkills: [_required('Flutter'), _required('Dart')],
        preferredSkills: [_skill('Kubernetes')],
      );

      expect(exact.overlap.matched, containsAll(['Flutter', 'Dart']));
      expect(exact.score, greaterThan(weak.score));
    });

    test(
      'el ranking mejora cuando hay adyacencia frente a ausencia total',
      () async {
        final adjacentCandidate = await service.calculateSemanticMatch(
          candidateSkills: [_skill('React Native')],
          requiredSkills: [_required('React')],
          preferredSkills: const [],
        );

        final noCoverage = await service.calculateSemanticMatch(
          candidateSkills: [_skill('Excel')],
          requiredSkills: [_required('React')],
          preferredSkills: const [],
        );

        expect(adjacentCandidate.overlap.adjacent, isNotEmpty);
        expect(noCoverage.overlap.adjacent, isEmpty);
        expect(adjacentCandidate.score, greaterThan(noCoverage.score));
      },
    );
  });
}

Skill _skill(String name) => Skill(
  skillId: name.toLowerCase().replaceAll(' ', '_'),
  name: name,
  level: SkillLevel.intermediate,
  yearsOfExperience: 2,
);

JobOfferSkill _required(String name) => JobOfferSkill(
  skillId: name.toLowerCase(),
  name: name,
  minimumLevel: SkillLevel.beginner,
);
