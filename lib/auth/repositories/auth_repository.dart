import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/auth/models/auth_service.dart';
import 'package:opti_job_app/auth/models/auth_exceptions.dart';

class AuthRepository {
  AuthRepository(this._service);

  final AuthService _service;

  Stream<String?> get uidStream => _service.uidStream;

  Future<Candidate> loginCandidate({
    required String email,
    required String password,
  }) {
    return _service.loginCandidate(email: email, password: password);
  }

  Future<Candidate> registerCandidate({
    required String name,
    required String email,
    required String password,
  }) {
    return _service.registerCandidate(
      name: name,
      email: email,
      password: password,
    );
  }

  Future<Company> loginCompany({
    required String email,
    required String password,
  }) {
    return _service.loginCompany(email: email, password: password);
  }

  Future<Company> registerCompany({
    required String name,
    required String email,
    required String password,
  }) {
    return _service.registerCompany(
      name: name,
      email: email,
      password: password,
    );
  }

  Future<void> logout() {
    return _service.logout();
  }

  Future<Candidate?> restoreCandidateSession() {
    return _service.restoreCandidateSession();
  }

  Future<Company?> restoreCompanySession() {
    return _service.restoreCompanySession();
  }

  AuthException mapException(Object e) => _service.mapFirebaseException(e);
}
