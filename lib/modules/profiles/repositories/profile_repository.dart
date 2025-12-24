import 'dart:typed_data';

import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/profiles/models/profile_service.dart';

class ProfileRepository {
  ProfileRepository(this._service);

  final ProfileService _service;

  Future<Candidate> fetchCandidateProfile(String uid) {
    return _service.fetchCandidateProfile(uid);
  }

  Future<Company> fetchCompanyProfile(int id) {
    return _service.fetchCompanyProfile(id);
  }

  Future<Candidate> updateCandidateProfile({
    required String uid,
    required String name,
    required String lastName,
    Uint8List? avatarBytes,
  }) {
    return _service.updateCandidateProfile(
      uid: uid,
      name: name,
      lastName: lastName,
      avatarBytes: avatarBytes,
    );
  }
}
