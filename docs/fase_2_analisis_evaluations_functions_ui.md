# Fase 2: Analisis de Integracion (carpeta evaluations)

## Objetivo
Cerrar evidencia tecnica de conexion backend->UI para la carpeta `evaluations`.

## Inventario backend (carpeta evaluations)
- `submitEvaluation` en `functions/src/callable/evaluations/submitEvaluation.ts:23`
- `requestApproval` en `functions/src/callable/evaluations/requestApproval.ts:30`

Ambas funciones estan exportadas en `functions/src/index.ts`:
- `export { submitEvaluation } from "./callable/evaluations/submitEvaluation";`
- `export { requestApproval } from "./callable/evaluations/requestApproval";`

## Evidencia backend
1. `submitEvaluation`
- Callable `https.onCall` con validaciones de autenticacion, pertenencia a empresa y rol recruiter.
- Escribe en `evaluations`.

2. `requestApproval`
- Callable `https.onCall` con validaciones de autenticacion, empresa y rol.
- Escribe en `approvals`.

3. Triggers relacionados:
- `onEvaluationCreate` (`triggers/firestore/evaluations/onEvaluationCreate.ts`) actualiza metricas en `applications`.
- `onApprovalUpdate` (`triggers/firestore/approvals/onApprovalUpdate.ts`) consolida estado final de aprobaciones.

## Evidencia frontend
1. Invocacion directa de callables:
- No se detectan invocaciones `httpsCallable` de `submitEvaluation` ni `requestApproval` en `lib/**`.

2. Implementacion cliente de evaluations:
- `FirebaseEvaluationRepository` escribe directamente en Firestore:
  - `evaluations`
  - `approvals`
- No usa Cloud Functions para `submitEvaluation/requestApproval`.

3. Estado de integracion del modulo:
- `FirebaseEvaluationRepository` no esta registrado en bootstrap DI principal.
- `EvaluationRepository` no aparece en `app_scope`, `bootstrap` ni rutas.
- `EvaluationFormScreen` solo aparece en su propia definicion (sin callsites activos).

## Clasificacion cerrada de carpeta evaluations
1. `submitEvaluation`
- Estado: `reviewed`
- Tipo de conexion: `no_evidence` (respecto a callable)
- Riesgo: `high`
- Recomendacion: `deprecate_or_wire_ui`

2. `requestApproval`
- Estado: `reviewed`
- Tipo de conexion: `no_evidence` (respecto a callable)
- Riesgo: `high`
- Recomendacion: `deprecate_or_wire_ui`

## Observacion tecnica
La logica de autorizacion fuerte esta en callables backend, pero el cliente de evaluations actual realiza escritura directa Firestore. Si este modulo se activa sin endurecer reglas y sin migrar a callable, existe riesgo de bypass de validaciones de negocio.

## Cambios aplicados
- Matriz actualizada en:
  - `docs/fase_1_matriz_trazabilidad_functions_ui.csv`

## Siguiente carpeta recomendada
Continuar con `ai`.
