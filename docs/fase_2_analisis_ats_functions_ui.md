# Fase 2: Analisis de Integracion (carpeta ats)

## Objetivo
Cerrar evidencia tecnica de conexion backend->UI para la carpeta `ats` (bloque critico de flujo recruiter/company).

## Inventario backend (carpeta ats)
- `createJobOfferSecure` en `functions/src/callable/ats/createJobOfferSecure.ts:24`
- `evaluateKnockoutQuestions` en `functions/src/callable/ats/evaluateKnockoutQuestions.ts:44`
- `getApplicationsForReview` en `functions/src/callable/ats/getApplicationsForReview.ts:269`
- `moveApplicationStage` en `functions/src/callable/ats/moveApplicationStage.ts:8`
- `publishOfferMultiposting` en `functions/src/callable/ats/publishOfferMultiposting.ts:22`

Exports relacionados en `functions/src/index.ts`:
- `functions/src/index.ts:77` (`moveApplicationStage`)
- `functions/src/index.ts:78` (`getApplicationsForReview`)
- `functions/src/index.ts:79` (`evaluateKnockoutQuestions`)
- `functions/src/index.ts:80` (`publishOfferMultiposting`)
- `functions/src/index.ts:81` (`createJobOfferSecure`)

## Evidencia frontend por callable
1. `createJobOfferSecure`
- Invocacion callable en:
  - `lib/modules/job_offers/data/services/job_offer_write_service.dart:24`
  - `lib/modules/job_offers/data/services/job_offer_write_service.dart:32` (fallback)
- Flujo UI enlazado:
  - `lib/modules/companies/ui/widgets/company_offer_creation_tab.dart:78`
  - `lib/modules/companies/logic/company_offer_creation_controller.dart:62`
  - `lib/modules/job_offers/cubits/job_offer_form_cubit.dart:80`
  - `lib/modules/job_offers/repositories/job_offer_repository.dart:74`

2. `evaluateKnockoutQuestions`
- Invocacion callable en:
  - `lib/modules/applications/logic/application_service.dart:150`
  - `lib/modules/applications/logic/application_service.dart:155` (fallback condicional a `not-found`)
- Flujo UI enlazado:
  - `lib/modules/job_offers/ui/controllers/job_offer_detail_controller.dart:634`
  - `lib/modules/job_offers/ui/controllers/job_offer_detail_controller.dart:127`
  - `lib/modules/job_offers/cubits/job_offer_detail_cubit.dart:189`
  - `lib/modules/applications/logic/application_service.dart:47`

3. `getApplicationsForReview`
- Invocacion callable en:
  - `lib/modules/applicants/data/repositories/firebase_applicants_repository.dart:30`
  - `lib/modules/applicants/data/repositories/firebase_applicants_repository.dart:74`
- Flujo UI enlazado:
  - `lib/modules/job_offers/ui/controllers/offer_card_controller.dart:37`
  - `lib/modules/applications/cubits/offer_applicants_cubit.dart:67`
  - `lib/modules/ats/cubits/pipeline_board_cubit.dart:46`
  - `lib/modules/ats/ui/pages/pipeline_board_screen.dart:16`

4. `moveApplicationStage`
- Invocacion callable en:
  - `lib/modules/ats/cubits/pipeline_board_cubit.dart:123`
  - `lib/modules/ats/cubits/pipeline_board_cubit.dart:129` (fallback)
- Flujo UI enlazado:
  - `lib/modules/ats/ui/widgets/pipeline_stage_column.dart:25`
  - `lib/modules/ats/cubits/pipeline_board_cubit.dart:77`
  - `lib/core/router/routes/company_routes.dart:88`
  - `lib/core/router/routes/company_routes.dart:315`

5. `publishOfferMultiposting`
- Invocacion callable en:
  - `lib/modules/job_offers/ui/widgets/offer_card.dart:282`
- Flujo UI enlazado:
  - `lib/modules/job_offers/ui/widgets/offer_card.dart:118`
  - `lib/modules/job_offers/ui/widgets/offer_card.dart:241`

## Evidencia de dataflow
- `createJobOfferSecure` persiste oferta con validaciones salariales/compliance, pipeline y knockout:
  - `functions/src/callable/ats/createJobOfferSecure.ts:79`
  - `functions/src/callable/ats/createJobOfferSecure.ts:129`
  - `functions/src/callable/ats/createJobOfferSecure.ts:166`
- `getApplicationsForReview` aplica proyeccion LGPD por etapa (`blind/partial/full`) y la UI respeta anonimato:
  - `functions/src/callable/ats/getApplicationsForReview.ts:102`
  - `functions/src/callable/ats/getApplicationsForReview.ts:186`
  - `lib/modules/applicants/logic/candidate_anonymization_logic.dart:11`
- `moveApplicationStage` actualiza stage/history y puede revelar identidad en etapas definidas:
  - `functions/src/callable/ats/moveApplicationStage.ts:67`
  - `functions/src/callable/ats/moveApplicationStage.ts:91`
- `publishOfferMultiposting` crea `multipostingPublications` y actualiza estado de canales en la oferta:
  - `functions/src/callable/ats/publishOfferMultiposting.ts:86`
  - `functions/src/callable/ats/publishOfferMultiposting.ts:112`
- `evaluateKnockoutQuestions` escribe `knockoutPassed`/`requiresHumanReview` y, si falla, fuerza revisión humana:
  - `functions/src/callable/ats/evaluateKnockoutQuestions.ts:133`
  - `functions/src/callable/ats/evaluateKnockoutQuestions.ts:149`

## Hallazgo tecnico (relevante)
- `evaluateKnockoutQuestions` se ejecuta en modo best-effort: el flujo de postulación no se bloquea si falla (`application_service` captura y continúa).
- Implicación: hay trazabilidad activa, pero existe riesgo operativo de perder evaluación automática en errores transitorios.

## Clasificacion cerrada de carpeta ats
1. `createJobOfferSecure`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

2. `evaluateKnockoutQuestions`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `medium`
- Recomendacion: `keep`

3. `getApplicationsForReview`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

4. `moveApplicationStage`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

5. `publishOfferMultiposting`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

## Cambios aplicados
- Matriz actualizada en:
  - `docs/fase_1_matriz_trazabilidad_functions_ui.csv`

## Siguiente carpeta recomendada
Continuar con `interviews`.
