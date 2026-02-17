import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';
import 'package:opti_job_app/modules/interviews/logic/interview_chat_session_logic.dart';
import 'package:opti_job_app/modules/interviews/models/interview.dart';
import 'package:opti_job_app/modules/interviews/ui/models/interview_chat_session_view_model.dart';

void main() {
  InterviewSessionLoaded buildLoadedState() {
    final now = DateTime.utc(2026, 2, 17, 12);
    return InterviewSessionLoaded(
      interview: Interview(
        id: 'int-1',
        applicationId: 'app-1',
        jobOfferId: 'offer-1',
        companyUid: 'company-1',
        candidateUid: 'candidate-1',
        participants: const ['company-1', 'candidate-1'],
        status: InterviewStatus.scheduling,
        createdAt: now,
        updatedAt: now,
      ),
      messages: const [],
    );
  }

  group('InterviewChatSessionLogic', () {
    test('maps initial/loading to loading view state', () {
      final fromInitial = InterviewChatSessionLogic.buildViewModel(
        InterviewSessionInitial(),
      );
      final fromLoading = InterviewChatSessionLogic.buildViewModel(
        InterviewSessionLoading(),
      );

      expect(fromInitial.status, InterviewChatSessionViewStatus.loading);
      expect(fromLoading.status, InterviewChatSessionViewStatus.loading);
      expect(fromInitial.loadedState, isNull);
      expect(fromLoading.loadedState, isNull);
    });

    test('maps error to error view state', () {
      final viewModel = InterviewChatSessionLogic.buildViewModel(
        const InterviewSessionError('error-message'),
      );

      expect(viewModel.status, InterviewChatSessionViewStatus.error);
      expect(viewModel.errorMessage, 'error-message');
    });

    test('maps loaded/action-error(with previous) to ready state', () {
      final loadedState = buildLoadedState();
      final fromLoaded = InterviewChatSessionLogic.buildViewModel(loadedState);
      final fromActionError = InterviewChatSessionLogic.buildViewModel(
        InterviewSessionActionError(loadedState, 'x'),
      );

      expect(fromLoaded.status, InterviewChatSessionViewStatus.ready);
      expect(fromLoaded.loadedState, loadedState);
      expect(fromActionError.status, InterviewChatSessionViewStatus.ready);
      expect(fromActionError.loadedState, loadedState);
    });

    test('maps action-error without previous to loading state', () {
      final viewModel = InterviewChatSessionLogic.buildViewModel(
        const InterviewSessionActionError(null, 'x'),
      );

      expect(viewModel.status, InterviewChatSessionViewStatus.loading);
      expect(viewModel.loadedState, isNull);
    });
  });
}
