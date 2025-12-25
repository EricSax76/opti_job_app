import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CurriculumShareService {
  Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
    String? subject,
    String? text,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: subject,
      text: text,
    );
  }
}

