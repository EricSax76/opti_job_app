import 'package:opti_job_app/data/models/candidate.dart';
import 'package:opti_job_app/data/models/company.dart';
import 'package:opti_job_app/data/services/auth_service.dart';

class AuthRepository {
  AuthRepository(this._service);

  final AuthService _service;

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
}
