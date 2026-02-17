import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/features/video_curriculum/bloc/video_curriculum_bloc.dart';
import 'package:opti_job_app/features/video_curriculum/logic/video_camera_logic.dart';
import 'package:opti_job_app/features/video_curriculum/view/controllers/video_camera_controller.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/camera_view_components.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/camera_session_controller.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  late final CameraSessionController _cameraSessionController;

  @override
  void initState() {
    super.initState();
    _cameraSessionController = CameraSessionController();
    WidgetsBinding.instance.addObserver(this);
    _cameraSessionController.initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    VideoCameraController.onLifecycleStateChanged(
      context,
      state: state,
      cameraSessionController: _cameraSessionController,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraSessionController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    await VideoCameraController.toggleRecording(
      context,
      cameraSessionController: _cameraSessionController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cameraSessionController,
      builder: (context, _) {
        return BlocBuilder<VideoCurriculumBloc, VideoCurriculumState>(
          builder: (context, state) {
            final hasAttemptsLeft = VideoCameraLogic.hasAttemptsLeft(
              state.attemptsLeft,
            );

            if (state.recordedVideoPath != null) {
              return CameraRecordedVideoView(
                attemptsLeft: state.attemptsLeft,
                onRetry: hasAttemptsLeft
                    ? () => VideoCameraController.retryRecording(
                        context,
                        cameraSessionController: _cameraSessionController,
                      )
                    : null,
              );
            }

            if (!_cameraSessionController.isCameraReady) {
              final cameraError = _cameraSessionController.cameraError;
              if (cameraError != null) {
                return CameraErrorView(
                  message: cameraError,
                  onRetry: _cameraSessionController.isInitializing
                      ? null
                      : _cameraSessionController.initializeCamera,
                );
              }
              return const Center(child: CircularProgressIndicator());
            }

            return CameraLivePreviewView(
              controller: _cameraSessionController.cameraController!,
              attemptsLeft: state.attemptsLeft,
              hasAttemptsLeft: hasAttemptsLeft,
              isRecording: _cameraSessionController.isRecording,
              onToggleRecording: _toggleRecording,
            );
          },
        );
      },
    );
  }
}
