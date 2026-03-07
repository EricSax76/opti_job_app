# Fase 2: Analisis de Integracion (carpeta applications)

## Objetivo
Cerrar evidencia tecnica de conexion backend->UI para la carpeta `applications`.

## Inventario backend (carpeta applications)
- `submitApplication` en `functions/src/callable/applications/submitApplication.ts:72`
- `startQualifiedOfferSignature` en `functions/src/callable/applications/qualifiedSignatureCallables.ts:17`
- `confirmQualifiedOfferSignature` en `functions/src/callable/applications/qualifiedSignatureCallables.ts:143`
- `getQualifiedOfferSignatureStatus` en `functions/src/callable/applications/qualifiedSignatureCallables.ts:316`

Exports relacionados en `functions/src/index.ts`:
- `export { submitApplication } from "./callable/applications/submitApplication";` (`functions/src/index.ts:62`)
- `export * from "./callable/applications/qualifiedSignatureCallables";` (`functions/src/index.ts:65`)

## Evidencia frontend por callable
1. `submitApplication`
- Invocacion callable en:
  - `lib/modules/applications/logic/application_service.dart:72`
  - `lib/modules/applications/logic/application_service.dart:87` (fallback)
- Flujo UI enlazado:
  - `lib/modules/job_offers/ui/containers/job_offer_detail_container.dart:50`
  - `lib/modules/job_offers/ui/controllers/job_offer_detail_controller.dart:106`
  - `lib/modules/job_offers/cubits/job_offer_detail_cubit.dart:189`
  - `lib/modules/job_offers/ui/widgets/job_offer_actions.dart:40`

2. `startQualifiedOfferSignature`
- Invocacion callable en:
  - `lib/modules/applications/logic/application_service.dart:170`
- Flujo UI enlazado:
  - `lib/modules/job_offers/ui/widgets/job_offer_actions.dart:55`
  - `lib/modules/job_offers/ui/containers/job_offer_detail_container.dart:41`
  - `lib/modules/job_offers/ui/controllers/job_offer_detail_controller.dart:382`
  - `lib/modules/job_offers/ui/controllers/job_offer_detail_controller.dart:412`

3. `confirmQualifiedOfferSignature`
- Invocacion callable en:
  - `lib/modules/applications/logic/application_service.dart:188`
- Flujo UI enlazado:
  - `lib/modules/job_offers/ui/controllers/job_offer_detail_controller.dart:428`

4. `getQualifiedOfferSignatureStatus`
- Invocacion callable en:
  - `lib/modules/applications/logic/application_service.dart:203`
- Flujo UI enlazado:
  - `lib/modules/job_offers/ui/controllers/job_offer_detail_controller.dart:391`

## Evidencia de dataflow
- `submitApplication` crea documentos en `applications` con `status: "pending"` y retorna `applicationId`:
  - `functions/src/callable/applications/submitApplication.ts:286`
  - `functions/src/callable/applications/submitApplication.ts:338`
- El estado de candidatura creado se refleja en UI via refresh/lectura de application:
  - `lib/modules/job_offers/cubits/job_offer_detail_cubit.dart:196`
  - `lib/modules/job_offers/ui/widgets/detail/job_offer_detail_content.dart:60`
- `startQualifiedOfferSignature` actualiza `applications.status` a `accepted_pending_signature` y crea `contractSignature`:
  - `functions/src/callable/applications/qualifiedSignatureCallables.ts:81`
- `confirmQualifiedOfferSignature` actualiza `applications.status` a `accepted` y persiste `qualifiedSignatures`:
  - `functions/src/callable/applications/qualifiedSignatureCallables.ts:231`
  - `functions/src/callable/applications/qualifiedSignatureCallables.ts:247`
- Tras confirmar firma, la UI refresca el detalle para mostrar estado actualizado:
  - `lib/modules/job_offers/ui/controllers/job_offer_detail_controller.dart:437`

## Hallazgo tecnico (no bloqueante)
- `ApplicationRepository` mantiene `createApplication` por escritura directa en Firestore (`lib/modules/applications/repositories/application_repository.dart:15`), pero el flujo activo de UI usa `submitApplication` via callable (`lib/modules/job_offers/cubits/job_offer_detail_cubit.dart:189`).
- Recomendable mantener esta convencion y evitar futuras llamadas directas para no saltar validaciones/rate limit server-side.

## Clasificacion cerrada de carpeta applications
1. `submitApplication`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

2. `startQualifiedOfferSignature`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

3. `confirmQualifiedOfferSignature`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

4. `getQualifiedOfferSignatureStatus`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

## Cambios aplicados
- Matriz actualizada en:
  - `docs/fase_1_matriz_trazabilidad_functions_ui.csv`

## Siguiente carpeta recomendada
Continuar con `ats`.
