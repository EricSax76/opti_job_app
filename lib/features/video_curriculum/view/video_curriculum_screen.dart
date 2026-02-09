import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/features/video_curriculum/bloc/video_curriculum_bloc.dart';
import 'package:opti_job_app/features/video_curriculum/repositories/video_curriculum_repository.dart';
import 'package:opti_job_app/features/video_curriculum/view/video_curriculum_screen_controller.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/camera_view.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/video_curriculum_status_cards.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';

class VideoCurriculumScreen extends StatefulWidget {
  const VideoCurriculumScreen({super.key});

  @override
  State<VideoCurriculumScreen> createState() => _VideoCurriculumScreenState();
}

class _VideoCurriculumScreenState extends State<VideoCurriculumScreen>
    with AutomaticKeepAliveClientMixin {
  late final VideoCurriculumScreenController _screenController;

  @override
  void initState() {
    super.initState();
    _screenController = VideoCurriculumScreenController(
      videoCurriculumRepository: context.read<VideoCurriculumRepository>(),
      candidateUidProvider: () =>
          context.read<CandidateAuthCubit>().state.candidate?.uid,
    );
  }

  @override
  void dispose() {
    _screenController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(
      value: _screenController.bloc,
      child: BlocListener<VideoCurriculumBloc, VideoCurriculumState>(
        listenWhen: _screenController.shouldListenWhen,
        listener: _screenController.onBlocStateChanged,
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
                const _CameraViewContainer(),
                const SizedBox(height: 16),
                const UploadedVideoStatusCard(),
                const SizedBox(height: 12),
                const RecordedVideoStatusCard(),
                const SizedBox(height: 12),
                _SaveVideoButton(onSave: _screenController.save),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CameraViewContainer extends StatelessWidget {
  const _CameraViewContainer();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
    );
  }
}

class _SaveVideoButton extends StatelessWidget {
  const _SaveVideoButton({required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoCurriculumBloc, VideoCurriculumState>(
      builder: (context, state) {
        final canSave = state.recordedVideoPath != null;
        return ElevatedButton(
          onPressed: canSave ? onSave : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Guardar video'),
        );
      },
    );
  }
}
