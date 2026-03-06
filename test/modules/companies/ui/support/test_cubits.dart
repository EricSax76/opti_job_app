import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/features/ai/models/ai_job_offer_draft.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_form_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_payload.dart';
import 'package:opti_job_app/modules/companies/cubits/company_offer_creation_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_offer_creation_state.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_list_cubit.dart';

class TestCompanyAuthCubit extends Cubit<CompanyAuthState>
    implements CompanyAuthCubit {
  TestCompanyAuthCubit(super.initialState);

  var logoutCalled = false;
  final List<Company> updatedCompanies = <Company>[];

  void emitState(CompanyAuthState nextState) => emit(nextState);

  @override
  Future<void> restoreSession() async {}

  @override
  Future<void> loginCompany({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> registerCompany({
    required String name,
    required String email,
    required String password,
  }) async {}

  @override
  void completeOnboarding() {}

  @override
  void clearError() {}

  @override
  Future<void> logout() async {
    logoutCalled = true;
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        clearCompany: true,
        clearError: true,
        needsOnboarding: false,
      ),
    );
  }

  @override
  void updateCompany(Company company) {
    updatedCompanies.add(company);
    emit(state.copyWith(company: company));
  }
}

class TestCompanyJobOffersCubit extends Cubit<CompanyJobOffersState>
    implements CompanyJobOffersCubit {
  TestCompanyJobOffersCubit(super.initialState);

  final List<String> loadedCompanyUids = <String>[];
  String? _companyUid;

  void emitState(CompanyJobOffersState nextState) => emit(nextState);

  @override
  Future<void> start(String companyUid) async {
    _companyUid = companyUid;
    loadedCompanyUids.add(companyUid);
  }

  @override
  Future<void> refresh() async {
    final companyUid = _companyUid;
    if (companyUid == null) return;
    loadedCompanyUids.add(companyUid);
  }

  @override
  void retry() => unawaited(refresh());
}

class TestOfferApplicantsCubit extends Cubit<OfferApplicantsState>
    implements OfferApplicantsCubit {
  TestOfferApplicantsCubit(super.initialState);

  void emitState(OfferApplicantsState nextState) => emit(nextState);

  @override
  Future<void> loadApplicants({
    required String offerId,
    required String companyUid,
  }) async {}

  @override
  Future<void> loadApplicantsForOffers({
    required Iterable<String> offerIds,
    required String companyUid,
    bool force = false,
  }) async {}

  @override
  Future<void> updateApplicationStatus({
    required String offerId,
    required String applicationId,
    required String newStatus,
    required String companyUid,
  }) async {}
}

class TestJobOfferFormCubit extends Cubit<JobOfferFormState>
    implements JobOfferFormCubit {
  TestJobOfferFormCubit(super.initialState);

  final List<JobOfferPayload> submittedPayloads = <JobOfferPayload>[];

  void emitState(JobOfferFormState nextState) => emit(nextState);

  @override
  Future<void> submit(
    JobOfferPayload payload, {
    String? pipelineId,
    List<dynamic>? pipelineStages,
    List<dynamic>? knockoutQuestions,
  }) async {
    submittedPayloads.add(payload);
  }
}

class TestCompanyOfferCreationCubit extends Cubit<CompanyOfferCreationState>
    implements CompanyOfferCreationCubit {
  TestCompanyOfferCreationCubit(super.initialState);

  void emitState(CompanyOfferCreationState nextState) => emit(nextState);

  @override
  AiRepository get aiRepository =>
      throw UnimplementedError('aiRepository is not used in this test cubit.');

  @override
  Future<AiJobOfferDraft?> generateJobOffer({
    required Map<String, dynamic> criteria,
  }) async {
    return null;
  }
}

class TestInterviewListCubit extends Cubit<InterviewListState>
    implements InterviewListCubit {
  TestInterviewListCubit(super.initialState);

  var startCalled = false;
  var refreshCalled = false;

  void emitState(InterviewListState nextState) => emit(nextState);

  @override
  Future<void> start() async {
    startCalled = true;
  }

  @override
  Future<void> refresh() async {
    refreshCalled = true;
  }

  @override
  void retry() => unawaited(refresh());
}
