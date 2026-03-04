import 'package:opti_job_app/modules/talent_pool/models/candidate_note.dart';
import 'package:opti_job_app/modules/talent_pool/models/pool_member.dart';
import 'package:opti_job_app/modules/talent_pool/models/talent_pool.dart';

abstract class TalentPoolRepository {
  // Talent Pools
  Future<List<TalentPool>> getTalentPools(String companyId);
  Future<TalentPool> createTalentPool(TalentPool pool);
  Future<void> updateTalentPool(TalentPool pool);
  Future<void> deleteTalentPool(String poolId);

  // Pool Members
  Stream<List<PoolMember>> getPoolMembers(String poolId);
  Future<void> addMemberToPool(String poolId, PoolMember member);
  Future<void> removeMemberFromPool(String poolId, String candidateUid);
  Future<void> updateMemberTags(String poolId, String candidateUid, List<String> tags);

  // Candidate Notes
  Stream<List<CandidateNote>> getCandidateNotes(String candidateUid, String companyId);
  Future<CandidateNote> addNote(CandidateNote note);
  Future<void> updateNote(CandidateNote note);
  Future<void> deleteNote(String noteId);
}
