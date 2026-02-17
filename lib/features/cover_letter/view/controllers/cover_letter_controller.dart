import 'package:flutter/material.dart';
import 'package:opti_job_app/features/cover_letter/bloc/cover_letter_bloc.dart';
import 'package:opti_job_app/features/cover_letter/logic/cover_letter_logic.dart';

class CoverLetterController {
  CoverLetterController({required CoverLetterBloc bloc})
    : _bloc = bloc,
      textController = TextEditingController();

  final CoverLetterBloc _bloc;
  final TextEditingController textController;
  String? _lastAppliedImprovedCoverLetter;

  void loadCoverLetter() {
    _bloc.add(LoadCoverLetterRequested());
  }

  void improveWithAI(BuildContext context) {
    final currentText = textController.text.trim();
    final locale = Localizations.localeOf(context).toLanguageTag();
    _bloc.add(ImproveCoverLetterRequested(currentText, locale: locale));
  }

  void save() {
    _bloc.add(SaveCoverLetterRequested(textController.text.trim()));
  }

  void onStateChanged(BuildContext context, CoverLetterState state) {
    _syncImprovedCoverLetter(state);
    _hydrateSavedCoverLetter(state);

    final failureMessage = CoverLetterLogic.failureMessage(state);
    if (failureMessage != null) {
      final colorScheme = Theme.of(context).colorScheme;
      _showSnackBar(
        context,
        SnackBar(
          content: Text(
            failureMessage,
            style: TextStyle(color: colorScheme.onError),
          ),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }

    if (CoverLetterLogic.shouldShowSavingFeedback(state)) {
      _showSnackBar(context, const SnackBar(content: Text('Guardando...')));
    }
  }

  void _syncImprovedCoverLetter(CoverLetterState state) {
    if (CoverLetterLogic.shouldResetImprovedTracking(state)) {
      _lastAppliedImprovedCoverLetter = null;
      return;
    }

    final improvedCoverLetter = CoverLetterLogic.improvedCoverLetterToApply(
      state,
      _lastAppliedImprovedCoverLetter,
    );
    if (improvedCoverLetter == null) return;

    textController.value = TextEditingValue(
      text: improvedCoverLetter,
      selection: TextSelection.collapsed(offset: improvedCoverLetter.length),
    );
    _lastAppliedImprovedCoverLetter = improvedCoverLetter;
  }

  void _hydrateSavedCoverLetter(CoverLetterState state) {
    final savedCoverLetterText = CoverLetterLogic.savedCoverLetterTextToHydrate(
      state: state,
      currentText: textController.text,
    );
    if (savedCoverLetterText == null) return;
    textController.text = savedCoverLetterText;
  }

  void _showSnackBar(BuildContext context, SnackBar snackBar) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  void dispose() {
    textController.dispose();
  }
}
