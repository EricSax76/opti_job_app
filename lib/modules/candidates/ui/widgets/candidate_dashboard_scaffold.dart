import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/core/config/feature_flags.dart';
import 'package:opti_job_app/modules/candidates/logic/candidate_dashboard_scaffold_controller.dart';
import 'package:opti_job_app/modules/candidates/logic/candidate_dashboard_screen_logic.dart';
import 'package:opti_job_app/modules/candidates/ui/models/candidate_dashboard_screen_view_model.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_dashboard_app_bar.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_dashboard_drawer.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_dashboard_sidebar.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_interviews_badge.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_list_cubit.dart';

class CandidateDashboardScaffold extends StatelessWidget {
  const CandidateDashboardScaffold({
    super.key,
    required this.tabController,
    required this.viewModel,
    required this.dashboardPages,
    required this.interviewsCubit,
    required this.candidateUid,
    required this.onSelectIndex,
    required this.onOpenProfile,
    required this.onLogout,
  });

  final TabController tabController;
  final CandidateDashboardScreenViewModel viewModel;
  final List<Widget?> dashboardPages;
  final InterviewListCubit interviewsCubit;
  final String? candidateUid;
  final ValueChanged<int> onSelectIndex;
  final VoidCallback onOpenProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = viewModel.selectedIndex;

    final content = _CandidateDashboardContent(
      selectedIndex: selectedIndex,
      dashboardPages: dashboardPages,
      interviewsCubit: interviewsCubit,
      candidateUid: candidateUid,
      onOpenInterviews: () =>
          onSelectIndex(CandidateDashboardScreenLogic.interviewsIndex),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CandidateDashboardAppBar(
        tabController: tabController,
        avatarUrl: viewModel.avatarUrl,
        onOpenProfile: onOpenProfile,
        onLogout: onLogout,
        showTabBar: false,
      ),
      drawer: viewModel.showDrawer
          ? CandidateDashboardDrawer(
              selectedIndex: selectedIndex,
              onSelected: (index) {
                Navigator.of(context).pop();
                onSelectIndex(index);
              },
            )
          : null,
      bottomNavigationBar: viewModel.showBottomNavigationBar
          ? _buildBottomBar(viewModel)
          : null,
      body: viewModel.showNavigationSidebar
          ? Row(
              children: [
                CandidateDashboardSidebar(
                  selectedIndex: selectedIndex,
                  onSelected: onSelectIndex,
                ),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }

  Widget _buildBottomBar(CandidateDashboardScreenViewModel viewModel) {
    return BottomNavigationBar(
      currentIndex: viewModel.selectedBottomNavigationPosition,
      onTap: (position) =>
          onSelectIndex(viewModel.bottomNavigationItems[position].index),
      type: BottomNavigationBarType.fixed,
      items: [
        for (final item in viewModel.bottomNavigationItems)
          BottomNavigationBarItem(
            icon: item.showsInterviewsBadge
                ? CandidateInterviewsBadge(child: Icon(item.icon))
                : Icon(item.icon),
            label: item.label,
          ),
      ],
    );
  }
}

class _CandidateDashboardContent extends StatelessWidget {
  const _CandidateDashboardContent({
    required this.selectedIndex,
    required this.dashboardPages,
    required this.interviewsCubit,
    required this.candidateUid,
    required this.onOpenInterviews,
  });

  final int selectedIndex;
  final List<Widget?> dashboardPages;
  final InterviewListCubit interviewsCubit;
  final String? candidateUid;
  final VoidCallback onOpenInterviews;

  @override
  Widget build(BuildContext context) {
    return BlocListener<InterviewListCubit, InterviewListState>(
      bloc: interviewsCubit,
      listenWhen: (previous, current) =>
          CandidateDashboardScreenLogic.shouldNotifyNewInterviewMessages(
            previousState: previous,
            currentState: current,
            candidateUid: candidateUid,
            interviewsEnabled: FeatureFlags.interviews,
          ),
      listener: (context, _) =>
          CandidateDashboardScaffoldController.showNewInterviewMessage(
            context: context,
            onOpenInterviews: onOpenInterviews,
          ),
      child: IndexedStack(
        index: selectedIndex,
        children: List<Widget>.generate(
          dashboardPages.length,
          (index) => dashboardPages[index] ?? const SizedBox.shrink(),
          growable: false,
        ),
      ),
    );
  }
}
