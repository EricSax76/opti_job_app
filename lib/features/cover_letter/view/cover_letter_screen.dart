import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/features/cover_letter/bloc/cover_letter_bloc.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_cubit.dart';

class CoverLetterScreen extends StatefulWidget {
  const CoverLetterScreen({super.key});

  @override
  State<CoverLetterScreen> createState() => _CoverLetterScreenState();
}

class _CoverLetterScreenState extends State<CoverLetterScreen> {
  final _coverLetterController = TextEditingController();
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
    _bloc.add(SaveCoverLetterAndVideo(_coverLetterController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<CoverLetterBloc, CoverLetterState>(
        listener: (context, state) {
          if (state.status == CoverLetterStatus.success &&
              state.improvedCoverLetter != null) {
            _coverLetterController.text = state.improvedCoverLetter!;
          }

          if (state.savedCoverLetterText != null &&
              _coverLetterController.text.trim().isEmpty) {
            _coverLetterController.text = state.savedCoverLetterText!;
          }

          if (state.status == CoverLetterStatus.failure && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }

          if (state.status == CoverLetterStatus.uploading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Guardando...')),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Carta de presentación'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Carta de presentación',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _coverLetterController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText:
                        'Escribe aquí tu carta de presentación o deja que la IA te ayude...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                BlocBuilder<CoverLetterBloc, CoverLetterState>(
                  buildWhen: (previous, current) =>
                      previous.status != current.status,
                  builder: (context, state) {
                    final isImproving =
                        state.status == CoverLetterStatus.improving;
                    return ElevatedButton.icon(
                      onPressed: isImproving ? null : _improveWithAI,
                      icon: isImproving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(isImproving ? 'Generando...' : 'Mejorar con IA'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onSecondary,
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Guardar carta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
