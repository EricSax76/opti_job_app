import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_pre_apply_logic.dart';

void main() {
  group('JobOfferPreApplyLogic', () {
    test('marks high scores as recommended', () {
      final verdict = JobOfferPreApplyLogic.buildVerdict(score: 85);

      expect(verdict.level, JobOfferApplicationVerdictLevel.recommended);
      expect(verdict.title, 'Postulación recomendada');
    });

    test('marks medium scores as caution', () {
      final verdict = JobOfferPreApplyLogic.buildVerdict(score: 60);

      expect(verdict.level, JobOfferApplicationVerdictLevel.caution);
      expect(verdict.title, 'Postulación viable con cautela');
    });

    test('marks low scores as not recommended', () {
      final verdict = JobOfferPreApplyLogic.buildVerdict(score: 34);

      expect(verdict.level, JobOfferApplicationVerdictLevel.notRecommended);
      expect(verdict.title, 'Postulación no recomendada');
    });
  });
}
