import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/applicants/cubits/applicant_curriculum_cubit.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/applicant_curriculum_widgets.dart';
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
  final String offerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ApplicantCurriculumCubit(
        profileRepository: context.read<ProfileRepository>(),
        curriculumRepository: context.read<CurriculumRepository>(),
        jobOfferRepository: context.read<JobOfferRepository>(),
        aiRepository: context.read<AiRepository>(),
      )..loadData(candidateUid: candidateUid, offerId: offerId),
      child: _ApplicantCurriculumView(
        candidateUid: candidateUid,
        offerId: offerId,
      ),
    );
  }
}

class _ApplicantCurriculumView extends StatelessWidget {
  const _ApplicantCurriculumView({
    required this.candidateUid,
    required this.offerId,
  });

  final String candidateUid;
  final String offerId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApplicantCurriculumCubit, ApplicantCurriculumState>(
      listenWhen: (previous, current) {
        return previous.infoMessage != current.infoMessage ||
            previous.matchResult != current.matchResult;
      },
      listener: (context, state) {
        final infoMessage = state.infoMessage;
        if (infoMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(infoMessage)));
        }
        final matchResult = state.matchResult;
        if (matchResult != null) {
          showDialog(
            context: context,
            builder: (_) => MatchResultDialog(result: matchResult),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('CV del aplicante')),
          body: _ApplicantCurriculumBody(
            state: state,
            candidateUid: candidateUid,
            offerId: offerId,
          ),
        );
      },
    );
  }
}

class _ApplicantCurriculumBody extends StatelessWidget {
  const _ApplicantCurriculumBody({
    required this.state,
    required this.candidateUid,
    required this.offerId,
  });

  final ApplicantCurriculumState state;
  final String candidateUid;
  final String offerId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ApplicantCurriculumCubit>();

    switch (state.status) {
      case ApplicantCurriculumStatus.initial:
      case ApplicantCurriculumStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ApplicantCurriculumStatus.failure:
        return StateMessage(
          title: 'No se pudo cargar el CV del aplicante',
          message: state.errorMessage ?? 'Intenta nuevamente en unos segundos.',
          actionLabel: 'Reintentar',
          onAction: () =>
              cubit.loadData(candidateUid: candidateUid, offerId: offerId),
        );
      case ApplicantCurriculumStatus.success:
        final candidate = state.candidate;
        final curriculum = state.curriculum;
        if (candidate == null || curriculum == null) {
          return const StateMessage(
            title: 'No hay datos del aplicante',
            message:
                'No encontramos la información necesaria para mostrar este perfil.',
          );
        }
        return ApplicantCurriculumContent(
          candidate: candidate,
          curriculum: curriculum,
          isExporting: state.isExporting,
          isMatching: state.isMatching,
          onExport: cubit.exportPdf,
          onMatch: cubit.analyzeMatch,
        );
    }
  }
}
