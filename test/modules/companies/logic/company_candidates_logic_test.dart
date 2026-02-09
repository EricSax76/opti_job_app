import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/companies/logic/company_candidates_logic.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

void main() {
  JobOffer buildOffer({required String id, required String title}) {
    return JobOffer(id: id, title: title, description: '', location: '');
  }

  test('groupCandidates keeps the most recent application per offer', () {
    final now = DateTime.utc(2026, 2, 1, 12);
    final grouped = groupCandidates(
      applicantsByOffer: {
        '101': [
          Application(
            id: 'app-1',
            jobOfferId: '101',
            candidateUid: 'candidate-1',
            candidateName: 'Ana',
            status: 'pending',
            updatedAt: now.subtract(const Duration(days: 1)),
          ),
          Application(
            id: 'app-2',
            jobOfferId: '101',
            candidateUid: 'candidate-1',
            candidateName: 'Ana',
            status: 'accepted',
            updatedAt: now,
          ),
        ],
        '102': [
          Application(
            id: 'app-3',
            jobOfferId: '102',
            candidateUid: 'candidate-1',
            candidateName: 'Ana',
            status: 'review',
            updatedAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
      },
      offerById: {
        '101': buildOffer(id: '101', title: 'Backend Engineer'),
        '102': buildOffer(id: '102', title: 'Mobile Engineer'),
      },
    );

    expect(grouped, hasLength(1));
    expect(grouped.first.displayName, 'Ana');
    expect(grouped.first.entries.map((entry) => entry.offerId).toList(), [
      '101',
      '102',
    ]);
    expect(grouped.first.entries.first.status, 'accepted');
  });

  test('groupCandidates falls back to email and then uid for display name', () {
    final grouped = groupCandidates(
      applicantsByOffer: {
        '201': [
          Application(
            id: 'app-10',
            jobOfferId: '201',
            candidateUid: 'candidate-z',
            candidateEmail: 'zoe@example.com',
            status: 'pending',
          ),
          Application(
            id: 'app-11',
            jobOfferId: '201',
            candidateUid: 'candidate-a',
            status: 'pending',
          ),
        ],
      },
      offerById: {'201': buildOffer(id: '201', title: 'Data Analyst')},
    );

    expect(grouped, hasLength(2));
    expect(grouped[0].displayName, 'candidate-a');
    expect(grouped[1].displayName, 'zoe@example.com');
  });
}
