# Fase 3: Backlog por Acciones (Functions <-> UI)

## Objetivo
Convertir el analisis de trazabilidad en un backlog ejecutable, priorizado por riesgo e impacto.

## Criterio de priorizacion
- `P0`: Riesgo alto o brecha funcional/seguridad clara.
- `P1`: Mejora importante de producto, gobernanza o mantenibilidad.
- `P2`: Refactor y consolidacion.

## Backlog priorizado
| ID | Pri | Tipo | Modulo | Funcion(es) | Accion concreta | Criterio de cierre |
|---|---|---|---|---|---|---|
| BL-001 | P0 | `wire_ui` o `deprecate` | evaluations | `submitEvaluation`, `requestApproval` | Definir si se habilita flujo UI por callable o se elimina; hoy hay bypass por escritura directa. | No existen escrituras cliente que salten la logica server-side; flujo activo validado E2E. |
| BL-002 | P0 | `wire_ui` o `deprecate` | recruiters | `createInvitation`, `acceptInvitation`, `updateRecruiterRole`, `removeRecruiter` | Implementar pantalla de gestión de equipo (invitación/roles/baja) o retirar callables no usados. | Existe ruta UI funcional con permisos y llamadas a callables, o callables removidas/documentadas como fuera de alcance. |
| BL-003 | P0 | `wire_ui` o `deprecate` | talent | `addToPool`, `requestConsent` | Integrar módulo de Talent Pool en navegación/DI o descontinuarlo formalmente. | Flujo navegable con llamadas reales, o eliminación de rutas/servicios/callables inactivos. |
| BL-004 | P0 | `wire_ui` o `deprecate` | interviews | `cancelInterview`, `completeInterview` | Exponer acciones de cerrar/cancelar entrevista en chat/listado con reglas de rol. | Botones visibles según rol + llamada callable + cambio de estado verificado en UI y Firestore. |
| BL-005 | P0 | `wire_ui` o `deprecate` | compliance | `upsertSalaryBenchmark` | Crear entrada admin/company para cargar benchmarks salariales o retirar callable no usada. | Benchmarks actualizables desde UI (o proceso alternativo oficial) y evidencia de uso en producción. |
| BL-006 | P0 | `hardening` | interviews | `startMeeting` (cliente directo Firestore) | Mover `startMeeting` a callable con control de permisos y auditoría. | Ya no hay escrituras directas para inicio de meeting desde cliente; callable y tests en su lugar. |
| BL-007 | P1 | `wire_ui` o `deprecate` | ai | `getAiDecisionReview`, `overrideAiDecision` | Crear consola de revisión/override para roles autorizados o retirar endpoints. | UI admin operativa con trazabilidad/auditoría o funciones retiradas/documentadas. |
| BL-008 | P1 | `wire_ui` o `keep_internal` | ai | `matchCandidateWithSkills`, `matchCandidateVector` | Definir trigger explícito (manual/batch) y su visibilidad en UI interna. | Existe invocación clara (UI o job interno documentado) y métricas de ejecución. |
| BL-009 | P1 | `wire_ui` o `deprecate` | analytics | `getAnalyticsSummary` | Unificar fuente de analytics: callable o Firestore directo, evitando doble estrategia. | Un solo camino de lectura en frontend y callable alineada o eliminada. |
| BL-010 | P1 | `keep_internal` o `wire_ui` | recruiters | `syncRecruiterClaims` | Definir si queda utilitaria interna o se expone en panel admin. | Ruta de invocación única y documentada; sin callable huérfana. |
| BL-011 | P1 | `hardening` | ats | `evaluateKnockoutQuestions` | Reducir modo best-effort: reintentos, cola o alerta cuando falle evaluación. | Fallos de knockout generan señal observable y no se pierden silenciosamente. |
| BL-012 | P1 | `hardening` | compliance | `exportCandidateData`, `processDataRequest` | Añadir observabilidad y trazas operativas (latencia, errores, tasa de completado SLA). | Dashboard/alertas mínimas de operación y SLA de solicitudes de datos. |
| BL-013 | P1 | `refactor` | auth | `verifySelectiveDisclosureProof` | Unificar invocación (evitar duplicación entre widget directo y repositorio). | Existe un único punto de acceso en frontend para esa callable. |
| BL-014 | P1 | `refactor` | compliance | `exportCandidateData` | Pasar invocación del widget a `ComplianceRepository` para consistencia arquitectónica. | Pantalla usa repositorio (no llamada directa), manteniendo fallback regional. |
| BL-015 | P2 | `hardening` | transversal | todas | Definir test matrix por callable crítica (auth, applications, ats, interviews, compliance). | Suite mínima automatizada cubre permisos, happy path y errores clave. |
| BL-016 | P2 | `hardening` | transversal | todas | Alinear auditoría y naming de campos (`snake_case`/`camelCase`) en respuestas y writes. | Guía de contratos + validaciones; nuevos callables siguen convención única. |
| BL-017 | P2 | `refactor` | transversal | todas con fallback | Estandarizar helper de `httpsCallable` con fallback para evitar lógica repetida. | Reutilización en servicios/repositorios y reducción de código duplicado. |

