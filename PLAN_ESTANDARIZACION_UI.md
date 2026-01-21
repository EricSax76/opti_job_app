# Plan de Estandarización UI - OptiJob

**Fecha**: 2026-01-21  
**Objetivo**: Eliminar duplicaciones, centralizar estilos y crear componentes core reutilizables

---

## 📊 Resumen Ejecutivo

Basado en el análisis exhaustivo de `lib/modules`, se identificaron **7 áreas críticas** de duplicación que afectan mantenibilidad y coherencia visual. Este plan prioriza las acciones por impacto y facilidad de implementación.

---

## 🎯 Fase 1: Tokens y Temas (Fundación)

### 1.1 Ampliar ui_tokens.dart

**Archivo**: `/lib/core/theme/ui_tokens.dart`

**Estado actual**: Solo contiene 5 colores y 3 radios  
**Problema**: Colores y valores duplicados en 15+ archivos

**Acción**:

```dart
// Ampliar con:
// - Más valores de espaciado (spacing tokens)
// - Sombras estandarizadas
// - Durations para animaciones
// - Breakpoints para responsive
```

**Referencias a migrar**:

- `candidate_login_form.dart`: líneas 24-28 (colores duplicados)
- `job_offer_header.dart`: líneas 19-21 (colores duplicados)
- `curriculum_styles.dart`: archivo completo → migrar a ui_tokens
- `profile_form_content.dart`: constantes inline de color
- `applicant_curriculum_screen.dart`: constantes de color

**Estimación**: 1-2 horas  
**Prioridad**: 🔴 CRÍTICA (bloquea el resto)

---

### 1.2 Crear ThemeExtensions para InputDecoration

**Archivo nueva**: `/lib/core/theme/app_input_theme.dart`

**Problema**: 8+ archivos reimplementan la misma decoración de inputs

**Acción**:

```dart
// Crear InputDecorationTheme centralizado
// Incluir variantes: default, error, success
```

**Referencias a migrar**:

- `candidate_login_form.dart`: método `_inputDecoration` (líneas 154-168)
- `candidate_register_form.dart`: decoración similar
- `company_login_form.dart`: decoración idéntica
- `company_register_form.dart`: decoración idéntica
- `profile_form_content.dart`: inputs custom

**Estimación**: 2 horas  
**Prioridad**: 🔴 ALTA

---

### 1.3 Crear ButtonThemes centralizados

**Archivo nueva**: `/lib/core/theme/app_button_theme.dart`

**Problema**: FilledButton y OutlinedButton con estilos inline repetidos

**Acción**:

```dart
// FilledButtonThemeData + OutlinedButtonThemeData
// Variantes: primary, secondary, danger
```

**Referencias**:

- `candidate_login_form.dart`: líneas 110-114
- Todos los formularios auth (candidates, company)

**Estimación**: 1 hora  
**Prioridad**: 🟡 MEDIA

---

## 🧱 Fase 2: Componentes Core (Building Blocks)

### 2.1 AppCard / SectionCard

**Archivo nuevo**: `/lib/core/widgets/app_card.dart`

**Problema**: 10+ archivos crean containers con `white + border + radius 24`

**Acción**:

```dart
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  // Usar ui_tokens para color, border, radius
}

class SectionCard extends AppCard {
  // Variante con padding específico para secciones
}
```

**Referencias a reemplazar**:

- `candidate_login_form.dart`: Container líneas 44-50
- `job_offer_header.dart`: Container líneas 35-41
- `job_offer_details.dart`: tarjetas similares
- `applicant_curriculum_header.dart`: cards repetidas
- `section_message.dart`: Card con estilos custom
- `profile_form_content.dart`: múltiples containers con misma receta

**Estimación**: 2 horas  
**Prioridad**: 🔴 ALTA

---

### 2.2 InfoPill (Badge Component)

**Archivo nuevo**: `/lib/core/widgets/info_pill.dart`

**Problema**: Pill con `border + radius 999 + icon + label` aparece en 4+ módulos

**Acción**:

```dart
class InfoPill extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color? backgroundColor;
  final Color? borderColor;

  // Extraer de _InfoPill en job_offer_header.dart
}
```

**Referencias a reemplazar**:

