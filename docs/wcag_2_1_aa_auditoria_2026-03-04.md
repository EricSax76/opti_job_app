# Auditoría WCAG 2.1 AA (Módulo Companies y flujos críticos)

Fecha: 2026-03-04  
Alcance: formularios de autenticación, navegación lateral candidato/empresa, controles de tema y colapso.

## Resultado ejecutivo

- Estado: **Remediación aplicada + regresión automatizable activa**.
- Riesgo residual: medio-bajo (pendiente una validación manual final con lector de pantalla real en dispositivos físicos).
- Evidencia de regresión automática: `test/accessibility/wcag_regression_test.dart`.

## Hallazgos y remediación

1. Navegación y controles colapsados con semántica insuficiente  
Estado previo: botones y áreas de expansión sin semántica completa en sidebars.  
Acción: se añadieron etiquetas semánticas, estado `selected` y `expanded`, y activación por teclado en el overlay colapsado del sidebar de candidato.

2. Operabilidad por teclado en formularios de acceso  
Estado previo: flujo utilizable, pero sin cobertura automática de regresión.  
Acción: se consolidó `AutofillGroup`, se reforzaron etiquetas semánticas de acciones primarias y se añadió test de tabulación.

3. Etiquetas de acción en botones de autenticación y tema  
Estado previo: elementos accionables con señal visual pero sin cobertura de accesibilidad formal.  
Acción: se añadieron `Semantics` explícitas para login/registro, cambio de tema y colapsado/expandido en menús.

## Checklist WCAG 2.1 AA (operativo)

- [x] 1.3.1 Info and Relationships: jerarquía de navegación y campos con etiqueta accesible.
- [x] 1.4.3 Contrast (Minimum): cobertura por guideline automatizada en formulario login.
- [x] 2.1.1 Keyboard: interacción por teclado en formularios y control de expansión en sidebar colapsado.
- [x] 2.4.3 Focus Order: verificación de avance por tabulación en registro.
- [x] 2.4.6 Headings and Labels: labels explícitas en acciones críticas.
- [x] 4.1.2 Name, Role, Value: roles semánticos `button`, `selected`, `expanded`, `toggled`.

## Regresión automatizable

Archivo de pruebas:
- `test/accessibility/wcag_regression_test.dart`

Cobertura actual:
- Guidelines de `labeledTapTarget`, `androidTapTarget`, `textContrast` en login.
- Navegación por teclado en formulario de registro.
- Presencia semántica y acción de expandir en sidebar candidato.
- Semántica estructural del sidebar de empresa.

Comando:

```bash
flutter test test/accessibility/wcag_regression_test.dart
```

## Validación manual recomendada (pendiente)

1. VoiceOver (iOS) y TalkBack (Android) en flujos de login y sidebars.  
2. Navegación completa sin ratón en escritorio (tab/shift+tab/enter/space).  
3. Revisión de contraste en temas claro/oscuro con contenido real de producción.
