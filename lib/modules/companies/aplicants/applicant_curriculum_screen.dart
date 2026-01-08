import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/companies/aplicants/applicant_curriculum_cubit.dart';
import 'package:opti_job_app/modules/companies/aplicants/applicant_curriculum_widgets.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

class ApplicantCurriculumScreen extends StatelessWidget {
  const ApplicantCurriculumScreen({
    super.key,
    required this.candidateUid,
    required this.offerId,
  });

  final String candidateUid;
  final int offerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ApplicantCurriculumCubit(
        profileRepository: context.read<ProfileRepository>(),
        curriculumRepository: context.read<CurriculumRepository>(),
        jobOfferRepository: context.read<JobOfferRepository>(),
        aiRepository: context.read<AiRepository>(),
      )..loadData(candidateUid: candidateUid, offerId: offerId),
      child: const _ApplicantCurriculumView(),
    );
  }
}

class _ApplicantCurriculumView extends StatelessWidget {
  const _ApplicantCurriculumView();

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF8FAFC);
    const border = Color(0xFFE2E8F0);
    const muted = Color(0xFF475569);

    return BlocConsumer<ApplicantCurriculumCubit, ApplicantCurriculumState>(
      listener: (context, state) {
        if (state.infoMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.infoMessage!)));
        }
        if (state.matchResult != null) {
          showDialog(
            context: context,
            builder: (_) => MatchResultDialog(result: state.matchResult!),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('CV del aplicante')),
          body: Builder(
            builder: (context) {
              if (state.status == ApplicantCurriculumStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == ApplicantCurriculumStatus.failure ||
                  state.candidate == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      state.errorMessage ?? 'Error al cargar datos.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final candidate = state.candidate!;
              final curriculum = state.curriculum!;
              final hasCurriculum =
                  curriculum.headline.trim().isNotEmpty ||
                  curriculum.summary.trim().isNotEmpty ||
                  curriculum.phone.trim().isNotEmpty ||
                  curriculum.location.trim().isNotEmpty ||
                  curriculum.skills.isNotEmpty ||
                  curriculum.experiences.isNotEmpty ||
                  curriculum.education.isNotEmpty;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ApplicantCurriculumHeader(
                          candidate: candidate,
                          hasCurriculum: hasCurriculum,
                          isExporting: state.isExporting,
                          isMatching: state.isMatching,
                          onExport: () => context
                              .read<ApplicantCurriculumCubit>()
                              .exportPdf(),
                          onMatch: () => context
                              .read<ApplicantCurriculumCubit>()
                              .analyzeMatch(),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: border),
                          ),
                          child: hasCurriculum
                              ? CurriculumReadOnlyView(curriculum: curriculum)
                              : Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: background,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: border),
                                  ),
                                  child: const Text(
                                    'El aplicante aún no tiene un CV cargado.',
                                    style: TextStyle(color: muted, height: 1.4),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
