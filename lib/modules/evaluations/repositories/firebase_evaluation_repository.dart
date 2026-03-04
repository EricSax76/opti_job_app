import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:opti_job_app/modules/evaluations/models/approval.dart';
import 'package:opti_job_app/modules/evaluations/models/evaluation.dart';
import 'package:opti_job_app/modules/evaluations/models/scorecard_template.dart';
import 'package:opti_job_app/modules/evaluations/repositories/evaluation_repository.dart';

class FirebaseEvaluationRepository implements EvaluationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<ScorecardTemplate>> getScorecardTemplates(String companyId) async {
    final snapshot = await _firestore
        .collection('scorecardTemplates')
        .where('companyId', isEqualTo: companyId)
        .get();
    return snapshot.docs
        .map((doc) => ScorecardTemplate.fromFirestore({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<void> submitEvaluation(Evaluation evaluation) async {
    await _firestore.collection('evaluations').doc(evaluation.id.isEmpty ? null : evaluation.id).set(
          evaluation.toFirestore(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<List<Evaluation>> getEvaluationsForApplication(String applicationId) async {
    final snapshot = await _firestore
        .collection('evaluations')
        .where('applicationId', isEqualTo: applicationId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Evaluation.fromFirestore({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<void> requestApproval(Approval approval) async {
    await _firestore.collection('approvals').doc(approval.id.isEmpty ? null : approval.id).set(
          approval.toFirestore(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<List<Approval>> getApprovalsForApplication(String applicationId) async {
    final snapshot = await _firestore
        .collection('approvals')
        .where('applicationId', isEqualTo: applicationId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Approval.fromFirestore({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<void> updateApprovalStatus(
    String approvalId,
    String approverUid,
    ApprovalStatus status, {
    String? notes,
  }) async {
    final docRef = _firestore.collection('approvals').doc(approvalId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final approval = Approval.fromFirestore({...doc.data()!, 'id': doc.id});
    final updatedApprovers = approval.approvers.map((a) {
      if (a.uid == approverUid) {
        return Approver(
          uid: a.uid,
          name: a.name,
          status: status,
          decidedAt: DateTime.now(),
          notes: notes,
        );
      }
      return a;
    }).toList();

    await docRef.update({
      'approvers': updatedApprovers.map((a) => a.toFirestore()).toList(),
    });
  }
}