## Plan de ejecucion sugerido
1. Sprint A (`P0`): BL-001 a BL-006.
2. Sprint B (`P1`): BL-007 a BL-014.
3. Sprint C (`P2`): BL-015 a BL-017.

## Detalle de ejecucion BL-001 (evaluations)
### Decision
- Estrategia elegida: `wire_ui`.
- Motivo: existen callables backend con validacion de autenticacion/rol/empresa y triggers dependientes (`onEvaluationCreate`, `onApprovalUpdate`), por lo que conviene alinear el cliente en vez de eliminar.

### Etapas
1. Backend contract
- Confirmar payloads de `submitEvaluation` y `requestApproval`.
- Mantener creacion de documentos exclusivamente en backend callable.

2. Frontend wiring
- Migrar `FirebaseEvaluationRepository` para invocar callables (`submitEvaluation`, `requestApproval`) con fallback regional.
- Mantener lecturas en Firestore para listados y estado.

3. Hardening de reglas
- Bloquear `create` directo en `evaluations` y `approvals` desde cliente.
- Mantener `update` actual solo para flujo de decision de aprobadores.

4. Validacion
- Prueba positiva: usuario autorizado puede crear evaluacion y solicitud de aprobacion via callable.
- Prueba negativa: intento de `create` directo cliente en `evaluations`/`approvals` devuelve `PERMISSION_DENIED`.
- Verificar en Firestore que `createdAt` de nuevos registros queda con timestamp server-side.

### Criterio de cierre operativo
- No existen escrituras cliente de creacion que salten logica server-side para evaluaciones/aprobaciones.
- Flujo callable documentado y verificado en entorno de staging con evidencia de logs.

## Detalle de ejecucion BL-002 (recruiters)
### Decision
- Estrategia elegida: `wire_ui`.
- Motivo: las callables de equipo (`createInvitation`, `acceptInvitation`, `updateRecruiterRole`, `removeRecruiter`) contienen control RBAC + MFA y sincronizacion de claims, por lo que deben ser el camino principal de UI.

### Etapas
1. Backend contract
- Confirmar payloads:
  - `createInvitation`: `role`, `email?`
  - `acceptInvitation`: `code`, `name`
  - `updateRecruiterRole`: `targetUid`, `newRole`
  - `removeRecruiter`: `targetUid`

2. Frontend wiring
- Migrar mutaciones de `FirebaseRecruiterRepository` a callables con fallback regional.
- Mantener lecturas por Firestore stream para listado de miembros e invitaciones.

3. UI operativa
- Añadir pantalla `/recruiter/:uid/team` para:
  - generar invitaciones,
  - aceptar invitaciones,
  - cambiar rol,
  - deshabilitar miembro.
- Exponer acceso desde `RecruiterDashboard`.

4. Validacion
- Prueba positiva admin: crear invitacion, cambiar rol y deshabilitar miembro.
- Prueba positiva recruiter freelance: aceptar codigo de invitacion.
- Prueba de permisos: recruiter no-admin no puede ejecutar acciones de gestion de equipo.
- Evidencia ejecutada (2026-03-07):
  - Comando: `npm run test:e2e` en `functions/`
  - Resultado: `pass 4, fail 0` (incluye dos casos E2E nuevos de recruiters).

### Criterio de cierre operativo
- Existe ruta UI funcional de gestion de equipo con llamadas reales a las cuatro callables criticas.
- Las acciones de equipo reflejan cambios en Firestore (`recruiters`, `invitations`) tras ejecucion de callables.

## Detalle de ejecucion BL-003 (talent)
### Decision
- Estrategia elegida: `wire_ui`.
- Motivo: el módulo `talent_pool` ya existía en frontend pero sin DI/ruta y con bypass de lógica callable para altas con consentimiento.

### Etapas
1. Backend contract
- Confirmar payloads:
  - `addToPool`: `poolId`, `candidateUid`, `tags?`, `source?`, `sourceApplicationId?`
  - `requestConsent`: `candidateUid`, `poolId`
- Corregir contrato backend para no persistir campos `undefined` en Firestore (`sourceApplicationId` opcional).

2. Frontend wiring
- Registrar `TalentPoolRepository` en DI (`GetIt` + `AppDependencies` + `AppScope`).
- Migrar `addMemberToPool` en `FirebaseTalentPoolRepository` a callables:
  - `addToPool`
  - `requestConsent` condicional si `consentRequired=true`.

