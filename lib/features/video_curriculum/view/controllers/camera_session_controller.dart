import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

enum CameraToggleResultType { started, stopped, noAttemptsLeft, ignored, error }

class CameraToggleResult {
  const CameraToggleResult._(this.type, {this.recordedPath, this.errorMessage});

  const CameraToggleResult.started() : this._(CameraToggleResultType.started);

  const CameraToggleResult.stopped(String path)
    : this._(CameraToggleResultType.stopped, recordedPath: path);

  const CameraToggleResult.noAttemptsLeft()
    : this._(CameraToggleResultType.noAttemptsLeft);

  const CameraToggleResult.ignored() : this._(CameraToggleResultType.ignored);

  const CameraToggleResult.error(String message)
    : this._(CameraToggleResultType.error, errorMessage: message);

  final CameraToggleResultType type;
  final String? recordedPath;
  final String? errorMessage;
}

class CameraSessionController extends ChangeNotifier {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  bool _isInitializing = false;
  bool _isToggling = false;
  String? _cameraError;
  Timer? _autoStopTimer;
  void Function(String path)? _onRecordingStopped;

  CameraController? get cameraController => _cameraController;
  bool get isCameraInitialized => _isCameraInitialized;
  bool get isRecording => _isRecording;
  bool get isInitializing => _isInitializing;
  bool get isCameraReady => _isCameraInitialized && _cameraController != null;
  String? get cameraError => _cameraError;

  Future<void> initializeCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;
    _cameraError = null;
    notifyListeners();

    try {
      await _disposeControllerInternal();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _cameraError = 'No se encontró ninguna cámara disponible.';
        notifyListeners();
        return;
      }

      final firstCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      _cameraController = controller;

      await controller.initialize();
      _isCameraInitialized = true;
      _cameraError = null;
      notifyListeners();
    } on CameraException catch (error) {
      await _disposeControllerInternal();
      _cameraError = _cameraErrorMessage(error.code);
      notifyListeners();
    } catch (_) {
      await _disposeControllerInternal();
      _cameraError =
          'No se pudo inicializar la cámara. Revisa permisos e inténtalo de nuevo.';
      notifyListeners();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<CameraToggleResult> toggleRecording({
    required int attemptsLeft,
    required void Function(String path) onRecordingStopped,
  }) async {
    if (_isToggling || !isCameraReady) {
      return const CameraToggleResult.ignored();
    }

    _isToggling = true;
    try {
      if (_isRecording) {
        return await _stopRecordingInternal();
      }

      if (attemptsLeft <= 0) {
        return const CameraToggleResult.noAttemptsLeft();
      }

      _onRecordingStopped = onRecordingStopped;
      await _cameraController!.startVideoRecording();
      _isRecording = true;
      _scheduleAutoStop();
      notifyListeners();
      return const CameraToggleResult.started();
    } on CameraException catch (error) {
      _isRecording = false;
      notifyListeners();
      return CameraToggleResult.error(_cameraErrorMessage(error.code));
    } catch (_) {
      _isRecording = false;
      notifyListeners();
      return const CameraToggleResult.error(
        'No se pudo iniciar o detener la grabación.',
      );
    } finally {
      _isToggling = false;
    }
  }

  void _scheduleAutoStop() {
    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(const Duration(seconds: 60), () {
      if (!_isRecording) return;
      unawaited(_stopRecordingInternal(fromAutoStop: true));
    });
  }

  Future<CameraToggleResult> _stopRecordingInternal({
    bool fromAutoStop = false,
  }) async {
    if (!isCameraReady) {
      return const CameraToggleResult.ignored();
    }

    _autoStopTimer?.cancel();
    _autoStopTimer = null;

    final file = await _cameraController!.stopVideoRecording();
    _isRecording = false;
    notifyListeners();

    final recordedPath = file.path;
    _onRecordingStopped?.call(recordedPath);
    await _disposeControllerInternal();

    if (fromAutoStop) {
      notifyListeners();
    }
    return CameraToggleResult.stopped(recordedPath);
  }

  Future<void> disposeCamera() async {
    await _disposeControllerInternal();
    notifyListeners();
  }

  Future<void> _disposeControllerInternal() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _onRecordingStopped = null;

    final controller = _cameraController;
    _cameraController = null;
    _isCameraInitialized = false;
    _isRecording = false;

    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {
        // Ignorar: puede fallar si el controlador ya se liberó.
      }
    }
  }

  String _cameraErrorMessage(String code) {
    switch (code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return 'No se concedió permiso para usar la cámara.';
      case 'AudioAccessDenied':
      case 'AudioAccessDeniedWithoutPrompt':
      case 'AudioAccessRestricted':
        return 'No se concedió permiso para usar el micrófono.';
      default:
        return 'No se pudo inicializar la cámara. Revisa permisos e inténtalo de nuevo.';
    }
  }

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    final controller = _cameraController;
    _cameraController = null;
    _isCameraInitialized = false;
    _isRecording = false;
    _onRecordingStopped = null;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }
}
