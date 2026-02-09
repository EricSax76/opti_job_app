import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/inline_video_preview.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/video_curriculum_playback_helpers.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';

class UploadedVideoStatusCard extends StatelessWidget {
  const UploadedVideoStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final candidate = context.watch<ProfileCubit>().state.candidate;
    final video = candidate?.videoCurriculum;
    final storagePath = video?.storagePath.trim() ?? '';
    final hasUploaded = storagePath.isNotEmpty;

    if (!hasUploaded || video == null) {
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
                    'Sin videocurrículum subido',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Graba y guarda un vídeo para que quede asociado a tu perfil.',
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<String>(
      future: FirebaseStorage.instance
          .ref()
          .child(storagePath)
          .getDownloadURL(),
      builder: (context, snapshot) {
        final downloadUrl = snapshot.data?.trim();
        final uri = (downloadUrl == null || downloadUrl.isEmpty)
            ? null
            : Uri.tryParse(downloadUrl);
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
                      'Videocurrículum subido',
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
                Text('Tamaño: ${formatBytes(video.sizeBytes)}'),
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
