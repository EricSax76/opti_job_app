import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/models/company_multiposting_settings.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/offer_applicants_section.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/logic/offer_card_logic.dart';

import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/ui/controllers/offer_card_controller.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer});

  final JobOffer offer;

  bool get _salaryGapBlocked =>
      offer.status == 'blocked_pending_salary_justification' ||
      offer.salaryGapJustificationRequired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final surface = theme.cardTheme.color ?? colorScheme.surface;
    final surfaceContainer = colorScheme.surfaceContainerHighest;
    final ink = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    final pillBackground = colorScheme.surface;

    final company = context.watch<CompanyAuthCubit>().state.company;
    final viewModel = OfferCardLogic.buildViewModel(
      offer: offer,
      companyUidFromAuth: company?.uid,
      avatarUrlFromAuth: company?.avatarUrl,
    );
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: uiCardRadius,
      backgroundColor: surface,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(
          dividerColor: colorScheme.surface.withValues(alpha: 0),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: uiSpacing16 + 2,
            vertical: uiSpacing8,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            uiSpacing16 + 2,
            0,
            uiSpacing16 + 2,
            uiSpacing16 + 2,
          ),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: surfaceContainer,
            backgroundImage: (viewModel.avatarUrl != null)
                ? NetworkImage(viewModel.avatarUrl!)
                : null,
            child: (viewModel.avatarUrl == null)
                ? Icon(Icons.business_outlined, color: muted)
                : null,
          ),
          title: Text(
            offer.title,
            style: textTheme.bodyLarge?.copyWith(
              color: ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            viewModel.subtitle,
            style: textTheme.bodySmall?.copyWith(color: muted, height: 1.4),
          ),
          onExpansionChanged: (expanded) =>
              OfferCardController.onExpansionChanged(
                context,
                expanded: expanded,
                offer: offer,
                companyUid: viewModel.companyUid,
              ),
          children: [
            Wrap(
              spacing: uiSpacing8,
              runSpacing: uiSpacing8,
              children: [
                if (_salaryGapBlocked)
                  InfoPill(
                    icon: Icons.warning_amber_rounded,
                    label: 'Bloqueada por brecha salarial',
                    backgroundColor: colorScheme.errorContainer,
                    borderColor: colorScheme.error,
                  ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/job-offer/${offer.id}'),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Ver detalle'),
                ),
                FilledButton.icon(
                  onPressed: _salaryGapBlocked
                      ? null
                      : () => _publishToExternalChannels(context),
                  icon: const Icon(Icons.send_to_mobile_outlined, size: 18),
                  label: const Text('Multiposting'),
                ),
                if (_salaryGapBlocked)
                  FilledButton.icon(
                    onPressed: () => _openJustificationDialog(context),
                    icon: const Icon(Icons.rule_folder_outlined, size: 18),
                    label: const Text('Enviar justificación'),
                  ),
                if (offer.multipostingEnabledChannels.isNotEmpty)
                  InfoPill(
                    icon: Icons.hub_outlined,
                    label:
                        'Canales: ${offer.multipostingEnabledChannels.length}',
                    backgroundColor: colorScheme.primaryContainer,
                    borderColor: colorScheme.primary,
                  ),
                InfoPill(
                  icon: Icons.tag_outlined,
                  label: 'Oferta #${offer.id}',
                  backgroundColor: pillBackground,
                  borderColor: colorScheme.outline,
                ),
              ],
            ),
            const SizedBox(height: uiSpacing12),
            OfferApplicantsSection(
              offer: offer,
              companyUid: viewModel.companyUid,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openJustificationDialog(BuildContext context) async {
    final result = await showDialog<_SalaryGapJustificationInput>(
      context: context,
      builder: (_) => const _SalaryGapJustificationDialog(),
    );
    if (result == null || !context.mounted) return;
    await _submitJustification(context, result);
  }

  Future<void> _submitJustification(
    BuildContext context,
    _SalaryGapJustificationInput input,
  ) async {
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('submitSalaryGapJustification');
      await callable.call({
        'jobOfferId': offer.id,
        'justification': input.justification,
        'objectiveCriteria': input.objectiveCriteria,
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Justificación enviada. La oferta se ha desbloqueado.'),
        ),
      );
      context.read<CompanyJobOffersCubit>().refresh();
    } on FirebaseFunctionsException catch (error) {
      if (!context.mounted) return;
      final message = error.message?.trim().isNotEmpty == true
          ? error.message!
          : 'No se pudo enviar la justificación.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar la justificación.')),
      );
    }
  }

  Future<void> _publishToExternalChannels(BuildContext context) async {
    final companySettings = context
        .read<CompanyAuthCubit>()
        .state
        .company
        ?.multipostingSettings;
    final fallbackSelection =
        companySettings?.enabledChannels ?? companyDefaultMultipostingChannels;
    final initialSelection = offer.multipostingEnabledChannels.isEmpty
        ? fallbackSelection
        : offer.multipostingEnabledChannels;

    final options = companyMultipostingChannelCatalog
        .map(
          (channel) => _MultipostingChannelOption(
            id: channel.id,
            label: channel.label,
            estimatedCostEur:
                companySettings?.resolvedCostEur(channel.id) ??
                channel.defaultCostEur,
          ),
        )
        .toList(growable: false);

    final selectedChannels = await showDialog<List<_MultipostingChannelOption>>(
      context: context,
      builder: (_) => _MultipostingChannelDialog(
        options: options,
        initialSelection: initialSelection,
      ),
    );

    if (selectedChannels == null ||
        selectedChannels.isEmpty ||
        !context.mounted) {
      return;
    }

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('publishOfferMultiposting');
      final response = await callable.call({
        'jobOfferId': offer.id,
        'channels': selectedChannels
            .map(
              (channel) => {
                'channel': channel.id,
                'costEur': channel.estimatedCostEur,
              },
            )
            .toList(growable: false),
      });

      final responseData = response.data as Map<Object?, Object?>?;
      final publishedChannels =
          (responseData?['channels'] as List<Object?>?)?.length ??
          selectedChannels.length;
      final totalCost =
          (responseData?['totalEstimatedCostEur'] as num?)?.toDouble() ??
          selectedChannels.fold<double>(
            0,
            (total, channel) => total + channel.estimatedCostEur,
          );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Oferta publicada en $publishedChannels canal(es). '
            'Coste estimado: €${totalCost.toStringAsFixed(2)}.',
          ),
        ),
      );
      context.read<CompanyJobOffersCubit>().refresh();
    } on FirebaseFunctionsException catch (error) {
      if (!context.mounted) return;
      final message = error.message?.trim().isNotEmpty == true
          ? error.message!
          : 'No se pudo publicar en canales externos.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo publicar en canales externos.'),
        ),
      );
    }
  }
}

