import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/interviews/logic/interview_list_tile_logic.dart';
import 'package:opti_job_app/modules/interviews/models/interview.dart';
import 'package:opti_job_app/modules/interviews/ui/models/interview_status_view_model.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/list/interview_list_tile_title.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/list/interview_status_badge.dart';

class InterviewListTile extends StatelessWidget {
  const InterviewListTile({
    super.key,
    required this.interview,
    required this.isCompany,
  });

  final Interview interview;
  final bool isCompany;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewModel = InterviewListTileLogic.buildViewModel(
      interview: interview,
      isCompany: isCompany,
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
        ),
      ),
    );
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
  });

  final InterviewStatusViewModel status;
  final String? scheduledLabel;
  final Color scheduledColor;

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
      ],
    );
  }
}
