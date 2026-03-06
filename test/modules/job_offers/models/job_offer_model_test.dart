import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

void main() {
  group('JobOffer.fromJson languageCheckResult mapping', () {
    test('reads snake_case language_check_result from backend payload', () {
      final offer = JobOffer.fromJson({
        'id': 'offer-1',
        'title': 'Oferta',
        'description': 'Descripcion',
        'location': 'Madrid',
        'language_check_result': {
          'score': 92,
          'warnings': ['biased_term'],
        },
      });

      expect(offer.languageCheckResult, isNotNull);
      expect(offer.languageCheckResult?['score'], 92);
      expect(offer.languageCheckResult?['warnings'], ['biased_term']);
    });

    test('keeps camelCase languageCheckResult compatibility', () {
      final offer = JobOffer.fromJson({
        'id': 'offer-2',
        'title': 'Oferta',
        'description': 'Descripcion',
        'location': 'Madrid',
        'languageCheckResult': {'score': 88},
      });

      expect(offer.languageCheckResult, isNotNull);
      expect(offer.languageCheckResult?['score'], 88);
    });
  });
}
