# Fase 6: Estandarizacion del Shell de Core

## Objetivo
Unificar navegacion, app bar y comportamiento responsive para movil/desktop mediante un shell comun del core en todas las paginas funcionales.

## Problema que resuelve
Hoy existe consistencia parcial (por ejemplo, `AppNavBar`), pero el layout principal se arma de forma distribuida por modulo:
- Varias pantallas crean su propio `Scaffold`.
- Existen app bars distintas segun modulo.
- Hay `Scaffold` anidados dentro de tabs/vistas que viven dentro de un dashboard.
- El router usa `GoRoute` plano sin un shell estructural comun para grupos de rutas.

Esto incrementa costo de mantenimiento, riesgo de regresiones responsive y divergencia UX entre flujos equivalentes.

## Linea base actual (2026-02-17)
- Router sin `ShellRoute`:
  - `lib/core/router/app_router.dart`
- App bar comun liviano (no shell completo):
  - `lib/core/widgets/app_nav_bar.dart`
- Pantallas funcionales con `Scaffold` propio + `AppNavBar`:
  - `lib/auth/ui/pages/candidate_login_screen.dart`
  - `lib/auth/ui/pages/company_login_screen.dart`
  - `lib/auth/ui/pages/candidate_register_screen.dart`
  - `lib/auth/ui/pages/company_register_screen.dart`
  - `lib/modules/job_offers/ui/pages/job_offer_list_screen.dart`
  - `lib/modules/job_offers/ui/pages/job_offer_detail_screen.dart`
  - `lib/home/pages/landing_screen.dart`
  - `lib/home/pages/onboarding_screen.dart`
- Pantallas funcionales con app bar personalizada por modulo:
  - `lib/modules/candidates/ui/widgets/candidate_dashboard_scaffold.dart`
  - `lib/modules/companies/ui/pages/company_dashboard_screen.dart`
  - `lib/modules/companies/ui/pages/company_profile_screen.dart`
  - `lib/modules/profiles/ui/pages/profile_screen.dart`
  - `lib/modules/applicants/ui/pages/applicant_curriculum_screen.dart`
  - `lib/features/cover_letter/view/cover_letter_screen.dart`
  - `lib/modules/interviews/ui/widgets/chat/interview_chat_view.dart`
  - `lib/features/video_curriculum/view/video_playback_screen.dart`
- Casos con `Scaffold` anidado dentro de shell de dashboard (deuda explicita):
  - `lib/modules/candidates/ui/widgets/interviews_view.dart`
  - `lib/modules/companies/ui/widgets/company_interviews_tab.dart`
  - `lib/features/cover_letter/view/cover_letter_screen.dart` (cuando vive dentro de `CandidateDashboardScreen`)

## Politica de arquitectura (Fase 6)
Permitido:
- Todas las paginas funcionales de modulos en alcance usan shell comun del core.
- Variaciones por rol/area se resuelven por configuracion del shell (slots/variant), no por `Scaffold` duplicado.
- Excepciones solo si estan registradas y justificadas como flujo especial (ejemplo: reproductor fullscreen).

No permitido:
- `Scaffold` aislado en paginas funcionales donde el modulo exige shell comun.
- `Scaffold` anidado en vistas hijas de un shell ya activo, salvo excepcion documentada.
- Crear nueva app bar de modulo para casos que el shell ya cubre.

Regla principal:
- Un modulo en alcance define una sola entrada de shell; las vistas internas entregan contenido, no estructura de pagina.

## Alcance
En alcance:
- Rutas funcionales de `auth`, `home`, `job_offers`, `candidates`, `companies`, `profiles`, `applicants`, `interviews` y features integradas al dashboard.

Fuera de alcance (esta fase):
- Reescritura de logica de negocio.
- Cambios funcionales de casos de uso.
- Overhaul visual completo de branding/tema.

## Patron objetivo
Contrato esperado del shell:
```dart
class CoreShell extends StatelessWidget {
  const CoreShell({
    super.key,
    required this.body,
    this.variant = CoreShellVariant.standard,
    this.title,
    this.actions,
    this.drawer,
    this.navigationRail,
    this.bottomNavigationBar,
    this.fab,
  });

  final Widget body;
  final CoreShellVariant variant;
  final String? title;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? navigationRail;
  final Widget? bottomNavigationBar;
  final Widget? fab;
}
```

