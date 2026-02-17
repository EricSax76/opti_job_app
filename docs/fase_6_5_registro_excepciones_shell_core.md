# Fase 6.5: Registro de excepciones del CoreShell

Fecha de publicacion: 2026-02-17  
Estado: activo  
Fuente de verdad para excepciones de shell: este documento.

## Objetivo
Controlar de forma explicita y auditable las excepciones al patron de shell comun del core.

## Politica operativa
1. Toda excepcion debe tener `id` estable y unico (`shell-ex-XXX`).
2. Toda excepcion debe estar etiquetada en codigo con su `id`.
3. Toda excepcion debe definir owner, motivo tecnico y criterio de salida.
4. Revision obligatoria semestral por owner.
5. Excepcion sin revision vigente se considera deuda vencida.

## Flujo de gestion de excepciones
1. Alta:
   - Registrar fila en este documento.
   - Etiquetar codigo/ruta con el `id`.
2. Mantenimiento:
   - Revisar cada 6 meses estado, riesgo y necesidad.
   - Actualizar `proxima_revision`.
3. Cierre:
   - Migrar flujo al `CoreShell` o a variant oficial.
   - Eliminar etiqueta de excepcion del codigo.
   - Mover estado a `cerrada`.

## Registro vigente
| id | Estado | Flujo/Ruta | Ubicacion principal | Motivo tecnico | Owner | Aprobada | Proxima revision | Frecuencia | Criterio de salida |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `shell-ex-001` | `activa` | Chat de entrevista (`/interviews/:id`) | `lib/core/router/app_router.dart` y `lib/modules/interviews/ui/widgets/chat/interview_chat_view.dart` | Flujo conversacional inmersivo que requiere evaluacion de variant `immersive` antes de integrarse al shell comun. | `frontend-core` | `2026-02-17` | `2026-08-17` | `6 meses` | Definir y adoptar variant `immersive` para chat o justificar excepcion permanente. |
| `shell-ex-002` | `activa` | Playback de video curriculum (push interno) | `lib/features/video_curriculum/view/video_curriculum_playback_helpers.dart` y `lib/features/video_curriculum/view/video_playback_screen.dart` | Flujo multimedia inmersivo/fullscreen con controles de reproduccion dedicados. | `frontend-core` | `2026-02-17` | `2026-08-17` | `6 meses` | Migrar a variant `immersive` del shell o retirar necesidad de pantalla fullscreen dedicada. |

## Checklist de revision semestral
1. El motivo tecnico sigue vigente: si/no.
2. Existe variant de shell que ya cubre el flujo: si/no.
3. Riesgo UX de mantener excepcion: bajo/medio/alto.
4. Fecha de proxima revision actualizada: si.
5. Decision: `mantener`, `migrar`, `cerrar`.
