import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/candidates/data/mappers/candidate_mapper.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/auth/models/auth_exceptions.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<String?> get uidStream => _auth.authStateChanges().map((user) => user?.uid);

  CollectionReference<Map<String, dynamic>> get _candidatesCollection =>
      _firestore.collection('candidates');
  CollectionReference<Map<String, dynamic>> get _companiesCollection =>
      _firestore.collection('companies');

  Future<Candidate> loginCandidate({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No se encontró el usuario solicitado.',
      );
    }
    final doc = await _candidatesCollection.doc(user.uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw StateError('No existe un perfil de candidato asociado.');
    }
    final data = doc.data()!;
    final token = await user.getIdToken();
    return CandidateMapper.fromFirestore({...data, 'token': token});
  }

  Future<Candidate> registerCandidate({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-creation-failed',
        message: 'No se pudo crear el usuario.',
      );
    }

    final candidateId = DateTime.now().millisecondsSinceEpoch;
    final candidateData = <String, dynamic>{
      'id': candidateId,
      'name': name,
      'last_name': '',
      'email': email.toLowerCase().trim(),
      'role': 'candidate',
      'uid': user.uid,
    };

    await _candidatesCollection.doc(user.uid).set({
      ...candidateData,
      'created_at': FieldValue.serverTimestamp(),
    });

    final token = await user.getIdToken();
    return CandidateMapper.fromFirestore({...candidateData, 'token': token});
  }

  Future<Company> loginCompany({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No se encontró el usuario solicitado.',
      );
    }
    final doc = await _companiesCollection.doc(user.uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw StateError('No existe un perfil de empresa asociado.');
    }
    final data = doc.data()!;
    final token = await user.getIdToken();
    return Company.fromJson({...data, 'token': token});
  }

  Future<Company> registerCompany({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-creation-failed',
        message: 'No se pudo crear el usuario.',
      );
    }

    final companyId = DateTime.now().millisecondsSinceEpoch;
    final companyData = <String, dynamic>{
      'id': companyId,
      'name': name,
      'email': email.toLowerCase().trim(),
      'role': 'company',
      'uid': user.uid,
    };

    await _companiesCollection.doc(user.uid).set({
      ...companyData,
      'created_at': FieldValue.serverTimestamp(),
    });

    final token = await user.getIdToken();
    return Company.fromJson({...companyData, 'token': token});
  }

  Future<void> logout() {
    return _auth.signOut();
  }

  Future<Candidate?> restoreCandidateSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _candidatesCollection.doc(user.uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    final token = await user.getIdToken();
    return CandidateMapper.fromFirestore({...data, 'token': token});
  }

  Future<Company?> restoreCompanySession() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _companiesCollection.doc(user.uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    final token = await user.getIdToken();
    return Company.fromJson({...data, 'token': token});
  }

  AuthException mapFirebaseException(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return InvalidEmailException();
        case 'user-not-found':
          return UserNotFoundException();
        case 'wrong-password':
          return WrongPasswordException();
        case 'too-many-requests':
          return TooManyRequestsException();
        case 'network-request-failed':
          return NetworkException();
        default:
          return AuthException(e.message ?? 'Error de autenticación');
      }
    }
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        return PermissionDeniedException();
      }
    }
    return AuthException(e.toString());
  }
}
