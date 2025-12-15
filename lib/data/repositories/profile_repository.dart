import 'package:opti_job_app/data/models/candidate.dart';
import 'package:opti_job_app/data/models/company.dart';
import 'package:opti_job_app/data/services/profile_service.dart';

class ProfileRepository {
  ProfileRepository(this._service);

  final ProfileService _service;

  Future<Candidate> fetchCandidateProfile(int id) {
    return _service.fetchCandidateProfile(id);
  }

  Future<Company> fetchCompanyProfile(int id) {
    return _service.fetchCompanyProfile(id);
  }
}
