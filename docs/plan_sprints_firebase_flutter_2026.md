# Plan de Sprints 2026 (Flutter + Firebase)

Fecha de creacion: 2026-03-04  
Objetivo: cerrar brechas para cumplimiento tecnico/legal en Espana 2026 (AI Act, transparencia salarial, RGPD, ENS, accesibilidad).

## Cadencia propuesta

- Sprint 1: 2026-03-09 a 2026-03-20
- Sprint 2: 2026-03-23 a 2026-04-03
- Sprint 3: 2026-04-06 a 2026-04-17
- Sprint 4: 2026-04-20 a 2026-05-01
- Sprint 5: 2026-05-04 a 2026-05-15
- Sprint 6: 2026-05-18 a 2026-05-29

## Sprint 1 - Identidad ENS y control de acceso

### Objetivo
Blindar identidad y autorizacion para perfiles de empresa/recruiting.

Checklist operativo (Console vs codigo):
- `docs/sprint_1_checklist_console_vs_codigo.md`

### Entregables
1. Firebase Auth:
- Politica MFA obligatoria para `admin`, `recruiter`, `hiring_manager`.
- Flujo de alta MFA y challenge en login.

2. RBAC con Custom Claims:
- Claims minimos: `role`, `companyId`, `status`, `assuranceLevel`.
- Callable administrativa para sincronizar claims desde `recruiters/{uid}`.

3. Firestore Rules:
- Migrar checks de rol desde documentos a `request.auth.token.*`.
- Mantener fallback temporal por compatibilidad durante migracion.

4. Migracion y operaciones:
- Script de backfill de claims para usuarios existentes.
- Runbook de rollback de claims.

### Criterios de aceptacion (DoD)
- Usuario recruiter sin MFA no puede entrar en pantallas de gestion.
- Reglas Firestore bloquean operaciones de rol incorrecto sin depender solo de UI.
- 100% de recruiters activos con claims sincronizadas en entorno de staging.

---

## Sprint 2 - EUDI real (nativo) y pruebas de credencial

### Objetivo
Pasar de MVP simulado a integracion nativa EUDI con trazabilidad.

### Entregables
1. Flutter (nativo):
- `MethodChannel` Android/iOS para wallet EUDI.
- Intercambio de `presentation request` y recepcion de `verifiable presentation`.

2. Firebase Functions:
- Verificacion server-side de firma, issuer, exp y audience.
- Emision de `verifiedCredentials` solo tras validacion criptografica.

3. Evidencia y auditoria:
- `auditLogs` enriquecidos con `verificationMethod`, `issuerDid`, `credentialType`.
- Versionado de esquema de prueba (`proofSchemaVersion`).

### Criterios de aceptacion (DoD)
- No se puede importar credencial EUDI sin pasar validacion criptografica.
- Prueba selectiva se puede crear/verificar/revocar extremo a extremo.
- Trazabilidad completa en `auditLogs` para cada validacion EUDI.

---

## Sprint 3 - Publicacion de ofertas y consentimiento IA

### Objetivo
Forzar cumplimiento en backend para salario y consentimiento IA granular.

### Entregables
1. Publicacion por backend:
- Reemplazar alta directa de `jobOffers` desde cliente por Callable `createJobOfferSecure`.
- Validaciones obligatorias en backend: `salary_min`, `salary_max`, moneda/periodo, coherencia de rango.

2. Transparencia salarial:
- Bloqueo de publicacion sin rango salarial valido.
- Motivo de bloqueo y estado trazable en documento.

3. Consentimiento IA granular:
- Pantalla de consentimiento previa a entrevista/test IA.
- Registro inmutable en Firestore: `consentHash`, `consentTextVersion`, `grantedAt`, `scope`.
- Hash SHA-256 del payload de consentimiento.

### Criterios de aceptacion (DoD)
- Ninguna oferta nueva se publica sin salario valido.
- Entrevistas IA y test IA no arrancan sin consentimiento previo vigente.
- Consentimiento queda auditable con hash verificable.

---

## Sprint 4 - Retencion, TTL y deber de bloqueo RGPD

### Objetivo
Implementar retencion automatizada separando purga y archivo bloqueado.

