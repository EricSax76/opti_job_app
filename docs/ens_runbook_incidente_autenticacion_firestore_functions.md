# Runbook ENS - Incidente Auth/Firestore/Functions

Fecha: 2026-03-05  
Ámbito: operación producción para cumplimiento ENS + continuidad.

## 1. Detección y alerta

Severidad alta (activar guardia):
- ratio de errores `5xx` en Cloud Functions > 2% durante 5 min,
- picos `permission-denied` en Firestore Rules > 3x baseline,
- fallos de login/MFA > 3x baseline,
- caída de callable crítico (`submitApplication`, `matchCandidateVector`, `createJobOfferSecure`).

Paneles recomendados:
- Cloud Monitoring: request count, error count, latencia p95 por función.
- Logs Explorer:
  - `resource.type="cloud_function"`
  - `severity>=ERROR`
  - `jsonPayload.action="ai_decision_overridden"` (auditoría crítica)
  - `jsonPayload.action="ai_vector_match_generated"` (cadena IA).

## 2. Contención (0-30 min)

1. Confirmar alcance:
- auth, firestore rules, functions o combinación.

2. Mitigar impacto:
- activar feature flags para rutas no críticas si aplica,
- deshabilitar temporalmente rutas de escritura no esenciales,
- forzar fallback seguro en IA (`DISABLE_VERTEX_EMBEDDINGS=1`) si falla proveedor externo.

3. Preservar evidencia:
- snapshot de logs y métricas,
- export de eventos de auditoría relevantes (`auditLogs`, `aiDecisionLogs`).

## 3. Diagnóstico y recuperación (30-120 min)

1. Revisar despliegues recientes:
- reglas Firestore,
- índices/vector config,
- versión de Functions.

2. Acciones de recuperación:
- rollback selectivo de Functions,
- rollback de Rules si hay bloqueo masivo no esperado,
- redeploy de índices si hay errores de query/ordenación.

3. Validación posterior:
- smoke test login MFA,
- smoke test lectura/escritura Firestore clave,
- smoke test callables legales/IA.

## 4. Comunicación y cierre

1. Comunicación interna:
- estado inicial, ETA de mitigación, ETA de cierre.

2. Cierre técnico:
- causa raíz,
- impacto real (usuarios/operaciones),
- controles preventivos añadidos.

3. Evidencia para auditoría:
- timeline con timestamps,
- acciones ejecutadas y responsables,
- enlaces a dashboards/logs/exportes.

## 5. Simulacro ENS trimestral (checklist)

- [ ] Escenario: caída parcial de callable crítico.
- [ ] Activación de guardia en < 10 min.
- [ ] Contención en < 30 min.
- [ ] Recuperación funcional en < 120 min.
- [ ] Postmortem documentado en < 48 h.
- [ ] Actualización de runbook y backlog.

