import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/features/cover_letter/bloc/cover_letter_bloc.dart';
import 'package:opti_job_app/features/cover_letter/widgets/camera_view.dart';
import 'package:opti_job_app/features/cover_letter/view/video_playback_screen.dart';
import 'package:opti_job_app/features/cover_letter/view/video_playback_controller.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubit/curriculum_cubit.dart';
import 'package:opti_job_app/modules/profiles/cubit/profile_cubit.dart';
import 'package:video_player/video_player.dart';

class VideoCurriculumScreen extends StatefulWidget {
  const VideoCurriculumScreen({super.key});

  @override
  State<VideoCurriculumScreen> createState() => _VideoCurriculumScreenState();
}

class _VideoCurriculumScreenState extends State<VideoCurriculumScreen>
    with AutomaticKeepAliveClientMixin {
  late final CoverLetterBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = CoverLetterBloc(
      aiRepository: context.read<AiRepository>(),
      curriculumProvider: () => context.read<CurriculumCubit>().state.curriculum,
      candidateUidProvider: () =>
          context.read<CandidateAuthCubit>().state.candidate?.uid,
    );
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _save() {
    _bloc.add(const SaveCoverLetterAndVideo(''));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<CoverLetterBloc, CoverLetterState>(
        listenWhen: (previous, current) {
          if (previous.status == current.status) return false;
          if (current.status == CoverLetterStatus.uploading) return true;
          if (current.status == CoverLetterStatus.failure) return true;
          return previous.status == CoverLetterStatus.uploading &&
              current.status == CoverLetterStatus.success;
        },
        listener: (context, state) {
          if (state.status == CoverLetterStatus.failure && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }

          if (state.status == CoverLetterStatus.uploading) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Guardando...')));
          }

          if (state.status == CoverLetterStatus.success) {
            context.read<ProfileCubit>().refreshProfile();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Vídeo guardado.')));
          }
        },
        child: Builder(
          builder: (context) {
            final bottomPadding = MediaQuery.paddingOf(context).bottom;
            return ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding + 96),
              children: [
                Text(
                  'Videocurrículum',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final desiredHeight = width * (4 / 3);
                    final height = desiredHeight.clamp(240.0, 420.0);
                    return SizedBox(
                      height: height,
                      child: const ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        child: CameraView(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const _UploadedVideoStatus(),
                const SizedBox(height: 12),
                const _RecordedVideoStatus(),
                const SizedBox(height: 12),
                BlocBuilder<CoverLetterBloc, CoverLetterState>(
                  builder: (context, state) {
                    final canSave = state.recordedVideoPath != null;
                    return ElevatedButton(
                      onPressed: canSave ? _save : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Guardar video'),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UploadedVideoStatus extends StatelessWidget {
  const _UploadedVideoStatus();

  @override
  Widget build(BuildContext context) {
    final candidate = context.watch<ProfileCubit>().state.candidate;
    final video = candidate?.videoCurriculum;
    final hasUploaded = video != null && video.downloadUrl.trim().isNotEmpty;
    final url = hasUploaded ? Uri.tryParse(video.downloadUrl.trim()) : null;
    final canPlay = hasUploaded && url != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  hasUploaded ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasUploaded
                        ? 'Videocurrículum subido'
                        : 'Sin videocurrículum subido',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (canPlay)
                  IconButton(
                    tooltip: 'Ver',
                    icon: const Icon(Icons.play_circle_outline),
                    onPressed: () => _openPlayer(
                      context,
                      url,
                      title: 'Videocurrículum',
                      allowExternalFallback: true,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasUploaded
                  ? 'Tamaño: ${_formatBytes(video.sizeBytes)}'
                  : 'Graba y guarda un vídeo para que quede asociado a tu perfil.',
            ),
            if (canPlay) ...[
              const SizedBox(height: 12),
              _InlineVideoPreview(
                uri: url,
                onOpen: () => _openPlayer(
                  context,
                  url,
                  title: 'Videocurrículum',
                  allowExternalFallback: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecordedVideoStatus extends StatelessWidget {
  const _RecordedVideoStatus();

  @override
  Widget build(BuildContext context) {
    final recordedPath = context.select(
      (CoverLetterBloc bloc) => bloc.state.recordedVideoPath,
    );
    final safePath = recordedPath ?? '';
    final hasRecorded = safePath.trim().isNotEmpty;
    final fileName = hasRecorded ? safePath.split('/').last : null;
    final localUri = hasRecorded ? Uri.file(safePath) : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  hasRecorded ? Icons.videocam_outlined : Icons.videocam_off_outlined,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasRecorded
                        ? 'Vídeo grabado (local)'
                        : 'Aún no grabaste un vídeo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (hasRecorded && localUri != null)
                  IconButton(
                    tooltip: 'Ver',
                    icon: const Icon(Icons.play_circle_outline),
                    onPressed: () => _openPlayer(
                      context,
                      localUri,
                      title: 'Vídeo (local)',
                      allowExternalFallback: false,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasRecorded
                  ? (fileName ?? safePath)
                  : 'Pulsa el botón rojo para empezar a grabar.',
            ),
            if (hasRecorded && localUri != null) ...[
              const SizedBox(height: 12),
              _InlineVideoPreview(
                uri: localUri,
                onOpen: () => _openPlayer(
                  context,
                  localUri,
                  title: 'Vídeo (local)',
                  allowExternalFallback: false,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _openPlayer(
  BuildContext context,
  Uri uri, {
  required String title,
  required bool allowExternalFallback,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => VideoPlaybackScreen(
        uri: uri,
        title: title,
        allowExternalFallback: allowExternalFallback,
      ),
    ),
  );
}

class _InlineVideoPreview extends StatefulWidget {
  const _InlineVideoPreview({required this.uri, required this.onOpen});

  final Uri uri;
  final VoidCallback onOpen;

  @override
  State<_InlineVideoPreview> createState() => _InlineVideoPreviewState();
}

class _InlineVideoPreviewState extends State<_InlineVideoPreview> {
  late final VideoPlayerController _controller;
  Future<void>? _initializeFuture;

  @override
  void initState() {
    super.initState();
    _controller = createVideoController(widget.uri);
    _initializeFuture = _controller.initialize().then((_) async {
      if (!mounted) return;
      await _controller.pause();
      if (mounted) setState(() {});
    }).catchError((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Material(
          color: Colors.black,
          child: InkWell(
            onTap: widget.onOpen,
            child: FutureBuilder<void>(
              future: _initializeFuture,
              builder: (context, snapshot) {
                final initialized = _controller.value.isInitialized;
                if (!initialized) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
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
                    Container(color: Colors.black.withValues(alpha: 0.2)),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
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

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  double size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  final value = unitIndex == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
  return '$value ${units[unitIndex]}';
}
