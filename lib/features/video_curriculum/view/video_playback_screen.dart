import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:opti_job_app/features/video_curriculum/view/video_playback_controller.dart';

class VideoPlaybackScreen extends StatefulWidget {
  const VideoPlaybackScreen({
    super.key,
    required this.uri,
    this.title,
    this.allowExternalFallback = true,
  });

  final Uri uri;
  final String? title;
  final bool allowExternalFallback;

  @override
  State<VideoPlaybackScreen> createState() => _VideoPlaybackScreenState();
}

class _VideoPlaybackScreenState extends State<VideoPlaybackScreen> {
  late final VideoPlayerController _controller;
  Future<void>? _initializeFuture;
  Object? _initError;
  var _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = createVideoController(widget.uri);
    _initializeFuture = _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          _controller.setLooping(true);
          setState(() {});
        })
        .catchError((Object error) {
          _initError = error;
          if (mounted) setState(() {});
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (!_controller.value.isInitialized) return;
    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
    if (!mounted) return;
    setState(() => _isPlaying = _controller.value.isPlaying);
  }

  Future<void> _openExternal() async {
    if (!widget.allowExternalFallback) return;
    if (widget.uri.scheme == 'file' || widget.uri.scheme.isEmpty) return;
    final ok = await launchUrl(
      widget.uri,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir en una app externa.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? 'Reproducir vídeo';
    final colorScheme = Theme.of(context).colorScheme;
    final canOpenExternal =
        widget.allowExternalFallback &&
        widget.uri.scheme.isNotEmpty &&
        widget.uri.scheme != 'file';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (canOpenExternal)
            IconButton(
              tooltip: 'Abrir en app externa',
              onPressed: _openExternal,
              icon: const Icon(Icons.open_in_new),
            ),
        ],
      ),
      body: Center(
        child: FutureBuilder<void>(
          future: _initializeFuture,
          builder: (context, snapshot) {
            final hasError = _initError != null || snapshot.hasError;
            if (hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 42),
                    const SizedBox(height: 12),
                    const Text(
                      'No se pudo reproducir el vídeo dentro de la app.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (canOpenExternal)
                      FilledButton.icon(
                        onPressed: _openExternal,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Abrir en app externa'),
                      ),
                  ],
                ),
              );
            }

            if (!_controller.value.isInitialized) {
              return const CircularProgressIndicator();
            }

            return GestureDetector(
              onTap: _togglePlay,
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    AnimatedOpacity(
                      opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: colorScheme.secondary,
                          size: 42,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: colorScheme.secondary,
                          bufferedColor: colorScheme.onSurface.withValues(
                            alpha: 0.35,
                          ),
                          backgroundColor: colorScheme.onSurface.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _controller.value.isInitialized
          ? FloatingActionButton(
              heroTag: null,
              onPressed: _togglePlay,
              child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            )
          : null,
    );
  }
}
