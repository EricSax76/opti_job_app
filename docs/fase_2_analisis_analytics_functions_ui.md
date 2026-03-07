# Fase 2: Analisis de Integracion (carpeta analytics)

## Objetivo
Cerrar evidencia tecnica de conexion backend->UI para la primera carpeta del orden de revision: `analytics`.

## Inventario backend (entrypoint)
Fuente: `functions/src/index.ts`.

- Exports hacia `callable/*`: 38
- Exports hacia `scheduled/*`: 8
- Exports hacia `triggers/*`: 13

Bloque `Analytics` en entrypoint:
- `./scheduled/computeMonthlyAnalytics`
- `./triggers/firestore/onApplicationStatusChange`
- `./callable/analytics/getAnalyticsSummary`
- `./callable/performance/webVitalsCallables`
- `./scheduled/aggregateWebVitals`

## Evidencia backend (analytics)
1. Callable de carpeta analizada:
- `getAnalyticsSummary` en `functions/src/callable/analytics/getAnalyticsSummary.ts:7`

2. Produccion de datos para dashboard:
- `computeMonthlyAnalytics` escribe en `analytics/{companyId}/monthly/{period}` y `analytics/{companyId}`.
- `reportWebVitalsBatch` escribe en `webVitalsEvents`.
- `aggregateWebVitalsP75` consolida en `performanceDashboards/{docId}`.

3. Trigger relacionado:
- `onApplicationStatusChange` actualmente solo registra logs; no persiste metrica consumida por UI.

## Evidencia frontend
1. No hay llamada directa a la callable:
- busqueda `getAnalyticsSummary` en `lib/**`: sin resultados.

2. UI de analytics consume Firestore directo:
- `lib/modules/analytics/repositories/firebase_analytics_repository.dart:18`
  - `analytics/{companyId}/monthly/{period}`
- `lib/modules/analytics/repositories/firebase_analytics_repository.dart:51`
  - `performanceDashboards/company:{companyId}`

3. Pantalla conectada por ruta:
- `lib/core/router/routes/company_routes.dart:149` (`/company/:uid/analytics`)
- `lib/modules/analytics/cubits/analytics_dashboard_cubit.dart:24`
  - usa `getAnalyticsHistory` y `watchPerformanceDashboard`

## Clasificacion cerrada de carpeta analytics
- Funcion: `getAnalyticsSummary`
- Estado: `reviewed`
- Tipo de conexion: `no_evidence` (sin invocacion UI directa)
- Riesgo: `medium` (superficie backend sin uso confirmado desde app)
- Recomendacion: `deprecate_or_wire_ui`

## Cambios aplicados en matriz
- Actualizada fila de `getAnalyticsSummary` en:
  - `docs/fase_1_matriz_trazabilidad_functions_ui.csv`

## Siguiente carpeta recomendada
Continuar con `talent` (segunda carpeta del orden priorizado).

## Actualizacion BL-009 (2026-03-07)
- Decisión aplicada: `deprecate` para `getAnalyticsSummary`.
- Acción técnica:
  - se retiró el export de `getAnalyticsSummary` en `functions/src/index.ts`,
    evitando su despliegue como callable pública.
- Estado operativo resultante:
  - frontend mantiene ruta única de lectura analytics por Firestore directo,
  - sin duplicidad callable vs Firestore en la app Flutter.
