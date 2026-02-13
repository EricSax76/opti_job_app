import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_list_cubit.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/interview_list_tile.dart';

class InterviewsView extends StatelessWidget {
  const InterviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    final candidateUid = context
        .read<CandidateAuthCubit>()
        .state
        .candidate
        ?.uid;
    if (candidateUid == null) return const SizedBox.shrink();

    return BlocProvider(
      create: (context) => InterviewListCubit(
        repository: context.read<InterviewRepository>(),
        uid: candidateUid,
      ),
      child: const _InterviewsList(),
    );
  }
}

class _InterviewsList extends StatelessWidget {
  const _InterviewsList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<InterviewListCubit, InterviewListState>(
        builder: (context, state) {
          if (state is InterviewListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is InterviewListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        context.read<InterviewListCubit>().refresh(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          if (state is InterviewListEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes entrevistas activas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cuando una empresa inicie una entrevista,\naparecerá aquí.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }
          if (state is InterviewListLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                await context.read<InterviewListCubit>().refresh();
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.interviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return InterviewListTile(
                    interview: state.interviews[index],
                    isCompany: false,
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
