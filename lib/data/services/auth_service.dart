import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:opti_job_app/data/models/candidate.dart';
import 'package:opti_job_app/data/models/company.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

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
    return Candidate.fromJson({...data, 'token': token});
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
      'email': email.toLowerCase().trim(),
      'role': 'candidate',
      'uid': user.uid,
    };

    await _candidatesCollection.doc(user.uid).set({
      ...candidateData,
      'created_at': FieldValue.serverTimestamp(),
    });

    final token = await user.getIdToken();
    return Candidate.fromJson({...candidateData, 'token': token});
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
}
