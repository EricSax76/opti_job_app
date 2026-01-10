import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/features/cover_letter/bloc/cover_letter_bloc.dart';
import 'package:opti_job_app/features/cover_letter/widgets/camera_view.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubit/curriculum_cubit.dart';

class VideoCurriculumScreen extends StatefulWidget {
  const VideoCurriculumScreen({super.key});

  @override
  State<VideoCurriculumScreen> createState() => _VideoCurriculumScreenState();
}

class _VideoCurriculumScreenState extends State<VideoCurriculumScreen> {
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

  void _save() {
    _bloc.add(const SaveCoverLetterAndVideo(''));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<CoverLetterBloc, CoverLetterState>(
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
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Videocurrículum')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    child: CameraView(),
                  ),
                ),
                const SizedBox(height: 16),
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
            ),
          ),
        ),
      ),
    );
  }
}
