import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/applications/logic/application_service.dart';
import 'package:opti_job_app/modules/applications/models/qualified_signature_models.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/compliance/models/consent_record.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_match_logic.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_detail_view_model.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/job_offers/ui/controllers/job_offer_detail_controller.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

class _MockJobOfferRepository extends Mock implements JobOfferRepository {}

class _MockApplicationService extends Mock implements ApplicationService {}

class _MockCurriculumRepository extends Mock implements CurriculumRepository {}

class _MockAiRepository extends Mock implements AiRepository {}

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockConsentRepository extends Mock implements ConsentRepository {}

class _SpyJobOfferDetailCubit extends JobOfferDetailCubit {
  _SpyJobOfferDetailCubit({
    required JobOfferMatchOutcome evaluateOutcome,
    Completer<void>? computeMatchCompleter,
  }) : _evaluateOutcome = evaluateOutcome,
       _computeMatchCompleter = computeMatchCompleter,
       super(
         _MockJobOfferRepository(),
         _MockApplicationService(),
         curriculumRepository: _MockCurriculumRepository(),
         aiRepository: _MockAiRepository(),
         profileRepository: _MockProfileRepository(),
       );

  final JobOfferMatchOutcome _evaluateOutcome;
  final Completer<void>? _computeMatchCompleter;

  var computeMatchCalls = 0;
  var applyCalls = 0;
  var refreshCalls = 0;

  final List<Map<String, dynamic>?> applyResponses = <Map<String, dynamic>?>[];
  final List<String> evaluateCandidateUids = <String>[];
  final List<JobOffer> evaluateOffers = <JobOffer>[];

  @override
  Future<void> computeMatch() async {
    computeMatchCalls += 1;
    final completer = _computeMatchCompleter;
    if (completer != null) {
      await completer.future;
    }
  }

  @override
  Future<JobOfferMatchOutcome> evaluateFitForApplication({
    required String candidateUid,
    required JobOffer offer,
  }) async {
    evaluateCandidateUids.add(candidateUid);
    evaluateOffers.add(offer);
    return _evaluateOutcome;
  }

  @override
  Future<void> apply({
    required Candidate candidate,
    required JobOffer offer,
    Map<String, dynamic>? knockoutResponses,
  }) async {
    applyCalls += 1;
    applyResponses.add(knockoutResponses);
  }