3. UI operativa
- Añadir ruta `/company/:uid/talent-pools`.
- Añadir acceso desde tab de candidatos (`CompanyCandidatesTab`).
- Habilitar alta real de miembros desde `TalentPoolDetailScreen` (flujo navegable end-to-end).

4. Validacion
- `flutter analyze` sin issues en archivos tocados.
- Evidencia ejecutada (2026-03-07):
  - Comando: `npm run test:e2e` en `functions/`
  - Resultado: `pass 6, fail 0` (incluye 2 casos E2E nuevos de talent).

### Criterio de cierre operativo
- El módulo talent pool es navegable desde UI company y está cableado en DI.
- Las altas al pool usan `addToPool` y disparan `requestConsent` cuando aplica.
- No quedan callables `addToPool/requestConsent` huérfanas sin ruta funcional de frontend.

## Detalle de ejecucion BL-004 (interviews)
### Decision
- Estrategia elegida: `wire_ui`.
- Motivo: `cancelInterview` y `completeInterview` ya estaban implementadas en backend/repo, pero sin entrypoints en UI.

### Etapas
1. Backend contract
- Confirmar payloads:
  - `cancelInterview`: `interviewId`, `reason?`
  - `completeInterview`: `interviewId`, `notes?`
- Confirmar reglas backend:
  - cancelación: cualquier participante (`participants`),
  - completado: solo `companyUid`.

2. Frontend wiring
- Exponer acciones en `InterviewSessionCubit`:
  - `cancelInterview(...)`
  - `completeInterview(...)`
- Extender controladores/dialogos de chat para capturar `reason/notes` opcionales.

3. UI operativa
- Chat:
  - menú de acciones en AppBar con visibilidad por rol/estado.
- Listado:
  - menú por item (`InterviewListTile`) con las mismas reglas de visibilidad.
- Reglas UI aplicadas:
  - `complete`: solo `companyUid` y entrevista no cerrada.
  - `cancel`: solo participante y entrevista no cerrada.

4. Validacion
- `flutter analyze` sin issues en archivos tocados.
- Evidencia ejecutada (2026-03-07):
  - Comando: `firebase emulators:exec --only firestore,auth "node --test e2e/p3_interviews_actions_callables.test.js"` en `functions/`
  - Resultado: `tests 3`, `pass 3`, `fail 0`.

### Criterio de cierre operativo
- Botones visibles según rol en chat/listado.
- Acciones invocan callables reales (`cancelInterview`, `completeInterview`).
- Estado en Firestore cambia y se refleja en UI por stream de entrevistas.

## Detalle de ejecucion BL-005 (compliance)
### Decision
- Estrategia elegida: `wire_ui`.
- Motivo: `upsertSalaryBenchmark` es insumo directo del trigger de auditoría salarial (`onJobOfferCreate`) y debía quedar operable desde UI company/recruiter autorizada.

### Etapas
1. Backend contract
- Confirmar payload:
  - `companyId`, `roleKey/title`, `maleAverageSalary?`, `femaleAverageSalary?`, `nonBinaryAverageSalary?`, `sampleSize?`.
- Confirmar reglas backend de acceso:
  - company owner,
  - recruiter activo de la misma empresa con rol `admin` o `recruiter`.

2. Frontend wiring
- Añadir `SalaryBenchmarkRepository` en compliance y registrar implementación en DI.
- Implementar `upsertSalaryBenchmark(...)` en `FirebaseComplianceRepository` con callable/fallback.

3. UI operativa
- Extender `ConsentManagementScreen` con tab `Benchmarks`.
- Añadir formulario para carga de medias salariales por género y muestra.
- Añadir tabla de benchmarks existentes (`salaryBenchmarks`) para trazabilidad operativa.
- Aplicar visibilidad de edición por rol alineada a backend.

4. Validacion
- `flutter analyze` sin issues en archivos tocados.
- Evidencia ejecutada (2026-03-07):
  - Comando: `firebase emulators:exec --only firestore,auth "node --test e2e/p3_compliance_salary_benchmark.test.js"` en `functions/`
  - Resultado: `tests 3`, `pass 3`, `fail 0`.

### Criterio de cierre operativo
- Benchmarks actualizables desde UI company/recruiter autorizada.
- Persistencia visible en `salaryBenchmarks` y utilizable por flujos de auditoría salarial.

## Detalle de ejecucion BL-007 (ai review/override)
### Decision
- Estrategia elegida: `wire_ui`.
- Motivo: existían callables con permisos y auditoría (`getAiDecisionReview`, `overrideAiDecision`) sin entrypoint de frontend.

### Etapas
1. Backend contract
- Confirmar payloads:
  - `getAiDecisionReview`: `applicationId`, `limit?`
  - `overrideAiDecision`: `applicationId`, `reason`, `overrideScore?`, `originalAiScore?`
