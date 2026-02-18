import 'package:cloud_firestore/cloud_firestore.dart';

class CoverLetterService {
  CoverLetterService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _coverLetterDocRef(
    String candidateUid,
  ) {
    return _firestore
        .collection('candidates')
        .doc(candidateUid)
        .collection('cover_letter')
        .doc('main');
  }

  Future<String?> fetchCoverLetterText(String candidateUid) async {
    final coverLetterDoc = await _coverLetterDocRef(candidateUid).get();
    final coverLetterData = coverLetterDoc.data();
    final subcollectionText = _extractText(coverLetterData?['text']);
    if (subcollectionText != null) {
      return subcollectionText;
    }

    // Backward-compatible fallback for legacy data embedded in candidates/{uid}.
    final candidateDoc = await _firestore
        .collection('candidates')
        .doc(candidateUid)
        .get();
    final candidateData = candidateDoc.data();
    final legacyCoverLetter = candidateData?['cover_letter'];
    final rawText = legacyCoverLetter is Map ? legacyCoverLetter['text'] : null;
    final text = _extractText(rawText);
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  Future<void> saveCoverLetterText({
    required String candidateUid,
    required String text,
  }) async {
    await _coverLetterDocRef(candidateUid).set({
      'text': text,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

String? _extractText(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}
