import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/profiles/models/profile_service.dart';

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
