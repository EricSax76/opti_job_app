import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class CurriculumService {
  CurriculumService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DocumentReference<Map<String, dynamic>> _docRef(String candidateUid) {
    return _firestore
        .collection('candidates')
        .doc(candidateUid)
        .collection('curriculum')
        .doc('main');
  }

  Future<Curriculum> fetchCurriculum(String candidateUid) async {
    final snapshot = await _docRef(candidateUid).get();
    if (!snapshot.exists) {
      return Curriculum.empty();
    }
    final data = snapshot.data();
    if (data == null) return Curriculum.empty();
    return Curriculum.fromJson(data);
  }

  Future<Curriculum> saveCurriculum({
    required String candidateUid,
    required Curriculum curriculum,
  }) async {
    final data = curriculum.toJson()
      ..['updated_at'] = FieldValue.serverTimestamp();
    await _docRef(candidateUid).set(data, SetOptions(merge: true));
    final snapshot = await _docRef(candidateUid).get();
    final refreshed = snapshot.data();
    if (refreshed == null) return curriculum;
    return Curriculum.fromJson(refreshed);
  }

  Future<Curriculum> uploadAttachment({
    required String candidateUid,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final previousSnapshot = await _docRef(candidateUid).get();
    final previousData = previousSnapshot.data();
    final previousAttachment = CurriculumAttachment.fromJson(
      previousData?['attachment'] as Map<String, dynamic>?,
    );

    final sanitizedName = _sanitizeFileName(fileName);
    final storagePath =
        'candidates/$candidateUid/curriculum/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
    final ref = _storage.ref().child(storagePath);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    final downloadUrl = await ref.getDownloadURL();

    await _docRef(candidateUid).set(
      {
        'attachment': {
          'file_name': fileName,
          'download_url': downloadUrl,
          'storage_path': storagePath,
          'content_type': contentType,
          'size_bytes': bytes.length,
          'updated_at': FieldValue.serverTimestamp(),
        },
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (previousAttachment != null &&
        previousAttachment.storagePath.isNotEmpty &&
        previousAttachment.storagePath != storagePath) {
      try {
        await _storage.ref().child(previousAttachment.storagePath).delete();
      } catch (_) {
        // Ignorar: puede fallar por permisos o inexistencia del archivo.
      }
    }

    return fetchCurriculum(candidateUid);
  }

  Future<Curriculum> deleteAttachment({
    required String candidateUid,
    required CurriculumAttachment attachment,
  }) async {
    try {
      await _storage.ref().child(attachment.storagePath).delete();
    } catch (_) {
      // Ignorar: el archivo puede no existir o no tener permisos de borrado.
    }

    await _docRef(candidateUid).set(
      {
        'attachment': FieldValue.delete(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return fetchCurriculum(candidateUid);
  }
}

String _sanitizeFileName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'archivo';
  return trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
}
