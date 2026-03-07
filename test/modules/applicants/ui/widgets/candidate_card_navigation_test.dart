import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/modules/applicants/logic/company_candidates_logic.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/candidate_card.dart';

void main() {
  testWidgets(
    'abre CV directamente con la primera oferta y vuelve sin dejar la navegación bloqueada',
    (tester) async {
      const candidate = CandidateGroup(
        candidateUid: 'candidate-1',
        displayName: 'Candidato Uno',
        anonymizedLabel: 'Candidato #CANDID',
        isAnonymousScreening: false,
        entries: [
          CandidateOfferEntry(
            applicationId: 'app-1',
            offerId: 'offer-1',
            offerTitle: 'Oferta Uno',
            status: 'pending',
            hasCoverLetter: true,
            hasVideoCurriculum: true,
            canViewVideoCurriculum: true,
          ),
          CandidateOfferEntry(
            applicationId: 'app-2',
            offerId: 'offer-2',
            offerTitle: 'Oferta Dos',
            status: 'pending',
            hasCoverLetter: false,
            hasVideoCurriculum: false,
            canViewVideoCurriculum: true,
          ),
        ],
      );

      final router = GoRouter(
        initialLocation: '/company/company-1/candidates',
        routes: [
          GoRoute(
            path: '/company/:uid/candidates',
            builder: (context, state) => const Scaffold(
              body: SafeArea(child: CandidateCard(candidate: candidate)),
            ),
          ),
          GoRoute(
            path: '/company/offers/:offerId/applicants/:candidateUid/cv',
            name: 'company-applicant-cv',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('CV screen')),
              body: const SizedBox.shrink(),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();
      expect(find.text('CV screen'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();
      expect(find.text('CV screen'), findsOneWidget);
    },
  );
}
