import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/evaluations/models/approval.dart';

class ApprovalFlowLogic {
  const ApprovalFlowLogic._();

  static String approvalTypeLabel(ApprovalType type) {
    return switch (type) {
      ApprovalType.offerApproval => 'Offer Approval',
      ApprovalType.salaryApproval => 'Salary Approval',
    };
  }

  static IconData approvalTypeIcon(ApprovalType type) {
    return switch (type) {
      ApprovalType.offerApproval => Icons.assignment_turned_in,
      ApprovalType.salaryApproval => Icons.monetization_on,
    };
  }

  static IconData statusIcon(ApprovalStatus status) {
    return switch (status) {
      ApprovalStatus.approved => Icons.check,
      ApprovalStatus.rejected => Icons.close,
      ApprovalStatus.pending => Icons.access_time,
    };
  }

  static bool canCurrentUserDecide({
    required Approver approver,
    required String? currentUid,
    required bool hasDecisionHandlers,
  }) {
    final normalizedCurrentUid = currentUid?.trim() ?? '';
    if (!hasDecisionHandlers || normalizedCurrentUid.isEmpty) return false;
    return approver.uid == normalizedCurrentUid &&
        approver.status == ApprovalStatus.pending;
  }

  static String approverDisplayName({
    required Approver approver,
    required String? currentUid,
  }) {
    final normalizedCurrentUid = currentUid?.trim() ?? '';
    if (normalizedCurrentUid.isNotEmpty &&
        approver.uid == normalizedCurrentUid) {
      return '${approver.name} (You)';
    }
    return approver.name;
  }

  static String? approverNotes(Approver approver) {
    final normalizedNotes = approver.notes?.trim() ?? '';
    return normalizedNotes.isEmpty ? null : normalizedNotes;
  }

  static String formatDecisionDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
