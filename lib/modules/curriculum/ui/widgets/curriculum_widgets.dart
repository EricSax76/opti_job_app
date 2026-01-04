import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';

import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/modules/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/curriculum/cubit/curriculum_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubit/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';

const _cvBackground = Color(0xFFF8FAFC);
const _cvInk = Color(0xFF0F172A);
const _cvMuted = Color(0xFF475569);
const _cvBorder = Color(0xFFE2E8F0);
const _cvAccent = Color(0xFF3FA7A0);

class CandidateCurriculumView extends StatelessWidget {
  const CandidateCurriculumView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CurriculumFormCubit(curriculumCubit: context.read<CurriculumCubit>()),
      child: const _CandidateCurriculumContent(),
    );
  }
}

class _CandidateCurriculumContent extends StatefulWidget {
  const _CandidateCurriculumContent();

  @override
  State<_CandidateCurriculumContent> createState() =>
      _CandidateCurriculumContentState();
}

class _CandidateCurriculumContentState extends State<_CandidateCurriculumContent> {
  final _skillController = TextEditingController();
  var _isImprovingSummary = false;
  var _isManagingAttachment = false;

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _improveSummary(
    BuildContext context,
    CurriculumFormState state,
  ) async {
    if (_isImprovingSummary) return;
    setState(() => _isImprovingSummary = true);

    try {
      final formCubit = context.read<CurriculumFormCubit>();
      final curriculum = Curriculum(
        headline: formCubit.headlineController.text.trim(),
        summary: formCubit.summaryController.text.trim(),
        phone: formCubit.phoneController.text.trim(),
        location: formCubit.locationController.text.trim(),
        skills: state.skills,
        experiences: state.experiences,
        education: state.education,
      );

      final locale = Localizations.localeOf(context).toLanguageTag();
      final suggestion = await context
          .read<AiRepository>()
          .improveCurriculumSummary(curriculum: curriculum, locale: locale);

      if (!context.mounted) return;

      final shouldApply = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Resumen sugerido'),
            content: SingleChildScrollView(
              child: SelectableText(suggestion),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      );

      if (shouldApply == true && mounted) {
        formCubit.summaryController.text = suggestion;
      }
    } on AiConfigurationException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } on AiRequestException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo generar el resumen con IA.')),
      );
    } finally {
      if (mounted) setState(() => _isImprovingSummary = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formCubit = context.read<CurriculumFormCubit>();
    final attachment = context.watch<CurriculumCubit>().state.curriculum?.attachment;

    return BlocConsumer<CurriculumFormCubit, CurriculumFormState>(
      listener: (context, state) {
        if (state.notice != null && state.noticeMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.noticeMessage!)),
          );
          formCubit.clearNotice();
        }
      },
      builder: (context, state) {
        if (state.viewStatus == CurriculumFormViewStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.viewStatus == CurriculumFormViewStatus.error) {
          return _StateMessage(
            title: 'No pudimos cargar tu curriculum',
            message: state.errorMessage ?? 'Intenta nuevamente en unos segundos.',
            actionLabel: 'Reintentar',
            onAction: formCubit.refresh,
          );
        }

        if (state.viewStatus == CurriculumFormViewStatus.empty) {
          return const _StateMessage(
            title: 'Inicia sesión para ver tu curriculum',
            message: 'Necesitas una cuenta activa para editar tu CV.',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _cvBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Curriculum',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: state.isSaving || _isManagingAttachment
                              ? null
                              : () => _pickAndUploadAttachment(context),
                          icon: _isManagingAttachment
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.upload_file_outlined),
                          label: Text(
                            _isManagingAttachment
                                ? 'Subiendo...'
                                : 'Importar PDF/DOCX',
                          ),
                        ),
                      ],
                    ),
                    if (attachment != null) ...[
                      const SizedBox(height: 16),
                      _AttachmentTile(
                        attachment: attachment,
                        isBusy: state.isSaving || _isManagingAttachment,
                        onDelete: () => _confirmAndDeleteAttachment(
                          context,
                          attachment,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Completa tu CV para postular más rápido.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: _cvMuted),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: formCubit.headlineController,
                      decoration: _inputDecoration(labelText: 'Titular'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: formCubit.summaryController,
                      maxLines: 4,
                      decoration: _inputDecoration(labelText: 'Resumen'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: state.isSaving || _isImprovingSummary
                              ? null
                              : () => _improveSummary(context, state),
                          icon: _isImprovingSummary
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome_outlined),
                          label: Text(
                            _isImprovingSummary
                                ? 'Generando...'
                                : 'Mejorar con IA',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: formCubit.phoneController,
                            decoration: _inputDecoration(labelText: 'Teléfono'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: formCubit.locationController,
                            decoration: _inputDecoration(labelText: 'Ubicación'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: 'Habilidades',
                      subtitle: 'Agrega palabras clave (p.ej. Flutter, Firebase).',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _skillController,
                            decoration: _inputDecoration(
                              labelText: 'Nueva habilidad',
                            ),
                            onSubmitted: (value) {
                              formCubit.addSkill(value);
                              _skillController.clear();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _cvInk,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            formCubit.addSkill(_skillController.text);
                            _skillController.clear();
                          },
                          child: const Text('Agregar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final skill in state.skills)
                          InputChip(
                            label: Text(skill),
                            onDeleted: () => formCubit.removeSkill(skill),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _ItemsSection(
                      title: 'Experiencia',
                      items: state.experiences,
                      emptyHint: 'Agrega tu experiencia laboral más relevante.',
                      onAdd: () async {
                        final created = await _showItemDialog(context);
                        if (created != null) formCubit.addExperience(created);
                      },
                      onEdit: (index, item) async {
                        final updated = await _showItemDialog(
                          context,
                          initial: item,
                        );
                        if (updated != null) {
                          formCubit.updateExperience(index, updated);
                        }
                      },
                      onRemove: formCubit.removeExperience,
                    ),
                    const SizedBox(height: 20),
                    _ItemsSection(
                      title: 'Educación',
                      items: state.education,
                      emptyHint: 'Agrega tu formación académica o cursos clave.',
                      onAdd: () async {
                        final created = await _showItemDialog(context);
                        if (created != null) formCubit.addEducation(created);
                      },
                      onEdit: (index, item) async {
                        final updated = await _showItemDialog(
                          context,
                          initial: item,
                        );
                        if (updated != null) {
                          formCubit.updateEducation(index, updated);
                        }
                      },
                      onRemove: formCubit.removeEducation,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _cvInk,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: state.canSubmit ? formCubit.submit : null,
                        child: state.isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Guardar curriculum'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadAttachment(BuildContext context) async {
    if (_isManagingAttachment) return;
    final candidate = context.read<CandidateAuthCubit>().state.candidate;
    if (candidate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para importar.')),
      );
      return;
    }

    final repository = context.read<CurriculumRepository>();
    final curriculumCubit = context.read<CurriculumCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    final extension = file.extension?.toLowerCase();
    final contentType = _contentTypeForExtension(extension);

    if (bytes == null || contentType == null) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Selecciona un PDF o DOCX válido.')),
      );
      return;
    }

    setState(() => _isManagingAttachment = true);
    try {
      await repository.uploadAttachment(
        candidateUid: candidate.uid,
        bytes: bytes,
        fileName: file.name,
        contentType: contentType,
      );
      if (!mounted) return;
      await curriculumCubit.refresh();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Archivo importado correctamente.')),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo importar el archivo.')),
      );
    } finally {
      if (mounted) setState(() => _isManagingAttachment = false);
    }
  }

  Future<void> _confirmAndDeleteAttachment(
    BuildContext context,
    CurriculumAttachment attachment,
  ) async {
    if (_isManagingAttachment) return;
    final candidate = context.read<CandidateAuthCubit>().state.candidate;
    if (candidate == null) return;

    final repository = context.read<CurriculumRepository>();
    final curriculumCubit = context.read<CurriculumCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar archivo'),
          content: const Text(
            'Se eliminará el archivo importado de tu curriculum.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true || !mounted) return;

    setState(() => _isManagingAttachment = true);
    try {
      await repository.deleteAttachment(
        candidateUid: candidate.uid,
        attachment: attachment,
      );
      if (!mounted) return;
      await curriculumCubit.refresh();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Archivo eliminado.')),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el archivo.')),
      );
    } finally {
      if (mounted) setState(() => _isManagingAttachment = false);
    }
  }
}

