import 'package:firebase_storage/firebase_storage.dart';

class UploadedVideoStatusController {
  const UploadedVideoStatusController._();

  static Future<String?> loadDownloadUrl(String storagePath) async {
    final normalizedPath = storagePath.trim();
    if (normalizedPath.isEmpty) return null;
    return FirebaseStorage.instance
        .ref()
        .child(normalizedPath)
        .getDownloadURL();
  }
}
