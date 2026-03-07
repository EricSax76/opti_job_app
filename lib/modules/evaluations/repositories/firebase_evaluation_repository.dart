import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:opti_job_app/modules/evaluations/models/approval.dart';
import 'package:opti_job_app/modules/evaluations/models/evaluation.dart';
import 'package:opti_job_app/modules/evaluations/models/scorecard_template.dart';
import 'package:opti_job_app/modules/evaluations/repositories/evaluation_repository.dart';

class FirebaseEvaluationRepository implements EvaluationRepository {
  FirebaseEvaluationRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseFunctions? fallbackFunctions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
       _fallbackFunctions = fallbackFunctions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseFunctions _fallbackFunctions;

  @override
  Future<List<ScorecardTemplate>> getScorecardTemplates(
    String companyId,
  ) async {
    final snapshot = await _firestore
        .collection('scorecardTemplates')
        .where('companyId', isEqualTo: companyId)
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              ScorecardTemplate.fromFirestore({...doc.data(), 'id': doc.id}),
        )
        .toList();
  }

  @override
  Future<void> submitEvaluation(Evaluation evaluation) async {
    await _callCallableWithFallback(
      functionName: 'submitEvaluation',
      payload: {
        'applicationId': evaluation.applicationId,
        'jobOfferId': evaluation.jobOfferId,
        'companyId': evaluation.companyId,
        'criteria': evaluation.criteria.map((c) => c.toFirestore()).toList(),
        'overallScore': evaluation.overallScore,
        'recommendation': evaluation.recommendation.toSnakeCase(),
        'comments': evaluation.comments,
        'aiAssisted': evaluation.aiAssisted,
        'aiOverridden': evaluation.aiOverridden,
        'aiOriginalScore': evaluation.aiOriginalScore,
        'aiExplanation': evaluation.aiExplanation,
      },
    );
  }

  @override
  Future<List<Evaluation>> getEvaluationsForApplication(
    String applicationId,
  ) async {
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
    await _callCallableWithFallback(
      functionName: 'requestApproval',
      payload: {
        'applicationId': approval.applicationId,
        'jobOfferId': approval.jobOfferId,
        'companyId': approval.companyId,
        'type': approval.type.toSnakeCase(),
        'approverUids': approval.approvers
            .map((a) => {'uid': a.uid, 'name': a.name})
            .toList(),
      },
    );
  }

  @override
  Future<List<Approval>> getApprovalsForApplication(
    String applicationId,
  ) async {
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

  Future<void> _callCallableWithFallback({
    required String functionName,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _functions.httpsCallable(functionName).call(payload);
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'not-found' && error.code != 'unimplemented') {
        rethrow;
      }
      await _fallbackFunctions.httpsCallable(functionName).call(payload);
    }
  }
}
