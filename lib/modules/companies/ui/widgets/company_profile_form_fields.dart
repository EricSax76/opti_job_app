import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/companies/models/company_multiposting_settings.dart';

class CompanyProfileFormFields extends StatelessWidget {
  const CompanyProfileFormFields({
    super.key,
    required this.nameController,
    required this.websiteController,
    required this.industryController,
    required this.teamSizeController,
    required this.headquartersController,
    required this.descriptionController,
    required this.controllerLegalNameController,
    required this.controllerTaxIdController,
    required this.privacyContactEmailController,
    required this.dpoNameController,
    required this.dpoEmailController,
    required this.privacyPolicyUrlController,
    required this.retentionPolicySummaryController,
    required this.internationalTransfersSummaryController,
    required this.aiConsentTextVersionController,
    required this.aiConsentTextController,
    required this.email,
    required this.complianceComplete,
    required this.enabledMultipostingChannels,
    required this.onChannelToggle,
    required this.canSubmit,
    required this.isSaving,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController websiteController;
  final TextEditingController industryController;
  final TextEditingController teamSizeController;
  final TextEditingController headquartersController;
  final TextEditingController descriptionController;
  final TextEditingController controllerLegalNameController;
  final TextEditingController controllerTaxIdController;
  final TextEditingController privacyContactEmailController;
  final TextEditingController dpoNameController;
  final TextEditingController dpoEmailController;
  final TextEditingController privacyPolicyUrlController;
  final TextEditingController retentionPolicySummaryController;
  final TextEditingController internationalTransfersSummaryController;
  final TextEditingController aiConsentTextVersionController;
  final TextEditingController aiConsentTextController;
  final String email;
  final bool complianceComplete;
  final List<String> enabledMultipostingChannels;
  final void Function(String channelId, bool enabled) onChannelToggle;
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
          'Ajustes de la empresa',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: ink,
          ),
        ),
        const SizedBox(height: uiSpacing8),
        _ComplianceStatusPill(complianceComplete: complianceComplete),
        const SizedBox(height: uiSpacing16),
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nombre de la empresa'),
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
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: websiteController,
          decoration: const InputDecoration(
            labelText: 'Sitio web',
            hintText: 'https://tuempresa.com',
          ),
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: industryController,
          decoration: const InputDecoration(
            labelText: 'Sector',
            hintText: 'Tecnologia, retail, salud...',
          ),
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: teamSizeController,
          decoration: const InputDecoration(
            labelText: 'Tamano del equipo',
            hintText: '1-10, 11-50, 51-200...',
          ),
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: headquartersController,
          decoration: const InputDecoration(
            labelText: 'Sede principal',
            hintText: 'Madrid, Barcelona, remoto...',
          ),
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Descripcion breve',
            hintText: 'Cuenta en pocas lineas como trabaja tu empresa.',
          ),
        ),
        const SizedBox(height: uiSpacing24),
        Text(
          'LGPD / Privacidad',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        const SizedBox(height: uiSpacing8),
        Text(
          'Completa los datos del controlador y del encargado para trazabilidad y atención a titulares.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: controllerLegalNameController,
          decoration: const InputDecoration(
            labelText: 'Razón social del responsable',
            hintText: 'Empresa XYZ Ltda.',
          ),
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: controllerTaxIdController,
          decoration: const InputDecoration(
            labelText: 'Identificador fiscal (CNPJ/NIF)',
          ),
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: privacyContactEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email de privacidad',
            hintText: 'privacidad@tuempresa.com',
          ),
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: dpoNameController,
          decoration: const InputDecoration(labelText: 'Encargado/DPO'),
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: dpoEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email del encargado/DPO',
            hintText: 'dpo@tuempresa.com',
          ),
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: privacyPolicyUrlController,
          decoration: const InputDecoration(
            labelText: 'URL política de privacidad',
            hintText: 'https://tuempresa.com/privacidad',
          ),
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: retentionPolicySummaryController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Resumen de retención',
            hintText:
                'Ejemplo: Conservamos datos de candidatos por 36 meses salvo oposición o obligación legal.',
          ),
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: internationalTransfersSummaryController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Transferencias internacionales',
            hintText:
                'Describe si existen y bajo qué salvaguardas contractuales/legales.',
          ),
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: aiConsentTextVersionController,
          decoration: const InputDecoration(
            labelText: 'Versión texto consentimiento IA',
            hintText: '2026.04',
          ),
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: aiConsentTextController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Texto consentimiento IA',
          ),
        ),
        const SizedBox(height: uiSpacing24),
        Text(
          'Canales por defecto de multiposting (opcional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        const SizedBox(height: uiSpacing8),
        Text(
          'Si no seleccionas ninguno, tus ofertas se publicaran solo en esta app.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: uiSpacing8),
        ...companyMultipostingChannelCatalog.map((channel) {
          final enabled = enabledMultipostingChannels.contains(channel.id);
          return CheckboxListTile.adaptive(
            value: enabled,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(channel.label),
            subtitle: Text(
              'Coste base estimado: €${channel.defaultCostEur.toStringAsFixed(0)}',
            ),
            onChanged: (value) => onChannelToggle(channel.id, value ?? false),
          );
        }),
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

class _ComplianceStatusPill extends StatelessWidget {
  const _ComplianceStatusPill({required this.complianceComplete});

  final bool complianceComplete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = complianceComplete ? colorScheme.primary : colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complianceComplete
                ? Icons.verified_user_outlined
                : Icons.warning_amber_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            complianceComplete
                ? 'Perfil LGPD completo'
                : 'Perfil LGPD incompleto',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
