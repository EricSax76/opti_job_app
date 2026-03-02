import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/candidates/data/mappers/candidate_mapper.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';

class ProfileService {
  ProfileService({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DocumentReference<Map<String, dynamic>> _coverLetterDocRef(
    String candidateUid,
  ) {
    return _firestore
        .collection('candidates')
        .doc(candidateUid)
        .collection('cover_letter')
        .doc('main');
  }

  Future<Candidate> fetchCandidateProfile(String uid) async {
    final doc = await _firestore.collection('candidates').doc(uid).get();
    if (!doc.exists) {
      throw StateError('Perfil de candidato no encontrado.');
    }
    final data = doc.data();
    if (data == null) {
      throw StateError('Perfil de candidato no encontrado.');
    }
    final rawUid = data['uid'] as String?;
    final candidateUid = rawUid == null || rawUid.trim().isEmpty
        ? uid
        : rawUid.trim();
    final baseCandidateData = rawUid == null || rawUid.trim().isEmpty
        ? {...data, 'uid': uid}
        : data;
    final candidateData = await _withCoverLetterData(
      candidateUid: candidateUid,
      candidateData: baseCandidateData,
    );
    return CandidateMapper.fromFirestore(candidateData);
  }

  Future<Map<String, Candidate>> fetchCandidateProfilesByUids(
    Iterable<String> uids,
  ) async {
    final uniqueUids = uids
        .map((uid) => uid.trim())
        .where((uid) => uid.isNotEmpty)
        .toSet()
        .toList();
    if (uniqueUids.isEmpty) return const {};

    final candidatesByUid = <String, Candidate>{};
    for (final chunk in _chunk(uniqueUids, 10)) {
      final query = await _firestore
          .collection('candidates')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in query.docs) {
        final data = doc.data();
        final documentUid = doc.id.trim();
        if (documentUid.isEmpty) continue;
        final rawUid = data['uid'] as String?;
        final candidateUid = rawUid == null || rawUid.trim().isEmpty
            ? documentUid
            : rawUid.trim();
        final baseCandidateData = rawUid == null || rawUid.trim().isEmpty
            ? {...data, 'uid': candidateUid}
            : data;
        final candidateData = await _withCoverLetterData(
          candidateUid: candidateUid,
          candidateData: baseCandidateData,
        );
        candidatesByUid[documentUid] = CandidateMapper.fromFirestore(
          candidateData,
        );
      }
    }

    return candidatesByUid;
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
      // append cache buster to force NetworkImage to reload the image
      final bustUrl = avatarUrl.contains('?')
          ? '$avatarUrl&_v=${DateTime.now().millisecondsSinceEpoch}'
          : '$avatarUrl?_v=${DateTime.now().millisecondsSinceEpoch}';
      updateData['avatar_url'] = bustUrl;
    }

    await docRef.update(updateData);
    final updatedSnapshot = await docRef.get();
    final data = updatedSnapshot.data();
    if (data == null) {
      throw StateError('No se pudo actualizar el perfil.');
    }
    return CandidateMapper.fromFirestore(data);
  }

  Future<Candidate> saveCandidateOnboardingProfile({
    required String uid,
    required CandidateOnboardingProfile onboardingProfile,
  }) async {
    final docRef = _firestore.collection('candidates').doc(uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw StateError('Perfil de candidato no encontrado.');
    }

    await docRef.set({
      'onboarding_profile': onboardingProfile.toJson(),
      'target_role': onboardingProfile.targetRole,
      'preferred_location': onboardingProfile.preferredLocation,
      'preferred_modality': onboardingProfile.preferredModality,
      'preferred_seniority': onboardingProfile.preferredSeniority,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final updatedSnapshot = await docRef.get();
    final data = updatedSnapshot.data();
    if (data == null) {
      throw StateError('No se pudo guardar el onboarding del candidato.');
    }

    final rawUid = data['uid'] as String?;
    final candidateUid = rawUid == null || rawUid.trim().isEmpty
        ? uid
        : rawUid.trim();
    final candidateData = rawUid == null || rawUid.trim().isEmpty
        ? {...data, 'uid': uid}
        : data;
    final enriched = await _withCoverLetterData(
      candidateUid: candidateUid,
      candidateData: candidateData,
    );
    return CandidateMapper.fromFirestore(enriched);
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
    if (snapshotData == null) {
      throw StateError('Perfil de empresa no encontrado.');
    }
    final existingAvatarUrl = snapshotData['avatar_url'] as String?;

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
      final rawAvatarUrl = await avatarRef.getDownloadURL();
      newAvatarUrl = rawAvatarUrl.contains('?')
          ? '$rawAvatarUrl&_v=${DateTime.now().millisecondsSinceEpoch}'
          : '$rawAvatarUrl?_v=${DateTime.now().millisecondsSinceEpoch}';
      updateData['avatar_url'] = newAvatarUrl;
    }

    await docRef.update(updateData);

    final avatarUrlForOffers = (newAvatarUrl != null && newAvatarUrl.isNotEmpty)
        ? newAvatarUrl
        : existingAvatarUrl;
    final previousName = (snapshotData['name'] as String?)?.trim() ?? '';
    final hasNameChanged = previousName != name;
    final hasAvatarChanged =
        newAvatarUrl != null &&
        newAvatarUrl.isNotEmpty &&
        newAvatarUrl != existingAvatarUrl;
    if (hasNameChanged || hasAvatarChanged) {
      final offersQuery = await _firestore
          .collection('jobOffers')
          .where('company_uid', isEqualTo: uid)
          .get();
      if (offersQuery.docs.isNotEmpty) {
        for (final chunk in _chunk(offersQuery.docs, 400)) {
          final batch = _firestore.batch();
          for (final doc in chunk) {
            final update = <String, dynamic>{'company_name': name};
            if (avatarUrlForOffers != null && avatarUrlForOffers.isNotEmpty) {
              update['company_avatar_url'] = avatarUrlForOffers;
            }
            batch.update(doc.reference, update);
          }
          await batch.commit();
        }
      }
    }

    return Company.fromJson({
      ...snapshotData,
      'uid': uid,
      'name': name,
      if (avatarUrlForOffers != null && avatarUrlForOffers.isNotEmpty)
        'avatar_url': avatarUrlForOffers,
    });
  }

  Future<Map<String, dynamic>> _withCoverLetterData({
    required String candidateUid,
    required Map<String, dynamic> candidateData,
  }) async {
    final coverLetterSnapshot = await _coverLetterDocRef(candidateUid).get();
    final coverLetterData = coverLetterSnapshot.data();
    if (coverLetterData == null) {
      return candidateData;
    }
    return <String, dynamic>{...candidateData, 'cover_letter': coverLetterData};
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
