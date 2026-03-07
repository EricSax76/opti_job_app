# Fase 2: Analisis de Integracion (carpeta recruiters)

## Objetivo
Cerrar evidencia tecnica de conexion backend->UI para la carpeta `recruiters`.

## Inventario backend (carpeta recruiters)
- `createInvitation` en `functions/src/callable/recruiters/createInvitation.ts:46`
- `acceptInvitation` en `functions/src/callable/recruiters/acceptInvitation.ts:27`
- `registerRecruiterFreelance` en `functions/src/callable/recruiters/registerRecruiterFreelance.ts:31`
- `updateRecruiterRole` en `functions/src/callable/recruiters/updateRecruiterRole.ts:29`
- `removeRecruiter` en `functions/src/callable/recruiters/removeRecruiter.ts:21`
- `syncRecruiterClaims` en `functions/src/callable/recruiters/syncRecruiterClaims.ts:27`

## Evidencia frontend
1. Uso directo de callables:
- `registerRecruiterFreelance` en Flutter:
  - `lib/auth/models/auth_service.dart:557`
- Flujo de UI que lo ejecuta:
  - `lib/modules/recruiters/ui/pages/recruiter_register_screen.dart:30`
  - `lib/auth/ui/controllers/auth_screen_controller.dart:188`
  - `lib/modules/recruiters/cubits/recruiter_auth_cubit.dart:101`
  - `lib/auth/models/auth_service.dart:535`

2. BL-002 wire_ui aplicado (gestion de equipo):
- Nueva ruta de equipo:
  - `lib/core/router/routes/recruiter_routes.dart`
  - `/recruiter/:uid/team`
- Nueva pantalla operativa:
  - `lib/modules/recruiters/ui/pages/recruiter_team_management_screen.dart`
- Punto de entrada desde dashboard:
  - `lib/modules/recruiters/ui/pages/recruiter_dashboard_screen.dart`
- Repositorio recruiters migrado a callables para mutaciones:
  - `createInvitation`
  - `acceptInvitation`
  - `updateRecruiterRole`
  - `removeRecruiter`
  - Implementacion: `lib/modules/recruiters/repositories/firebase_recruiter_repository.dart`

3. Servicios/repositorios relacionados:
- `RecruiterRepository` actualizado para exponer operaciones de callables.
- `FirebaseRecruiterRepository` ahora usa `FirebaseFunctions` + fallback regional.
- `get_it_bootstrap` inyecta `functions` y `fallbackFunctions` al repositorio recruiters.
- `InvitationService` queda como utilitario legacy/test, sin callsites en el flujo principal.

4. Evidencia E2E ejecutada:
- Suite: `functions/e2e/p3_recruiters_team_management.test.js`
- Comando: `npm run test:e2e` (emuladores Firestore + Auth)
- Resultado: casos recruiter `pass` (admin+freelance y permisos no-admin).

## Clasificacion cerrada de carpeta recruiters
1. `registerRecruiterFreelance`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

2. `createInvitation`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

3. `acceptInvitation`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

4. `updateRecruiterRole`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

5. `removeRecruiter`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

6. `syncRecruiterClaims`
- Estado: `reviewed`
- Tipo de conexion: `no_evidence` (desde UI)
- Riesgo: `medium`
- Recomendacion: `keep_internal_or_wire_admin_ui`

## Cambios aplicados
- Matriz actualizada en:
  - `docs/fase_1_matriz_trazabilidad_functions_ui.csv`

## Siguiente carpeta recomendada
Continuar con `evaluations`.

## Actualizacion BL-010 (2026-03-07)
- Decisión aplicada: `keep_internal` para `syncRecruiterClaims`.
- Acción técnica:
  - se retiró el export de `syncRecruiterClaims` en `functions/src/index.ts`,
    por lo que deja de desplegarse como callable pública.
- Ruta interna documentada para sincronizar claims:
  - trigger `onRecruiterWrite`,
  - utilidades `syncRecruiterClaims` / `syncRecruiterClaimsFromFirestore`,
  - script operativo `functions/src/scripts/backfillRecruiterClaims.ts`.
- Resultado:
  - sin callable huérfana expuesta,
  - sincronización de claims preservada en caminos internos de plataforma.
