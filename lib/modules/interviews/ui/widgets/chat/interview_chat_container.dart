import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';
import 'package:opti_job_app/modules/interviews/logic/interview_action_permissions_logic.dart';
import 'package:opti_job_app/modules/interviews/logic/interview_chat_logic.dart';
import 'package:opti_job_app/modules/interviews/models/interview.dart';
import 'package:opti_job_app/modules/interviews/ui/controllers/interview_chat_actions_controller.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/chat/interview_chat_session_body.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/chat/interview_chat_view.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/chat/interview_message_input_area.dart';

enum _InterviewChatMenuAction { complete, cancel }

class InterviewChatContainer extends StatefulWidget {
  const InterviewChatContainer({super.key});

  @override
  State<InterviewChatContainer> createState() => _InterviewChatContainerState();
}

class _InterviewChatContainerState extends State<InterviewChatContainer> {
  late final InterviewChatActionsController _actions;

  @override
  void initState() {
    super.initState();
    _actions = InterviewChatActionsController(
      sessionCubit: context.read<InterviewSessionCubit>(),
    );
  }

  @override
  void dispose() {
    _actions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final candidateUid = context.select<CandidateAuthCubit, String?>(
      (cubit) => cubit.state.candidate?.uid,
    );
    final companyUid = context.select<CompanyAuthCubit, String?>(
      (cubit) => cubit.state.company?.uid,
    );
    final currentUid = InterviewChatLogic.resolveCurrentUid(
      candidateUid: candidateUid,
      companyUid: companyUid,
    );

    return BlocConsumer<InterviewSessionCubit, InterviewSessionState>(
      listenWhen: (_, current) => current is InterviewSessionActionError,
      listener: (context, state) {
        final message = InterviewChatLogic.actionErrorMessage(state);
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(message), duration: uiDurationNormal),
          );
      },
      builder: (context, state) {
        final loadedState = InterviewChatLogic.resolveLoadedState(state);
        final interview = loadedState?.interview;
        return InterviewChatView(
          appBarActions: _buildAppBarActions(
            context: context,
            currentUid: currentUid,
            interview: interview,
          ),
          body: InterviewChatSessionBody(
            currentUid: currentUid,
            onRespondToProposal: _actions.respondToProposal,
          ),
          inputArea: InterviewMessageInputArea(
            controller: _actions.messageController,
            onSend: _actions.sendMessage,
            onProposeSlot: () => _actions.proposeSlot(context),
            onStartMeeting: () => _actions.startMeeting(context),
          ),
        );
      },
    );
  }

  List<Widget> _buildAppBarActions({
    required BuildContext context,
    required String? currentUid,
    required Interview? interview,
  }) {
    if (interview == null) return const [];

    final canComplete = InterviewActionPermissionsLogic.canComplete(
      interview: interview,
      currentUid: currentUid,
    );
    final canCancel = InterviewActionPermissionsLogic.canCancel(
      interview: interview,
      currentUid: currentUid,
    );
    if (!canComplete && !canCancel) return const [];

    return [
      PopupMenuButton<_InterviewChatMenuAction>(
        tooltip: 'Acciones entrevista',
        onSelected: (action) => _handleMenuAction(context, action),
        itemBuilder: (_) {
          final items = <PopupMenuEntry<_InterviewChatMenuAction>>[];
          if (canComplete) {
            items.add(
              const PopupMenuItem(
                value: _InterviewChatMenuAction.complete,
                child: ListTile(
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('Completar entrevista'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            );
          }
          if (canCancel) {
            items.add(
              const PopupMenuItem(
                value: _InterviewChatMenuAction.cancel,
                child: ListTile(
                  leading: Icon(Icons.cancel_outlined),
                  title: Text('Cancelar entrevista'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            );
          }
          return items;
        },
      ),
    ];
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    _InterviewChatMenuAction action,
  ) async {
    switch (action) {
      case _InterviewChatMenuAction.complete:
        await _actions.completeInterview(context);
        break;
      case _InterviewChatMenuAction.cancel:
        await _actions.cancelInterview(context);
        break;
    }
  }
}
