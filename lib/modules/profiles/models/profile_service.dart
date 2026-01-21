import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/candidates/data/mappers/candidate_mapper.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';

class ProfileService {
  ProfileService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

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

  Future<Company> fetchCompanyProfile(int id) async {
    final query = await _firestore
        .collection('companies')
        .where('id', isEqualTo: id)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw StateError('Perfil de empresa no encontrado.');
    }
    final data = query.docs.first.data();
    return Company.fromJson(data);
  }

  Future<Map<int, Company>> fetchCompaniesByIds(List<int> ids) async {
    final uniqueIds = ids.where((id) => id > 0).toSet().toList();
    if (uniqueIds.isEmpty) return {};

    final companiesById = <int, Company>{};
    for (final chunk in _chunk(uniqueIds, 10)) {
      final query = await _firestore
          .collection('companies')
          .where('id', whereIn: chunk)
          .get();
      for (final doc in query.docs) {
        final company = Company.fromJson(doc.data());
        companiesById[company.id] = company;
      }
    }
    return companiesById;
  }

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

  Future<Company> updateCompanyProfile({
    required String uid,
    required String name,
    Uint8List? avatarBytes,
  }) async {
    final docRef = _firestore.collection('companies').doc(uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw StateError('Perfil de empresa no encontrado.');
    }
    final snapshotData = snapshot.data();
    final existingAvatarUrl = snapshotData?['avatar_url'] as String?;

    final updateData = <String, dynamic>{
      'name': name,
      'updated_at': FieldValue.serverTimestamp(),
    };
    String? newAvatarUrl;

    if (avatarBytes != null) {
      final avatarRef = _storage.ref().child('companies/$uid/avatar.jpg');
      await avatarRef.putData(
        avatarBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      newAvatarUrl = await avatarRef.getDownloadURL();
      updateData['avatar_url'] = newAvatarUrl;
    }

    await docRef.update(updateData);

    final avatarUrlForOffers = (newAvatarUrl != null && newAvatarUrl.isNotEmpty)
        ? newAvatarUrl
        : existingAvatarUrl;
    final offersQuery = await _firestore
        .collection('jobOffers')
        .where('company_uid', isEqualTo: uid)
        .get();
    if (offersQuery.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in offersQuery.docs) {
        final update = <String, dynamic>{'company_name': name};
        if (avatarUrlForOffers != null && avatarUrlForOffers.isNotEmpty) {
          update['company_avatar_url'] = avatarUrlForOffers;
        }
        batch.update(doc.reference, update);
      }
      await batch.commit();
    }

    final updatedSnapshot = await docRef.get();
    final data = updatedSnapshot.data();
    if (data == null) {
      throw StateError('No se pudo actualizar el perfil.');
    }
    return Company.fromJson(data);
  }
}

List<List<T>> _chunk<T>(List<T> items, int size) {
  if (items.isEmpty) return const [];
  final chunks = <List<T>>[];
  for (var i = 0; i < items.length; i += size) {
    final end = i + size > items.length ? items.length : i + size;
    chunks.add(items.sublist(i, end));
  }
  return chunks;
}