class _MultipostingChannelOption {
  const _MultipostingChannelOption({
    required this.id,
    required this.label,
    required this.estimatedCostEur,
  });

  final String id;
  final String label;
  final double estimatedCostEur;
}

class _MultipostingChannelDialog extends StatefulWidget {
  const _MultipostingChannelDialog({
    required this.options,
    required this.initialSelection,
  });

  final List<_MultipostingChannelOption> options;
  final List<String> initialSelection;

  @override
  State<_MultipostingChannelDialog> createState() =>
      _MultipostingChannelDialogState();
}

class _MultipostingChannelDialogState
    extends State<_MultipostingChannelDialog> {
  late final Set<String> _selectedChannels;

  @override
  void initState() {
    super.initState();
    final availableIds = widget.options.map((channel) => channel.id).toSet();
    final initial = widget.initialSelection
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty && availableIds.contains(value))
        .toSet();
    _selectedChannels = initial.isNotEmpty ? initial : {...availableIds};
  }

  @override
  Widget build(BuildContext context) {
    final estimatedTotal = widget.options
        .where((channel) => _selectedChannels.contains(channel.id))
        .fold<double>(0, (total, channel) => total + channel.estimatedCostEur);

    return AlertDialog(
      title: const Text('Seleccionar canales de multiposting'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Elige canales y revisa coste estimado por publicación.',
            ),
            const SizedBox(height: uiSpacing12),
            SizedBox(
              height: 280,
              child: SingleChildScrollView(
                child: Column(
                  children: widget.options
                      .map((channel) {
                        final selected = _selectedChannels.contains(channel.id);
                        return CheckboxListTile(
                          value: selected,
                          contentPadding: EdgeInsets.zero,
                          title: Text(channel.label),
                          subtitle: Text(
                            'Coste estimado: €${channel.estimatedCostEur.toStringAsFixed(2)}',
                          ),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedChannels.add(channel.id);
                              } else {
                                _selectedChannels.remove(channel.id);
                              }
                            });
                          },
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            ),
            const SizedBox(height: uiSpacing8),
            Text(
              'Total estimado: €${estimatedTotal.toStringAsFixed(2)}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _selectedChannels.isEmpty
              ? null
              : () {
                  final selected = widget.options
                      .where(
                        (channel) => _selectedChannels.contains(channel.id),
                      )
                      .toList(growable: false);
                  Navigator.of(context).pop(selected);
                },
          child: const Text('Publicar'),
        ),
      ],
    );
  }
}

class _SalaryGapJustificationInput {
  const _SalaryGapJustificationInput({
    required this.justification,
    required this.objectiveCriteria,
  });

  final String justification;
  final List<String> objectiveCriteria;
}

class _SalaryGapJustificationDialog extends StatefulWidget {
  const _SalaryGapJustificationDialog();

  @override
  State<_SalaryGapJustificationDialog> createState() =>
      _SalaryGapJustificationDialogState();
}

class _SalaryGapJustificationDialogState
    extends State<_SalaryGapJustificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _justificationController = TextEditingController();
  final _criteriaController = TextEditingController();

  @override
  void dispose() {
    _justificationController.dispose();
    _criteriaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Justificación objetiva de brecha salarial'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _justificationController,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Justificación',
                  hintText:
                      'Describe criterios objetivos (mercado, seniority, certificaciones, etc.)',
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'La justificación es obligatoria';
                  if (v.length < 20) return 'Añade más detalle objetivo';
                  return null;
                },
              ),
              const SizedBox(height: uiSpacing12),
              TextFormField(
                controller: _criteriaController,
                decoration: const InputDecoration(
                  labelText: 'Criterios objetivos (separados por coma)',
                  hintText:
                      'Ejemplo: seniority, certificación oficial, idiomas',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final criteria = _criteriaController.text
                .split(',')
                .map((v) => v.trim())
                .where((v) => v.isNotEmpty)
                .toList(growable: false);
            Navigator.of(context).pop(
              _SalaryGapJustificationInput(
                justification: _justificationController.text.trim(),
                objectiveCriteria: criteria,
              ),
            );
          },
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}
