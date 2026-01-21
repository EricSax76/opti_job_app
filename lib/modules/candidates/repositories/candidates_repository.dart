import 'dart:typed_data';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';

abstract class CandidatesRepository {
  Future<Candidate> fetchCandidateProfile(String uid);
  Future<Candidate> updateCandidateProfile({
    required String uid,
    required String name,
    required String lastName,
    Uint8List? avatarBytes,
  });
}
