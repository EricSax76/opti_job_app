import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/features/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/features/ai/models/ai_match_result.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum_pdf_service.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum_share_service.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

enum ApplicantCurriculumStatus { initial, loading, success, failure }

class ApplicantCurriculumState extends Equatable {
  const ApplicantCurriculumState({
    this.status = ApplicantCurriculumStatus.initial,
    this.candidate,
    this.curriculum,
    this.offer,
    this.isExporting = false,
    this.isMatching = false,
    this.matchResult,
    this.errorMessage,
    this.infoMessage,
  });

  final ApplicantCurriculumStatus status;
  final Candidate? candidate;
  final Curriculum? curriculum;
  final JobOffer? offer;
  final bool isExporting;
  final bool isMatching;
  final AiMatchResult? matchResult;
  final String? errorMessage;
  final String? infoMessage;

  ApplicantCurriculumState copyWith({
    ApplicantCurriculumStatus? status,
    Candidate? candidate,
    Curriculum? curriculum,
    JobOffer? offer,
    bool? isExporting,
    bool? isMatching,
    AiMatchResult? matchResult,
    String? errorMessage,
    String? infoMessage,
    bool clearMatchResult = false,
    bool clearInfoMessage = false,
  }) {
    return ApplicantCurriculumState(
      status: status ?? this.status,
      candidate: candidate ?? this.candidate,
      curriculum: curriculum ?? this.curriculum,
      offer: offer ?? this.offer,
      isExporting: isExporting ?? this.isExporting,
      isMatching: isMatching ?? this.isMatching,
      matchResult: clearMatchResult ? null : matchResult ?? this.matchResult,
      errorMessage: errorMessage ?? this.errorMessage,
      infoMessage: clearInfoMessage ? null : infoMessage ?? this.infoMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    candidate,
    curriculum,
    offer,
    isExporting,
    isMatching,
    matchResult,
    errorMessage,
    infoMessage,
  ];
}

class ApplicantCurriculumCubit extends Cubit<ApplicantCurriculumState> {
  ApplicantCurriculumCubit({
    required this.profileRepository,
    required this.curriculumRepository,
    required this.jobOfferRepository,
    required this.aiRepository,
  }) : super(const ApplicantCurriculumState());

  final ProfileRepository profileRepository;
  final CurriculumRepository curriculumRepository;
  final JobOfferRepository jobOfferRepository;
  final AiRepository aiRepository;

  Future<void> loadData({
    required String candidateUid,
    required int offerId,
  }) async {
    emit(state.copyWith(status: ApplicantCurriculumStatus.loading));
    try {
      final results = await Future.wait([
        profileRepository.fetchCandidateProfile(candidateUid),
        curriculumRepository.fetchCurriculum(candidateUid),
        jobOfferRepository.fetchById(offerId),
      ]);

      emit(
        state.copyWith(
          status: ApplicantCurriculumStatus.success,
          candidate: results[0] as Candidate,
          curriculum: results[1] as Curriculum,
          offer: results[2] as JobOffer,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ApplicantCurriculumStatus.failure,
          errorMessage: 'No se pudo cargar el CV del aplicante.',
        ),
      );
    }
  }

  Future<void> exportPdf() async {
    if (state.isExporting ||
        state.candidate == null ||
        state.curriculum == null) {
      return;
    }
    emit(state.copyWith(isExporting: true));
    try {
      final pdfBytes = await CurriculumPdfService().buildPdf(
        candidate: state.candidate!,
        curriculum: state.curriculum!,
      );
      final safeName = _safeFileName(
        '${state.candidate!.name}_${state.candidate!.lastName}'.trim(),
      );
      await CurriculumShareService().sharePdf(
        bytes: pdfBytes,
        fileName: 'CV_$safeName.pdf',
        subject: 'Curriculum - ${state.candidate!.name}',
      );
    } catch (_) {
      emit(state.copyWith(infoMessage: 'No se pudo exportar el PDF.'));
    } finally {
      emit(state.copyWith(isExporting: false, clearInfoMessage: true));
    }
  }

  Future<void> analyzeMatch() async {
    if (state.isMatching || state.curriculum == null || state.offer == null) {
      return;
    }
    emit(state.copyWith(isMatching: true, clearMatchResult: true));
    try {
      final result = await aiRepository.matchOfferCandidateForCompany(
        curriculum: state.curriculum!,
        offer: state.offer!,
        locale: 'es-ES',
      );
      emit(state.copyWith(matchResult: result));
    } on AiConfigurationException catch (e) {
      emit(state.copyWith(infoMessage: e.message));
    } on AiRequestException catch (e) {
      emit(state.copyWith(infoMessage: e.message));
    } catch (_) {
      emit(state.copyWith(infoMessage: 'No se pudo calcular el match.'));
    } finally {
      emit(state.copyWith(isMatching: false, clearInfoMessage: true));
    }
  }

  String _safeFileName(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'candidato';
    return trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
  }
}
