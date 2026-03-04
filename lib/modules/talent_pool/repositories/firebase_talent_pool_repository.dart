import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:opti_job_app/modules/talent_pool/models/candidate_note.dart';
import 'package:opti_job_app/modules/talent_pool/models/pool_member.dart';
import 'package:opti_job_app/modules/talent_pool/models/talent_pool.dart';
import 'package:opti_job_app/modules/talent_pool/repositories/talent_pool_repository.dart';

class FirebaseTalentPoolRepository implements TalentPoolRepository {
  FirebaseTalentPoolRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
    return pool.toJson().containsKey('id') ? pool : TalentPool.fromJson((await docRef.get()).data()!, id: docRef.id);
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
        .map((snapshot) => snapshot.docs
            .map((doc) => PoolMember.fromJson(doc.data()))
            .toList());
  }

  @override
  Future<void> addMemberToPool(String poolId, PoolMember member) async {
    // This will be mostly handled by a Cloud Function to check consent,
    // but the repository can also do it directly if permitted.
    await _firestore
        .collection('talentPools')
        .doc(poolId)
        .collection('members')
        .doc(member.candidateUid)
        .set({
      ...member.toJson(),
      'addedAt': FieldValue.serverTimestamp(),
    });

    // Update member count
    await _firestore.collection('talentPools').doc(poolId).update({
      'memberCount': FieldValue.increment(1),
    });
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
  Future<void> updateMemberTags(String poolId, String candidateUid, List<String> tags) async {
    await _firestore
        .collection('talentPools')
        .doc(poolId)
        .collection('members')
        .doc(candidateUid)
        .update({'tags': tags});
  }

  @override
  Stream<List<CandidateNote>> getCandidateNotes(String candidateUid, String companyId) {
    return _firestore
        .collection('candidateNotes')
        .where('candidateUid', isEqualTo: candidateUid)
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CandidateNote.fromJson(doc.data(), id: doc.id))
            .toList());
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
}
