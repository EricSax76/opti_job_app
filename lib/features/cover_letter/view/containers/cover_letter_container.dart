import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/features/cover_letter/bloc/cover_letter_bloc.dart';
import 'package:opti_job_app/features/cover_letter/repositories/cover_letter_repository.dart';
import 'package:opti_job_app/features/cover_letter/view/widgets/cover_letter_content.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_cubit.dart';

class CoverLetterContainer extends StatefulWidget {
  const CoverLetterContainer({super.key});

  @override
  State<CoverLetterContainer> createState() => _CoverLetterContainerState();
}

class _CoverLetterContainerState extends State<CoverLetterContainer> {
  final _coverLetterController = TextEditingController();
  late final CoverLetterBloc _bloc;
  String? _lastAppliedImprovedCoverLetter;

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
    _bloc.add(LoadCoverLetterRequested());
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _improveWithAI() {
    final currentText = _coverLetterController.text.trim();
    final locale = Localizations.localeOf(context).toLanguageTag();
    _bloc.add(ImproveCoverLetterRequested(currentText, locale: locale));
  }

  void _save() {
    _bloc.add(SaveCoverLetterRequested(_coverLetterController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<CoverLetterBloc, CoverLetterState>(
        listenWhen: (previous, current) {
          return previous.status != current.status ||
              previous.savedCoverLetterText != current.savedCoverLetterText ||
              previous.improvedCoverLetter != current.improvedCoverLetter ||
              previous.error != current.error;
        },
        listener: _handleStateEffects,
        child: BlocBuilder<CoverLetterBloc, CoverLetterState>(
          buildWhen: (previous, current) =>
              previous.status != current.status ||
              previous.savedCoverLetterText != current.savedCoverLetterText,
          builder: (context, state) {
            return CoverLetterContent(
              controller: _coverLetterController,
              isLoading: state.status == CoverLetterStatus.loading,
              isImproving: state.status == CoverLetterStatus.improving,
              onImprove: _improveWithAI,
              onSave: _save,
            );
          },
        ),
      ),
    );
  }

  void _handleStateEffects(BuildContext context, CoverLetterState state) {
    final improvedCoverLetter = state.improvedCoverLetter;
    if (improvedCoverLetter == null) {
      _lastAppliedImprovedCoverLetter = null;
    } else if (improvedCoverLetter != _lastAppliedImprovedCoverLetter) {
      _coverLetterController.value = TextEditingValue(
        text: improvedCoverLetter,
        selection: TextSelection.collapsed(offset: improvedCoverLetter.length),
      );
      _lastAppliedImprovedCoverLetter = improvedCoverLetter;
    }

    if (state.savedCoverLetterText != null &&
        _coverLetterController.text.trim().isEmpty) {
      _coverLetterController.text = state.savedCoverLetterText!;
    }

    if (state.status == CoverLetterStatus.failure && state.error != null) {
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.error!,
            style: TextStyle(color: colorScheme.onError),
          ),
          backgroundColor: colorScheme.error,
        ),
      );
    }

    if (state.status == CoverLetterStatus.saving) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Guardando...')));
    }
  }
}
