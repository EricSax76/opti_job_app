import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class CurriculumReadOnlyView extends StatelessWidget {
  const CurriculumReadOnlyView({super.key, required this.curriculum});

  final Curriculum curriculum;

  @override
  Widget build(BuildContext context) {
    Widget sectionTitle(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: uiSpacing8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: uiMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      );
    }

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (curriculum.headline.trim().isNotEmpty) ...[
            sectionTitle('Titular'),
            AppCard(
              padding: const EdgeInsets.all(uiSpacing16),
              child: Text(
                curriculum.headline.trim(),
                style: const TextStyle(
                  color: uiInk,
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: uiSpacing24),
          ],
          if (curriculum.summary.trim().isNotEmpty) ...[
            sectionTitle('Resumen Profesional'),
            AppCard(
              padding: const EdgeInsets.all(uiSpacing16),
              child: Text(
                curriculum.summary.trim(),
                style: const TextStyle(
                  color: uiInk,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: uiSpacing24),
          ],
          if (curriculum.phone.trim().isNotEmpty ||
              curriculum.location.trim().isNotEmpty) ...[
            sectionTitle('Información de Contacto'),
            AppCard(
              padding: const EdgeInsets.all(uiSpacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (curriculum.phone.trim().isNotEmpty)
                    _ContactRow(
                      icon: Icons.phone_outlined,
                      label: curriculum.phone.trim(),
                    ),
                  if (curriculum.phone.trim().isNotEmpty &&
                      curriculum.location.trim().isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: uiSpacing12),
                      child: Divider(height: 1),
                    ),
                  if (curriculum.location.trim().isNotEmpty)
                    _ContactRow(
                      icon: Icons.place_outlined,
                      label: curriculum.location.trim(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: uiSpacing24),
          ],
          if (curriculum.skills.isNotEmpty) ...[
            sectionTitle('Habilidades y Conocimientos'),
            AppCard(
              padding: const EdgeInsets.all(uiSpacing16),
              child: Wrap(
                spacing: uiSpacing8,
                runSpacing: uiSpacing8,
                children: [
                  for (final skill in curriculum.skills)
                    InfoPill(
                      label: skill,
                      backgroundColor: uiAccentSoft,
                      textColor: uiInk,
                    ),
                ],
              ),
            ),
            const SizedBox(height: uiSpacing24),
          ],
          if (curriculum.experiences.isNotEmpty) ...[
            sectionTitle('Experiencia Laboral'),
            AppCard(
              padding: const EdgeInsets.all(uiSpacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < curriculum.experiences.length; i++) ...[
                    _CurriculumItemBlock(item: curriculum.experiences[i]),
                    if (i < curriculum.experiences.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: uiSpacing16),
                        child: Divider(height: 1),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: uiSpacing24),
          ],
          if (curriculum.education.isNotEmpty) ...[
            sectionTitle('Formación Académica'),
            AppCard(
              padding: const EdgeInsets.all(uiSpacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < curriculum.education.length; i++) ...[
                    _CurriculumItemBlock(item: curriculum.education[i]),
                    if (i < curriculum.education.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: uiSpacing16),
                        child: Divider(height: 1),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: uiSpacing24),
          ],
          if (curriculum.attachment != null) ...[
            sectionTitle('Curriculum Adjunto'),
            AppCard(
              padding: const EdgeInsets.all(uiSpacing16),
              backgroundColor: uiAccentSoft,
              borderColor: Colors.transparent,
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, color: uiAccent, size: 24),
                  const SizedBox(width: uiSpacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          curriculum.attachment!.fileName,
                          style: const TextStyle(
                            color: uiInk,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: uiSpacing4),
                        Text(
                          'Archivo importado',
                          style: TextStyle(
                            color: uiMuted.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: uiMuted),
        const SizedBox(width: uiSpacing12),
        Text(label, style: const TextStyle(color: uiInk, fontSize: 15)),
      ],
    );
  }
}

class _CurriculumItemBlock extends StatelessWidget {
  const _CurriculumItemBlock({required this.item});

  final CurriculumItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: uiInk,
          ),
        ),
        if (item.subtitle.isNotEmpty) ...[
          const SizedBox(height: uiSpacing4),
          Text(
            item.subtitle,
            style: const TextStyle(
              color: uiMuted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
        if (item.period.isNotEmpty) ...[
          const SizedBox(height: uiSpacing4),
          Text(
            item.period,
            style: const TextStyle(color: uiMuted, fontSize: 13),
          ),
        ],
        if (item.description.isNotEmpty) ...[
          const SizedBox(height: uiSpacing8),
          Text(
            item.description,
            style: const TextStyle(color: uiInk, height: 1.4, fontSize: 14),
          ),
        ],
      ],
    );
  }
}
