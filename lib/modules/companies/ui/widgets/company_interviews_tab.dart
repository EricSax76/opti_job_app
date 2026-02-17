import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    return BlocProvider(
      create: (context) => CompanyInterviewsTabController.createCubit(
        context: context,
        companyUid: companyUid,
      ),
      child: const _CompanyInterviewsView(),
    );
  }
}

class _CompanyInterviewsView extends StatelessWidget {
  const _CompanyInterviewsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<InterviewListCubit, InterviewListState>(
        builder: (context, state) {
          if (state is InterviewListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is InterviewListError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is InterviewListEmpty) {
            return const Center(child: Text('No hay entrevistas activas.'));
          }
          if (state is InterviewListLoaded) {
            return RefreshIndicator(
              onRefresh: () => CompanyInterviewsTabController.refresh(context),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.interviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return InterviewListTile(
                    interview: state.interviews[index],
                    isCompany: true,
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
