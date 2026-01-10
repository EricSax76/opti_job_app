import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/features/cover_letter/bloc/cover_letter_bloc.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    final firstCamera = _cameras?.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );

    if (firstCamera == null) return;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: true,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (_) {
      // Gestionar error de inicialización
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (!_isCameraInitialized || _controller == null) return;

    final bloc = context.read<CoverLetterBloc>();

    if (_isRecording) {
      final file = await _controller!.stopVideoRecording();
      setState(() => _isRecording = false);
      bloc.add(VideoRecordingStopped(file.path));
      return;
    }

    if (bloc.state.attemptsLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No te quedan más intentos.')),
      );
      return;
    }

    bloc.add(VideoRecordingStarted());
    await _controller!.startVideoRecording();
    setState(() => _isRecording = true);

    Future.delayed(const Duration(seconds: 60), () {
      if (_isRecording && mounted) {
        _toggleRecording();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoverLetterBloc, CoverLetterState>(
      builder: (context, state) {
        if (state.recordedVideoPath != null) {
          return Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam, color: Colors.white, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Vídeo grabado. Quedan ${state.attemptsLeft} intentos.',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                if (state.attemptsLeft > 0)
                  ElevatedButton(
                    onPressed: () {
                      context.read<CoverLetterBloc>().add(RetryVideoRecording());
                    },
                    child: const Text('Grabar de nuevo'),
                  ),
              ],
            ),
          );
        }

        if (!_isCameraInitialized || _controller == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_controller!),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FloatingActionButton(
                  onPressed: state.attemptsLeft > 0 ? _toggleRecording : null,
                  backgroundColor: _isRecording
                      ? Colors.white
                      : (state.attemptsLeft > 0 ? Colors.red : Colors.grey),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.videocam,
                    color: _isRecording ? Colors.red : Colors.white,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Chip(
                  label: Text('Intentos: ${state.attemptsLeft}'),
                  backgroundColor: Colors.black.withOpacity(0.5),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
