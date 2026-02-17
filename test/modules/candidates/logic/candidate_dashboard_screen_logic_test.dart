import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_dashboard_cubit.dart';
import 'package:opti_job_app/modules/candidates/logic/candidate_dashboard_screen_logic.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_list_cubit.dart';
import 'package:opti_job_app/modules/interviews/models/interview.dart';

void main() {
  Interview buildInterview({
    required String id,
    required Map<String, int> unreadCounts,
  }) {
    final timestamp = DateTime.utc(2026, 2, 1, 12);
    return Interview(
      id: id,
      applicationId: 'app-$id',
      jobOfferId: 'offer-$id',
      companyUid: 'company-1',
      candidateUid: 'candidate-1',
      participants: const ['company-1', 'candidate-1'],
      status: InterviewStatus.scheduled,
      createdAt: timestamp,
      updatedAt: timestamp,
      unreadCounts: unreadCounts,
    );
  }

  group('CandidateDashboardScreenLogic.buildViewModel', () {
    test('shows sidebar on desktop layout', () {
      final viewModel = CandidateDashboardScreenLogic.buildViewModel(
        dashboardState: CandidateDashboardState.initial(1),
        avatarUrl: 'https://example.com/avatar.png',
        viewportWidth: 1200,
        interviewsEnabled: true,
      );

      expect(viewModel.showNavigationSidebar, isTrue);
      expect(viewModel.showDrawer, isFalse);
      expect(viewModel.showBottomNavigationBar, isFalse);
      expect(viewModel.bottomNavigationItems, hasLength(3));
      expect(viewModel.selectedBottomNavigationPosition, 1);
    });

    test('filters interview tab from mobile nav when feature is disabled', () {
      final viewModel = CandidateDashboardScreenLogic.buildViewModel(
        dashboardState: CandidateDashboardState.initial(2),
        avatarUrl: null,
        viewportWidth: 390,
        interviewsEnabled: false,
      );

      expect(viewModel.showNavigationSidebar, isFalse);
      expect(viewModel.showDrawer, isTrue);
      expect(viewModel.showBottomNavigationBar, isTrue);
      expect(viewModel.bottomNavigationItems, hasLength(2));
      expect(viewModel.selectedBottomNavigationPosition, 0);
    });
  });

  group('CandidateDashboardScreenLogic unread logic', () {
    test('unreadInterviewCount sums unread messages for candidate', () {
      final state = InterviewListLoaded([
        buildInterview(id: 'int-1', unreadCounts: const {'candidate-1': 1}),
        buildInterview(id: 'int-2', unreadCounts: const {'candidate-1': 3}),
        buildInterview(id: 'int-3', unreadCounts: const {'candidate-2': 10}),
      ]);

      final count = CandidateDashboardScreenLogic.unreadInterviewCount(
        state: state,
        candidateUid: 'candidate-1',
      );

      expect(count, 4);
    });

    test('shouldNotifyNewInterviewMessages detects unread increases only', () {
      final previous = InterviewListLoaded([
        buildInterview(id: 'int-1', unreadCounts: const {'candidate-1': 1}),
      ]);
      final current = InterviewListLoaded([
        buildInterview(id: 'int-1', unreadCounts: const {'candidate-1': 2}),
      ]);

      expect(
        CandidateDashboardScreenLogic.shouldNotifyNewInterviewMessages(
          previousState: previous,
          currentState: current,
          candidateUid: 'candidate-1',
          interviewsEnabled: true,
        ),
        isTrue,
      );

      expect(
        CandidateDashboardScreenLogic.shouldNotifyNewInterviewMessages(
          previousState: previous,
          currentState: current,
          candidateUid: 'candidate-1',
          interviewsEnabled: false,
        ),
        isFalse,
      );
    });
  });
}
