import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class CameraRecordedVideoView extends StatelessWidget {
  const CameraRecordedVideoView({
    super.key,
    required this.attemptsLeft,
    this.onRetry,
  });

  final int attemptsLeft;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam, color: colorScheme.onSurface, size: 64),
          const SizedBox(height: uiSpacing16),
          Text(
            'Vídeo grabado. Quedan $attemptsLeft intentos.',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: uiSpacing16),
          if (onRetry != null)
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Grabar de nuevo'),
            ),
        ],
      ),
    );
  }
}

class CameraLivePreviewView extends StatelessWidget {
  const CameraLivePreviewView({
    super.key,
    required this.controller,
    required this.attemptsLeft,
    required this.hasAttemptsLeft,
    required this.isRecording,
    required this.onToggleRecording,
  });

  final CameraController controller;
  final int attemptsLeft;
  final bool hasAttemptsLeft;
  final bool isRecording;
  final VoidCallback onToggleRecording;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fabBackgroundColor = isRecording
        ? colorScheme.surface
        : (hasAttemptsLeft
              ? colorScheme.error
              : colorScheme.surfaceContainerHighest);
    final fabForegroundColor = isRecording
        ? colorScheme.error
        : (hasAttemptsLeft
              ? colorScheme.onError
              : colorScheme.onSurfaceVariant);

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(uiSpacing24),
            child: FloatingActionButton(
              heroTag: null,
              onPressed: hasAttemptsLeft ? onToggleRecording : null,
              backgroundColor: fabBackgroundColor,
              foregroundColor: fabForegroundColor,
              child: Icon(isRecording ? Icons.stop : Icons.videocam),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(uiSpacing16),
            child: Chip(
              label: Text('Intentos: $attemptsLeft'),
              backgroundColor: colorScheme.surface.withValues(alpha: 0.85),
              labelStyle: TextStyle(color: colorScheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}

class CameraErrorView extends StatelessWidget {
  const CameraErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(uiSpacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off, color: colorScheme.error, size: 56),
            const SizedBox(height: uiSpacing12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: uiSpacing12),
            ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
