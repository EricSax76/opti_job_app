import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_service.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

class _MockJobOfferRepository extends Mock implements JobOfferRepository {}

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _MockJobOfferRepository repository;
  late _MockProfileRepository profileRepository;
  late JobOffersCubit cubit;

  setUp(() {
    repository = _MockJobOfferRepository();
    profileRepository = _MockProfileRepository();
    cubit = JobOffersCubit(repository, profileRepository: profileRepository);
  });

  tearDown(() async {
    await cubit.close();
  });

  test(
    'selectJobType(null) clears current filter and fetches unfiltered page',
    () async {
      when(
        () => repository.fetchPage(
          jobType: any(named: 'jobType'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((invocation) async {
        final selectedType = invocation.namedArguments[#jobType] as String?;
        if (selectedType == null) {
          return const JobOffersPage(
            offers: [],
            hasMore: false,
            nextPageCursor: null,
          );
        }
        return JobOffersPage(
          offers: [_offer(id: 'offer-$selectedType', jobType: selectedType)],
          hasMore: false,
          nextPageCursor: null,
        );
      });

      await cubit.loadOffers(
        jobType: 'Remoto',
        forceRefresh: true,
        preserveCurrentJobType: false,
      );
      expect(cubit.state.selectedJobType, 'Remoto');

      cubit.selectJobType(null);
      await untilCalled(
        () => repository.fetchPage(jobType: null, limit: any(named: 'limit')),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selectedJobType, isNull);
      verify(
        () => repository.fetchPage(
          jobType: 'Remoto',
          limit: any(named: 'limit'),
        ),
      ).called(1);
      verify(
        () => repository.fetchPage(jobType: null, limit: any(named: 'limit')),
      ).called(1);
    },
  );

  test(
    'keeps known job types available after selecting a specific type',
    () async {
      when(
        () => repository.fetchPage(
          jobType: any(named: 'jobType'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((invocation) async {
        final selectedType = invocation.namedArguments[#jobType] as String?;
        if (selectedType == null) {
          return JobOffersPage(
            offers: [
              _offer(id: 'offer-1', jobType: 'Remoto'),
              _offer(id: 'offer-2', jobType: 'Hibrido'),
            ],
            hasMore: false,
            nextPageCursor: null,
          );
        }
        return JobOffersPage(
          offers: [_offer(id: 'offer-3', jobType: selectedType)],
          hasMore: false,
          nextPageCursor: null,
        );
      });

      await cubit.loadOffers(forceRefresh: true);
      expect(cubit.state.availableJobTypes, ['Hibrido', 'Remoto']);

      cubit.selectJobType('Remoto');
      await untilCalled(
        () => repository.fetchPage(
          jobType: 'Remoto',
          limit: any(named: 'limit'),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selectedJobType, 'Remoto');
      expect(cubit.state.availableJobTypes, ['Hibrido', 'Remoto']);
    },
  );

  test('clearErrorMessage removes non-blocking refresh error', () async {
    var requestCount = 0;
    when(
      () => repository.fetchPage(
        jobType: any(named: 'jobType'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async {
      requestCount += 1;
      if (requestCount == 1) {
        return JobOffersPage(
          offers: [_offer(id: 'offer-1', jobType: 'Remoto')],
          hasMore: false,
          nextPageCursor: null,
        );
      }
      throw Exception('network error');
    });

    await cubit.loadOffers(forceRefresh: true);
    await cubit.loadOffers(forceRefresh: true);

    expect(cubit.state.status, JobOffersStatus.success);
    expect(cubit.state.errorMessage, 'No se pudieron actualizar las ofertas.');

    cubit.clearErrorMessage();
    expect(cubit.state.errorMessage, isNull);
  });
}

JobOffer _offer({required String id, required String jobType}) {
  return JobOffer(
    id: id,
    title: 'Oferta $id',
    description: 'Descripcion',
    location: 'Madrid',
    companyUid: 'company-1',
    jobType: jobType,
  );
}
