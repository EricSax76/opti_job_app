import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/interviews/logic/interview_action_permissions_logic.dart';
import 'package:opti_job_app/modules/interviews/logic/interview_list_tile_logic.dart';
import 'package:opti_job_app/modules/interviews/models/interview.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';
import 'package:opti_job_app/modules/interviews/ui/controllers/interview_chat_dialogs_controller.dart';
import 'package:opti_job_app/modules/interviews/ui/models/interview_status_view_model.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/list/interview_list_tile_title.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/list/interview_status_badge.dart';

enum _InterviewListMenuAction { complete, cancel }

class InterviewListTile extends StatelessWidget {
  const InterviewListTile({
    super.key,
    required this.interview,
    required this.isCompany,
    required this.currentUid,
  });

  final Interview interview;
  final bool isCompany;
  final String currentUid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewModel = InterviewListTileLogic.buildViewModel(
      interview: interview,
      isCompany: isCompany,
    );
    final canComplete = InterviewActionPermissionsLogic.canComplete(
      interview: interview,
      currentUid: currentUid,
    );
    final canCancel = InterviewActionPermissionsLogic.canCancel(
      interview: interview,
      currentUid: currentUid,
    );

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(uiTileRadius),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          context.pushNamed(
            'interview-chat',
            pathParameters: {'id': viewModel.interviewId},
          );
        },
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.person, color: colorScheme.onPrimaryContainer),
        ),
        title: InterviewListTileTitle(title: viewModel.title),
        subtitle: _InterviewListSubtitle(
          messagePreview: viewModel.messagePreview,
          timeText: viewModel.timeText,
          textColor: colorScheme.onSurfaceVariant,
          timeColor: colorScheme.outline,
        ),
        subtitleTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        isThreeLine: viewModel.isThreeLine,
        trailing: _InterviewListTrailing(
          status: viewModel.status,
          scheduledLabel: viewModel.scheduledLabel,
          scheduledColor: colorScheme.primary,
          actionsMenu: _buildActionsMenu(
            context,
            canComplete: canComplete,
            canCancel: canCancel,
          ),
        ),
      ),
    );
  }

  Widget? _buildActionsMenu(
    BuildContext context, {
    required bool canComplete,
    required bool canCancel,
  }) {
    if (!canComplete && !canCancel) return null;
    return PopupMenuButton<_InterviewListMenuAction>(
      tooltip: 'Acciones entrevista',
      icon: const Icon(Icons.more_vert, size: 18),
      onSelected: (action) => _handleActionSelection(context, action),
      itemBuilder: (_) {
        final items = <PopupMenuEntry<_InterviewListMenuAction>>[];
        if (canComplete) {
          items.add(
            const PopupMenuItem(
              value: _InterviewListMenuAction.complete,
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
              value: _InterviewListMenuAction.cancel,
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
    );
  }

  Future<void> _handleActionSelection(
    BuildContext context,
    _InterviewListMenuAction action,
  ) async {
    final repository = context.read<InterviewRepository>();

    try {
      switch (action) {
        case _InterviewListMenuAction.complete:
          final notes =
              await InterviewChatDialogsController.askForCompletionNotes(
                context,
              );
          if (notes == null || !context.mounted) return;
          await repository.completeInterview(
            interview.id,
            notes: notes.trim().isEmpty ? null : notes.trim(),
          );
          if (!context.mounted) return;
          _showMessage(context, 'Entrevista completada.');
          break;
        case _InterviewListMenuAction.cancel:
          final reason =
              await InterviewChatDialogsController.askForCancellationReason(
                context,
              );
          if (reason == null || !context.mounted) return;
          await repository.cancelInterview(
            interview.id,
            reason: reason.trim().isEmpty ? null : reason.trim(),
          );
          if (!context.mounted) return;
          _showMessage(context, 'Entrevista cancelada.');
          break;
      }
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, _normalizeErrorMessage(error));
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: uiDurationNormal),
      );
  }

  String _normalizeErrorMessage(Object error) {
    if (error is FirebaseFunctionsException) {
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
    }
    final message = error.toString().trim();
    if (message.isEmpty) return 'No se pudo completar la acción.';
    return message;
  }
}

class _InterviewListSubtitle extends StatelessWidget {
  const _InterviewListSubtitle({
    required this.messagePreview,
    required this.timeText,
    required this.textColor,
    required this.timeColor,
  });

  final String messagePreview;
  final String timeText;
  final Color textColor;
  final Color timeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            messagePreview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(timeText, style: TextStyle(fontSize: 12, color: timeColor)),
      ],
    );
  }
}

class _InterviewListTrailing extends StatelessWidget {
  const _InterviewListTrailing({
    required this.status,
    required this.scheduledLabel,
    required this.scheduledColor,
    required this.actionsMenu,
  });

  final InterviewStatusViewModel status;
  final String? scheduledLabel;
  final Color scheduledColor;
  final Widget? actionsMenu;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        InterviewStatusBadge(viewModel: status),
        if (scheduledLabel != null) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              scheduledLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                color: scheduledColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        if (actionsMenu != null) ...[const SizedBox(height: 4), actionsMenu!],
      ],
    );
  }
}
