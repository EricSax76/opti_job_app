import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/features/ai/models/ai_match_result.dart';
import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_detail_logic.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_list_logic.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_match_logic.dart';
import 'package:opti_job_app/modules/job_offers/logic/offer_card_logic.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

void main() {
  Company company({
    int id = 10,
    String name = 'Acme',
    String uid = 'company-uid',
    String? avatarUrl,
  }) {
    return Company(
      id: id,
      name: name,
      email: 'acme@example.com',
      uid: uid,
      avatarUrl: avatarUrl,
    );
  }

  Candidate candidate({String uid = 'candidate-uid'}) {
    return Candidate(
      id: 1,
      name: 'Ana',
      lastName: 'Perez',
      email: 'ana@example.com',
      uid: uid,
      role: 'candidate',
    );
  }

  JobOffer offer({
    required String id,
    int? companyId,
    String? companyUid,
    String? companyName,
    String? companyAvatarUrl,
    String? jobType,
    String? salaryMin,
    String? salaryMax,
    String location = 'Madrid',
  }) {
    return JobOffer(
      id: id,
      title: 'Oferta $id',
      description: 'Descripcion',
      location: location,
      companyId: companyId,
      companyUid: companyUid,
      companyName: companyName,
      companyAvatarUrl: companyAvatarUrl,
      jobType: jobType,
      salaryMin: salaryMin,
      salaryMax: salaryMax,
    );
  }

  group('JobOfferListLogic', () {
    test('buildViewModel creates list items and sorted job types', () {
      final state = JobOffersState(
        status: JobOffersStatus.success,
        offers: [
          offer(
            id: '1',
            companyId: 10,
            companyName: ' ',
            companyAvatarUrl: ' ',
            jobType: 'Remoto',
            salaryMin: '1000',
            salaryMax: '2000',
          ),
          offer(id: '2', companyName: 'Empresa QA', jobType: 'Hibrido'),
        ],
        availableJobTypes: const ['Presencial', ''],
        companiesById: {
          10: company(avatarUrl: 'https://cdn.example.com/company.png'),
        },
        selectedJobType: 'Remoto',
        isRefreshing: true,
        hasMore: false,
      );

      final viewModel = JobOfferListLogic.buildViewModel(state);

      expect(viewModel.items, hasLength(2));
      expect(viewModel.items.first.companyName, 'Acme');
      expect(
        viewModel.items.first.avatarUrl,
        'https://cdn.example.com/company.png',
      );
      expect(viewModel.items.first.salary, '1000 - 2000');
      expect(viewModel.availableJobTypes, ['Hibrido', 'Presencial', 'Remoto']);
      expect(viewModel.isRefreshing, isTrue);
      expect(viewModel.hasMore, isFalse);
    });

    test(
      'shouldShowRefreshError only emits for success-state refresh errors',
      () {
        final previous = const JobOffersState(status: JobOffersStatus.success);
        final successErrorState = const JobOffersState(
          status: JobOffersStatus.success,
          errorMessage: 'No se pudieron actualizar las ofertas.',
        );
        final failureErrorState = const JobOffersState(
          status: JobOffersStatus.failure,
          errorMessage: 'No se pudieron cargar las ofertas.',
        );

        expect(
          JobOfferListLogic.shouldShowRefreshError(
            previous: previous,
            current: successErrorState,
          ),
          isTrue,
        );
        expect(
          JobOfferListLogic.shouldShowRefreshError(
            previous: previous,
            current: failureErrorState,
          ),
          isFalse,
        );
      },
    );
  });

  group('JobOfferDetailLogic', () {
    test('buildViewModel resolves actions and avatar fallback', () {
      final state = JobOfferDetailState(
        status: JobOfferDetailStatus.success,
        offer: offer(id: 'offer-1', companyId: 10, companyAvatarUrl: ' '),
      );
      final viewModel = JobOfferDetailLogic.buildViewModel(
        state: state,
        isAuthenticated: true,
        candidate: candidate(),
        companiesById: {
          10: company(avatarUrl: 'https://cdn.example.com/company.png'),
        },
      );

      expect(viewModel.isAuthenticated, isTrue);
      expect(viewModel.companyAvatarUrl, 'https://cdn.example.com/company.png');
      expect(viewModel.applyRequest, isNotNull);
      expect(viewModel.matchRequest?.candidateUid, 'candidate-uid');
    });

    test(
      'shouldListenForMessages detects message and match outcome changes',
      () {
        const previous = JobOfferDetailState(successMessage: ' Listo ');
        const currentSameMessage = JobOfferDetailState(successMessage: 'Listo');
        const currentError = JobOfferDetailState(errorMessage: 'Error');
        final currentMatch = JobOfferDetailState(
          matchOutcome: JobOfferMatchSuccess(
            const AiMatchResult(
              score: 72,
              reasons: ['Experiencia relevante'],
              recommendations: ['Destacar logro medible'],
            ),
          ),
        );

        expect(
          JobOfferDetailLogic.shouldListenForMessages(
            previous: previous,
            current: currentSameMessage,
          ),
          isFalse,
        );
        expect(
          JobOfferDetailLogic.shouldListenForMessages(
            previous: previous,
            current: currentError,
          ),
          isTrue,
        );
        expect(
          JobOfferDetailLogic.shouldListenForMessages(
            previous: previous,
            current: currentMatch,
          ),
          isTrue,
        );
      },
    );
  });

  group('OfferCardLogic', () {
    test('buildViewModel applies subtitle and company uid fallback', () {
      final viewModel = OfferCardLogic.buildViewModel(
        offer: offer(id: 'offer-1', jobType: ' ', location: 'Valencia'),
        companyUidFromAuth: ' company-123 ',
        avatarUrlFromAuth: ' ',
      );

      expect(viewModel.subtitle, 'Valencia • Tipología no especificada');
      expect(viewModel.companyUid, 'company-123');
      expect(viewModel.avatarUrl, isNull);
    });

    test('shouldLoadApplicants only for initial or failure on expand', () {
      expect(
        OfferCardLogic.shouldLoadApplicants(
          expanded: true,
          status: OfferApplicantsStatus.initial,
        ),
        isTrue,
      );
      expect(
        OfferCardLogic.shouldLoadApplicants(
          expanded: true,
          status: OfferApplicantsStatus.failure,
        ),
        isTrue,
      );
      expect(
        OfferCardLogic.shouldLoadApplicants(
          expanded: true,
          status: OfferApplicantsStatus.success,
        ),
        isFalse,
      );
      expect(
        OfferCardLogic.shouldLoadApplicants(
          expanded: false,
          status: OfferApplicantsStatus.initial,
        ),
        isFalse,
      );
    });
  });
}
