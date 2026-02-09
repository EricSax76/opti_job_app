import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/applications/models/candidate_application_entry.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/interviews_view.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/my_applications_view.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

void main() {
  testWidgets(
    'keeps Hero tags unique when applications and interviews coexist in IndexedStack',
    (tester) async {
      final entries = <CandidateApplicationEntry>[
        _entry(
          applicationId: 'app-1',
          offerId: 'offer-1',
          status: 'pending',
        ),
        _entry(
          applicationId: 'app-2',
          offerId: 'offer-2',
          status: 'interview',
        ),
      ];

      await tester.pumpWidget(_buildHarness(entries));
      await tester.pump();

      final heroes = tester.widgetList<Hero>(find.byType(Hero)).toList();
      final tags = heroes.map((hero) => hero.tag).toList(growable: false);

      expect(tags, isNotEmpty);
      expect(tags.toSet().length, tags.length);

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}

CandidateApplicationEntry _entry({
  required String applicationId,
  required String offerId,
  required String status,
}) {
  return CandidateApplicationEntry(
    application: Application(
      id: applicationId,
      jobOfferId: offerId,
      jobOfferTitle: 'Oferta $offerId',
      candidateUid: 'candidate-1',
      status: status,
    ),
    offer: JobOffer(
      id: offerId,
      title: 'Oferta $offerId',
      description: 'Descripción',
      location: 'Madrid',
      companyName: 'Acme',
    ),
  );
}

Widget _buildHarness(List<CandidateApplicationEntry> entries) {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: 0,
              children: [
                ApplicationsList(applications: entries),
                InterviewsList(interviews: entries),
              ],
            ),
          ),
          Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        body: Center(child: Text('Next route')),
                      ),
                    ),
                  );
                },
                child: const Text('Navigate'),
              );
            },
          ),
        ],
      ),
    ),
  );
}