### Entregables
1. TTL Firebase:
- TTL para datos de grabaciones de videoentrevista (30 dias).
- Verificacion de expiracion automatica en entorno de prueba.

2. Archivo bloqueado (3 anos):
- Job que mueve CV/documentos expirados a `blockedArchive/*` (no borrar directo).
- Reglas estrictas: solo acceso por rol legal/auditoria.

3. Gobernanza legal:
- Campo `legalHold` para evitar borrado/traslado cuando aplique.
- Trazas de cada traslado en `auditLogs` con motivo y timestamp.

### Criterios de aceptacion (DoD)
- Grabaciones de videoentrevista eliminadas automaticamente tras 30 dias.
- CV expirado se mueve a archivo bloqueado con acceso restringido.
- Existe evidencia de no acceso por roles no autorizados.

---

## Sprint 5 - Matching vectorial y derecho a explicacion

### Objetivo
Migrar matching a embeddings + vector search y reforzar explicabilidad AI Act.

### Entregables
1. Embeddings con Vertex AI:
- Generacion de embeddings para perfil candidato y requisitos de oferta.
- Pipeline de refresco cuando cambia CV/oferta.

2. Firestore Vector Search:
- Campos/vector index configurados.
- Callable `matchCandidateVector` con score semantico real.

3. Logs explicables:
- Coleccion `aiDecisionLogs` con:
  - pesos utilizados (`skillsWeight`, `locationWeight`, etc.),
  - modelo/version,
  - executionId/requestId,
  - features consideradas.
- Endpoint para revision humana de decision.

### Criterios de aceptacion (DoD)
- Matching devuelve resultados semanticos medibles en pruebas comparativas.
- Cada decision AI tiene log explicable recuperable por `applicationId`.
- Flujo de override humano operativo y auditado

---

## Sprint 6 - Accesibilidad, etiquetado IA y cierre de auditoria

### Objetivo
Cerrar cumplimiento UX legal (WCAG 2.1 AA, neurodiversidad, etiquetado IA) y hardening final.

### Entregables
1. Accesibilidad:
- Cobertura `Semantics` en acciones criticas faltantes.
- Cierre de QA manual en iOS/Android con evidencia.

2. Modo enfoque:
- Toggle de "Modo enfoque" para candidatos:
  - ocultar elementos no esenciales,
  - reducir/pausar animaciones no necesarias,
  - densidad visual simplificada.

3. Etiquetado IA:
- Componente unico obligatorio para marcar contenido generado por IA.
- Aplicado en resumen CV, sugerencias, veredictos, borradores IA.

4. Operacion ENS:
- Alertas y dashboards para errores auth/rules/functions.
- Simulacro de incidente y runbook de respuesta.

### Criterios de aceptacion (DoD)
- Checklist WCAG 2.1 AA cerrado con pruebas automatizadas y manuales.
- Modo enfoque activable en produccion.
- 100% de contenido IA visible con etiqueta estandar.

---

## Backlog transversal (todos los sprints)

1. Pruebas
- Unitarias en Functions para validaciones legales.
- Integracion con emuladores Auth/Firestore/Functions.
- Pruebas E2E para flujos: login MFA, publicar oferta, consentimiento IA, firma cualificada.

2. Seguridad
- App Check en entornos productivos.
- Rotacion de secretos y claves de integraciones externas.

3. Observabilidad
- Correlation IDs por request.
- Reporte semanal de KPIs de cumplimiento.

## KPIs de salida (fin Sprint 6)

- 0 ofertas publicadas sin rango salarial.
- 0 acciones recruiter/admin sin MFA.
- 100% decisiones AI con log explicable.
- 100% consentimientos IA con hash y version de texto.
- 100% cobertura de etiquetado IA en vistas objetivo.
- WCAG 2.1 AA cerrado (auto + manual).

## Riesgos y mitigacion

1. Dependencia EUDI nativa
- Mitigacion: spike tecnico temprano en Sprint 2, feature flag de rollout.

2. Cambio de reglas Firestore con impacto
- Mitigacion: rollout gradual con fallback temporal y test de regresion.

3. Coste de embeddings/vector
- Mitigacion: batch nocturno + cache + limites por evento de cambio.

4. Bloqueo legal por interpretacion normativa
- Mitigacion: validacion legal quincenal de textos/flujo y versionado de politicas.
