import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/features/video_curriculum/bloc/video_curriculum_bloc.dart';
import 'package:opti_job_app/features/video_curriculum/logic/video_curriculum_logic.dart';
import 'package:opti_job_app/features/video_curriculum/repositories/video_curriculum_repository.dart';
import 'package:opti_job_app/features/video_curriculum/view/video_curriculum_screen_controller.dart';
import 'package:opti_job_app/features/video_curriculum/view/widgets/video_curriculum_content.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/recorded_video_status_card.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/uploaded_video_status_card.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';

class VideoCurriculumContainer extends StatefulWidget {
  const VideoCurriculumContainer({super.key});

  @override
  State<VideoCurriculumContainer> createState() =>
      _VideoCurriculumContainerState();
}

class _VideoCurriculumContainerState extends State<VideoCurriculumContainer>
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
        child: BlocBuilder<VideoCurriculumBloc, VideoCurriculumState>(
          buildWhen: VideoCurriculumLogic.shouldRebuildContent,
          builder: (context, state) {
            final viewModel = VideoCurriculumLogic.buildViewModel(state);
            return VideoCurriculumContent(
              viewModel: viewModel,
              onSave: _screenController.save,
              uploadedStatusCard: const UploadedVideoStatusCardContainer(),
              recordedStatusCard: const RecordedVideoStatusCardContainer(),
            );
          },
        ),
      ),
    );
  }
}