- `job_offer_header.dart`: clase `_InfoPill` líneas 123-165
- `job_offer_summary_card.dart`: pills similares
- `candidate_card.dart`: badges de estado

**Estimación**: 1.5 horas  
**Prioridad**: 🟡 MEDIA-ALTA

---

### 2.3 Extender SectionHeader (variantes)

**Archivo existente**: `/lib/core/widgets/section_header.dart`

**Problema**: Algunos módulos necesitan header sin tagline/subtitle

**Acción**:

```dart
// Modificar SectionHeader para hacer tagline/subtitle opcionales
class SectionHeader extends StatelessWidget {
  final String? tagline;  // hacer opcional
  final String title;
  final String? subtitle; // hacer opcional
  // ...
}
```

**Referencias a migrar**:

- `dashboard_home_header.dart`: puede usar SectionHeader extendido
- `company_offers_header.dart`: ídem
- Varios módulos con headers custom simples

**Estimación**: 1 hora  
**Prioridad**: 🟡 MEDIA

---

### 2.4 InlineStateMessage (variante StateMessage)

**Archivo nuevo**: `/lib/core/widgets/inline_state_message.dart`

**Problema**: Algunos contextos necesitan estado inline, no centrado

**Acción**:

```dart
class InlineStateMessage extends StatelessWidget {
  final IconData? icon;
  final String message;
  final Widget? action;

  // Variante compacta de StateMessage sin Card
}
```

**Referencias**:

- `section_message.dart`: reemplazar con StateMessage o InlineStateMessage
- `job_offer_detail_widgets.dart`: estados inline
- `my_applications_view.dart`: mensajes vacíos
- `job_offer_list_screen.dart`: estado vacío

**Estimación**: 1.5 horas  
**Prioridad**: 🟡 MEDIA

---

### 2.5 AuthFormCard / FormSection

**Archivo nuevo**: `/lib/core/widgets/auth_form_card.dart`

**Problema**: Login/Register forms replican toda la estructura (card + header + campos)

**Acción**:

```dart
class AuthFormCard extends StatelessWidget {
  final String tagline;
  final String title;
  final String subtitle;
  final Widget formContent;

  // Wrapper reutilizable para formularios auth
}
```

**Referencias**:

- `candidate_login_form.dart`: líneas 44-143
- `candidate_register_form.dart`: estructura similar
- `company_login_form.dart`: ídem
- `company_register_form.dart`: ídem
- `profile_form_content.dart`: puede usar variante

**Estimación**: 2 horas  
**Prioridad**: 🟡 MEDIA

---

## 🔄 Fase 3: Migraciones (Aplicar cambios)

### 3.1 Migrar módulo auth/candidates

**Archivos a modificar**:

- `candidate_login_form.dart`
- `candidate_register_form.dart`

**Acciones**:

1. Reemplazar constantes inline por `ui_tokens`
2. Usar `AuthFormCard` para estructura
3. Usar `AppInputTheme` para inputs
4. Usar `AppButtonTheme` para botones

**Estimación**: 2 horas

---

### 3.2 Migrar módulo auth/company

**Archivos**: `company_login_form.dart`, `company_register_form.dart`

**Acciones**: Igual que 3.1

**Estimación**: 1.5 horas

---

### 3.3 Migrar módulo job_offers

**Archivos**:

- `job_offer_header.dart`
- `job_offer_summary_card.dart`
- `job_offer_details.dart`
- `job_offer_list_screen.dart`

**Acciones**:

1. Reemplazar `_InfoPill` por `InfoPill` core
2. Usar `AppCard` para containers
3. Reemplazar constantes por `ui_tokens`
4. Homogeneizar `JobOfferListScreen` con `JobOfferSummaryCard`

**Estimación**: 3 horas

---

### 3.4 Migrar módulo profile

**Archivos**:

- `profile_form_content.dart`

**Acciones**:

1. Usar `ui_tokens` para colores/radios
2. Usar `AppInputTheme`
3. Considerar `SectionCard` para secciones

**Estimación**: 1.5 horas

---

### 3.5 Migrar módulo curriculum

**Archivos**:

