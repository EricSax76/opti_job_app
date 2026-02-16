import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/interviews/models/interview.dart';
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

    final lastMessage = interview.lastMessage?.content ?? 'Nueva entrevista';
    final date = interview.lastMessage?.createdAt ?? interview.updatedAt;
    final timeText = _safeFormatDateTime(date, 'jm');

    final scheduledLabel =
        interview.status == InterviewStatus.scheduled &&
            interview.scheduledAt != null
        ? _safeFormatDateTime(interview.scheduledAt!, 'MMM d, h:mm a')
        : null;

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
            pathParameters: {'id': interview.id},
          );
        },
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.person, color: colorScheme.onPrimaryContainer),
        ),
        title: InterviewListTileTitle(
          interview: interview,
          isCompany: isCompany,
        ),
        subtitle: _InterviewListSubtitle(
          messagePreview: lastMessage,
          timeText: timeText,
          textColor: colorScheme.onSurfaceVariant,
          timeColor: colorScheme.outline,
        ),
        subtitleTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        isThreeLine: scheduledLabel != null,
        trailing: _InterviewListTrailing(
          status: interview.status,
          scheduledLabel: scheduledLabel,
          scheduledColor: colorScheme.primary,
        ),
      ),
    );
  }

  String _safeFormatDateTime(DateTime date, String pattern) {
    try {
      return DateFormat(pattern).format(date);
    } catch (_) {
      return date.toLocal().toIso8601String();
    }
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

  final InterviewStatus status;
  final String? scheduledLabel;
  final Color scheduledColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        InterviewStatusBadge(status: status),
        if (scheduledLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            scheduledLabel!,
            style: TextStyle(
              fontSize: 11,
              color: scheduledColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
