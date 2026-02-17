import 'package:flutter/material.dart';

class CoverLetterContent extends StatelessWidget {
  const CoverLetterContent({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.isImproving,
    required this.onImprove,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool isLoading;
  final bool isImproving;
  final VoidCallback onImprove;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText:
                  'Escribe aquí tu carta de presentación o deja que la IA te ayude...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: isImproving ? null : onImprove,
            icon: isImproving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(isImproving ? 'Generando...' : 'Mejorar con IA'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Guardar carta'),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}
