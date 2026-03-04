import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/core/widgets/inline_state_message.dart';
import 'package:opti_job_app/modules/talent_pool/models/candidate_note.dart';

class CandidateNotesPanel extends StatelessWidget {
  const CandidateNotesPanel({
    super.key,
    required this.notes,
    this.onDeleteNote,
  });

  final List<CandidateNote> notes;
  final ValueChanged<String>? onDeleteNote;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const InlineStateMessage(
        icon: Icons.notes_outlined,
        message: 'No notes yet.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: notes.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final note = notes[index];
        return _NoteItem(
          note: note,
          onDelete: () => onDeleteNote?.call(note.id),
        );
      },
    );
  }
}

class _NoteItem extends StatelessWidget {
  const _NoteItem({required this.note, this.onDelete});

  final CandidateNote note;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: uiSpacing8),
      padding: const EdgeInsets.all(uiSpacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                child: Text(
                  note.recruiterName[0].toUpperCase(),
                  style: textTheme.labelSmall,
                ),
              ),
              const SizedBox(width: uiSpacing8),
              Text(
                note.recruiterName,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (note.isPrivate)
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              const SizedBox(width: uiSpacing8),
              Text(
                note.createdAt != null
                    ? DateFormat('MMM d, HH:mm').format(note.createdAt!)
                    : 'Just now',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: uiSpacing4),
          _TypeBadge(type: note.type),
          const SizedBox(height: uiSpacing4),
          Text(note.content),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final NoteType type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color color;
    switch (type) {
      case NoteType.interview:
        color = scheme.primary;
        break;
      case NoteType.evaluation:
        color = scheme.tertiary;
        break;
      default:
        color = scheme.outline;
    }

    return InfoPill(
      label: type.name.toUpperCase(),
      backgroundColor: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.5),
      textColor: color,
    );
  }
}