String? _contentTypeForExtension(String? extension) {
  switch (extension) {
    case 'pdf':
      return 'application/pdf';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
  return null;
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.onDelete,
    required this.isBusy,
  });

  final CurriculumAttachment attachment;
  final VoidCallback onDelete;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final sizeLabel = _formatBytes(attachment.sizeBytes);
    final updatedLabel = attachment.updatedAt == null
        ? null
        : 'Actualizado: ${_formatDate(attachment.updatedAt!)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cvBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cvBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: _cvMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _cvInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [sizeLabel, if (updatedLabel != null) updatedLabel].join(' · '),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: _cvMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Eliminar',
            onPressed: isBusy ? null : onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  final fixed = unitIndex == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
  return '$fixed ${units[unitIndex]}';
}

String _formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}

InputDecoration _inputDecoration({required String labelText}) {
  return InputDecoration(
    labelText: labelText,
    filled: true,
    fillColor: _cvBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _cvBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _cvBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _cvAccent),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _cvMuted),
        ),
      ],
    );
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({
    required this.title,
    required this.items,
    required this.emptyHint,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final String title;
  final List<CurriculumItem> items;
  final String emptyHint;
  final VoidCallback onAdd;
  final Future<void> Function(int index, CurriculumItem item) onEdit;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cvBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cvBorder),
            ),
            child: Text(
              emptyHint,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: _cvMuted),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(items[i].title.isEmpty ? 'Sin título' : items[i].title),
                    subtitle: Text(
                      [
                        if (items[i].subtitle.trim().isNotEmpty) items[i].subtitle.trim(),
                        if (items[i].period.trim().isNotEmpty) items[i].period.trim(),
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await onEdit(i, items[i]);
                        } else if (value == 'remove') {
                          onRemove(i);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'remove', child: Text('Eliminar')),
                      ],
                    ),
                    onTap: () => onEdit(i, items[i]),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: _cvMuted),
                  textAlign: TextAlign.center,
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<CurriculumItem?> _showItemDialog(
  BuildContext context, {
  CurriculumItem? initial,
}) {
  final initialItem = initial ?? CurriculumItem.empty();
  final titleController = TextEditingController(text: initialItem.title);
  final subtitleController = TextEditingController(text: initialItem.subtitle);
  final periodController = TextEditingController(text: initialItem.period);
  final descriptionController = TextEditingController(
    text: initialItem.description,
  );

  return showDialog<CurriculumItem>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(initial == null ? 'Agregar' : 'Editar'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: subtitleController,
                decoration: const InputDecoration(labelText: 'Subtítulo'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: periodController,
                decoration: const InputDecoration(labelText: 'Periodo'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Descripción'),
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
            onPressed: () {
              Navigator.of(context).pop(
                CurriculumItem(
                  title: titleController.text.trim(),
                  subtitle: subtitleController.text.trim(),
                  period: periodController.text.trim(),
                  description: descriptionController.text.trim(),
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  ).whenComplete(() {
    titleController.dispose();
    subtitleController.dispose();
    periodController.dispose();
    descriptionController.dispose();
  });
}
