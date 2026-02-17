import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class CompanyProfileFormFields extends StatelessWidget {
  const CompanyProfileFormFields({
    super.key,
    required this.nameController,
    required this.email,
    required this.canSubmit,
    required this.isSaving,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final String email;
  final bool canSubmit;
  final bool isSaving;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ink = colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Datos de la empresa',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: ink,
          ),
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          initialValue: email,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Correo',
            helperText: 'Este dato no se puede modificar.',
          ),
        ),
        const SizedBox(height: uiSpacing20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: uiSpacing12),
            ),
            onPressed: canSubmit ? onSubmit : null,
            child: isSaving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  )
                : const Text('Guardar cambios'),
          ),
        ),
      ],
    );
  }
}
