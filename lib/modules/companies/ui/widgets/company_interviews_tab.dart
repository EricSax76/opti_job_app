import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/companies/logic/company_interviews_tab_controller.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_list_cubit.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/interview_list_tile.dart';

class CompanyInterviewsTab extends StatelessWidget {
  const CompanyInterviewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final companyUid = CompanyInterviewsTabController.resolveCompanyUid(
      context,
    );
    if (companyUid == null) return const SizedBox.shrink();

    return _CompanyInterviewsView(companyUid: companyUid);
  }
}

class _CompanyInterviewsView extends StatelessWidget {
  const _CompanyInterviewsView({required this.companyUid});

  final String companyUid;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InterviewListCubit, InterviewListState>(
      builder: (context, state) {
        if (state is InterviewListLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is InterviewListError) {
          return StateMessage(
            title: 'No se pudieron cargar las entrevistas',
            message: state.message,
          );
        }
        if (state is InterviewListEmpty) {
          return const StateMessage(
            title: 'Sin entrevistas activas',
            message: 'Cuando recibas respuestas de candidatos apareceran aqui.',
          );
        }
        if (state is InterviewListLoaded) {
          return RefreshIndicator(
            onRefresh: () => CompanyInterviewsTabController.refresh(context),
            child: ListView.separated(
              padding: const EdgeInsets.all(uiSpacing16),
              itemCount: state.interviews.length,
              separatorBuilder: (_, _) => const SizedBox(height: uiSpacing12),
              itemBuilder: (context, index) {
                return InterviewListTile(
                  interview: state.interviews[index],
                  isCompany: true,
                  currentUid: companyUid,
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
