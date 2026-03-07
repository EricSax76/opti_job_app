# Fase 2: Analisis de Integracion (carpeta talent)

## Objetivo
Cerrar evidencia tecnica de conexion backend->UI para la carpeta `talent`.

## Inventario backend (carpeta talent)
- `addToPool` en `functions/src/callable/talent/addToPool.ts:4`
- `requestConsent` en `functions/src/callable/talent/requestConsent.ts:4`

Ambas funciones estan exportadas en `functions/src/index.ts`:
- `export * from './callable/talent/addToPool';`
- `export * from './callable/talent/requestConsent';`

## Evidencia backend
1. `addToPool`
- Es callable `https.onCall`.
- Escribe en:
  - `talentPools/{poolId}/members/{candidateUid}`
  - `talentPools/{poolId}` (`memberCount`).
- Devuelve `consentRequired`.

2. `requestConsent`
- Es callable `https.onCall`.
- Escribe en:
  - `notifications` (documento de `consent_request`).

## Evidencia frontend
1. Invocacion directa de callables:
- `FirebaseTalentPoolRepository` invoca callables:
  - `addToPool`
  - `requestConsent` (cuando `addToPool` devuelve `consentRequired=true`)
  - Archivo: `lib/modules/talent_pool/repositories/firebase_talent_pool_repository.dart`

2. Dataflow de Talent Pool en Flutter:
- Flujo navegable activo:
  - Ruta nueva: `/company/:uid/talent-pools`
  - Pantalla lista: `TalentPoolListScreen`
  - Pantalla detalle: `TalentPoolDetailScreen`
- El detalle permite alta de miembro y dispara flujo callable real:
  - `TalentPoolDetailCubit.addMember` -> `TalentPoolRepository.addMemberToPool`
  - `FirebaseTalentPoolRepository.addMemberToPool` -> `addToPool` -> `requestConsent` condicional.

3. Integracion app principal:
- `TalentPoolRepository` registrado en DI:
  - `lib/bootstrap/get_it_bootstrap.dart`
  - `lib/bootstrap/app_dependencies.dart`
  - `lib/app/app_scope.dart`
- Ruta integrada en router company:
  - `lib/core/router/routes/company_routes.dart`
- Entrada de navegación desde tab de candidatos:
  - `lib/modules/companies/ui/widgets/company_candidates_tab.dart`

4. Evidencia E2E ejecutada:
- Suite nueva: `functions/e2e/p3_talent_pool_callables.test.js`
- Comando: `npm run test:e2e` (emuladores Firestore + Auth)
- Resultado: `pass 6, fail 0` (incluye 2 casos nuevos de talent).

## Clasificacion cerrada de carpeta talent
1. `addToPool`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

2. `requestConsent`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `medium`
- Recomendacion: `keep`

## Cambios aplicados
- Matriz actualizada en:
  - `docs/fase_1_matriz_trazabilidad_functions_ui.csv`

## Siguiente carpeta recomendada
Continuar con `recruiters`.
