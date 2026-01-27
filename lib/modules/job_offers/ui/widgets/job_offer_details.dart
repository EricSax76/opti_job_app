import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_extensions.dart';

class JobOfferDetails extends StatelessWidget {
  const JobOfferDetails({super.key, required this.offer});

  final JobOffer offer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? uiDarkInk : uiInk;
    final muted = isDark ? uiDarkMuted : uiMuted;
    final surface = isDark ? uiDarkSurface : Colors.white;
    final description = offer.description.trim().isEmpty
        ? 'Sin descripción.'
        : offer.description.trim();
    final salary = offer.formattedSalary ?? 'No especificado';
    final education = offer.education?.trim().isNotEmpty == true
        ? offer.education!.trim()
        : 'No especificada';
    final keyIndicators = offer.keyIndicators?.trim().isNotEmpty == true
        ? offer.keyIndicators!.trim()
        : null;

    return SingleChildScrollView(
      child: Column(
        children: [
          SectionCard(
            title: 'Descripción',
            child: Text(
              description,
              style: TextStyle(color: ink, height: 1.5),
            ),
          ),
          const SizedBox(height: uiSpacing12),
          SectionCard(
            title: 'Detalles',
            child: Column(
              children: [
                _DetailRow(label: 'Salario', value: salary),
                _DetailRow(
                  label: 'Modalidad',
                  value: offer.jobType ?? 'No especificada',
                ),
                _DetailRow(label: 'Educación', value: education),
                if (keyIndicators != null)
                  _DetailRow(label: 'Indicadores clave', value: keyIndicators),
              ],
            ),
          ),
          const SizedBox(height: uiSpacing16),
          AppCard(
            padding: const EdgeInsets.all(uiSpacing12 + 2),
            borderRadius: uiTileRadius,
            backgroundColor: surface,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: muted),
                const SizedBox(width: uiSpacing12 - 2),
                Expanded(
                  child: Text(
                    'Revisa los detalles y postúlate cuando estés listo.',
                    style: TextStyle(color: muted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? uiDarkMuted : uiMuted;
    final ink = isDark ? uiDarkInk : uiInk;
    return Padding(
      padding: const EdgeInsets.only(bottom: uiSpacing12 - 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: uiSpacing12 - 2),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: ink, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