- `applicant_curriculum_screen.dart`
- `applicant_curriculum_header.dart`
- `curriculum_styles.dart` (eliminar, migrar a ui_tokens)

**Acciones**:

1. **Eliminar** `curriculum_styles.dart` completamente
2. Migrar sus constantes a `ui_tokens`
3. Actualizar imports en todos los archivos del módulo
4. Usar `AppCard` para cards
5. Usar `InfoPill` para badges

**Estimación**: 2.5 horas

---

### 3.6 Migrar módulo dashboard

**Archivos**:

- `dashboard_home_header.dart`
- `company_offers_header.dart`
- Otros headers custom

**Acciones**:

1. Reemplazar por `SectionHeader` core (ahora con campos opcionales)
2. Unificar estilos

**Estimación**: 1 hora

---

### 3.7 Migrar módulo applications

**Archivos**:

- `my_applications_view.dart`
- Mensajes de estado vacío

**Acciones**:

1. Usar `StateMessage` o `InlineStateMessage`
2. Unificar manejo de estados

**Estimación**: 1 hora

---

## 📈 Cronograma Estimado

| Fase                      | Duración        | Dependencias    |
| ------------------------- | --------------- | --------------- |
| **Fase 1** (Tokens/Temas) | 4-5 horas       | Ninguna         |
| **Fase 2** (Componentes)  | 8-9 horas       | Requiere Fase 1 |
| **Fase 3** (Migraciones)  | 12-13 horas     | Requiere Fase 2 |
| **TOTAL**                 | **24-27 horas** | -               |

---

## ✅ Criterios de Éxito

- [ ] Zero constantes de color/radius inline en módulos
- [ ] Zero decoraciones de input duplicadas
- [ ] `curriculum_styles.dart` eliminado
- [ ] Todos los headers usan `SectionHeader` o variante
- [ ] Todas las cards usan `AppCard` o `SectionCard`
- [ ] Todas las pills usan `InfoPill`
- [ ] Todos los estados usan `StateMessage` o `InlineStateMessage`
- [ ] Todos los forms auth usan `AuthFormCard`
- [ ] Tests pasan después de cada migración

---

## 🔧 Orden de Ejecución Recomendado

1. **Día 1**: Fase 1 completa (fundación)
2. **Día 2**: Fase 2.1, 2.2, 2.3 (componentes principales)
3. **Día 3**: Fase 2.4, 2.5 + Fase 3.1, 3.2 (migrar auth)
4. **Día 4**: Fase 3.3, 3.4 (migrar job_offers, profile)
5. **Día 5**: Fase 3.5, 3.6, 3.7 (resto + testing)

---

## 📝 Notas Importantes

- **No romper funcionalidad**: Cada migración debe pasar tests
- **Git**: Commit después de cada fase completada
- **Documentación**: Actualizar README core con nuevos widgets
- **Backwards compatibility**: Deprecar widgets viejos gradualmente si hay dependencias externas

---

## 🚀 Quick Wins (si hay poco tiempo)

Si solo hay tiempo para lo esencial:

1. **ui_tokens** ampliado (1.1) → impacto inmediato en coherencia
2. **AppCard** (2.1) → elimina 80% de duplicación de containers
3. **InfoPill** (2.2) → unifica badges en job_offers
4. **Migrar curriculum** (3.5) → eliminar `curriculum_styles.dart` es muy valioso

**Total Quick Wins**: ~7-8 horas, impacto del 60% del plan completo

---

## Referencias Técnicas

### Archivos Core Existentes

- ✅ `/lib/core/widgets/section_header.dart` (reutilizable)
- ✅ `/lib/core/widgets/state_message.dart` (reutilizable)
- ✅ `/lib/core/theme/ui_tokens.dart` (ampliar)

### Archivos a Crear

- `/lib/core/theme/app_input_theme.dart`
- `/lib/core/theme/app_button_theme.dart`
- `/lib/core/widgets/app_card.dart`
- `/lib/core/widgets/info_pill.dart`
- `/lib/core/widgets/inline_state_message.dart`
- `/lib/core/widgets/auth_form_card.dart`

### Archivos a Eliminar

- `/lib/modules/curriculum/ui/styles/curriculum_styles.dart`

---

**Fin del Plan** 🎯
