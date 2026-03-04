import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/inline_state_message.dart';

class PrivacyNoticeDialog extends StatelessWidget {
  const PrivacyNoticeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Información sobre Protección de Datos'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _LayerSection(
              title: '¿Quién es el responsable?',
              content: 'OptiJob AI S.L. y la empresa a la que aplicas.',
            ),
            _LayerSection(
              title: '¿Para qué usamos tus datos?',
              content:
                  'Gestionar tu candidatura, matching por skills mediante IA y mantenerte en el Talent Pool si das tu consentimiento.',
            ),
            _LayerSection(
              title: '¿Cuál es la base legal?',
              content:
                  'Tu consentimiento expreso y cumplimiento de medidas precontractuales.',
            ),
            _LayerSection(
              title: '¿A quién cedemos tus datos?',
              content:
                  'A las empresas empleadoras y proveedores tecnológicos esenciales.',
            ),
            _LayerSection(
              title: 'Tus derechos',
              content:
                  'Acceso, rectificación, supresión (bloqueo), portabilidad y limitación (ARSULIPO).',
            ),
            SizedBox(height: uiSpacing16),
            InlineStateMessage(
              icon: Icons.info_outline,
              message:
                  'Al continuar, confirmas que has leído esta información básica complementada por nuestra Política de Privacidad detallada.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _LayerSection extends StatelessWidget {
  const _LayerSection({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: uiSpacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: uiSpacing4),
          Text(content, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
