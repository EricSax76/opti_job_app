import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/features/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class CurriculumLogic {
  static Future<void> improveSummary({
    required BuildContext context,
    required CurriculumFormState state,
    required VoidCallback onStart,
    required VoidCallback onEnd,
  }) async {
    onStart();
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
            content: SingleChildScrollView(child: SelectableText(suggestion)),
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

      if (shouldApply == true && context.mounted) {
        formCubit.summaryController.text = suggestion;
      }
    } on AiConfigurationException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on AiRequestException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo generar el resumen con IA.')),
      );
    } finally {
      onEnd();
    }
  }

  static Future<void> pickAndUploadAttachment({
    required BuildContext context,
    required VoidCallback onStart,
    required VoidCallback onEnd,
  }) async {
    onStart();
    try {
      final candidate = context.read<CandidateAuthCubit>().state.candidate;
      if (candidate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión para importar.')),
        );
        return;
      }

      final repository = context.read<CurriculumRepository>();
      final curriculumCubit = context.read<CurriculumCubit>();
      final formCubit = context.read<CurriculumFormCubit>();
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
        messenger.showSnackBar(
          const SnackBar(content: Text('Selecciona un PDF o DOCX válido.')),
        );
        return;
      }

      // Antes de subir, intentamos extraer datos del CV para rellenar el form.
      // Actualmente solo se soporta extracción automática desde `.docx`.
      if (extension == 'docx') {
        await formCubit.analyzeCvFile(bytes, file.name);
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Por ahora solo se puede extraer información automáticamente desde .docx.',
            ),
          ),
        );
      }

      await repository.uploadAttachment(
        candidateUid: candidate.uid,
        bytes: bytes,
        fileName: file.name,
        contentType: contentType,
      );

      await curriculumCubit.refresh();
      messenger.showSnackBar(
        const SnackBar(content: Text('Archivo importado correctamente.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo importar el archivo.')),
      );
    } finally {
      onEnd();
    }
  }

  static Future<void> confirmAndDeleteAttachment({
    required BuildContext context,
    required CurriculumAttachment attachment,
    required VoidCallback onStart,
    required VoidCallback onEnd,
  }) async {
    final candidate = context.read<CandidateAuthCubit>().state.candidate;
    if (candidate == null) return;

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
    if (shouldDelete != true) return;
    if (!context.mounted) return;

    onStart();
    try {
      final repository = context.read<CurriculumRepository>();
      final curriculumCubit = context.read<CurriculumCubit>();
      final messenger = ScaffoldMessenger.of(context);

      await repository.deleteAttachment(
        candidateUid: candidate.uid,
        attachment: attachment,
      );
      await curriculumCubit.refresh();
      messenger.showSnackBar(
        const SnackBar(content: Text('Archivo eliminado.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el archivo.')),
      );
    } finally {
      onEnd();
    }
  }

  static Future<void> openAttachment({
    required BuildContext context,
    required CurriculumAttachment attachment,
  }) async {
    if (attachment.storagePath.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No encontramos el archivo del CV.')),
      );
      return;
    }

    try {
      final repository = context.read<CurriculumRepository>();
      final url = await repository.getAttachmentUrl(attachment: attachment);
      final uri = Uri.parse(url);
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el archivo.')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el archivo.')),
      );
    }
  }

  static String? _contentTypeForExtension(String? extension) {
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
}
