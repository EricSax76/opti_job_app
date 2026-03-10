import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/applicants/cubits/applicant_curriculum_cubit.dart';
import 'package:opti_job_app/modules/applicants/logic/applicant_curriculum_screen_controller.dart';
import 'package:opti_job_app/modules/applicants/ui/applicant_curriculum_exports.dart';

class ApplicantCurriculumScreen extends StatelessWidget {
  const ApplicantCurriculumScreen({
    super.key,
    required this.cubit,
    required this.candidateUid,
    required this.offerId,
    this.applicationId,
  });

  final ApplicantCurriculumCubit cubit;
  final String candidateUid;
  final String offerId;
  final String? applicationId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: _ApplicantCurriculumView(
        candidateUid: candidateUid,
        offerId: offerId,
        applicationId: applicationId,
      ),
    );
  }
}

class _ApplicantCurriculumView extends StatelessWidget {
  const _ApplicantCurriculumView({
    required this.candidateUid,
    required this.offerId,
    required this.applicationId,
  });

  final String candidateUid;
  final String offerId;
  final String? applicationId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApplicantCurriculumCubit, ApplicantCurriculumState>(
      listenWhen: ApplicantCurriculumScreenController.shouldListen,
      listener: ApplicantCurriculumScreenController.handleSideEffects,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('CV del aplicante')),
          body: _ApplicantCurriculumBody(
            state: state,
            candidateUid: candidateUid,
            offerId: offerId,
            applicationId: applicationId,
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
    required this.applicationId,
  });

  final ApplicantCurriculumState state;
  final String candidateUid;
  final String offerId;
  final String? applicationId;

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
          onAction: () => cubit.retry(),
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
          offerId: offerId,
          applicationId: applicationId,
          companyUid:
              state.offer?.companyUid?.trim() ??
              state.offer?.companyId?.toString(),
          hasVideoCurriculum: state.hasVideoCurriculum,
          canViewVideoCurriculum: state.canViewVideoCurriculum,
          isExporting: state.isExporting,
          isMatching: state.isMatching,
          onExport: cubit.exportPdf,
          onMatch: cubit.analyzeMatch,
        );
    }
  }
}
