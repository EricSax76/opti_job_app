import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:opti_job_app/modules/interviews/models/interview.dart';
import 'package:opti_job_app/modules/interviews/models/interview_message.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';

class FirebaseInterviewRepository implements InterviewRepository {
  static const String _primaryFunctionsRegion = 'europe-west1';

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebaseInterviewRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions =
            functions ??
            FirebaseFunctions.instanceFor(region: _primaryFunctionsRegion);

  CollectionReference<Map<String, dynamic>> get _interviewsRef =>
      _firestore.collection('interviews');

  @override
  Stream<List<Interview>> interviewsStream(String uid) {
    return _interviewsRef
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Interview.fromJson(doc.data()..['id'] = doc.id))
          .toList();
    });
  }

  @override
  Stream<Interview?> interviewStream(String interviewId) {
    return _interviewsRef.doc(interviewId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Interview.fromJson(doc.data()!..['id'] = doc.id);
    });
  }

  @override
  Stream<List<InterviewMessage>> messagesStream(String interviewId) {
    return _interviewsRef
        .doc(interviewId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InterviewMessage.fromJson(doc.data()..['id'] = doc.id))
          .toList();
    });
  }

  @override
  Future<String> startInterview(String applicationId) async {
    final payload = {'applicationId': applicationId};
    try {
      final result = await _callWithRegionFallback('startInterview', payload);
      return _extractInterviewId(result);
    } on FirebaseFunctionsException catch (error) {
      if (!_isRecoverableStartInterviewError(error)) rethrow;
      final repaired = await _backfillLegacyApplicationFields(applicationId);
      if (!repaired) rethrow;

      final retryResult = await _callWithRegionFallback(
        'startInterview',
        payload,
      );
      return _extractInterviewId(retryResult);
    }
  }

  @override
  Future<void> sendMessage({
    required String interviewId,
    required String content,
    MessageType type = MessageType.text,
    MessageMetadata? metadata,
  }) async {
    await _callWithRegionFallback('sendInterviewMessage', {
      'interviewId': interviewId,
      'content': content,
      'type': type.value,
      if (metadata != null) 'metadata': metadata.toJson(),
    });
  }

  @override
  Future<void> proposeSlot({
    required String interviewId,
    required DateTime proposedAt,
    required String timeZone,
  }) async {
    await _callWithRegionFallback('proposeInterviewSlot', {
      'interviewId': interviewId,
      'proposedAt': proposedAt.toIso8601String(),
      'timeZone': timeZone,
    });
  }

  @override
  Future<void> respondToSlot({
    required String interviewId,
    required String proposalId,
    required bool accept,
  }) async {
    await _callWithRegionFallback('respondInterviewSlot', {
      'interviewId': interviewId,
      'proposalId': proposalId,
      'response': accept ? 'accept' : 'reject',
    });
  }

  @override
  Future<void> markAsSeen(String interviewId) async {
    await _callWithRegionFallback('markInterviewSeen', {
      'interviewId': interviewId,
    });
  }

  @override
  Future<void> cancelInterview(String interviewId, {String? reason}) async {
    await _callWithRegionFallback('cancelInterview', {
      'interviewId': interviewId,
      'reason': reason,
    });
  }

  @override
  Future<void> completeInterview(String interviewId, {String? notes}) async {
    await _callWithRegionFallback('completeInterview', {
      'interviewId': interviewId,
      'notes': notes,
    });
  }
  @override
  Future<void> startMeeting({
    required String interviewId,
    required String meetingLink,
  }) async {
    final batch = _firestore.batch();
    
    // Update interview with meeting link
    final interviewRef = _interviewsRef.doc(interviewId);
    batch.update(interviewRef, {
      'meetingLink': meetingLink,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Add system message
    final messageRef = interviewRef.collection('messages').doc();
    final message = InterviewMessage(
      id: messageRef.id,
      senderUid: 'system',
      content: 'Inició una videollamada. Únete aquí: $meetingLink',
      type: MessageType.system,
      createdAt: DateTime.now(),
    );
    batch.set(messageRef, message.toJson());
    
    // Update last message
    batch.update(interviewRef, {
      'lastMessage': {
        'content': 'Videollamada iniciada',
        'senderUid': 'system',
        'createdAt': FieldValue.serverTimestamp(),
      },
    });

    await batch.commit();
  }

  Future<HttpsCallableResult<dynamic>> _callWithRegionFallback(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    try {
      return await _functions.httpsCallable(functionName).call(payload);
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'not-found') rethrow;
      return FirebaseFunctions.instance.httpsCallable(functionName).call(payload);
    }
  }

  String _extractInterviewId(HttpsCallableResult<dynamic> result) {
    final data = result.data;
    if (data is Map && data['interviewId'] is String) {
      final interviewId = (data['interviewId'] as String).trim();
      if (interviewId.isNotEmpty) return interviewId;
    }
    throw FirebaseFunctionsException(
      code: 'internal',
      message: 'Cloud Function response did not include interviewId.',
    );
  }

  bool _isRecoverableStartInterviewError(FirebaseFunctionsException error) {
    return error.code == 'invalid-argument' ||
        error.code == 'internal' ||
        error.code == 'unknown' ||
        error.code == 'failed-precondition';
  }

  Future<bool> _backfillLegacyApplicationFields(String applicationId) async {
    final appRef = _firestore.collection('applications').doc(applicationId);
    final appSnapshot = await appRef.get();
    final data = appSnapshot.data();
    if (!appSnapshot.exists || data == null) return false;

    final jobOfferId = _readNonEmptyString(
      data['job_offer_id'] ?? data['jobOfferId'],
    );
    final candidateUid = _readNonEmptyString(
      data['candidate_uid'] ?? data['candidateId'] ?? data['candidate_id'],
    );
    final companyUid = _readNonEmptyString(
      data['company_uid'] ?? data['companyUid'],
    );
    final candidateName = _readNonEmptyString(
      data['candidate_name'] ?? data['candidateName'],
    );
    final candidateEmail = _readNonEmptyString(
      data['candidate_email'] ?? data['candidateEmail'],
    );

    final updates = <String, dynamic>{};
    final existingJobOfferId = _readNonEmptyString(data['job_offer_id']);
    final existingCandidateUid = _readNonEmptyString(data['candidate_uid']);
    final existingCompanyUid = _readNonEmptyString(data['company_uid']);

    if (existingJobOfferId == null && jobOfferId != null) {
      updates['job_offer_id'] = jobOfferId;
    }
    if (existingCandidateUid == null && candidateUid != null) {
      updates['candidate_uid'] = candidateUid;
    }
    if (existingCompanyUid == null && companyUid != null) {
      updates['company_uid'] = companyUid;
    }
    if (data['candidate_name'] == null && candidateName != null) {
      updates['candidate_name'] = candidateName;
    }
    if (data['candidate_email'] == null && candidateEmail != null) {
      updates['candidate_email'] = candidateEmail;
    }

    if (updates.isEmpty) return false;
    updates['updated_at'] = FieldValue.serverTimestamp();

    await appRef.update(updates);
    return true;
  }

  String? _readNonEmptyString(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }
}
