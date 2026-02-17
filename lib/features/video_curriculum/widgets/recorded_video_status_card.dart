import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/features/video_curriculum/bloc/video_curriculum_bloc.dart';
import 'package:opti_job_app/features/video_curriculum/logic/recorded_video_status_logic.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/inline_video_preview.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/video_curriculum_playback_helpers.dart';

class RecordedVideoStatusCardContainer extends StatelessWidget {
  const RecordedVideoStatusCardContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final recordedPath = context.select(
      (VideoCurriculumBloc bloc) => bloc.state.recordedVideoPath,
    );
    return RecordedVideoStatusCard(recordedPath: recordedPath);
  }
}

class RecordedVideoStatusCard extends StatelessWidget {
  const RecordedVideoStatusCard({super.key, required this.recordedPath});

  final String? recordedPath;

  @override
  Widget build(BuildContext context) {
    final viewModel = RecordedVideoStatusLogic.buildViewModel(recordedPath);
    final playbackUri = viewModel.playbackUri;
    final canPlayLocalVideo = viewModel.canPlay;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  viewModel.hasRecordedVideo
                      ? Icons.videocam_outlined
                      : Icons.videocam_off_outlined,
                ),
                const SizedBox(width: 8),
                Text(
                  viewModel.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (canPlayLocalVideo)
                  IconButton(
                    tooltip: 'Ver',
                    icon: const Icon(Icons.play_circle_outline),
                    onPressed: () => openVideoPlayer(
                      context,
                      playbackUri!,
                      title: 'Vídeo (local)',
                      allowExternalFallback: false,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(viewModel.description),
            if (canPlayLocalVideo) ...[
              const SizedBox(height: 12),
              InlineVideoPreview(
                uri: playbackUri!,
                onOpen: () => openVideoPlayer(
                  context,
                  playbackUri,
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
