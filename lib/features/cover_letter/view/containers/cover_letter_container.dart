import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/features/cover_letter/bloc/cover_letter_bloc.dart';
import 'package:opti_job_app/features/cover_letter/logic/cover_letter_logic.dart';
import 'package:opti_job_app/features/cover_letter/repositories/cover_letter_repository.dart';
import 'package:opti_job_app/features/cover_letter/view/controllers/cover_letter_controller.dart';
import 'package:opti_job_app/features/cover_letter/view/widgets/cover_letter_content.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_cubit.dart';

class CoverLetterContainer extends StatefulWidget {
  const CoverLetterContainer({super.key});

  @override
  State<CoverLetterContainer> createState() => _CoverLetterContainerState();
}

class _CoverLetterContainerState extends State<CoverLetterContainer> {
  late final CoverLetterBloc _bloc;
  late final CoverLetterController _controller;

  @override
  void initState() {
    super.initState();
    _bloc = CoverLetterBloc(
      aiRepository: context.read<AiRepository>(),
      coverLetterRepository: context.read<CoverLetterRepository>(),
      curriculumProvider: () =>
          context.read<CurriculumCubit>().state.curriculum,
      candidateUidProvider: () =>
          context.read<CandidateAuthCubit>().state.candidate?.uid,
    );
    _controller = CoverLetterController(bloc: _bloc);
    _controller.loadCoverLetter();
  }

  @override
  void dispose() {
    _controller.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<CoverLetterBloc, CoverLetterState>(
        listenWhen: CoverLetterLogic.shouldListenWhen,
        listener: _controller.onStateChanged,
        child: BlocBuilder<CoverLetterBloc, CoverLetterState>(
          buildWhen: CoverLetterLogic.shouldBuildWhen,
          builder: (context, state) {
            final viewModel = CoverLetterLogic.buildViewModel(state);
            return CoverLetterContent(
              controller: _controller.textController,
              viewModel: viewModel,
              onImprove: () => _controller.improveWithAI(context),
              onSave: _controller.save,
            );
          },
        ),
      ),
    );
  }
}
