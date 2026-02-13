import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/interviews/models/interview.dart';
import 'package:intl/intl.dart';

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
    
    // Determine title (other participant name)
    // Note: In real app, we might need to fetch the profile of the other user
    // or store basic info in the interview doc (denormalization).
    // For now, let's use the UID or a placeholder until we have denormalized data.
    // Actually Application has candidateName/companyName. 
    // Ideally Interview should have this too. 
    // MVP: Show "Candidato" / "Empresa" or fetch? 
    // Let's assume we want to show updated info.
    // But for MVP speed, let's use "Entrevista [ID]" or generic if we don't have name.
    // Wait, Application doc has names. Interview doc as defined in models.ts doesn't have names.
    // We should probably rely on a join or future builder if we want names.
    // Or just show "Candidato" for now.
    
    final title = isCompany 
        ? 'Candidato (ID: ${interview.candidateUid.substring(0, 5)}...)' 
        : 'Empresa (ID: ${interview.companyUid.substring(0, 5)}...)';
        
    final lastMsg = interview.lastMessage?.content ?? 'Nueva entrevista';
    final date = interview.lastMessage?.createdAt ?? interview.updatedAt;
    final timeStr = DateFormat.jm().format(date);
    
    // Unread count
    // current user uid needed to check unreadCounts
    // passed implicitly or found via auth? 
    // We don't have auth in this widget easily without context.read or passing it.
    // Let's assume passed isCompany implies we know which side.
    // But we need exact UID for unreadCounts keys.
    // Let's just show dot if unreadCounts has ANY value for now? 
    // No, unreadCounts is Map<uid, int>.
    // effectively we need currentUserUid.
    
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
            // Navigate to chat
             context.pushNamed('interview-chat', pathParameters: {'id': interview.id});
        },
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.person, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                lastMsg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
        subtitleTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        isThreeLine: interview.status == InterviewStatus.scheduled && interview.scheduledAt != null,
        trailing: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           crossAxisAlignment: CrossAxisAlignment.end,
           children: [
              _buildStatusBadge(context, interview.status),
              if (interview.status == InterviewStatus.scheduled && interview.scheduledAt != null) ...[
                 const SizedBox(height: 4),
                 Text(
                    DateFormat('MMM d, h:mm a').format(interview.scheduledAt!),
                    style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.bold),
                 ),
              ],
           ],
        ),
      ),
    );
  }
  
  Widget _buildStatusBadge(BuildContext context, InterviewStatus status) {
      Color color;
      String label;
      
      switch (status) {
        case InterviewStatus.scheduling:
          color = Colors.orange;
          label = 'Agendando';
          break;
        case InterviewStatus.scheduled:
          color = Colors.blue;
          label = 'Agendada';
          break;
        case InterviewStatus.completed:
          color = Colors.green;
          label = 'Completada';
          break;
        case InterviewStatus.cancelled:
           color = Colors.red;
           label = 'Cancelada';
           break;
      }
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
  }
}
