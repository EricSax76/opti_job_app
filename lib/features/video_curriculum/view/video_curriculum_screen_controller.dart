import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/features/video_curriculum/bloc/video_curriculum_bloc.dart';
import 'package:opti_job_app/features/video_curriculum/repositories/video_curriculum_repository.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';

typedef CandidateUidProvider = String? Function();

class VideoCurriculumScreenController {
  VideoCurriculumScreenController({
    required VideoCurriculumRepository videoCurriculumRepository,
    required CandidateUidProvider candidateUidProvider,
  }) : bloc = VideoCurriculumBloc(
         videoCurriculumRepository: videoCurriculumRepository,
         candidateUidProvider: candidateUidProvider,
       );

  final VideoCurriculumBloc bloc;

  void save() {
    bloc.add(const SaveVideoCurriculumRequested());
  }

  bool shouldListenWhen(
    VideoCurriculumState previous,
    VideoCurriculumState current,
  ) {
    if (previous.status == current.status) return false;
    if (current.status == VideoCurriculumStatus.uploading) return true;
    if (current.status == VideoCurriculumStatus.failure) return true;
    return previous.status == VideoCurriculumStatus.uploading &&
        current.status == VideoCurriculumStatus.success;
  }

  void onBlocStateChanged(BuildContext context, VideoCurriculumState state) {
    if (state.status == VideoCurriculumStatus.failure && state.error != null) {
      final colorScheme = Theme.of(context).colorScheme;
      _showSnackBar(
        context,
        SnackBar(
          content: Text(
            state.error!,
            style: TextStyle(color: colorScheme.onError),
          ),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }

    if (state.status == VideoCurriculumStatus.uploading) {
      _showSnackBar(context, const SnackBar(content: Text('Guardando...')));
      return;
    }

    if (state.status == VideoCurriculumStatus.success) {
      context.read<ProfileCubit>().refreshProfile();
      _showSnackBar(context, const SnackBar(content: Text('Vídeo guardado.')));
    }
  }

  void _showSnackBar(BuildContext context, SnackBar snackBar) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(snackBar);
  }

  void dispose() {
    bloc.close();
  }
}
