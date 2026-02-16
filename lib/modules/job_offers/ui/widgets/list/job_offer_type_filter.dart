import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class JobOfferTypeFilter extends StatelessWidget {
  const JobOfferTypeFilter({
    super.key,
    required this.availableJobTypes,
    required this.selectedJobType,
    required this.onChanged,
    required this.onClear,
  });

  final List<String> availableJobTypes;
  final String? selectedJobType;
  final ValueChanged<String?> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String?>(
            initialValue: selectedJobType,
            decoration: const InputDecoration(
              labelText: 'Filtrar por tipología',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Todas'),
              ),
              ...availableJobTypes.map(
                (type) =>
                    DropdownMenuItem<String?>(value: type, child: Text(type)),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
        if (selectedJobType != null) ...[
          const SizedBox(width: uiSpacing12),
          IconButton.filledTonal(
            onPressed: onClear,
            icon: const Icon(Icons.close),
            tooltip: 'Limpiar filtro',
          ),
        ],
      ],
    );
  }
}
