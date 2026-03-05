# Sprint 1 - Checklist Operativo (Firebase Console vs Codigo)

Fecha de referencia: 2026-03-05  
Alcance: MFA + Custom Claims + Firestore Rules RBAC.

## Objetivo de este documento

Evitar:
- configuraciones duplicadas entre consola y repo,
- drift entre entornos (`dev`, `staging`, `prod`),
- cambios de seguridad sin trazabilidad.

## Regla de oro

1. **Firebase Console**: solo ajustes globales de plataforma (Auth/MFA).
2. **Codigo versionado (Git)**: autorizacion de negocio (claims, rules, functions, tests).
3. Cada cambio manual en consola debe dejar evidencia en PR (captura + fecha + responsable).

## Matriz: que va en Console y que va en Codigo

### A. SOLO Firebase Console (manual por entorno)

1. Firebase Authentication:
- Habilitar factores MFA que vas a permitir (p. ej. TOTP/SMS segun politica).
- Ajustes globales del proveedor de login (si aplica).

2. Seguridad operativa:
- Revisar dominios autorizados de Auth para cada entorno.
- Verificar que el proyecto correcto (`dev/staging/prod`) esta seleccionado antes de guardar.

Notas:
- Estos ajustes no se deben intentar "replicar" con archivos locales del repo.
- Se aplican una vez por entorno y se validan con evidencia.

### B. SOLO Codigo (commit + PR)

1. Cloud Functions:
- Sync de claims: callable/trigger para asignar `role`, `companyId`, `status`, `assuranceLevel`.
- Script/backfill de claims para usuarios existentes.

2. Firestore Rules:
- RBAC basado en `request.auth.token.*`.
- Fallback temporal documentado (si se usa migracion progresiva).

3. Tests:
- Tests de reglas (acceso permitido/denegado por rol).
- Tests de functions para sync/backfill de claims.

4. Runbooks:
- Procedimiento de rollback de claims.
- Procedimiento de validacion post-deploy.

### C. Coordinado (Console + Codigo)

1. MFA enforcement real:
- Console: habilita factores.
- Codigo: bloquea rutas/operaciones sensibles si falta segundo factor (backend-first).

2. Alta de nuevos recruiters/admins:
- Codigo: function que crea/actualiza claims.
- Operacion: verificacion en entorno antes de pasar a produccion.

## Checklist por entorno

## `dev`
- [ ] Console: factores MFA habilitados.
- [ ] Codigo desplegado: `syncRecruiterClaims` y backfill listos.
- [ ] Rules RBAC desplegadas en modo compatible (si hay fallback).
- [ ] Test funcional: recruiter sin MFA no puede operar en modulos protegidos.
- [ ] Evidencia guardada en PR.

## `staging`
- [ ] Console: configuracion MFA replicada desde `dev`.
- [ ] Backfill claims ejecutado y auditado (100% recruiters activos).
- [ ] Rules RBAC en modo objetivo (sin bypass no documentado).
- [ ] Smoke test completo (auth + writes Firestore + callables protegidos).
- [ ] Aprobacion para paso a `prod`.

## `prod`
- [ ] Ventana de despliegue aprobada.
- [ ] Console: verificacion final de factores MFA en proyecto `prod`.
- [ ] Deploy de functions/rules/tag de release.
- [ ] Backfill claims ejecutado con reporte final.
- [ ] Monitoreo 24h con alertas de errores auth/rules.

## Flujo recomendado de cambio (sin duplicaciones)

1. Crear ticket de cambio (`AUTH-MFA-RBAC-XXX`).
2. Aplicar cambios de **codigo** en rama + PR.
3. En paralelo, preparar checklist manual de Console.
4. Merge a `main` solo cuando:
- tests pasan,
- checklist Console `dev` completo,
- evidencia adjunta.
5. Promocion secuencial `dev -> staging -> prod`.

## Evidencias minimas obligatorias en PR

1. Capturas (o export) de ajustes MFA por entorno.
2. Hash/ID de commit con cambios en rules/functions.
3. Resultado de tests relevantes.
4. Registro de ejecucion de backfill:
- fecha/hora,
- entorno,
- total usuarios procesados,
- errores.

## Artefactos del repo a revisar en Sprint 1

1. Reglas:
- `firestore.rules`

2. Functions:
- `functions/src/triggers/auth/*`
- `functions/src/callable/recruiters/*`
- nuevo modulo de sync claims (a crear en Sprint 1)

3. Documentacion:
- `docs/plan_sprints_firebase_flutter_2026.md`
- este documento

## Señales de alerta (anti-drift)

1. Console cambiado sin ticket/PR asociado.
2. Staging funciona y prod falla por claims faltantes.
3. Rules dependen de docs Firestore y no de token, sin fallback planificado.
4. Usuarios nuevos sin claims tras invitacion/alta.

## Politica de rollback

1. Si falla enforcement MFA:
- mantener MFA habilitado en Console,
- activar fallback temporal controlado solo en backend (no en cliente),
- registrar incidente y ventana de correccion.

2. Si falla sync de claims:
- ejecutar script de reparacion,
- bloquear operaciones sensibles hasta consistencia.

3. Si falla rules deploy:
- revertir version de rules desde commit anterior validado,
- mantener functions nuevas solo si no degradan seguridad.

