import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/features/cover_letter/view/models/cover_letter_view_model.dart';

class CoverLetterContent extends StatelessWidget {
  const CoverLetterContent({
    super.key,
    required this.controller,
    required this.viewModel,
    required this.onImprove,
    required this.onSave,
  });

  final TextEditingController controller;
  final CoverLetterViewModel viewModel;
  final VoidCallback onImprove;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(uiSpacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Carta de presentación',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: uiSpacing8),
          TextField(
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText:
                  'La IA analizará tu CV y generará una carta personalizada. También puedes editarla aquí.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: uiSpacing16),
          ElevatedButton.icon(
            onPressed: viewModel.isImproving ? null : onImprove,
            icon: viewModel.isImproving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              viewModel.isImproving ? 'Generando...' : 'Generar con IA',
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: uiSpacing24),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: uiSpacing16),
            ),
            child: const Text('Guardar carta'),
          ),
          if (viewModel.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: uiSpacing12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}