Principios del patron:
- El `Scaffold` vive en un solo lugar (`CoreShell`).
- `AppBar` se compone por configuracion (`title`, `actions`, `variant`), no por duplicacion.
- Responsive centralizado (breakpoints y switching sidebar/drawer/bottom nav).
- Contenedores/paginas hijas no crean otro `Scaffold`.

## Excepciones documentadas
Plantilla minima por excepcion:
1. Ruta/archivo.
2. Motivo tecnico del flujo especial.
3. Duracion esperada (temporal/permanente).
4. Owner y fecha de revision.

Excepciones iniciales candidatas:
- `lib/features/video_curriculum/view/video_playback_screen.dart`
  - Motivo: experiencia inmersiva de reproduccion de video (flujo fullscreen/task focus).
- `lib/modules/interviews/ui/widgets/chat/interview_chat_view.dart`
  - Motivo: flujo conversacional de alta concentracion (evaluar si se mantiene aislado o se integra como variant de shell).

## Plan de ejecucion recomendado

### Fase 6.1 - Inventario y frontera de shell
Objetivo:
- Definir exactamente donde aplica shell comun y detectar desviaciones.

Estado:
- Completada (2026-02-17).
- Evidencia: `docs/fase_6_1_inventario_shell_core.md`.

Acciones:
1. Auditar `Scaffold`/`appBar` por rutas funcionales.
2. Clasificar cada pagina: `migrar`, `ok`, `excepcion`.
3. Publicar allowlist inicial de excepciones.

Comandos sugeridos:
1. `rg -n "Scaffold\\(" lib --glob '*screen.dart' --glob '*page.dart' --glob '*view.dart'`
2. `rg -n "appBar:\\s*" lib --glob '*screen.dart' --glob '*page.dart' --glob '*view.dart'`
3. `rg -n "ShellRoute|GoRoute\\(|path:\\s*'" lib/core/router/app_router.dart`

Entregable:
- Inventario versionado con estado por archivo/ruta.

### Fase 6.2 - Definir CoreShell del core
Objetivo:
- Centralizar estructura de pagina en un solo componente reutilizable.

Estado:
- Completada (2026-02-17).
- Evidencia tecnica:
  - `lib/core/shell/core_shell.dart`
  - `lib/core/shell/core_shell_breakpoints.dart`
  - `lib/core/widgets/app_nav_bar.dart` (adaptado a `CoreShellAppBar`)
  - `lib/modules/candidates/models/candidate_dashboard_navigation.dart` (breakpoint centralizado en core)

Acciones:
1. Crear `CoreShell` y configuraciones base de app bar/navegacion.
2. Definir variantes minimas (`public`, `candidate`, `company`, `immersive`).
3. Centralizar breakpoints responsive en core.

Entregable:
- Componente shell comun listo para adopcion incremental.

### Fase 6.3 - Migrar rutas de baja complejidad
Objetivo:
- Reducir rapido la duplicacion en pantallas simples.

Estado:
- Completada (2026-02-17).
- Evidencia tecnica:
  - `lib/home/pages/landing_screen.dart`
  - `lib/home/pages/onboarding_screen.dart`
  - `lib/modules/job_offers/ui/pages/job_offer_list_screen.dart`
  - `lib/modules/job_offers/ui/pages/job_offer_detail_screen.dart`
  - `lib/auth/ui/pages/candidate_login_screen.dart`
  - `lib/auth/ui/pages/company_login_screen.dart`
  - `lib/auth/ui/pages/candidate_register_screen.dart`
  - `lib/auth/ui/pages/company_register_screen.dart`

Acciones:
1. Migrar auth, landing/onboarding y job offers list/detail a `CoreShell`.
2. Eliminar construccion manual de `Scaffold` repetido en esas rutas.
3. Validar paridad visual y de navegacion.

Entregable:
- Primer bloque de rutas funcionales en shell comun.

### Fase 6.4 - Migrar dashboards y eliminar scaffolds anidados
Objetivo:
- Unificar comportamiento complejo movil/desktop.

Estado:
- Completada (2026-02-17).
- Evidencia tecnica:
  - `lib/modules/candidates/ui/widgets/candidate_dashboard_scaffold.dart` (ahora sobre `CoreShell`)
  - `lib/modules/companies/ui/pages/company_dashboard_screen.dart` (ahora sobre `CoreShell`)
  - `lib/modules/candidates/ui/widgets/interviews_view.dart` (sin `Scaffold` anidado)
  - `lib/modules/companies/ui/widgets/company_interviews_tab.dart` (sin `Scaffold` anidado)
  - `lib/modules/candidates/ui/pages/candidate_dashboard_pages.dart` (usa `CoverLetterContainer` embebido, sin pantalla con `Scaffold` dentro del dashboard)

