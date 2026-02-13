import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:opti_job_app/modules/interviews/models/interview.dart';
import 'package:opti_job_app/modules/interviews/models/interview_message.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';

class FirebaseInterviewRepository implements InterviewRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebaseInterviewRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

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
    final callable = _functions.httpsCallable('startInterview');
    final result = await callable.call({'applicationId': applicationId});
    return result.data['interviewId'] as String;
  }

  @override
  Future<void> sendMessage({
    required String interviewId,
    required String content,
    MessageType type = MessageType.text,
    MessageMetadata? metadata,
  }) async {
    final callable = _functions.httpsCallable('sendInterviewMessage');
    await callable.call({
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
    final callable = _functions.httpsCallable('proposeInterviewSlot');
    await callable.call({
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
    final callable = _functions.httpsCallable('respondInterviewSlot');
    await callable.call({
      'interviewId': interviewId,
      'proposalId': proposalId,
      'response': accept ? 'accept' : 'reject',
    });
  }

  @override
  Future<void> markAsSeen(String interviewId) async {
    final callable = _functions.httpsCallable('markInterviewSeen');
    await callable.call({'interviewId': interviewId});
  }

  @override
  Future<void> cancelInterview(String interviewId, {String? reason}) async {
    final callable = _functions.httpsCallable('cancelInterview');
    await callable.call({
      'interviewId': interviewId,
      'reason': reason,
    });
  }

  @override
  Future<void> completeInterview(String interviewId, {String? notes}) async {
    final callable = _functions.httpsCallable('completeInterview');
    await callable.call({
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
}
