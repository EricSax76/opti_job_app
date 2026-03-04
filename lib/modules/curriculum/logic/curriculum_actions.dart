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
        return const ActionSuccess('');
      }

      final file = result.files.single;
      final bytes = file.bytes;
      final extension = file.extension?.toLowerCase();
      final contentType = _contentTypeForExtension(extension);

      if (bytes == null || contentType == null) {
        return const ActionFailure('Selecciona un PDF o DOCX válido.');
      }

      final supportsExtraction = extension == 'docx' || extension == 'pdf';
      var extractedData = false;
      if (supportsExtraction) {
        extractedData = await formCubit.analyzeCvFile(bytes, file.name);
      }

      final updatedCurriculum = await repository.uploadAttachment(
        candidateUid: candidate.uid,
        bytes: bytes,
        fileName: file.name,
        contentType: contentType,
        previousAttachment: curriculumCubit.state.curriculum?.attachment,
      );
      curriculumCubit.setCurriculum(updatedCurriculum);

      // Persist extracted form data after import so the parsed content is not
      // left only in local UI state.
      if (supportsExtraction && extractedData) {
        await curriculumCubit.save(
          _buildCurriculumFromForm(
            formCubit: formCubit,
            baseCurriculum: updatedCurriculum,
            attachment: updatedCurriculum.attachment,
            updatedAt: updatedCurriculum.updatedAt,
          ),
        );
      }

      return ActionSuccess(
        !supportsExtraction
            ? 'Archivo importado. (Info: solo PDF y DOCX soportan extracción automática)'
            : extractedData
            ? 'Archivo importado y datos extraídos.'
            : 'Archivo importado. No se pudieron extraer datos automáticamente.',
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

      final updatedCurriculum = await repository.deleteAttachment(
        candidateUid: candidate.uid,
        attachment: attachment,
      );
      curriculumCubit.setCurriculum(updatedCurriculum);
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
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  static Curriculum _buildCurriculumFromForm({
    required CurriculumFormCubit formCubit,
    required Curriculum baseCurriculum,
    CurriculumAttachment? attachment,
    DateTime? updatedAt,
  }) {
    final state = formCubit.state;
    final headline = formCubit.headlineController.text.trim();
    final summary = formCubit.summaryController.text.trim();
    final phone = formCubit.phoneController.text.trim();
    final location = formCubit.locationController.text.trim();

    return Curriculum(
      headline: headline.isNotEmpty ? headline : baseCurriculum.headline,
      summary: summary.isNotEmpty ? summary : baseCurriculum.summary,
      phone: phone.isNotEmpty ? phone : baseCurriculum.phone,
      location: location.isNotEmpty ? location : baseCurriculum.location,
      skills: state.skills.isNotEmpty ? state.skills : baseCurriculum.skills,
      experiences: _hasMeaningfulItems(state.experiences)
          ? state.experiences
          : baseCurriculum.experiences,
      education: _hasMeaningfulItems(state.education)
          ? state.education
          : baseCurriculum.education,
      attachment: attachment ?? baseCurriculum.attachment,
      updatedAt: updatedAt ?? baseCurriculum.updatedAt,
    );
  }

  static bool _hasMeaningfulItems(List<CurriculumItem> items) {
    return items.any(
      (item) =>
          item.title.trim().isNotEmpty ||
          item.subtitle.trim().isNotEmpty ||
          item.period.trim().isNotEmpty ||
          item.description.trim().isNotEmpty,
    );
  }
}
