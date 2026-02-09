import 'dart:io' show File;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class VideoCurriculumService {
  VideoCurriculumService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<void> uploadVideoCurriculum({
    required String candidateUid,
    required String filePath,
  }) async {
    final normalizedPath = filePath.toLowerCase();
    final contentType = normalizedPath.endsWith('.mov')
        ? 'video/quicktime'
        : 'video/mp4';
    final extension = contentType == 'video/quicktime' ? 'mov' : 'mp4';
    final storagePath =
        'candidates/$candidateUid/video_curriculum/${DateTime.now().millisecondsSinceEpoch}.$extension';
    final ref = _storage.ref().child(storagePath);

    int sizeBytes;
    if (kIsWeb) {
      final bytes = await XFile(filePath).readAsBytes();
      if (bytes.isEmpty) {
        throw FirebaseException(
          plugin: 'firebase_storage',
          message: 'El vídeo grabado está vacío.',
        );
      }
      sizeBytes = bytes.length;
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
    } else {
      final file = File(filePath);
      sizeBytes = await file.length();
      if (sizeBytes == 0) {
        throw FirebaseException(
          plugin: 'firebase_storage',
          message: 'El vídeo grabado está vacío.',
        );
      }
      await ref.putFile(file, SettableMetadata(contentType: contentType));
    }

    await _firestore.collection('candidates').doc(candidateUid).update({
      'video_curriculum': {
        'storage_path': storagePath,
        'content_type': contentType,
        'size_bytes': sizeBytes,
        'updated_at': FieldValue.serverTimestamp(),
      },
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
