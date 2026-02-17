import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/features/video_curriculum/bloc/video_curriculum_bloc.dart';
import 'package:opti_job_app/features/video_curriculum/logic/video_camera_logic.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/camera_session_controller.dart';

class VideoCameraController {
  const VideoCameraController._();

  static void onLifecycleStateChanged(
    BuildContext context, {
    required AppLifecycleState state,
    required CameraSessionController cameraSessionController,
  }) {
    if (VideoCameraLogic.shouldDisposeCamera(state)) {
      unawaited(cameraSessionController.disposeCamera());
      return;
    }

    if (state != AppLifecycleState.resumed || !context.mounted) return;

    final hasRecordedVideo =
        context.read<VideoCurriculumBloc>().state.recordedVideoPath != null;
    if (!VideoCameraLogic.shouldInitializeOnResume(
      hasRecordedVideo: hasRecordedVideo,
      isCameraReady: cameraSessionController.isCameraReady,
    )) {
      return;
    }
    cameraSessionController.initializeCamera();
  }

  static Future<void> toggleRecording(
    BuildContext context, {
    required CameraSessionController cameraSessionController,
  }) async {
    final bloc = context.read<VideoCurriculumBloc>();
    final result = await cameraSessionController.toggleRecording(
      attemptsLeft: bloc.state.attemptsLeft,
      onRecordingStopped: (path) {
        if (!context.mounted) return;
        bloc.add(VideoRecordingStopped(path));
      },
    );
    if (!context.mounted) return;

    if (result.type == CameraToggleResultType.started) {
      bloc.add(VideoRecordingStarted());
      return;
    }
    if (result.type == CameraToggleResultType.noAttemptsLeft) {
      _showSnackBar(
        context,
        const SnackBar(content: Text('No te quedan más intentos.')),
      );
      return;
    }
    if (result.type == CameraToggleResultType.error &&
        result.errorMessage != null) {
      _showSnackBar(context, SnackBar(content: Text(result.errorMessage!)));
    }
  }

  static void retryRecording(
    BuildContext context, {
    required CameraSessionController cameraSessionController,
  }) {
    context.read<VideoCurriculumBloc>().add(RetryVideoRecording());
    cameraSessionController.initializeCamera();
  }

  static void _showSnackBar(BuildContext context, SnackBar snackBar) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(snackBar);
  }
}
