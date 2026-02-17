import 'package:opti_job_app/modules/candidates/cubits/candidate_dashboard_cubit.dart';
import 'package:opti_job_app/modules/candidates/models/candidate_dashboard_navigation.dart';
import 'package:opti_job_app/modules/candidates/ui/models/candidate_dashboard_screen_view_model.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_list_cubit.dart';

class CandidateDashboardScreenLogic {
  const CandidateDashboardScreenLogic._();

  static const int interviewsIndex = 2;

  static CandidateDashboardScreenViewModel buildViewModel({
    required CandidateDashboardState dashboardState,
    required String? avatarUrl,
    required double viewportWidth,
    required bool interviewsEnabled,
  }) {
    final bottomNavigationItems = _buildBottomNavigationItems(
      interviewsEnabled: interviewsEnabled,
    );

    return CandidateDashboardScreenViewModel(
      selectedIndex: dashboardState.selectedIndex,
      avatarUrl: avatarUrl,
      showNavigationSidebar:
          viewportWidth >= candidateDashboardSidebarBreakpoint,
      bottomNavigationItems: bottomNavigationItems,
      selectedBottomNavigationPosition: _resolveBottomNavigationPosition(
        selectedIndex: dashboardState.selectedIndex,
        bottomNavigationItems: bottomNavigationItems,
      ),
    );
  }

  static bool shouldNotifyNewInterviewMessages({
    required InterviewListState previousState,
    required InterviewListState currentState,
    required String? candidateUid,
    required bool interviewsEnabled,
  }) {
    if (!interviewsEnabled) return false;
    final previousUnread = unreadInterviewCount(
      state: previousState,
      candidateUid: candidateUid,
    );
    final currentUnread = unreadInterviewCount(
      state: currentState,
      candidateUid: candidateUid,
    );
    return currentUnread > previousUnread;
  }

  static int unreadInterviewCount({
    required InterviewListState state,
    required String? candidateUid,
  }) {
    if (candidateUid == null || candidateUid.isEmpty) return 0;
    if (state is! InterviewListLoaded) return 0;

    var unread = 0;
    for (final interview in state.interviews) {
      unread += interview.unreadCounts?[candidateUid] ?? 0;
    }
    return unread;
  }

  static List<CandidateDashboardBottomNavItemViewModel>
  _buildBottomNavigationItems({required bool interviewsEnabled}) {
    final items = <CandidateDashboardBottomNavItemViewModel>[];

    for (final item in candidateDashboardTabItems) {
      if (!interviewsEnabled && item.index == interviewsIndex) continue;

      items.add(
        CandidateDashboardBottomNavItemViewModel(
          index: item.index,
          icon: item.tabIcon ?? item.icon,
          label: item.tabLabel ?? item.label,
          showsInterviewsBadge: item.index == interviewsIndex,
        ),
      );
    }

    return List.unmodifiable(items);
  }

  static int _resolveBottomNavigationPosition({
    required int selectedIndex,
    required List<CandidateDashboardBottomNavItemViewModel>
    bottomNavigationItems,
  }) {
    if (bottomNavigationItems.isEmpty) return 0;
    final selectedPosition = bottomNavigationItems.indexWhere(
      (item) => item.index == selectedIndex,
    );
    return selectedPosition >= 0 ? selectedPosition : 0;
  }
}
