import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/candidates/data/mappers/candidate_mapper.dart';
import 'package:opti_job_app/modules/candidates/repositories/candidates_repository.dart';

class FirebaseCandidatesRepository implements CandidatesRepository {
  FirebaseCandidatesRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<Candidate> fetchCandidateProfile(String uid) async {
    final doc = await _firestore.collection('candidates').doc(uid).get();
    if (!doc.exists) {
      throw StateError('Perfil de candidato no encontrado.');
    }
    final data = doc.data();
    if (data == null) {
      throw StateError('Perfil de candidato no encontrado.');
    }
    return CandidateMapper.fromFirestore(data);
  }

  @override
  Future<Candidate> updateCandidateProfile({
    required String uid,
    required String name,
    required String lastName,
    Uint8List? avatarBytes,
  }) async {
    final docRef = _firestore.collection('candidates').doc(uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw StateError('Perfil de candidato no encontrado.');
    }
    
    final updateData = <String, dynamic>{
      'name': name,
      'last_name': lastName,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (avatarBytes != null) {
      final avatarRef = _storage.ref().child('candidates/$uid/avatar.jpg');
      await avatarRef.putData(
        avatarBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final avatarUrl = await avatarRef.getDownloadURL();
      updateData['avatar_url'] = avatarUrl;
    }

    await docRef.update(updateData);
    final updatedSnapshot = await docRef.get();
    final data = updatedSnapshot.data();
    if (data == null) {
      throw StateError('No se pudo actualizar el perfil.');
    }
    return CandidateMapper.fromFirestore(data);
  }
}
