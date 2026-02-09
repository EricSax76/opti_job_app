import 'package:flutter/material.dart';
import 'package:opti_job_app/features/video_curriculum/view/video_playback_controller.dart';
import 'package:video_player/video_player.dart';

class InlineVideoPreview extends StatefulWidget {
  const InlineVideoPreview({
    super.key,
    required this.uri,
    required this.onOpen,
  });

  final Uri uri;
  final VoidCallback onOpen;

  @override
  State<InlineVideoPreview> createState() => _InlineVideoPreviewState();
}

class _InlineVideoPreviewState extends State<InlineVideoPreview> {
  late final VideoPlayerController _controller;
  Future<void>? _initializeFuture;
  var _hasInitializeError = false;

  @override
  void initState() {
    super.initState();
    _controller = createVideoController(widget.uri);
    _initializeFuture = _controller
        .initialize()
        .then((_) async {
          if (!mounted) return;
          await _controller.pause();
          if (mounted) setState(() {});
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() {
            _hasInitializeError = true;
          });
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Material(
          color: colorScheme.surfaceContainerHighest,
          child: InkWell(
            onTap: widget.onOpen,
            child: FutureBuilder<void>(
              future: _initializeFuture,
              builder: (context, snapshot) {
                if (_hasInitializeError) {
                  return Center(
                    child: Text(
                      'No se pudo cargar la vista previa del vídeo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  );
                }

                final initialized = _controller.value.isInitialized;
                if (!initialized) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.onSurface,
                    ),
                  );
                }

                return Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    Container(color: colorScheme.scrim.withValues(alpha: 0.2)),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.75),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: colorScheme.secondary,
                        size: 34,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
