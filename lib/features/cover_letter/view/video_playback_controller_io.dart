import 'dart:io' show File;

import 'package:video_player/video_player.dart';

VideoPlayerController createController(Uri uri) {
  if (uri.scheme == 'file' || uri.scheme.isEmpty) {
    final file = uri.scheme == 'file' ? File.fromUri(uri) : File(uri.toString());
    return VideoPlayerController.file(file);
  }
  return VideoPlayerController.networkUrl(uri);
}

