import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class CurriculumPdfService {
  Future<Uint8List> buildPdf({
    required Candidate candidate,
    required Curriculum curriculum,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            '${candidate.name} ${candidate.lastName}'.trim(),
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          if (curriculum.headline.trim().isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              curriculum.headline.trim(),
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
            ),
          ],
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              pw.Text(candidate.email),
              if (curriculum.phone.trim().isNotEmpty)
                pw.Text(curriculum.phone.trim()),
              if (curriculum.location.trim().isNotEmpty)
                pw.Text(curriculum.location.trim()),
            ],
          ),
          if (curriculum.summary.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('Resumen'),
            pw.SizedBox(height: 6),
            pw.Text(curriculum.summary.trim()),
          ],
          if (curriculum.skills.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('Habilidades'),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final skill in curriculum.skills)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Text(skill, style: const pw.TextStyle(fontSize: 10)),
                  ),
              ],
            ),
          ],
          if (curriculum.experiences.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('Experiencia'),
            pw.SizedBox(height: 6),
            for (final item in curriculum.experiences) _itemBlock(item),
          ],
          if (curriculum.education.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('Educación'),
            pw.SizedBox(height: 6),
            for (final item in curriculum.education) _itemBlock(item),
          ],
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
    );
  }

  pw.Widget _itemBlock(CurriculumItem item) {
    final title = item.title.trim();
    final subtitle = item.subtitle.trim();
    final period = item.period.trim();
    final description = item.description.trim();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  title.isEmpty ? 'Sin título' : title,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if (period.isNotEmpty)
                pw.Text(
                  period,
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
            ],
          ),
          if (subtitle.isNotEmpty)
            pw.Text(
              subtitle,
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
            ),
          if (description.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(description),
          ],
        ],
      ),
    );
  }
}

