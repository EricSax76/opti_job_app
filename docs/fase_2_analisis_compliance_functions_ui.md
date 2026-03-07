# Fase 2: Analisis de Integracion (carpeta compliance)

## Objetivo
Cerrar evidencia tecnica de conexion backend->UI para la carpeta `compliance` (bloque critico RGPD/AI Act/salary compliance).

## Inventario backend (carpeta compliance)
- `submitDataRequest` en `functions/src/callable/compliance/complianceCallables.ts:19`
- `processDataRequest` en `functions/src/callable/compliance/complianceCallables.ts:138`
- `exportCandidateData` en `functions/src/callable/compliance/complianceCallables.ts:218`
- `grantAiConsent` en `functions/src/callable/compliance/aiConsentCallables.ts:14`
- `upsertSalaryBenchmark` en `functions/src/callable/compliance/salaryGapCallables.ts:10`
- `submitSalaryGapJustification` en `functions/src/callable/compliance/salaryGapCallables.ts:84`

Exports relacionados en `functions/src/index.ts`:
- `functions/src/index.ts:49` (`complianceCallables`)
- `functions/src/index.ts:50` (`salaryGapCallables`)
- `functions/src/index.ts:51` (`aiConsentCallables`)

## Evidencia frontend por callable
1. `submitDataRequest`
- Invocacion callable en:
  - `lib/modules/compliance/repositories/firebase_compliance_repository.dart:63`
- Flujo UI enlazado:
  - `lib/core/router/routes/candidate_routes.dart:110`
  - `lib/modules/compliance/ui/pages/candidate_privacy_portal_screen.dart:333`
  - `lib/modules/compliance/cubits/data_requests_cubit.dart:39`
  - `lib/modules/compliance/cubits/data_requests_cubit.dart:41`

2. `processDataRequest`
- Invocacion callable en:
  - `lib/modules/compliance/repositories/firebase_compliance_repository.dart:116`
- Flujo UI enlazado:
  - `lib/core/router/routes/company_routes.dart:141`
  - `lib/modules/compliance/ui/pages/consent_management_screen.dart:48`
  - `lib/modules/compliance/ui/pages/consent_management_screen.dart:58`

3. `exportCandidateData`
- Invocacion callable en:
  - `lib/modules/compliance/ui/pages/candidate_privacy_portal_screen.dart:261`
  - `lib/modules/compliance/ui/pages/candidate_privacy_portal_screen.dart:269` (fallback)
- Flujo UI enlazado:
  - `lib/modules/compliance/ui/pages/candidate_privacy_portal_screen.dart:60`
  - `lib/modules/compliance/ui/pages/candidate_privacy_portal_screen.dart:182`

4. `grantAiConsent`
- Invocacion callable en:
  - `lib/modules/compliance/repositories/firebase_compliance_repository.dart:151`
- Flujo UI enlazado:
  - `lib/modules/job_offers/ui/controllers/job_offer_detail_controller.dart:159`
  - `lib/modules/job_offers/ui/controllers/job_offer_detail_controller.dart:175`
  - `lib/modules/compliance/repositories/firebase_compliance_repository.dart:128`

5. `submitSalaryGapJustification`
- Invocacion callable en:
  - `lib/modules/job_offers/ui/widgets/offer_card.dart:174`
- Flujo UI enlazado:
  - `lib/modules/job_offers/ui/widgets/offer_card.dart:125`
  - `lib/modules/job_offers/ui/widgets/offer_card.dart:167`

6. `upsertSalaryBenchmark`
- Invocacion callable en:
  - `lib/modules/compliance/repositories/firebase_compliance_repository.dart` (metodo `upsertSalaryBenchmark`)
- Flujo UI enlazado:
  - `lib/core/router/routes/company_routes.dart:157`
  - `lib/modules/compliance/ui/pages/consent_management_screen.dart` (tab `Benchmarks`)
  - `lib/modules/compliance/ui/pages/consent_management_screen.dart` (formulario de actualización)
- Visibilidad por rol:
  - company owner de la ruta `companyId`,
  - recruiters activos con rol `admin` o `recruiter` de la misma empresa.
- Clasificacion: `direct_ui`.

## Evidencia de dataflow
- `submitDataRequest` crea `dataRequests` con `status: pending`, `dueAt` y SLA 30 dias:
  - `functions/src/callable/compliance/complianceCallables.ts:99`
  - `functions/src/callable/compliance/complianceCallables.ts:112`
- `processDataRequest` actualiza `status/response/processedBy/processorRole` y audita:
  - `functions/src/callable/compliance/complianceCallables.ts:189`
  - `functions/src/callable/compliance/complianceCallables.ts:199`
- `exportCandidateData` agrega `curriculum`, `applications`, `consents`, `candidateNotes`, `dataRequests`:
  - `functions/src/callable/compliance/complianceCallables.ts:228`
  - `functions/src/callable/compliance/complianceCallables.ts:243`
- `grantAiConsent` persiste `consentRecords` inmutable con `consentHash`, `scope` y `expiresAt`:
  - `functions/src/callable/compliance/aiConsentCallables.ts:57`
  - `functions/src/callable/compliance/aiConsentCallables.ts:67`
- `submitSalaryGapJustification` desbloquea oferta (`status: active`) y registra justificacion/auditoria:
  - `functions/src/callable/compliance/salaryGapCallables.ts:139`
  - `functions/src/callable/compliance/salaryGapCallables.ts:150`
- `upsertSalaryBenchmark` escribe `salaryBenchmarks`, usados luego por trigger de auditoria salarial:
  - `functions/src/callable/compliance/salaryGapCallables.ts:56`
  - `functions/src/triggers/firestore/onJobOfferCreate.ts:55`

## Hallazgos tecnicos (relevantes)
- `upsertSalaryBenchmark` queda integrado en pantalla company de compliance con formulario y tabla de benchmarks.
- `exportCandidateData` se invoca directo desde pantalla (no via repositorio compliance), con fallback regional/manual en el widget.

## Clasificacion cerrada de carpeta compliance
1. `submitDataRequest`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

2. `processDataRequest`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `medium`
- Recomendacion: `keep`

3. `exportCandidateData`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `medium`
- Recomendacion: `keep`

4. `grantAiConsent`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

5. `submitSalaryGapJustification`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

6. `upsertSalaryBenchmark`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

## Validacion E2E
- Suite nueva: `functions/e2e/p3_compliance_salary_benchmark.test.js`
- Cobertura:
  - company owner puede registrar benchmarks por género,
  - recruiter `admin` activo puede registrar benchmark,
  - recruiter `viewer` recibe `permission-denied`.

## Cambios aplicados
- Matriz actualizada en:
  - `docs/fase_1_matriz_trazabilidad_functions_ui.csv`

## Siguiente carpeta recomendada
Continuar con `analytics`/`performance` solo para consolidación final o pasar a revisión transversal de riesgos.
