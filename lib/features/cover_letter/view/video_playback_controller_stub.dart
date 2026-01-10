import 'package:video_player/video_player.dart';

VideoPlayerController createController(Uri uri) {
  return VideoPlayerController.networkUrl(uri);
}

