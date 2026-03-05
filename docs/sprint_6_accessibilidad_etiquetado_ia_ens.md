# Sprint 6 - Accesibilidad, Etiquetado IA y Cierre ENS

Estado: implementado en frontend (Flutter) + documentación operativa.

## Alcance implementado

1. Accesibilidad (WCAG 2.1 AA)
- Refuerzo de `Semantics` en acciones críticas:
  - menú de cuenta candidato,
  - importación de credenciales EUDI,
  - generación de contenido IA,
  - publicación de ofertas.
- Tests de regresión de accesibilidad actualizados:
  - `test/accessibility/wcag_regression_test.dart`
  - `test/modules/candidates/ui/widgets/candidate_settings_screen_test.dart`

2. Modo enfoque (candidatos)
- Estado global en `ThemeCubit/ThemeState`:
  - `focusModeEnabled`
- Toggle en ajustes de candidato (`CandidateSettingsScreen`).
- Comportamiento cuando está activo:
  - oculta paneles no esenciales (recordatorios en dashboard),
  - simplifica cabecera del dashboard,
  - reduce/pausa animaciones no necesarias (respeta `MediaQuery.disableAnimations`),
  - compacta densidad visual global (`VisualDensity.compact`).

3. Etiquetado IA unificado
- Componente único: `lib/core/widgets/ai_generated_label.dart`
- Aplicado en:
  - veredictos y resultados de matching,
  - explicación IA y recomendaciones en evaluación,
  - resumen IA en portal de privacidad de candidato,
  - mejora de resumen CV con IA,
  - generación de carta de presentación con IA,
  - generación de borrador de oferta con IA.

4. Operación ENS
- Runbook de incidentes y checklist de simulacro:
  - `docs/ens_runbook_incidente_autenticacion_firestore_functions.md`

## Verificación recomendada

```bash
flutter test test/accessibility/wcag_regression_test.dart
flutter test test/modules/candidates/ui/widgets/candidate_settings_screen_test.dart
```

