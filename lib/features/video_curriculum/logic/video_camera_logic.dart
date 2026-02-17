import 'package:flutter/widgets.dart';

class VideoCameraLogic {
  const VideoCameraLogic._();

  static bool shouldDisposeCamera(AppLifecycleState state) {
    return state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused;
  }

  static bool shouldInitializeOnResume({
    required bool hasRecordedVideo,
    required bool isCameraReady,
  }) {
    return !hasRecordedVideo && !isCameraReady;
  }

  static bool hasAttemptsLeft(int attemptsLeft) {
    return attemptsLeft > 0;
  }
}
