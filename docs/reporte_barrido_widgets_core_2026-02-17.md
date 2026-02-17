# Reporte de barrido de widgets vs core

Fecha del barrido inicial: 2026-02-17
Ultima actualizacion: 2026-02-17

## Alcance

- Se analizaron todos los archivos `lib/**/widgets/*.dart`, excluyendo `lib/core/**`.
- Se marcó como "con uso de core" cuando el archivo tiene import directo a:
  - `package:opti_job_app/core/...`
  - rutas relativas que apunten a `.../core/...`

## Resumen

- Total de widgets analizados en baseline: `122`
- Total de widgets actual en codigo: `112`
- Baseline inicial: `70` con import directo a core y `52` sin import directo a core
- Estado tras primera tanda de refactor: `76` con import directo a core y `46` sin import directo a core
- Estado tras segunda tanda (companies): `89` con import directo a core y `33` sin import directo a core
- Estado tras cierre de pendientes en companies: `91` con import directo a core y `31` sin import directo a core
- Estado tras tercera tanda (candidates): `99` con import directo a core y `23` sin import directo a core
- Estado tras consolidacion de candidates (eliminacion de wrappers/barrels y move de opciones): `99` con import directo a core y `18` sin import directo a core (sobre `117` widgets)
- Estado tras cierre rapido de job_offers/widgets: `101` con import directo a core y `16` sin import directo a core (sobre `117` widgets)
- Estado tras cierre de interviews/widgets: `111` con import directo a core y `6` sin import directo a core (sobre `117` widgets)
- Estado tras cierre de video_curriculum/widgets (move de utilitarios no-widget): `112` con import directo a core y `3` sin import directo a core (sobre `115` widgets)
- Estado final tras cierre applicants/curriculum y consolidacion de barrels: `113` con import directo a core y `0` sin import directo a core (sobre `113` widgets)
- Estado final con guardrail CI de import directo (barrel residual eliminado): `112` con import directo a core y `0` sin import directo a core (sobre `112` widgets)

## Widgets pendientes sin import directo a core (0)

No hay pendientes en el alcance actual.

## Comando de referencia

```bash
widget_files=$(rg --files lib | rg '/widgets/.*\.dart$' | rg -v '^lib/core/')
with_core=$(printf '%s\n' "$widget_files" | xargs rg -l "^import[[:space:]]+['\"][^'\"]*(package:opti_job_app/core/|(\.\./)+core/)" | sort)
comm -23 <(printf '%s\n' "$widget_files" | sort) <(printf '%s\n' "$with_core")
```
