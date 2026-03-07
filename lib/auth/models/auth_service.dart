import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:opti_job_app/core/utils/callable_with_fallback.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/candidates/data/mappers/candidate_mapper.dart';
import 'package:opti_job_app/core/utils/firestore_utils.dart';
import 'package:opti_job_app/modules/companies/models/company_compliance_profile.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/companies/models/company_multiposting_settings.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter.dart';
import 'package:opti_job_app/auth/models/auth_exceptions.dart';
import 'package:opti_job_app/auth/models/eudi_wallet_models.dart';
import 'package:opti_job_app/auth/services/eudi_wallet_native_channel.dart';

class AuthService {
  AuthService({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
    required FirebaseFunctions fallbackFunctions,
    required EudiWalletNativeChannel eudiWalletNativeChannel,
  }) : _auth = firebaseAuth,
       _firestore = firestore,
       _callables = CallableWithFallback(
         functions: functions,
         fallbackFunctions: fallbackFunctions,
       ),
       _eudiWalletNativeChannel = eudiWalletNativeChannel;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final CallableWithFallback _callables;
  final EudiWalletNativeChannel _eudiWalletNativeChannel;

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
    await _upsertRootUserDocument(
      uid: user.uid,
      role: 'candidate',
      email: (data['email'] as String? ?? user.email ?? '')
          .trim()
          .toLowerCase(),
      name: (data['name'] as String? ?? user.displayName ?? 'Candidato').trim(),
    );
    final token = await user.getIdToken();
    return CandidateMapper.fromFirestore({...data, 'token': token});
  }

  Future<Candidate> signInCandidateWithGoogle() async {
    final googleProvider = GoogleAuthProvider()
      ..addScope('email')
      ..setCustomParameters(<String, String>{'prompt': 'select_account'});

    final credential = kIsWeb
        ? await _auth.signInWithPopup(googleProvider)
        : await _auth.signInWithProvider(googleProvider);
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No se encontró el usuario solicitado.',
      );
    }

    final docRef = _candidatesCollection.doc(user.uid);
    final doc = await docRef.get();

    Map<String, dynamic> data;
    if (!doc.exists || doc.data() == null) {
      final normalizedEmail = (user.email ?? '').trim().toLowerCase();
      if (normalizedEmail.isEmpty) {
        await _auth.signOut();
        throw StateError(
          'La cuenta de Google no incluye un correo válido para crear el perfil.',
        );
      }

      final normalizedName = (user.displayName ?? '').trim();
      data = <String, dynamic>{
        'id': DateTime.now().millisecondsSinceEpoch,
        'name': normalizedName.isEmpty ? 'Candidato' : normalizedName,
        'last_name': '',
        'email': normalizedEmail,
        'role': 'candidate',
        'uid': user.uid,
        'onboarding_completed': false,
        'auth_provider': 'google',
        'created_at': FieldValue.serverTimestamp(),
      };
      await docRef.set(data, SetOptions(merge: true));
    } else {
      data = doc.data()!;
    }

    await _upsertRootUserDocument(
      uid: user.uid,
      role: 'candidate',
      email: (data['email'] as String? ?? user.email ?? '')
          .trim()
          .toLowerCase(),
      name: (data['name'] as String? ?? user.displayName ?? 'Candidato').trim(),
    );
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

    final usersRef = _firestore.collection('users').doc(user.uid);
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    batch.set(_candidatesCollection.doc(user.uid), {
      ...candidateData,
      'created_at': now,
      'updated_at': now,
    }, SetOptions(merge: true));
    batch.set(usersRef, {
      'uid': user.uid,
      'email': candidateData['email'],
      'name': candidateData['name'],
      'display_name': candidateData['name'],
      'primary_role': 'candidate',
      'roles': const ['candidate'],
      'created_at': now,
      'updated_at': now,
    }, SetOptions(merge: true));
    await batch.commit();

    final token = await user.getIdToken();
    return CandidateMapper.fromFirestore({...candidateData, 'token': token});
  }

  Future<Candidate> signInCandidateWithEudiWallet({
    required EudiWalletSignInInput input,
  }) async {
    final response = await _callCallableWithFallback(
      name: 'signInWithEudiWallet',
      payload: input.toJson(),
    );

    final customToken = response['customToken']?.toString().trim();
    if (customToken == null || customToken.isEmpty) {
      throw StateError('No se recibió customToken al iniciar con EUDI Wallet.');
    }

    final credential = await _auth.signInWithCustomToken(customToken);
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No se pudo resolver el usuario autenticado con EUDI Wallet.',
      );
    }

    final doc = await _candidatesCollection.doc(user.uid).get();
    if (!doc.exists || doc.data() == null) {
      await _auth.signOut();
      throw StateError('No existe un perfil de candidato asociado.');
    }

    await _upsertRootUserDocument(
      uid: user.uid,
      role: 'candidate',
      email: (doc.data()?['email'] as String? ?? user.email ?? '')
          .trim()
          .toLowerCase(),
      name: (doc.data()?['name'] as String? ?? user.displayName ?? 'Candidato')
          .trim(),
    );
    final token = await user.getIdToken();
    return CandidateMapper.fromFirestore({...doc.data()!, 'token': token});
  }

  Future<EudiWalletSignInInput> buildEudiWalletSignInInputFromNative({
    String? initialName,
    String? initialEmail,
    String audience = 'opti-job-app:eudi-signin',
    String proofSchemaVersion = '2026.1',
  }) async {
    final isAvailable = await _eudiWalletNativeChannel.isWalletAvailable();
    if (!isAvailable) {
      throw const EudiWalletNativeException(
        code: 'wallet-unavailable',
        message: 'No se detectó una EUDI Wallet nativa en este dispositivo.',
      );
    }

    final response = await _eudiWalletNativeChannel.requestPresentation(
      request: EudiPresentationRequest.forSignIn(
        audience: audience,
        proofSchemaVersion: proofSchemaVersion,
      ),
    );

    final resolvedEmail =
        response.email?.trim().toLowerCase() ??
        initialEmail?.trim().toLowerCase() ??
        '';
    if (resolvedEmail.isEmpty) {
      throw const EudiWalletNativeException(
        code: 'missing-email',
        message:
            'La presentación EUDI no incluye email y no se pudo resolver uno local.',
      );
    }

    final resolvedName =
        response.fullName?.trim() ?? initialName?.trim() ?? 'Candidato EUDI';

    return EudiWalletSignInInput(
      walletSubject: response.walletSubject.trim(),
      email: resolvedEmail,
      fullName: resolvedName,
      countryCode: response.countryCode.trim().toUpperCase(),
      assuranceLevel: response.assuranceLevel.trim(),
      credential: response.credential,
      verifiablePresentation: response.verifiablePresentation.trim(),
      expectedAudience: audience,
      proofSchemaVersion: response.proofSchemaVersion.trim().isNotEmpty
          ? response.proofSchemaVersion.trim()
          : proofSchemaVersion,
      verificationMethod: response.verificationMethod.trim(),
      issuerDid: response.issuerDid.trim(),
      credentialType: response.credentialType.trim(),
    );
  }

  Future<void> importEudiCredentialFromNativeWallet({
    String audience = 'opti-job-app:eudi-import',
    String proofSchemaVersion = '2026.1',
  }) async {
    final isAvailable = await _eudiWalletNativeChannel.isWalletAvailable();
    if (!isAvailable) {
      throw const EudiWalletNativeException(
        code: 'wallet-unavailable',
        message: 'No se detectó una EUDI Wallet nativa en este dispositivo.',
      );
    }

    final response = await _eudiWalletNativeChannel.requestPresentation(
      request: EudiPresentationRequest.forCredentialImport(
        audience: audience,
        proofSchemaVersion: proofSchemaVersion,
      ),
    );

    final input = EudiCredentialImportInput(
      verifiablePresentation: response.verifiablePresentation.trim(),
      expectedAudience: audience,
      proofSchemaVersion: response.proofSchemaVersion.trim().isNotEmpty
          ? response.proofSchemaVersion.trim()
          : proofSchemaVersion,
    );

    await _callCallableWithFallback(
      name: 'importEudiCredential',
      payload: input.toJson(),
    );
  }

  Future<SelectiveDisclosureProofResult> createSelectiveDisclosureProof({
    required SelectiveDisclosureProofInput input,
  }) async {
    final response = await _callCallableWithFallback(
      name: 'createSelectiveDisclosureProof',
      payload: input.toJson(),
    );
    return SelectiveDisclosureProofResult.fromJson(response);
  }

  Future<SelectiveDisclosureVerificationResult> verifySelectiveDisclosureProof({
    required String proofId,
    required String proofToken,
  }) async {
    final response = await _callCallableWithFallback(
      name: 'verifySelectiveDisclosureProof',
      payload: {'proofId': proofId.trim(), 'proofToken': proofToken.trim()},
    );
    return SelectiveDisclosureVerificationResult.fromJson(response);
  }

  Future<void> revokeSelectiveDisclosureProof({required String proofId}) async {
    await _callCallableWithFallback(
      name: 'revokeSelectiveDisclosureProof',
      payload: {'proofId': proofId.trim()},
    );
  }

  Future<List<VerifiedCredential>> fetchCandidateVerifiedCredentials(
    String candidateUid,
  ) async {
    final normalizedUid = candidateUid.trim();
    if (normalizedUid.isEmpty) return const [];

    final snapshot = await _candidatesCollection
        .doc(normalizedUid)
        .collection('verifiedCredentials')
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map(
          (doc) => VerifiedCredential.fromJson(
            FirestoreUtils.transformFirestoreData(doc.data()),
            id: doc.id,
          ),
        )
        .toList(growable: false);
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
    await _upsertRootUserDocument(
      uid: user.uid,
      role: 'company',
      email: (data['email'] as String? ?? user.email ?? '')
          .trim()
          .toLowerCase(),
      name: (data['name'] as String? ?? user.displayName ?? 'Empresa').trim(),
    );
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
      'website': '',
      'industry': '',
      'team_size': '',
      'headquarters': '',
      'description': '',
      'multiposting_channel_settings': const {
        'enabledChannels': companyDefaultMultipostingChannels,
      },
      'compliance_settings': const CompanyComplianceProfile().toJson(),
    };

    final usersRef = _firestore.collection('users').doc(user.uid);
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    batch.set(_companiesCollection.doc(user.uid), {
      ...companyData,
      'created_at': now,
      'updated_at': now,
    }, SetOptions(merge: true));
    batch.set(usersRef, {
      'uid': user.uid,
      'email': companyData['email'],
      'name': companyData['name'],
      'display_name': companyData['name'],
      'primary_role': 'company',
      'roles': const ['company'],
      'created_at': now,
      'updated_at': now,
    }, SetOptions(merge: true));
    await batch.commit();

    final token = await user.getIdToken();
    return Company.fromJson({...companyData, 'token': token});
  }

  Future<void> logout() {
    return _auth.signOut();
  }

  Future<Map<String, dynamic>> _callCallableWithFallback({
    required String name,
    Map<String, dynamic> payload = const {},
  }) async {
    return _callables.callMap(name: name, payload: payload);
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
    final data = doc.data()!;
    await _upsertRootUserDocument(
      uid: user.uid,
      role: 'recruiter',
      email: (data['email'] as String? ?? user.email ?? '')
          .trim()
          .toLowerCase(),
      name: (data['name'] as String? ?? user.displayName ?? 'Recruiter').trim(),
    );
    return Recruiter.fromFirestore({...data, 'uid': user.uid});
  }

  /// Registra un recruiter autónomo (sin empresa) usando email/contraseña.
  ///
  /// El perfil recruiter se crea en backend mediante la callable
  /// `registerRecruiterFreelance`, que también sincroniza claims RBAC.
  Future<Recruiter> registerRecruiter({
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

    final normalizedName = name.trim().isEmpty ? 'Recruiter' : name.trim();
    final normalizedEmail = email.trim().toLowerCase();

    try {
      await _callCallableWithFallback(
        name: 'registerRecruiterFreelance',
        payload: <String, dynamic>{'name': normalizedName},
      );
      final doc = await _recruitersCollection.doc(user.uid).get();
      if (!doc.exists || doc.data() == null) {
        throw StateError('No se pudo crear el perfil de reclutador.');
      }

      await _upsertRootUserDocument(
        uid: user.uid,
        role: 'recruiter',
        email: normalizedEmail,
        name: normalizedName,
      );

      return Recruiter.fromFirestore({...doc.data()!, 'uid': user.uid});
    } catch (error) {
      try {
        await user.delete();
      } catch (_) {
        // Si no puede eliminarse, al menos cerramos sesión local.
      }
      await _auth.signOut();
      rethrow;
    }
  }

  /// Restaura la sesión de un reclutador si hay un usuario activo en Auth.
  Future<Recruiter?> restoreRecruiterSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _recruitersCollection.doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    await _upsertRootUserDocument(
      uid: user.uid,
      role: 'recruiter',
      email: (data['email'] as String? ?? user.email ?? '')
          .trim()
          .toLowerCase(),
      name: (data['name'] as String? ?? user.displayName ?? 'Recruiter').trim(),
    );
    return Recruiter.fromFirestore({...data, 'uid': user.uid});
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

    await _upsertRootUserDocument(
      uid: user.uid,
      role: 'candidate',
      email: (data['email'] as String? ?? user.email ?? '')
          .trim()
          .toLowerCase(),
      name: (data['name'] as String? ?? user.displayName ?? 'Candidato').trim(),
    );
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

    await _upsertRootUserDocument(
      uid: user.uid,
      role: 'company',
      email: (data['email'] as String? ?? user.email ?? '')
          .trim()
          .toLowerCase(),
      name: (data['name'] as String? ?? user.displayName ?? 'Empresa').trim(),
    );
    final token = await user.getIdToken();
    return Company.fromJson({...data, 'token': token});
  }

  Future<void> _upsertRootUserDocument({
    required String uid,
    required String role,
    required String email,
    required String name,
  }) async {
    final normalizedRole = role.trim().toLowerCase();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = name.trim().isEmpty ? 'Usuario' : name.trim();
    final usersRef = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(usersRef);
      final data = snapshot.data() ?? const <String, dynamic>{};
      final roles = <String>{};
      final existingRolesRaw = data['roles'];
      if (existingRolesRaw is List) {
        for (final value in existingRolesRaw) {
          final parsed = value.toString().trim().toLowerCase();
          if (parsed.isNotEmpty) roles.add(parsed);
        }
      }
      roles.add(normalizedRole);
      final sortedRoles = roles.toList()..sort();
      final now = FieldValue.serverTimestamp();

      transaction.set(usersRef, {
        'uid': uid,
        'email': normalizedEmail,
        'name': normalizedName,
        'display_name': normalizedName,
        'primary_role': normalizedRole,
        'roles': sortedRoles,
        'updated_at': now,
        if (!snapshot.exists) 'created_at': now,
      }, SetOptions(merge: true));
    });
  }

  AuthException mapFirebaseException(Object e) {
    if (e is EudiWalletNativeException) {
      return AuthException(e.message);
    }
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
        case 'account-exists-with-different-credential':
          return AuthException(
            'Ya existe una cuenta con ese correo usando otro método de acceso.',
          );
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          return AuthException('Has cancelado el acceso con Google.');
        case 'popup-blocked':
          return AuthException(
            'El navegador ha bloqueado la ventana de acceso con Google.',
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
