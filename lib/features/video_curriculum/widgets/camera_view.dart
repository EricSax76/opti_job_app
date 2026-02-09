import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/features/video_curriculum/bloc/video_curriculum_bloc.dart';
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
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_cameraSessionController.disposeCamera());
      return;
    }

    if (state == AppLifecycleState.resumed && mounted) {
      final hasRecordedVideo =
          context.read<VideoCurriculumBloc>().state.recordedVideoPath != null;
      if (!hasRecordedVideo && !_cameraSessionController.isCameraReady) {
        _cameraSessionController.initializeCamera();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraSessionController.dispose();
    super.dispose();
  }

  void _showNoAttemptsLeftSnackBar() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('No te quedan más intentos.')));
  }

  Future<void> _toggleRecording() async {
    final bloc = context.read<VideoCurriculumBloc>();

    final result = await _cameraSessionController.toggleRecording(
      attemptsLeft: bloc.state.attemptsLeft,
      onRecordingStopped: (path) {
        if (!mounted) return;
        bloc.add(VideoRecordingStopped(path));
      },
    );
    if (!mounted) return;

    if (result.type == CameraToggleResultType.started) {
      bloc.add(VideoRecordingStarted());
      return;
    }
    if (result.type == CameraToggleResultType.noAttemptsLeft) {
      _showNoAttemptsLeftSnackBar();
      return;
    }
    if (result.type == CameraToggleResultType.error &&
        result.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cameraSessionController,
      builder: (context, _) {
        return BlocBuilder<VideoCurriculumBloc, VideoCurriculumState>(
          builder: (context, state) {
            final hasAttemptsLeft = state.attemptsLeft > 0;

            if (state.recordedVideoPath != null) {
              return CameraRecordedVideoView(
                attemptsLeft: state.attemptsLeft,
                onRetry: hasAttemptsLeft
                    ? () {
                        context.read<VideoCurriculumBloc>().add(
                          RetryVideoRecording(),
                        );
                        _cameraSessionController.initializeCamera();
                      }
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
