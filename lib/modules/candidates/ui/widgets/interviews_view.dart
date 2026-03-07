import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_list_cubit.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/interview_list_tile.dart';

class InterviewsView extends StatelessWidget {
  const InterviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    final candidateUid = context.select<CandidateAuthCubit, String>(
      (cubit) => cubit.state.candidate?.uid ?? '',
    );
    return _InterviewsList(currentUid: candidateUid);
  }
}

class _InterviewsList extends StatelessWidget {
  const _InterviewsList({required this.currentUid});

  final String currentUid;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InterviewListCubit, InterviewListState>(
      builder: (context, state) {
        if (state is InterviewListLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is InterviewListError) {
          return StateMessage(
            title: 'No se pudieron cargar tus entrevistas',
            message: state.message,
            actionLabel: 'Reintentar',
            onAction: () => context.read<InterviewListCubit>().refresh(),
          );
        }
        if (state is InterviewListEmpty) {
          return const StateMessage(
            title: 'No tienes entrevistas activas',
            message:
                'Cuando una empresa inicie una entrevista, aparecera aqui.',
          );
        }
        if (state is InterviewListLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              await context.read<InterviewListCubit>().refresh();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(uiSpacing16),
              itemCount: state.interviews.length,
              separatorBuilder: (_, _) => const SizedBox(height: uiSpacing12),
              itemBuilder: (context, index) {
                return InterviewListTile(
                  interview: state.interviews[index],
                  isCompany: false,
                  currentUid: currentUid,
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
