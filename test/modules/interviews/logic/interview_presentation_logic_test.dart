import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';
import 'package:opti_job_app/modules/interviews/logic/interview_chat_logic.dart';
import 'package:opti_job_app/modules/interviews/logic/interview_list_tile_logic.dart';
import 'package:opti_job_app/modules/interviews/logic/interview_message_bubble_logic.dart';
import 'package:opti_job_app/modules/interviews/models/interview.dart';
import 'package:opti_job_app/modules/interviews/models/interview_message.dart';

void main() {
  Interview buildInterview({
    InterviewStatus status = InterviewStatus.scheduling,
    InterviewLastMessage? lastMessage,
    DateTime? scheduledAt,
    DateTime? updatedAt,
    String candidateUid = 'candidate-123456',
    String companyUid = 'company-abcdef',
  }) {
    final now = DateTime.utc(2026, 2, 10, 12);
    return Interview(
      id: 'interview-1',
      applicationId: 'application-1',
      jobOfferId: 'offer-1',
      companyUid: companyUid,
      candidateUid: candidateUid,
      participants: const ['candidate-123456', 'company-abcdef'],
      status: status,
      createdAt: now,
      updatedAt: updatedAt ?? now,
      scheduledAt: scheduledAt,
      lastMessage: lastMessage,
    );
  }

  InterviewMessage buildMessage({
    required String id,
    required String senderUid,
    required MessageType type,
    DateTime? createdAt,
    MessageMetadata? metadata,
  }) {
    return InterviewMessage(
      id: id,
      senderUid: senderUid,
      content: 'Mensaje $id',
      type: type,
      createdAt: createdAt ?? DateTime.utc(2026, 2, 10, 12),
      metadata: metadata,
    );
  }

  group('InterviewChatLogic', () {
    test('resolveCurrentUid prioritizes candidate uid', () {
      final uid = InterviewChatLogic.resolveCurrentUid(
        candidateUid: '  candidate-1  ',
        companyUid: 'company-1',
      );
      expect(uid, 'candidate-1');
    });

    test('resolveCurrentUid falls back to company uid', () {
      final uid = InterviewChatLogic.resolveCurrentUid(
        candidateUid: ' ',
        companyUid: ' company-1 ',
      );
      expect(uid, 'company-1');
    });

    test('resolveLoadedState uses previous state from action error', () {
      final loaded = InterviewSessionLoaded(
        interview: buildInterview(),
        messages: const [],
      );
      final state = InterviewSessionActionError(loaded, 'error');

      expect(InterviewChatLogic.resolveLoadedState(state), loaded);
      expect(InterviewChatLogic.actionErrorMessage(state), 'error');
      expect(
        InterviewChatLogic.actionErrorMessage(const InterviewSessionError('x')),
        isNull,
      );
    });
  });

  group('InterviewMessageBubbleLogic', () {
    test('proposal from another user shows actions', () {
      final message = buildMessage(
        id: 'proposal-1',
        senderUid: 'company-1',
        type: MessageType.proposal,
        metadata: MessageMetadata(proposedAt: DateTime.utc(2026, 2, 11, 10)),
      );

      final viewModel = InterviewMessageBubbleLogic.buildViewModel(
        message: message,
        currentUid: 'candidate-1',
      );

      expect(viewModel.isProposal, isTrue);
      expect(viewModel.showProposalActions, isTrue);
      expect(viewModel.proposalDateText, isNotNull);
      expect(viewModel.createdAtText, isNotEmpty);
    });

    test('proposal from current user hides actions', () {
      final message = buildMessage(
        id: 'proposal-2',
        senderUid: 'candidate-1',
        type: MessageType.proposal,
      );

      final viewModel = InterviewMessageBubbleLogic.buildViewModel(
        message: message,
        currentUid: 'candidate-1',
      );

      expect(viewModel.showProposalActions, isFalse);
    });
  });

  group('InterviewListTileLogic', () {
    test('buildViewModel formats title and fallback preview', () {
      final interview = buildInterview(
        status: InterviewStatus.scheduled,
        scheduledAt: DateTime.utc(2026, 2, 14, 9, 30),
      );

      final viewModel = InterviewListTileLogic.buildViewModel(
        interview: interview,
        isCompany: true,
      );

      expect(viewModel.title, 'Candidato (ID: candi...)');
      expect(viewModel.messagePreview, 'Nueva entrevista');
      expect(viewModel.timeText, isNotEmpty);
      expect(viewModel.scheduledLabel, isNotNull);
      expect(viewModel.status.label, 'Agendada');
      expect(viewModel.isThreeLine, isTrue);
    });

    test('buildViewModel resolves company title for candidate view', () {
      final interview = buildInterview(
        companyUid: 'company-99999',
        lastMessage: InterviewLastMessage(
          content: 'Hola',
          senderUid: 'company-99999',
          createdAt: DateTime.utc(2026, 2, 12, 15),
        ),
      );

      final viewModel = InterviewListTileLogic.buildViewModel(
        interview: interview,
        isCompany: false,
      );

      expect(viewModel.title, 'Empresa (ID: compa...)');
      expect(viewModel.messagePreview, 'Hola');
      expect(viewModel.scheduledLabel, isNull);
    });
  });
}
