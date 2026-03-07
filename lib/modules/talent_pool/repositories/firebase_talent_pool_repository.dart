import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:opti_job_app/core/utils/callable_with_fallback.dart';
import 'package:opti_job_app/modules/talent_pool/models/candidate_note.dart';
import 'package:opti_job_app/modules/talent_pool/models/pool_member.dart';
import 'package:opti_job_app/modules/talent_pool/models/talent_pool.dart';
import 'package:opti_job_app/modules/talent_pool/repositories/talent_pool_repository.dart';

class FirebaseTalentPoolRepository implements TalentPoolRepository {
  FirebaseTalentPoolRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseFunctions? fallbackFunctions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _callables = CallableWithFallback(
         functions:
             functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
         fallbackFunctions: fallbackFunctions ?? FirebaseFunctions.instance,
       );

  final FirebaseFirestore _firestore;
  final CallableWithFallback _callables;

  @override
  Future<List<TalentPool>> getTalentPools(String companyId) async {
    final snapshot = await _firestore
        .collection('talentPools')
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TalentPool.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  @override
  Future<TalentPool> createTalentPool(TalentPool pool) async {
    final docRef = await _firestore.collection('talentPools').add({
      ...pool.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    final snapshot = await docRef.get();
    final data = snapshot.data() ?? <String, dynamic>{...pool.toJson()};
    return TalentPool.fromJson(data, id: docRef.id);
  }

  @override
  Future<void> updateTalentPool(TalentPool pool) async {
    await _firestore
        .collection('talentPools')
        .doc(pool.id)
        .update(pool.toJson());
  }

  @override
  Future<void> deleteTalentPool(String poolId) async {
    // Note: In real production, you might want to delete subcollections as well
    await _firestore.collection('talentPools').doc(poolId).delete();
  }

  @override
  Stream<List<PoolMember>> getPoolMembers(String poolId) {
    return _firestore
        .collection('talentPools')
        .doc(poolId)
        .collection('members')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PoolMember.fromJson(doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> addMemberToPool(String poolId, PoolMember member) async {
    final result = await _callCallableWithFallback(
      functionName: 'addToPool',
      payload: {
        'poolId': poolId,
        'candidateUid': member.candidateUid,
        'tags': member.tags,
        'source': member.source,
        'sourceApplicationId': member.sourceApplicationId,
      },
    );

    final consentRequired = result['consentRequired'] == true;
    if (!consentRequired) return;

    await _callCallableWithFallback(
      functionName: 'requestConsent',
      payload: {'candidateUid': member.candidateUid, 'poolId': poolId},
    );
  }

  @override
  Future<void> removeMemberFromPool(String poolId, String candidateUid) async {
    await _firestore
        .collection('talentPools')
        .doc(poolId)
        .collection('members')
        .doc(candidateUid)
        .delete();

    // Update member count
    await _firestore.collection('talentPools').doc(poolId).update({
      'memberCount': FieldValue.increment(-1),
    });
  }

  @override
  Future<void> updateMemberTags(
    String poolId,
    String candidateUid,
    List<String> tags,
  ) async {
    await _firestore
        .collection('talentPools')
        .doc(poolId)
        .collection('members')
        .doc(candidateUid)
        .update({'tags': tags});
  }

  @override
  Stream<List<CandidateNote>> getCandidateNotes(
    String candidateUid,
    String companyId,
  ) {
    return _firestore
        .collection('candidateNotes')
        .where('candidateUid', isEqualTo: candidateUid)
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CandidateNote.fromJson(doc.data(), id: doc.id))
              .toList(),
        );
  }

  @override
  Future<CandidateNote> addNote(CandidateNote note) async {
    final docRef = await _firestore.collection('candidateNotes').add({
      ...note.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return CandidateNote.fromJson(note.toJson(), id: docRef.id);
  }

  @override
  Future<void> updateNote(CandidateNote note) async {
    await _firestore
        .collection('candidateNotes')
        .doc(note.id)
        .update(note.toJson());
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await _firestore.collection('candidateNotes').doc(noteId).delete();
  }

  Future<Map<String, dynamic>> _callCallableWithFallback({
    required String functionName,
    required Map<String, dynamic> payload,
  }) async {
    return _callables.callMap(name: functionName, payload: payload);
  }
}
