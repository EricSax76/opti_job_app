import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/features/video_curriculum/view/models/video_curriculum_view_model.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/camera_view.dart';

class VideoCurriculumContent extends StatelessWidget {
  const VideoCurriculumContent({
    super.key,
    required this.viewModel,
    required this.onSave,
    required this.uploadedStatusCard,
    required this.recordedStatusCard,
  });

  final VideoCurriculumViewModel viewModel;
  final VoidCallback onSave;
  final Widget uploadedStatusCard;
  final Widget recordedStatusCard;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        uiSpacing16,
        uiSpacing16,
        uiSpacing16,
        uiSpacing16 + bottomPadding + (uiSpacing48 * 2),
      ),
      children: [
        Text(
          'Videocurrículum',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: uiSpacing12),
        const _CameraViewContainer(),
        const SizedBox(height: uiSpacing16),
        uploadedStatusCard,
        const SizedBox(height: uiSpacing12),
        recordedStatusCard,
        const SizedBox(height: uiSpacing12),
        ElevatedButton(
          onPressed: viewModel.hasRecordedVideo ? onSave : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: uiSpacing16),
          ),
          child: const Text('Guardar video'),
        ),
      ],
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
            borderRadius: BorderRadius.all(Radius.circular(uiTileRadius)),
            child: CameraView(),
          ),
        );
      },
    );
  }
}
