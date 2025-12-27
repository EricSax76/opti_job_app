import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum_pdf_service.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum_share_service.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

class ApplicantCurriculumScreen extends StatefulWidget {
  const ApplicantCurriculumScreen({super.key, required this.candidateUid});

  final String candidateUid;

  @override
  State<ApplicantCurriculumScreen> createState() =>
      _ApplicantCurriculumScreenState();
}

class _ApplicantCurriculumScreenState extends State<ApplicantCurriculumScreen> {
  late final Future<_ApplicantCurriculumPayload> _payloadFuture =
      _loadPayload();
  var _isExporting = false;

  Future<_ApplicantCurriculumPayload> _loadPayload() async {
    final profileRepository = context.read<ProfileRepository>();
    final curriculumRepository = context.read<CurriculumRepository>();
    final results = await Future.wait([
      profileRepository.fetchCandidateProfile(widget.candidateUid),
      curriculumRepository.fetchCurriculum(widget.candidateUid),
    ]);
    return _ApplicantCurriculumPayload(
      candidate: results[0] as Candidate,
      curriculum: results[1] as Curriculum,
    );
  }

  Future<void> _exportPdf({
    required Candidate candidate,
    required Curriculum curriculum,
  }) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final pdfBytes = await CurriculumPdfService().buildPdf(
        candidate: candidate,
        curriculum: curriculum,
      );
      final safeName = _safeFileName(
        '${candidate.name}_${candidate.lastName}'.trim(),
      );
      await CurriculumShareService().sharePdf(
        bytes: pdfBytes,
        fileName: 'CV_$safeName.pdf',
        subject: 'Curriculum - ${candidate.name}',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo exportar el PDF.')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _safeFileName(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'candidato';
    return trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF8FAFC);
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);
    const border = Color(0xFFE2E8F0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CV del aplicante'),
      ),
      body: FutureBuilder<_ApplicantCurriculumPayload>(
        future: _payloadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No se pudo cargar el CV del aplicante.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final candidate = snapshot.data!.candidate;
          final curriculum = snapshot.data!.curriculum;
          final hasCurriculum = curriculum.headline.trim().isNotEmpty ||
              curriculum.summary.trim().isNotEmpty ||
              curriculum.phone.trim().isNotEmpty ||
              curriculum.location.trim().isNotEmpty ||
              curriculum.skills.isNotEmpty ||
              curriculum.experiences.isNotEmpty ||
              curriculum.education.isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: ink,
                            foregroundColor: Colors.white,
                            child: Text(
                              _initial(candidate),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${candidate.name} ${candidate.lastName}'
                                      .trim(),
                                  style: const TextStyle(
                                    color: ink,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  candidate.email,
                                  style: const TextStyle(
                                    color: muted,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed:
                                _isExporting || !hasCurriculum
                                    ? null
                                    : () => _exportPdf(
                                      candidate: candidate,
                                      curriculum: curriculum,
                                    ),
                            icon:
                                _isExporting
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.picture_as_pdf_outlined),
                            label: Text(
                              _isExporting ? 'Exportando...' : 'Exportar PDF',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: border),
                      ),
                      child: hasCurriculum
                          ? _CurriculumReadOnlyView(curriculum: curriculum)
                          : Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: background,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: border),
                            ),
                            child: const Text(
                              'El aplicante aún no tiene un CV cargado.',
                              style: TextStyle(color: muted, height: 1.4),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ApplicantCurriculumPayload {
  const _ApplicantCurriculumPayload({
    required this.candidate,
    required this.curriculum,
  });

  final Candidate candidate;
  final Curriculum curriculum;
}

class _CurriculumReadOnlyView extends StatelessWidget {
  const _CurriculumReadOnlyView({required this.curriculum});

  final Curriculum curriculum;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);
    const border = Color(0xFFE2E8F0);
    const background = Color(0xFFF8FAFC);

    Widget sectionTitle(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: ink,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      );
    }

    Widget card({required Widget child}) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: child,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (curriculum.headline.trim().isNotEmpty) ...[
          sectionTitle('Titular'),
          card(
            child: Text(
              curriculum.headline.trim(),
              style: const TextStyle(color: ink, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (curriculum.summary.trim().isNotEmpty) ...[
          sectionTitle('Resumen'),
          card(
            child: Text(
              curriculum.summary.trim(),
              style: const TextStyle(color: muted, height: 1.5),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (curriculum.phone.trim().isNotEmpty ||
            curriculum.location.trim().isNotEmpty) ...[
          sectionTitle('Contacto'),
          card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (curriculum.phone.trim().isNotEmpty)
                  Text(
                    'Teléfono: ${curriculum.phone.trim()}',
                    style: const TextStyle(color: muted, height: 1.4),
                  ),
                if (curriculum.location.trim().isNotEmpty)
                  Text(
                    'Ubicación: ${curriculum.location.trim()}',
                    style: const TextStyle(color: muted, height: 1.4),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (curriculum.skills.isNotEmpty) ...[
          sectionTitle('Habilidades'),
          card(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in curriculum.skills)
                  Chip(
                    label: Text(skill),
                    side: const BorderSide(color: border),
                    backgroundColor: Colors.white,
                    labelStyle: const TextStyle(color: ink),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (curriculum.experiences.isNotEmpty) ...[
          sectionTitle('Experiencia'),
          card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in curriculum.experiences)
                  _CurriculumItemBlock(item: item),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (curriculum.education.isNotEmpty) ...[
          sectionTitle('Educación'),
          card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in curriculum.education)
                  _CurriculumItemBlock(item: item),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CurriculumItemBlock extends StatelessWidget {
  const _CurriculumItemBlock({required this.item});

  final CurriculumItem item;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);

    final title = item.title.trim();
    final subtitle = item.subtitle.trim();
    final period = item.period.trim();
    final description = item.description.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              style: const TextStyle(
                color: ink,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: const TextStyle(color: muted, height: 1.35),
            ),
          if (period.isNotEmpty)
            Text(
              period,
              style: const TextStyle(color: muted, height: 1.35),
            ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                description,
                style: const TextStyle(color: muted, height: 1.45),
              ),
            ),
        ],
      ),
    );
  }
}

String _initial(Candidate candidate) {
  final raw = (candidate.name.trim().isNotEmpty ? candidate.name : candidate.email)
      .trim();
  if (raw.isEmpty) return '?';
  return raw.substring(0, 1).toUpperCase();
}
