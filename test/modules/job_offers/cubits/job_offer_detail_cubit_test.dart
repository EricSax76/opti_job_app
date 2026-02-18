import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opti_job_app/features/ai/models/ai_match_result.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/applications/logic/application_service.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_match_logic.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';

class _MockJobOfferRepository extends Mock implements JobOfferRepository {}

class _MockApplicationService extends Mock implements ApplicationService {}

class _MockCurriculumRepository extends Mock implements CurriculumRepository {}

class _MockAiRepository extends Mock implements AiRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const Curriculum(
        headline: '',
        summary: '',
        phone: '',
        location: '',
        skills: <String>[],
        experiences: <CurriculumItem>[],
        education: <CurriculumItem>[],
      ),
    );
    registerFallbackValue(
      const JobOffer(
        id: 'fallback-offer',
        title: '',
        description: '',
        location: '',
      ),
    );
  });

  late _MockJobOfferRepository repository;
  late _MockApplicationService applicationService;
  late _MockCurriculumRepository curriculumRepository;
  late _MockAiRepository aiRepository;
  late JobOfferDetailCubit cubit;

  setUp(() {
    repository = _MockJobOfferRepository();
    applicationService = _MockApplicationService();
    curriculumRepository = _MockCurriculumRepository();
    aiRepository = _MockAiRepository();
    cubit = JobOfferDetailCubit(
      repository,
      applicationService,
      curriculumRepository: curriculumRepository,
      aiRepository: aiRepository,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  test(
    'evaluateFitForApplication fails fast when candidate uid is empty',
    () async {
      final outcome = await cubit.evaluateFitForApplication(
        candidateUid: '   ',
        offer: _offer(),
      );

      expect(outcome, isA<JobOfferMatchFailure>());
      verifyNever(() => curriculumRepository.fetchCurriculum(any()));
      verifyZeroInteractions(aiRepository);
    },
  );

  test('evaluateFitForApplication returns successful match outcome', () async {
    const curriculum = Curriculum(
      headline: 'Flutter Developer',
      summary: 'Experiencia en apps web y mobile.',
      phone: '',
      location: 'Madrid',
      skills: ['Flutter', 'Firebase'],
      experiences: [],
      education: [],
    );
    final offer = _offer();
    const match = AiMatchResult(
      score: 78,
      reasons: ['Experiencia en Flutter'],
      recommendations: ['Resaltar impacto en proyectos'],
      summary: 'Buen encaje general.',
    );

    when(
      () => curriculumRepository.fetchCurriculum('candidate-1'),
    ).thenAnswer((_) async => curriculum);
    when(
      () => aiRepository.matchOfferCandidate(
        curriculum: any(named: 'curriculum'),
        offer: any(named: 'offer'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async => match);

    final outcome = await cubit.evaluateFitForApplication(
      candidateUid: 'candidate-1',
      offer: offer,
    );

    expect(outcome, isA<JobOfferMatchSuccess>());
    expect((outcome as JobOfferMatchSuccess).result, match);
    verify(() => curriculumRepository.fetchCurriculum('candidate-1')).called(1);
    verify(
      () => aiRepository.matchOfferCandidate(
        curriculum: curriculum,
        offer: offer,
        locale: 'es-ES',
      ),
    ).called(1);
  });
}

JobOffer _offer() {
  return const JobOffer(
    id: 'offer-1',
    title: 'Flutter Engineer',
    description: 'Build job-search features',
    location: 'Barcelona',
    companyUid: 'company-1',
  );
}
