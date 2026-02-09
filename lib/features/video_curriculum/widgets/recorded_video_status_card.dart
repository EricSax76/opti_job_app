import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/features/video_curriculum/bloc/video_curriculum_bloc.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/inline_video_preview.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/video_curriculum_playback_helpers.dart';

class RecordedVideoStatusCard extends StatelessWidget {
  const RecordedVideoStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final recordedPath = context.select(
      (VideoCurriculumBloc bloc) => bloc.state.recordedVideoPath,
    );

    final safePath = recordedPath ?? '';
    final hasRecorded = safePath.trim().isNotEmpty;
    final fileName = hasRecorded ? safePath.split('/').last : null;
    final localUri = hasRecorded ? buildLocalVideoUri(safePath) : null;
    final canPlayLocalVideo = hasRecorded && localUri != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  hasRecorded
                      ? Icons.videocam_outlined
                      : Icons.videocam_off_outlined,
                ),
                const SizedBox(width: 8),
                Text(
                  hasRecorded
                      ? 'Vídeo grabado (local)'
                      : 'Aún no grabaste un vídeo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (canPlayLocalVideo)
                  IconButton(
                    tooltip: 'Ver',
                    icon: const Icon(Icons.play_circle_outline),
                    onPressed: () => openVideoPlayer(
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
            if (canPlayLocalVideo) ...[
              const SizedBox(height: 12),
              InlineVideoPreview(
                uri: localUri,
                onOpen: () => openVideoPlayer(
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
