import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/modules/talent_pool/models/pool_member.dart';

class PoolMemberCard extends StatelessWidget {
  const PoolMemberCard({
    super.key,
    required this.member,
    this.onTap,
    this.onRemove,
  });

  final PoolMember member;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: uiSpacing8),
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        title: Text(
          member.candidateUid,
        ), // In a real app, this would be the candidate's name
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Added on: ${DateFormat('MMM d, yyyy').format(member.addedAt)}',
            ),
            if (member.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: uiSpacing4),
                child: Wrap(
                  spacing: uiSpacing4,
                  children: member.tags
                      .map(
                        (tag) => InfoPill(
                          label: tag,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLowest,
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!member.consentGiven)
              Tooltip(
                message: 'Consent Pending',
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            if (member.consentGiven)
              Tooltip(
                message: 'Consent Given',
                child: Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
