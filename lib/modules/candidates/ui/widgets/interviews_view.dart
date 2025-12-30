import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/aplications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/my_applications_view.dart';

class InterviewsView extends StatelessWidget {
  const InterviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyApplicationsCubit, MyApplicationsState>(
      builder: (context, state) {
        if (state.status == ApplicationsStatus.loading ||
            state.status == ApplicationsStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == ApplicationsStatus.error) {
          return Center(
            child: Text(
              state.errorMessage ?? 'Error al cargar tus entrevistas.',
            ),
          );
        }

        final interviews =
            state.applications
                .where((entry) => entry.application.status == 'interview')
                .toList();

        if (interviews.isEmpty) {
          return const Center(
            child: Text('Aún no tienes entrevistas asignadas.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<MyApplicationsCubit>().loadMyApplications(),
          child: ApplicationsList(applications: interviews),
        );
      },
    );
  }
}

