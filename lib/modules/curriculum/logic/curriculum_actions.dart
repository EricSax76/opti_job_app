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

sealed class CurriculumActionResult<T> {
  const CurriculumActionResult();
}

class ActionSuccess<T> extends CurriculumActionResult<T> {
  const ActionSuccess([this.data]);
  final T? data;
}

class ActionFailure<T> extends CurriculumActionResult<T> {
  const ActionFailure(this.message);
  final String message;
}

class CurriculumLogic {
  static Future<CurriculumActionResult<String>> improveSummary({
    required BuildContext context,
    required CurriculumFormState state,
  }) async {
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

      return ActionSuccess(suggestion);
    } on AiConfigurationException catch (error) {
      return ActionFailure(error.message);
    } on AiRequestException catch (error) {
      return ActionFailure(error.message);
    } catch (_) {
      return const ActionFailure('No se pudo generar el resumen con IA.');
    }
  }

  static Future<CurriculumActionResult<String>> pickAndUploadAttachment({
    required BuildContext context,
  }) async {
    try {
      final candidate = context.read<CandidateAuthCubit>().state.candidate;
      if (candidate == null) {
        return const ActionFailure('Debes iniciar sesión para importar.');
      }

      final repository = context.read<CurriculumRepository>();
      final curriculumCubit = context.read<CurriculumCubit>();
      final formCubit = context.read<CurriculumFormCubit>();

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        // User canceled, treating as success with no action
        return const ActionSuccess();
      }

      final file = result.files.single;
      final bytes = file.bytes;
      final extension = file.extension?.toLowerCase();
      final contentType = _contentTypeForExtension(extension);

      if (bytes == null || contentType == null) {
        return const ActionFailure('Selecciona un PDF o DOCX válido.');
      }

      if (extension == 'docx') {
        await formCubit.analyzeCvFile(bytes, file.name);
      } else {
         // Not really an error, just info, but we return logic result. 
         // We'll treat this as part of success flow for logic, caller handles info?
         // Actually, let's just proceed. The original logic showed a snackbar.
         // We will just return clear success and let the file be uploaded.
      }

      await repository.uploadAttachment(
        candidateUid: candidate.uid,
        bytes: bytes,
        fileName: file.name,
        contentType: contentType,
      );

      await curriculumCubit.refresh();
      return ActionSuccess(
          extension != 'docx' 
          ? 'Archivo importado. (Info: solo .docx soporta extracción automática)' 
          : 'Archivo importado y analizado.'
      );
    } catch (_) {
      return const ActionFailure('No se pudo importar el archivo.');
    }
  }

  static Future<CurriculumActionResult<void>> deleteAttachment({
    required BuildContext context,
    required CurriculumAttachment attachment,
  }) async {
    final candidate = context.read<CandidateAuthCubit>().state.candidate;
    if (candidate == null) return const ActionFailure('No autenticado');

    try {
      final repository = context.read<CurriculumRepository>();
      final curriculumCubit = context.read<CurriculumCubit>();

      await repository.deleteAttachment(
        candidateUid: candidate.uid,
        attachment: attachment,
      );
      await curriculumCubit.refresh();
      return const ActionSuccess();
    } catch (_) {
      return const ActionFailure('No se pudo eliminar el archivo.');
    }
  }

  static Future<CurriculumActionResult<void>> openAttachment({
    required BuildContext context,
    required CurriculumAttachment attachment,
  }) async {
    if (attachment.storagePath.trim().isEmpty) {
      return const ActionFailure('No encontramos el archivo del CV.');
    }

    try {
      final repository = context.read<CurriculumRepository>();
      final url = await repository.getAttachmentUrl(attachment: attachment);
      final uri = Uri.parse(url);
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        return const ActionFailure('No se pudo abrir el archivo.');
      }
      return const ActionSuccess();
    } catch (_) {
      return const ActionFailure('No se pudo abrir el archivo.');
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