  @override
  Future<void> refresh() async {
    refreshCalls += 1;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const ConsentRecord(
        id: 'consent',
        candidateUid: 'candidate-1',
        companyId: 'company-1',
        type: 'ai_granular',
      ),
    );
  });

  testWidgets('showMatchResult muestra loading y ejecuta computeMatch', (
    tester,
  ) async {
    final computeMatchCompleter = Completer<void>();
    final cubit = _SpyJobOfferDetailCubit(
      evaluateOutcome: const JobOfferMatchFailure('No aplica para este test.'),
      computeMatchCompleter: computeMatchCompleter,
    );

    addTearDown(cubit.close);

    final context = await _pumpHarness(
      tester,
      cubit: cubit,
      consentRepository: _MockConsentRepository(),
      applicationService: _MockApplicationService(),
    );

    final future = JobOfferDetailController.showMatchResult(context);

    await tester.pump();

    expect(find.text('Calculando match'), findsOneWidget);
    expect(cubit.computeMatchCalls, 1);

    computeMatchCompleter.complete();
    await future;
    await tester.pumpAndSettle();

    expect(find.text('Calculando match'), findsNothing);
  });

  testWidgets(
    'apply confirma encaje, guarda consentimiento IA y envía knockout responses',
    (tester) async {
      final consentRepository = _MockConsentRepository();
      when(() => consentRepository.saveConsent(any())).thenAnswer((
        invocation,
      ) async {
        return invocation.positionalArguments.first as ConsentRecord;
      });

      final cubit = _SpyJobOfferDetailCubit(
        evaluateOutcome: const JobOfferMatchFailure(
          'No se pudo evaluar ahora mismo.',
        ),
      );
      addTearDown(cubit.close);

      final context = await _pumpHarness(
        tester,
        cubit: cubit,
        consentRepository: consentRepository,
        applicationService: _MockApplicationService(),
      );

      final request = JobOfferApplyRequest(
        candidate: _candidate(),
        offer: _offerWithKnockout(),
      );

      final future = JobOfferDetailController.apply(context, request);
      await tester.pumpAndSettle();

      expect(find.text('No se pudo evaluar el encaje'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Continuar postulación'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Consentimiento IA'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Acepto y continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Preguntas previas'), findsOneWidget);

      await tester.tap(find.text('Sí'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(FilledButton, 'Continuar postulación'),
      );
      await future;
      await tester.pumpAndSettle();

      expect(cubit.applyCalls, 1);
      expect(cubit.applyResponses.single?['q1'], true);

      final captured = verify(
        () => consentRepository.saveConsent(captureAny()),
      ).captured;
      expect(captured, hasLength(1));
      final record = captured.single as ConsentRecord;
      expect(record.candidateUid, 'candidate-1');
      expect(record.companyId, 'company-1');
      expect(record.scope, contains('ai_interview'));
      expect(record.scope, contains('ai_test'));
    },
  );

  testWidgets('apply se cancela cuando no se acepta el consentimiento IA', (
    tester,
  ) async {
    final consentRepository = _MockConsentRepository();
    when(() => consentRepository.saveConsent(any())).thenAnswer((
      invocation,
    ) async {
      return invocation.positionalArguments.first as ConsentRecord;
    });

    final cubit = _SpyJobOfferDetailCubit(
      evaluateOutcome: const JobOfferMatchFailure(
        'No se pudo evaluar ahora mismo.',
      ),
    );
    addTearDown(cubit.close);

    final context = await _pumpHarness(
      tester,
      cubit: cubit,
      consentRepository: consentRepository,
      applicationService: _MockApplicationService(),
    );

    final request = JobOfferApplyRequest(
      candidate: _candidate(),
      offer: _offerWithKnockout(),
    );

    final future = JobOfferDetailController.apply(context, request);
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(FilledButton, 'Continuar postulación'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'No acepto'));
    await future;
    await tester.pumpAndSettle();

    expect(cubit.applyCalls, 0);
    verifyNever(() => consentRepository.saveConsent(any()));
  });

  testWidgets(
    'apply tolera knockout malformado y usa campo de texto fallback',
    (tester) async {
      final consentRepository = _MockConsentRepository();
      when(() => consentRepository.saveConsent(any())).thenAnswer((
        invocation,
      ) async {
        return invocation.positionalArguments.first as ConsentRecord;
      });

      final cubit = _SpyJobOfferDetailCubit(
        evaluateOutcome: const JobOfferMatchFailure(
          'No se pudo evaluar ahora mismo.',
        ),
      );
      addTearDown(cubit.close);

      final context = await _pumpHarness(
        tester,
        cubit: cubit,
        consentRepository: consentRepository,
        applicationService: _MockApplicationService(),
      );

      final request = JobOfferApplyRequest(
        candidate: _candidate(),
        offer: _offerWithMalformedKnockoutOptions(),
      );

      final future = JobOfferDetailController.apply(context, request);
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(FilledButton, 'Continuar postulación'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Acepto y continuar'));
      await tester.pumpAndSettle();

      final answerField = find.byType(TextFormField);
      expect(answerField, findsOneWidget);
      await tester.enterText(answerField, 'Respuesta libre');
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(FilledButton, 'Continuar postulación'),
      );
      await future;
      await tester.pumpAndSettle();

      expect(cubit.applyCalls, 1);
      expect(cubit.applyResponses.single?['q_bad'], 'Respuesta libre');
    },
  );

  testWidgets('signQualifiedOffer completa flujo y refresca detalle', (
    tester,
  ) async {
    final applicationService = _MockApplicationService();

    when(
      () => applicationService.getQualifiedOfferSignatureStatus(
        applicationId: 'app-1',
      ),
    ).thenAnswer(
      (_) async => const QualifiedSignatureStatusResult(
        applicationId: 'app-1',
        status: 'offered',
      ),
    );
    when(
      () => applicationService.startQualifiedOfferSignature(
        applicationId: 'app-1',
      ),
    ).thenAnswer(
      (_) async => const QualifiedSignatureStartResult(
        requestId: 'req-1',
        applicationId: 'app-1',
        provider: 'qualified_trust_service_eidas',
        legalFramework: 'eidas',
        documentHash: 'hash-1',
      ),
    );
    when(
      () => applicationService.confirmQualifiedOfferSignature(
        requestId: 'req-1',
        otpCode: any(named: 'otpCode'),
        certificateFingerprint: any(named: 'certificateFingerprint'),
        providerReference: any(named: 'providerReference'),
      ),
    ).thenAnswer(
      (_) async => const QualifiedSignatureConfirmResult(
        success: true,
        requestId: 'req-1',
        signatureId: 'sig-1',
        applicationId: 'app-1',
        status: 'signed',
      ),
    );

    final cubit = _SpyJobOfferDetailCubit(
      evaluateOutcome: const JobOfferMatchFailure('No aplica para este test.'),
    );
    addTearDown(cubit.close);

    final context = await _pumpHarness(
      tester,
      cubit: cubit,
      consentRepository: _MockConsentRepository(),
      applicationService: applicationService,
    );

    final future = JobOfferDetailController.signQualifiedOffer(
      context,
      applicationId: 'app-1',
    );
    await tester.pumpAndSettle();

    expect(find.text('Completar firma cualificada'), findsOneWidget);

    await _enterFieldByLabel(tester, 'OTP de firma', '123456');
    await _enterFieldByLabel(
      tester,
      'Huella certificado cualificado',
      'ABCD-EFGH',
    );
    await _enterFieldByLabel(tester, 'Referencia proveedor', 'provider-ref-1');

    await tester.tap(find.widgetWithText(FilledButton, 'Firmar oferta'));
    await future;
    await tester.pumpAndSettle();

    expect(cubit.refreshCalls, 1);

    verify(
      () => applicationService.getQualifiedOfferSignatureStatus(
        applicationId: 'app-1',
      ),
    ).called(1);
    verify(
      () => applicationService.startQualifiedOfferSignature(
        applicationId: 'app-1',
      ),
    ).called(1);
    verify(
      () => applicationService.confirmQualifiedOfferSignature(
        requestId: 'req-1',
        otpCode: '123456',
        certificateFingerprint: 'ABCD-EFGH',
        providerReference: 'provider-ref-1',
      ),
    ).called(1);
  });

  testWidgets(
    'signQualifiedOffer ignora errores cuando el contexto ya no está montado',
    (tester) async {
      final applicationService = _MockApplicationService();
      final statusCompleter = Completer<QualifiedSignatureStatusResult>();

      when(
        () => applicationService.getQualifiedOfferSignatureStatus(
          applicationId: 'app-1',
        ),
      ).thenAnswer((_) => statusCompleter.future);

      final cubit = _SpyJobOfferDetailCubit(
        evaluateOutcome: const JobOfferMatchFailure(
          'No aplica para este test.',
        ),
      );
      addTearDown(cubit.close);

      final context = await _pumpHarness(
        tester,
        cubit: cubit,
        consentRepository: _MockConsentRepository(),
        applicationService: applicationService,
      );

      final future = JobOfferDetailController.signQualifiedOffer(
        context,
        applicationId: 'app-1',
      );
      await tester.pump();

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      statusCompleter.completeError(
        FirebaseFunctionsException(code: 'internal', message: 'fallo'),
      );

      await future;
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );
}

Future<BuildContext> _pumpHarness(
  WidgetTester tester, {
  required JobOfferDetailCubit cubit,
  required ConsentRepository consentRepository,
  required ApplicationService applicationService,
}) async {
  late BuildContext context;

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ConsentRepository>.value(value: consentRepository),
        RepositoryProvider<ApplicationService>.value(value: applicationService),
      ],
      child: BlocProvider<JobOfferDetailCubit>.value(
        value: cubit,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (buildContext) {
                context = buildContext;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    ),
  );

  return context;
}

Future<void> _enterFieldByLabel(
  WidgetTester tester,
  String label,
  String value,
) async {
  final labelFinder = find.text(label);
  final fieldFinder = find.ancestor(
    of: labelFinder,
    matching: find.byType(TextFormField),
  );
  await tester.ensureVisible(fieldFinder);
  await tester.enterText(fieldFinder, value);
  await tester.pumpAndSettle();
}

Candidate _candidate() {
  return const Candidate(
    id: 1,
    name: 'Test',
    lastName: 'Candidate',
    email: 'test@example.com',
    uid: 'candidate-1',
    role: 'candidate',
  );
}

JobOffer _offerWithKnockout() {
  return const JobOffer(
    id: 'offer-1',
    title: 'Flutter Engineer',
    description: 'Build products',
    location: 'Barcelona',
    companyUid: 'company-1',
    knockoutQuestions: [
      {
        'id': 'q1',
        'question': '¿Aceptas trabajar presencialmente?',
        'type': 'boolean',
        'requiredAnswer': true,
      },
    ],
  );
}

JobOffer _offerWithMalformedKnockoutOptions() {
  return const JobOffer(
    id: 'offer-2',
    title: 'QA Engineer',
    description: 'Test products',
    location: 'Madrid',
    companyUid: 'company-1',
    knockoutQuestions: [
      {
        'id': 'q_bad',
        'question': '¿Disponibilidad para turnos?',
        'type': 'multiple_choice',
        'options': [1, true, null],
        'requiredAnswer': 'si',
      },
    ],
  );
}
