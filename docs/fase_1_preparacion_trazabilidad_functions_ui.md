# Fase 1: Preparacion y plantilla de trazabilidad Functions-UI

## Objetivo
Definir un marco unico de analisis para mapear, carpeta por carpeta, la conexion real entre `functions/src/callable/*` y la UI Flutter.

## Alcance de Fase 1
- Definir criterios de clasificacion y evidencia.
- Crear una matriz de trazabilidad base con todas las callables detectadas.
- Dejar un orden operativo de revision para la Fase 2.

Fuera de alcance en esta fase:
- Declarar funciones como obsoletas de forma definitiva.
- Ejecutar refactors de conexion UI/backend.
- Cambios de seguridad o reglas.

## Inventario base (snapshot inicial)
- Total carpetas callable: 11.
- Total callables inventariadas: 43.
- Fuente: `functions/src/callable/**` (excluyendo `utils/**`).

Carpetas incluidas:
- `ai`
- `analytics`
- `applications`
- `ats`
- `auth`
- `compliance`
- `evaluations`
- `interviews`
- `performance`
- `recruiters`
- `talent`

## Definiciones de estado
- `direct_ui`: callable invocada desde Flutter via `httpsCallable("name")` o wrapper equivalente.
- `indirect_ui`: no invocada de forma directa, pero alimenta colecciones que la UI consume.
- `no_evidence`: sin evidencia de invocacion UI ni de consumo indirecto por colecciones.
- `pending`: aun no analizada.

## Reglas minimas de evidencia
Para cerrar una fila de la matriz se requieren 2 evidencias:
1. Evidencia backend:
- export callable con archivo y linea.

2. Evidencia frontend:
- llamada `httpsCallable` con archivo y linea, o
- lectura de Firestore conectada al output de esa callable/triggers/scheduled.

Si no hay evidencia frontend tras barrido, la fila queda en `no_evidence` con nota explicita.

## Matriz oficial de trabajo
Archivo:
- `docs/fase_1_matriz_trazabilidad_functions_ui.csv`

Columnas:
- `callable_folder`
- `function_name`
- `backend_file`
- `backend_line`
- `status`
- `connection_type`
- `ui_evidence`
- `dataflow_evidence`
- `risk`
- `recommended_action`
- `notes`

## Orden de revision para Fase 2
Orden recomendado (prioridad de sospecha de desconexion):
1. `analytics`
2. `talent`
3. `recruiters`
4. `evaluations`
5. `ai`
6. `performance`
7. `auth`
8. `applications`
9. `ats`
10. `interviews`
11. `compliance`

## Definition of Done (Fase 1)
- Existe matriz base con el 100% de callables registradas.
- Existe criterio formal de clasificacion y evidencia.
- Existe orden operativo para ejecutar Fase 2 sin ambiguedad.
