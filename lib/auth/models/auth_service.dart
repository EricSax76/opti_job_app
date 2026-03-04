import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/candidates/data/mappers/candidate_mapper.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter.dart';
import 'package:opti_job_app/auth/models/auth_exceptions.dart';

class AuthService {
  AuthService({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  }) : _auth = firebaseAuth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<String?> get uidStream =>
      _auth.authStateChanges().map((user) => user?.uid);

  CollectionReference<Map<String, dynamic>> get _candidatesCollection =>
      _firestore.collection('candidates');
  CollectionReference<Map<String, dynamic>> get _companiesCollection =>
      _firestore.collection('companies');
  CollectionReference<Map<String, dynamic>> get _recruitersCollection =>
      _firestore.collection('recruiters');

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
      'onboarding_completed': false,
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
      'onboarding_completed': false,
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

  // ─── Recruiter auth ──────────────────────────────────────────────────────

  /// Inicia sesión como reclutador y devuelve el modelo [Recruiter].
  ///
  /// Lanza [StateError] si el UID no tiene documento en `recruiters/`
  /// (el usuario existe en Auth pero no es un reclutador registrado).
  Future<Recruiter> loginRecruiter({
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
    final doc = await _recruitersCollection.doc(user.uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw StateError('No existe un perfil de reclutador asociado.');
    }
    return Recruiter.fromFirestore({...doc.data()!, 'uid': user.uid});
  }

  /// Restaura la sesión de un reclutador si hay un usuario activo en Auth.
  Future<Recruiter?> restoreRecruiterSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _recruitersCollection.doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;

    return Recruiter.fromFirestore({...doc.data()!, 'uid': user.uid});
  }

  Future<void> completeCandidateOnboarding(String uid) async {
    await _candidatesCollection.doc(uid).set({
      'onboarding_completed': true,
      'onboarding_completed_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> completeCompanyOnboarding(String uid) async {
    await _companiesCollection.doc(uid).set({
      'onboarding_completed': true,
      'onboarding_completed_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
      if (kDebugMode) {
        debugPrint(
          '[AuthService] FirebaseAuthException code=${e.code} '
          'message=${e.message}',
        );
      }

      switch (e.code) {
        case 'invalid-email':
          return InvalidEmailException();
        case 'user-not-found':
          return UserNotFoundException();
        case 'wrong-password':
          return WrongPasswordException();
        case 'invalid-credential':
        case 'invalid-login-credentials':
          return AuthException('Correo o contraseña incorrectos.');
        case 'user-disabled':
          return AuthException('Tu cuenta está deshabilitada.');
        case 'operation-not-allowed':
          return AuthException(
            'El login por correo/contraseña no está habilitado en Firebase.',
          );
        case 'invalid-api-key':
        case 'app-not-authorized':
          return AuthException(
            'La configuración de Firebase de esta app no es válida para este entorno.',
          );
        case 'firebase-app-check-token-is-invalid':
        case 'app-check-token-is-invalid':
          return AuthException(
            'App Check está rechazando el token web. '
            'Revisa la clave reCAPTCHA y los dominios autorizados.',
          );
        case 'too-many-requests':
          return TooManyRequestsException();
        case 'network-request-failed':
          return NetworkException();
        default:
          return AuthException(
            _normalizeFirebaseAuthMessage(e.message) ??
                'No se pudo iniciar sesión. Intenta nuevamente.',
          );
      }
    }
    if (e is FirebaseException) {
      if (kDebugMode) {
        debugPrint(
          '[AuthService] FirebaseException plugin=${e.plugin} code=${e.code} '
          'message=${e.message}',
        );
      }

      final code = e.code.toLowerCase();
      final message = (e.message ?? '').toLowerCase();
      final isAppCheckIssue =
          e.plugin == 'firebase_app_check' ||
          code.contains('appcheck') ||
          code.contains('app-check') ||
          message.contains('appcheck') ||
          message.contains('app check');

      if (isAppCheckIssue) {
        return AuthException(
          'App Check está fallando en este entorno. '
          'En desarrollo usa USE_FIREBASE_APP_CHECK=false '
          'o corrige la clave/sitio de App Check.',
        );
      }

      if (e.code == 'permission-denied') {
        return PermissionDeniedException();
      }
      return AuthException(
        e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'No se pudo completar la autenticación.',
      );
    }
    final text = e.toString().trim();
    return AuthException(
      text.isEmpty || text == 'Error'
          ? 'No se pudo iniciar sesión. Revisa la configuración e inténtalo de nuevo.'
          : text,
    );
  }

  String? _normalizeFirebaseAuthMessage(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    if (lower.contains('invalid_login_credentials') ||
        lower.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (lower == 'error') return null;
    return trimmed;
  }
}