- Confirmar reglas backend:
  - review: candidato/empresa/recruiter autorizado.
  - override: empresa o recruiter activo con rol `admin|recruiter|hiring_manager`.

2. Frontend wiring
- Extender `ApplicantsRepository` con:
  - `getAiDecisionReview(...)`
  - `overrideAiDecision(...)`
- Implementar en `FirebaseApplicantsRepository` con fallback regional.
- Crear modelos tipados de contrato para revisión/override IA.

3. UI operativa
- Añadir acción `Revisión IA` por aplicación en `OfferApplicantsSection`/`ApplicantTile`.
- Añadir diálogo `AiDecisionReviewDialog` con:
  - resumen de score/scope,
  - explicabilidad,
  - estado de override humano,
  - trazas recientes (`aiDecisionLogs`),
  - formulario para aplicar override (motivo + score opcional).
- Al confirmar override:
  - invocación callable real,
  - snackbar de confirmación,
  - recarga de aplicaciones para reflejar score actualizado.

4. Validacion
- `flutter --suppress-analytics analyze` sin issues en archivos tocados.
- Evidencia ejecutada (2026-03-07):
  - Comando: `flutter --suppress-analytics analyze lib/modules/applicants`
  - Resultado: `No issues found!`.

### Criterio de cierre operativo
- Existe consola operativa de revisión/override IA en UI company.
- La UI invoca callables reales (`getAiDecisionReview`, `overrideAiDecision`) y refleja cambios de score/estado tras override.
- La trazabilidad de decisiones queda visible en el diálogo y auditada en backend por las propias callables.

## Detalle de ejecucion BL-008 (ai triggers explícitos)
### Decision
- Estrategia elegida: `wire_ui`.
- Motivo: `matchCandidateWithSkills` y `matchCandidateVector` estaban activas en backend, pero sin trigger explícito y visible en UI interna.

### Etapas
1. Backend contract
- Confirmar payloads:
  - `matchCandidateVector`: `applicationId`, `limit?`
  - `matchCandidateWithSkills`: `applicationId`, `jobOfferId`
- Confirmar outputs relevantes:
  - actualización de `applications.aiMatchResult` + `match_score`,
  - escritura de `aiDecisionLogs` + `auditLogs`.

2. Frontend wiring
- Extender `ApplicantsRepository` con:
  - `runAiVectorMatch(...)`
  - `runAiSkillMatch(...)`
- Implementar en `FirebaseApplicantsRepository` con callable/fallback regional.

3. UI operativa
- Reutilizar consola `AiDecisionReviewDialog` para añadir:
  - botón `Recalcular vectorial`,
  - botón `Recalcular skills`.
- Al ejecutar trigger manual:
  - se invoca callable real,
  - se refresca la revisión (`getAiDecisionReview`) para ver score/logs nuevos,
  - se muestra feedback en UI.

4. Validacion
- Evidencia ejecutada (2026-03-07):
  - Comando: `flutter --suppress-analytics analyze lib/modules/applicants`
  - Resultado: `No issues found!`.

### Criterio de cierre operativo
- Existe invocación manual explícita y visible en UI interna para ambas callables AI.
- Tras ejecutar trigger, la UI refleja trazas/estado actualizados de decisión IA.
- No quedan `matchCandidateWithSkills`/`matchCandidateVector` como endpoints huérfanos sin entrypoint operativo.

## Detalle de ejecucion BL-009 (analytics source unificado)
### Decision
- Estrategia elegida: `deprecate`.
- Motivo: el frontend ya opera en una sola estrategia (Firestore directo) para analytics/performance, y `getAnalyticsSummary` no tenía invocación real desde UI.

### Etapas
1. Backend contract
- Identificar `getAnalyticsSummary` como callable sin evidencia de uso en app Flutter.

2. Unificacion de fuente
- Mantener frontend en ruta única de lectura:
  - `analytics/{companyId}/monthly/*`
  - `performanceDashboards/company:{companyId}`
- Retirar callable huérfana del entrypoint de despliegue (`functions/src/index.ts`).

3. Documentacion operativa
- Registrar decisión `deprecate` en backlog de fase 3 y análisis de carpeta analytics.

4. Validacion
- Evidencia ejecutada (2026-03-07):
  - `npm run build` en `functions/` sin errores de compilación tras retirar export.

### Criterio de cierre operativo
- El frontend conserva un único camino de lectura para analytics.
- `getAnalyticsSummary` deja de estar expuesta como callable desplegable.
- No hay duplicidad de estrategia de lectura callable vs Firestore en la app.

## Decisiones que debes cerrar primero
1. Para cada callable `no_evidence`, decidir `wire_ui` vs `deprecate`.
2. Definir owner por bloque (`frontend`, `backend`, `shared`).
3. Acordar criterio de Done: demo UI + evidencia de logs/auditoría + test mínimo.
