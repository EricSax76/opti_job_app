import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter.dart';
import 'package:opti_job_app/auth/models/auth_service.dart';
import 'package:opti_job_app/auth/models/auth_exceptions.dart';
import 'package:opti_job_app/auth/models/eudi_wallet_models.dart';

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

  Future<Candidate> signInCandidateWithEudiWallet({
    required EudiWalletSignInInput input,
  }) {
    return _service.signInCandidateWithEudiWallet(input: input);
  }

  Future<EudiWalletSignInInput> buildEudiWalletSignInInputFromNative({
    String? initialName,
    String? initialEmail,
    String audience = 'opti-job-app:eudi-signin',
    String proofSchemaVersion = '2026.1',
  }) {
    return _service.buildEudiWalletSignInInputFromNative(
      initialName: initialName,
      initialEmail: initialEmail,
      audience: audience,
      proofSchemaVersion: proofSchemaVersion,
    );
  }

  Future<void> importEudiCredentialFromNativeWallet({
    String audience = 'opti-job-app:eudi-import',
    String proofSchemaVersion = '2026.1',
  }) {
    return _service.importEudiCredentialFromNativeWallet(
      audience: audience,
      proofSchemaVersion: proofSchemaVersion,
    );
  }

  Future<SelectiveDisclosureProofResult> createSelectiveDisclosureProof({
    required SelectiveDisclosureProofInput input,
  }) {
    return _service.createSelectiveDisclosureProof(input: input);
  }

  Future<SelectiveDisclosureVerificationResult> verifySelectiveDisclosureProof({
    required String proofId,
    required String proofToken,
  }) {
    return _service.verifySelectiveDisclosureProof(
      proofId: proofId,
      proofToken: proofToken,
    );
  }

  Future<void> revokeSelectiveDisclosureProof({required String proofId}) {
    return _service.revokeSelectiveDisclosureProof(proofId: proofId);
  }

  Future<List<VerifiedCredential>> fetchCandidateVerifiedCredentials(
    String candidateUid,
  ) {
    return _service.fetchCandidateVerifiedCredentials(candidateUid);
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

  Future<void> completeCandidateOnboarding(String uid) {
    return _service.completeCandidateOnboarding(uid);
  }

  Future<void> completeCompanyOnboarding(String uid) {
    return _service.completeCompanyOnboarding(uid);
  }

  Future<Candidate?> restoreCandidateSession() {
    return _service.restoreCandidateSession();
  }

  Future<Company?> restoreCompanySession() {
    return _service.restoreCompanySession();
  }

  Future<Recruiter> loginRecruiter({
    required String email,
    required String password,
  }) {
    return _service.loginRecruiter(email: email, password: password);
  }

  Future<Recruiter?> restoreRecruiterSession() {
    return _service.restoreRecruiterSession();
  }

  AuthException mapException(Object e) => _service.mapFirebaseException(e);
}
