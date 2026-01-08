import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_extensions.dart';

class JobOfferDetails extends StatelessWidget {
  const JobOfferDetails({super.key, required this.offer});

  final JobOffer offer;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF64748B);
    const border = Color(0xFFE2E8F0);

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
          _SectionCard(
            title: 'Descripción',
            child: Text(
              description,
              style: const TextStyle(color: ink, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: muted),
                SizedBox(width: 10),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const border = Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          child,
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
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF64748B);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: ink, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
