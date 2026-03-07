# Fase 2: Analisis de Integracion (carpeta performance)

## Objetivo
Cerrar evidencia tecnica de conexion backend->UI para la carpeta `performance`.

## Inventario backend (carpeta performance)
- `reportWebVitalsBatch` en `functions/src/callable/performance/webVitalsCallables.ts:57`

Export relacionado en `functions/src/index.ts`:
- `export * from './callable/performance/webVitalsCallables';`

## Evidencia backend
1. Callable `reportWebVitalsBatch`
- Recibe lote de eventos Web Vitals y valida metricas (`INP`, `LCP`, `CLS`, `FCP`).
- Escribe eventos en `webVitalsEvents`.

2. Flujo de agregacion asociado
- `aggregateWebVitalsP75` (scheduled) lee `webVitalsEvents` y escribe en `performanceDashboards`.
- Referencia: `functions/src/scheduled/aggregateWebVitals.ts:50`.

## Evidencia frontend
1. Invocacion directa del callable
- `lib/core/performance/web_vitals_telemetry_web.dart:47`
  - llama `httpsCallable('reportWebVitalsBatch')` con fallback regional/default.

2. Arranque del flujo en app
- `lib/main.dart:18` llama `startWebVitalsTelemetry()`.
- `lib/core/performance/web_vitals_telemetry.dart:4` enruta a implementación web por import condicional.
- En no-web la implementación es stub (no-op), por diseño.

3. Consumo UI del resultado agregado
- `lib/modules/analytics/repositories/firebase_analytics_repository.dart:51`
  - lee `performanceDashboards/company:{companyId}` para dashboard de rendimiento.

## Clasificacion cerrada de carpeta performance
1. `reportWebVitalsBatch`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

## Cambios aplicados
- Matriz actualizada en:
  - `docs/fase_1_matriz_trazabilidad_functions_ui.csv`

## Siguiente carpeta recomendada
Continuar con `auth`.
