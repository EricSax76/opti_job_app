# Fase 2: Analisis de Integracion (carpeta auth)

## Objetivo
Cerrar evidencia tecnica de conexion backend->UI para la carpeta `auth`.

## Inventario backend (carpeta auth)
- `signInWithEudiWallet` en `functions/src/callable/auth/eudiWalletCallables.ts:33`
- `importEudiCredential` en `functions/src/callable/auth/eudiWalletCallables.ts:190`
- `createSelectiveDisclosureProof` en `functions/src/callable/auth/eudiSelectiveDisclosureCallables.ts:22`
- `verifySelectiveDisclosureProof` en `functions/src/callable/auth/eudiSelectiveDisclosureCallables.ts:190`
- `revokeSelectiveDisclosureProof` en `functions/src/callable/auth/eudiSelectiveDisclosureCallables.ts:331`

Exports relacionados en `functions/src/index.ts`:
- `export * from "./callable/auth/eudiWalletCallables";` (`functions/src/index.ts:63`)
- `export * from "./callable/auth/eudiSelectiveDisclosureCallables";` (`functions/src/index.ts:64`)

## Evidencia frontend por callable
1. `signInWithEudiWallet`
- Invocacion callable en `lib/auth/models/auth_service.dart:193`.
- Flujo UI enlazado:
  - `lib/auth/ui/pages/candidate_login_screen.dart:40`
  - `lib/auth/ui/pages/candidate_register_screen.dart:39`
  - `lib/auth/ui/controllers/auth_screen_controller.dart:140`
  - `lib/modules/candidates/cubits/candidate_auth_cubit.dart:150`

2. `importEudiCredential`
- Invocacion callable en `lib/auth/models/auth_service.dart:312`.
- Flujo UI enlazado desde ajustes de candidato:
  - `lib/modules/candidates/ui/pages/candidate_settings_screen.dart:111`
  - `lib/modules/candidates/ui/pages/candidate_settings_screen.dart:118`

3. `createSelectiveDisclosureProof`
- Invocacion callable en `lib/auth/models/auth_service.dart:321`.
- Flujo UI enlazado:
  - `lib/modules/candidates/ui/pages/candidate_settings_screen.dart:224`
  - `lib/modules/candidates/ui/pages/candidate_settings_screen.dart:232`
  - `lib/modules/candidates/ui/pages/candidate_settings_screen.dart:524`

4. `verifySelectiveDisclosureProof`
- Invocacion callable en `lib/auth/models/auth_service.dart:332` (ruta por repositorio disponible).
- Invocacion directa activa en panel recruiter:
  - `lib/modules/applicants/ui/widgets/applicant_curriculum_content.dart:193`
  - `lib/modules/applicants/ui/widgets/applicant_curriculum_content.dart:194`

5. `revokeSelectiveDisclosureProof`
- Invocacion callable en `lib/auth/models/auth_service.dart:340`.
- Flujo UI enlazado:
  - `lib/modules/candidates/ui/pages/candidate_settings_screen.dart:425`
  - `lib/modules/candidates/ui/pages/candidate_settings_screen.dart:430`

## Evidencia de dataflow
- Import EUDI escribe en `candidates/{uid}/verifiedCredentials` y la UI lo consume por stream:
  - `lib/modules/candidates/ui/pages/candidate_settings_screen.dart:452`
  - `lib/modules/candidates/ui/pages/candidate_settings_screen.dart:455`
- ZKP crea/actualiza `credentialProofs` y `credentialProofShares`; la UI lista y revoca desde `credentialProofShares`:
  - `lib/modules/candidates/ui/pages/candidate_settings_screen.dart:630`
  - `lib/modules/candidates/ui/pages/candidate_settings_screen.dart:631`
- Verificacion recruiter consume `proofId`/`proofToken` y valida correspondencia con candidato/oferta:
  - `lib/modules/applicants/ui/widgets/applicant_curriculum_content.dart:176`
  - `lib/modules/applicants/ui/widgets/applicant_curriculum_content.dart:200`

## Hallazgo tecnico (no bloqueante)
- Existen dos patrones de invocacion para `verifySelectiveDisclosureProof`:
  - via `AuthService/AuthRepository`
  - via callable directo dentro del widget recruiter
- No rompe trazabilidad (la conexion UI existe), pero conviene unificar para reducir duplicacion de manejo de errores/fallback.

## Clasificacion cerrada de carpeta auth
1. `signInWithEudiWallet`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

2. `importEudiCredential`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

3. `createSelectiveDisclosureProof`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

4. `verifySelectiveDisclosureProof`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

5. `revokeSelectiveDisclosureProof`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

## Cambios aplicados
- Matriz actualizada en:
  - `docs/fase_1_matriz_trazabilidad_functions_ui.csv`

## Siguiente carpeta recomendada
Continuar con `applications`.
