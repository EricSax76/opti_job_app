# Fase 2: Analisis de Integracion (carpeta ai)

## Objetivo
Cerrar evidencia tecnica de conexion backend->UI para la carpeta `ai`.

## Inventario backend (carpeta ai)
- `matchCandidateWithSkills` en `functions/src/callable/ai/matchCandidateWithSkills.ts:120`
- `matchCandidateVector` en `functions/src/callable/ai/matchCandidateVector.ts:80`
- `getAiDecisionReview` en `functions/src/callable/ai/getAiDecisionReview.ts:97`
- `overrideAiDecision` en `functions/src/callable/ai/overrideAiDecision.ts:69`

## Evidencia backend
1. `matchCandidateWithSkills`
- Calcula score y escribe en `applications`:
  - `aiMatchResult` y `match_score`
  - referencia: `functions/src/callable/ai/matchCandidateWithSkills.ts:265`

2. `matchCandidateVector`
- Calcula matching vectorial y escribe en `applications`:
  - `aiMatchResult` y `match_score`
  - referencia: `functions/src/callable/ai/matchCandidateVector.ts:307`

3. `overrideAiDecision`
- Escribe override humano en `applications`:
  - `humanOverride`, `aiMatchResult.override`, `match_score`
  - referencia: `functions/src/callable/ai/overrideAiDecision.ts:131`

4. `getAiDecisionReview`
- Lee `applications` + `aiDecisionLogs` y devuelve resumen de explicabilidad:
  - referencia: `functions/src/callable/ai/getAiDecisionReview.ts:138`

## Evidencia frontend
1. Invocacion directa de callables AI:
- Busqueda en `lib/**` de `httpsCallable`/wrappers con nombres:
  - `matchCandidateWithSkills`, `matchCandidateVector`, `getAiDecisionReview`, `overrideAiDecision`
  - resultado: 0 ocurrencias.

2. Flujo AI actual en Flutter:
- El frontend usa `FirebaseAI` (Gemini via `firebase_ai`) de forma directa:
  - `lib/features/ai/api/firebase_ai_client.dart`
  - `lib/features/ai/services/ai_match_service.dart`
- `AiRepository` usa ese cliente, no Cloud Functions AI:
  - `lib/features/ai/repositories/ai_repository.dart`

3. Cadena indirecta confirmada para scores AI:
- `getApplicationsForReview` proyecta `match_score` y campos de `aiMatchResult`:
  - `functions/src/callable/ats/getApplicationsForReview.ts:204`
- Flutter consume ese callable ATS:
  - `lib/modules/applicants/data/repositories/firebase_applicants_repository.dart:30`
- UI muestra `Match` en tarjetas:
  - `lib/modules/applicants/ui/widgets/applicant_tile.dart:102`
  - `lib/modules/ats/ui/widgets/pipeline_candidate_card.dart:110`

## Clasificacion cerrada de carpeta ai
1. `matchCandidateWithSkills`
- Estado: `reviewed`
- Tipo de conexion: `indirect_ui`
- Riesgo: `medium`
- Recomendacion: `wire_explicit_trigger_path_or_keep_internal`

2. `matchCandidateVector`
- Estado: `reviewed`
- Tipo de conexion: `indirect_ui`
- Riesgo: `medium`
- Recomendacion: `wire_explicit_trigger_path_or_keep_internal`

3. `overrideAiDecision`
- Estado: `reviewed`
- Tipo de conexion: `indirect_ui`
- Riesgo: `medium`
- Recomendacion: `wire_admin_override_ui_or_keep_internal`

4. `getAiDecisionReview`
- Estado: `reviewed`
- Tipo de conexion: `no_evidence`
- Riesgo: `medium`
- Recomendacion: `wire_admin_review_ui_or_deprecate`

## Observacion tecnica
La app muestra metadatos AI (ej. `match_score`) en ATS, pero no se encontro un entrypoint Flutter que ejecute las callables `ai/*`. El valor que llega a UI depende de ejecuciones backend externas o procesos no trazados desde el cliente actual.

## Cambios aplicados
- Matriz actualizada en:
  - `docs/fase_1_matriz_trazabilidad_functions_ui.csv`

## Siguiente carpeta recomendada
Continuar con `performance`.

## Actualizacion BL-007 (2026-03-07)
- Se implementó `wire_ui` para:
  - `getAiDecisionReview`
  - `overrideAiDecision`
- Evidencia de integración frontend:
  - `ApplicantsRepository` expone ambos métodos callables con fallback regional.
  - `OfferApplicantsSection` añade acción `Revisión IA` por aplicación.
  - `AiDecisionReviewDialog` permite:
    - inspeccionar explicabilidad + trazas recientes (`aiDecisionLogs`),
    - ejecutar override con motivo y score opcional.
- Estado actualizado de estas funciones:
  - `getAiDecisionReview`: `direct_ui`
  - `overrideAiDecision`: `direct_ui`

## Actualizacion BL-008 (2026-03-07)
- Se implementó `wire_ui` con trigger manual explícito para:
  - `matchCandidateWithSkills`
  - `matchCandidateVector`
- Evidencia de integración frontend:
  - `ApplicantsRepository` expone `runAiSkillMatch(...)` y `runAiVectorMatch(...)`.
  - `AiDecisionReviewDialog` añade acciones:
    - `Recalcular skills`
    - `Recalcular vectorial`
  - Tras cada ejecución se refresca `getAiDecisionReview` para visualizar score y trazas actualizadas.
- Estado actualizado de estas funciones:
  - `matchCandidateWithSkills`: `direct_ui`
  - `matchCandidateVector`: `direct_ui`
