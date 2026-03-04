# Auditoría WCAG 2.1 AA (Companies + Candidate Flows)

Fecha: 2026-03-04  
Alcance: autenticación, sidebar de empresa y portal de privacidad del candidato.

## Resultado ejecutivo

- Estado: **Remediación aplicada + regresión automatizable activa**.
- Evidencia automática: `test/accessibility/wcag_regression_test.dart`.
- Riesgo residual: bajo-medio hasta cierre de verificación manual en dispositivos físicos.

## Hallazgos y remediación

1. Semántica incompleta en navegación lateral
Estado previo: cobertura de navegación lateral sin regresión automatizada suficiente.  
Acción: verificación automatizada de semántica en sidebar de empresa y mantenimiento de labels en controles críticos.

2. Operabilidad por teclado en formularios
Estado previo: uso correcto pero sin guardrail automático.  
Acción: prueba de foco/tabulación en registro y chequeo de tamaño objetivo/contraste en login.

3. Cobertura de accesibilidad en portal de privacidad del candidato
Estado previo: sin test dedicado para acciones ARSULIPO.  
Acción: test de presencia de acciones clave (incluida exportación) y guideline de tap targets.

## Checklist WCAG 2.1 AA

- [x] 1.3.1 Info and Relationships
- [x] 1.4.3 Contrast (Minimum)
- [x] 2.1.1 Keyboard
- [x] 2.4.3 Focus Order
- [x] 2.4.6 Headings and Labels
- [x] 2.5.5 Target Size (AA)
- [x] 4.1.2 Name, Role, Value

## Regresión automatizable

Archivo:
- `test/accessibility/wcag_regression_test.dart`

Cobertura:
- Login: `labeledTapTarget`, `androidTapTarget`, `textContrast`.
- Register: navegación por teclado y orden de foco.
- Sidebar empresa: semántica de navegación.
- Portal privacidad candidato: acciones ARSULIPO accesibles y exportación.

Comando:

```bash
flutter test test/accessibility/wcag_regression_test.dart
```

## Validación manual documentada (VoiceOver/TalkBack)

Checklist operativo para cierre final en QA:

1. VoiceOver iOS: recorrer login, sidebar candidato y portal privacidad completo.
2. TalkBack Android: verificar anuncios de rol/estado en acciones ARSULIPO y chips.
3. Desktop teclado: flujo completo sin ratón (`Tab`, `Shift+Tab`, `Enter`, `Space`).
4. Contraste: validación visual en tema claro/oscuro con contenido real.

Registro de ejecución manual:

- Fecha objetivo: 2026-03-05
- Responsable: QA Accesibilidad
- Evidencia esperada: vídeo corto por flujo + checklist firmado
- Estado actual: pendiente ejecución en dispositivo físico
