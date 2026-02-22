import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class CandidateSettingsScreen extends StatelessWidget {
  const CandidateSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark ? uiDarkBackground : uiBackground;
    final border = isDark ? uiDarkBorder : uiBorder;
    final appBarBg = isDark ? uiDarkBackground : Colors.white;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Ajustes'),
        centerTitle: true,
        backgroundColor: appBarBg,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          uiSpacing16,
          uiSpacing16,
          uiSpacing16,
          uiSpacing24,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SettingsPlaceholderMessage(),
            SizedBox(height: uiSpacing16),
            _SettingsSection(
              title: 'Datos de acceso',
              items: ['Cambiar email', 'Cambiar contraseña'],
            ),
            SizedBox(height: uiSpacing16),
            _SettingsSection(
              title: 'Notificaciones y consejos',
              items: [
                'Alertas de empleo por email',
                'Configura tus comunicaciones',
              ],
            ),
            SizedBox(height: uiSpacing16),
            _SettingsSection(
              title: 'Privacidad',
              items: ['Qué ven las empresas', 'Bloquear empresas'],
            ),
            SizedBox(height: uiSpacing16),
            _SettingsStandaloneItem(title: 'Promociones de nuestros productos'),
            SizedBox(height: uiSpacing12),
            _SettingsStandaloneItem(title: 'Publicidad programática'),
            SizedBox(height: uiSpacing16),
            _SettingsSection(
              title: 'Cómo gestionamos tus datos',
              items: ['Descarga una copia de tus datos.'],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPlaceholderMessage extends StatelessWidget {
  const _SettingsPlaceholderMessage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? uiDarkBorder : uiBorder;
    return Container(
      padding: const EdgeInsets.all(uiSpacing16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(uiTileRadius),
        border: Border.all(color: border),
      ),
      child: Text(
        'Estamos preparando cada apartado. En otro momento desarrollaremos cada sección.',
        style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.35),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? uiDarkBorder : uiBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(uiTileRadius),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              uiSpacing16,
              uiSpacing16,
              uiSpacing16,
              uiSpacing8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colorScheme.outlineVariant),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: uiSpacing16,
              ),
              title: Text(items[i]),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsStandaloneItem extends StatelessWidget {
  const _SettingsStandaloneItem({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? uiDarkBorder : uiBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(uiTileRadius),
        border: Border.all(color: border),
      ),
      child: ListTile(
        title: Text(title),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
