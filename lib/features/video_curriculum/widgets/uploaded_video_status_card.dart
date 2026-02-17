import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/features/video_curriculum/logic/uploaded_video_status_logic.dart';
import 'package:opti_job_app/features/video_curriculum/view/controllers/uploaded_video_status_controller.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/inline_video_preview.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/video_curriculum_playback_helpers.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';

class UploadedVideoStatusCardContainer extends StatelessWidget {
  const UploadedVideoStatusCardContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final uploadedVideo = context.select(
      (ProfileCubit cubit) => cubit.state.candidate?.videoCurriculum,
    );
    return UploadedVideoStatusCard(video: uploadedVideo);
  }
}

class UploadedVideoStatusCard extends StatefulWidget {
  const UploadedVideoStatusCard({super.key, required this.video});

  final CandidateVideoCurriculum? video;

  @override
  State<UploadedVideoStatusCard> createState() =>
      _UploadedVideoStatusCardState();
}

class _UploadedVideoStatusCardState extends State<UploadedVideoStatusCard> {
  Future<String?>? _downloadUrlFuture;

  @override
  void initState() {
    super.initState();
    _syncDownloadUrlFuture();
  }

  @override
  void didUpdateWidget(covariant UploadedVideoStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldStoragePath = UploadedVideoStatusLogic.resolveStoragePath(
      oldWidget.video,
    );
    final newStoragePath = UploadedVideoStatusLogic.resolveStoragePath(
      widget.video,
    );
    if (oldStoragePath == newStoragePath) return;
    _syncDownloadUrlFuture();
  }

  void _syncDownloadUrlFuture() {
    final storagePath = UploadedVideoStatusLogic.resolveStoragePath(
      widget.video,
    );
    _downloadUrlFuture = UploadedVideoStatusController.loadDownloadUrl(
      storagePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = UploadedVideoStatusLogic.buildViewModel(widget.video);

    if (!viewModel.hasUploadedVideo) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_off_outlined),
                  const SizedBox(width: 8),
                  Text(
                    viewModel.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(viewModel.description),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<String?>(
      future: _downloadUrlFuture,
      builder: (context, snapshot) {
        final uri = UploadedVideoStatusLogic.parseDownloadUri(snapshot.data);
        final canPlay = uri != null;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_done_outlined),
                    const SizedBox(width: 8),
                    Text(
                      viewModel.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (canPlay)
                      IconButton(
                        tooltip: 'Ver',
                        icon: const Icon(Icons.play_circle_outline),
                        onPressed: () => openVideoPlayer(
                          context,
                          uri,
                          title: 'Videocurrículum',
                          allowExternalFallback: true,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(viewModel.description),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'No se pudo cargar el enlace del vídeo (verifica permisos).',
                    ),
                  )
                else if (canPlay) ...[
                  const SizedBox(height: 12),
                  InlineVideoPreview(
                    uri: uri,
                    onOpen: () => openVideoPlayer(
                      context,
                      uri,
                      title: 'Videocurrículum',
                      allowExternalFallback: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