Acciones:
1. Adaptar candidate/company dashboard para usar `CoreShell` como estructura raiz.
2. Convertir vistas internas con `Scaffold` anidado a widgets de contenido.
3. Mantener navegacion responsive (sidebar/drawer/bottom nav) desde shell.

Entregable:
- Dashboards sobre shell comun sin scaffolds anidados no justificados.

### Fase 6.5 - Excepciones y trazabilidad
Objetivo:
- Mantener controladas las excepciones inevitables.

Estado:
- Completada (2026-02-17).
- Evidencia tecnica:
  - `docs/fase_6_5_registro_excepciones_shell_core.md`
  - `lib/core/router/app_router.dart` (etiqueta `shell-ex-001`)
  - `lib/features/video_curriculum/view/video_curriculum_playback_helpers.dart` (etiqueta `shell-ex-002`)
  - `lib/features/video_curriculum/view/video_playback_screen.dart` (comentario de arquitectura `shell-ex-002`)

Acciones:
1. Crear registro de excepciones en docs (ruta, razon, owner, revision).
2. Etiquetar rutas de excepcion en router/comentarios de arquitectura.
3. Revisar semestralmente si siguen siendo necesarias.

Entregable:
- Registro explicito y auditable de excepciones.

### Fase 6.6 - Guardrails CI
Objetivo:
- Evitar regresion a scaffolds aislados.

Estado:
- Completada (2026-02-17).
- Evidencia tecnica:
  - `tool/check_core_shell_policy.sh`
  - `.github/workflows/architecture_guardrails.yml` (step `Check CoreShell policy`)
  - `docs/fase_6_5_registro_excepciones_shell_core.md` (source of truth para allowlist de excepciones)

Alcance del guardrail:
- Enforced (incremental): zonas ya migradas en Fase 6.3/6.4.
- Allowlist aprobada: `shell-ex-001`, `shell-ex-002`.

Acciones:
1. Agregar chequeo CI para detectar `Scaffold` fuera de zonas permitidas.
2. Definir allowlist corta para excepciones aprobadas.
3. Incluir checklist de shell en code review.

Entregable:
- Regla automatica activa que protege el patron.

### Fase 6.7 - Cierre y validacion DoD
Objetivo:
- Confirmar estandarizacion de shell completada.

Acciones:
1. Reauditar codigo y comparar contra inventario inicial.
2. Ejecutar smoke tests de navegacion en movil/desktop.
3. Documentar deuda residual y fecha de seguimiento.

Entregable:
- Acta de cierre de Fase 6 con evidencia tecnica.

## Riesgos y mitigaciones
Riesgo:
- Regresiones UX en dashboard por cambio estructural de layout.
Mitigacion:
- Migracion por lotes + pruebas visuales por breakpoint.

Riesgo:
- Reaparicion de scaffolds aislados en PR nuevos.
Mitigacion:
- Guardrail CI + checklist de revision.

Riesgo:
- Excepciones crecen sin control.
Mitigacion:
- Registro formal obligatorio y revisiones periodicas.

## Definition of Done (DoD)
Se considera completada la Fase 6 cuando:
1. Todas las paginas funcionales en alcance usan shell comun del core.
2. No existen `Scaffold` aislados en modulos donde se exige shell comun.
3. Toda excepcion esta documentada con justificacion, owner y fecha de revision.
4. Comportamiento de navegacion/app bar/responsive es consistente en movil y desktop.
5. Guardrail automatizado en CI bloquea nuevas violaciones del patron.

## Checklist operativo por PR (Fase 6)
1. Este cambio introduce `Scaffold` nuevo fuera del shell comun: no.
2. Si existe excepcion, esta registrada y aprobada: si/no (justificar).
3. Se mantuvo consistencia responsive movil/desktop: si.
4. Se verifico navegacion y acciones de app bar en el flujo afectado: si.
5. Pasa chequeo automatizado de shell en CI: si.

## Metricas de seguimiento sugeridas
- `metric_1`: conteo de `Scaffold` en paginas funcionales fuera del shell comun (target: 0, salvo excepciones allowlist).
- `metric_2`: conteo de `Scaffold` anidados dentro de dashboards/tab views (target: 0).
- `metric_3`: numero de excepciones abiertas sin fecha de revision vigente (target: 0).
