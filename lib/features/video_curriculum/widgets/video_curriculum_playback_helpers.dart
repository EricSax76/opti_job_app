import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:opti_job_app/features/video_curriculum/view/video_playback_screen.dart';

void openVideoPlayer(
  BuildContext context,
  Uri uri, {
  required String title,
  required bool allowExternalFallback,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => VideoPlaybackScreen(
        uri: uri,
        title: title,
        allowExternalFallback: allowExternalFallback,
      ),
    ),
  );
}

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  double size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  final value = unitIndex == 0
      ? size.toStringAsFixed(0)
      : size.toStringAsFixed(1);
  return '$value ${units[unitIndex]}';
}

Uri? buildLocalVideoUri(String path) {
  final trimmedPath = path.trim();
  if (trimmedPath.isEmpty) return null;

  final parsed = Uri.tryParse(trimmedPath);
  if (parsed != null && parsed.scheme.isNotEmpty) {
    return parsed;
  }

  if (kIsWeb) {
    return Uri.tryParse(trimmedPath);
  }

  return Uri.file(trimmedPath);
}
