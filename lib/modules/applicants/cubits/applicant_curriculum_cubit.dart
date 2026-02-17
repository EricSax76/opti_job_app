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

part 'applicant_curriculum_state.dart';

class ApplicantCurriculumCubit extends Cubit<ApplicantCurriculumState> {
  ApplicantCurriculumCubit({
    required this.profileRepository,
    required this.curriculumRepository,
    required this.jobOfferRepository,
    required this.aiRepository,
    required this.curriculumPdfService,
    required this.curriculumShareService,
  }) : super(const ApplicantCurriculumState());

  final ProfileRepository profileRepository;
  final CurriculumRepository curriculumRepository;
  final JobOfferRepository jobOfferRepository;
  final AiRepository aiRepository;
  final CurriculumPdfService curriculumPdfService;
  final CurriculumShareService curriculumShareService;

  String? _candidateUid;
  String? _offerId;

  void start({required String candidateUid, required String offerId}) {
    _candidateUid = candidateUid;
    _offerId = offerId;
    loadData(candidateUid: candidateUid, offerId: offerId);
  }

  Future<void> refresh() async {
    if (_candidateUid == null || _offerId == null) return;
    await loadData(candidateUid: _candidateUid!, offerId: _offerId!);
  }

  void retry() {
    refresh();
  }

  Future<void> loadData({
    required String candidateUid,
    required String offerId,
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
      final pdfBytes = await curriculumPdfService.buildPdf(
        candidate: state.candidate!,
        curriculum: state.curriculum!,
      );
      final safeName = _safeFileName(
        '${state.candidate!.name}_${state.candidate!.lastName}'.trim(),
      );
      await curriculumShareService.sharePdf(
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
