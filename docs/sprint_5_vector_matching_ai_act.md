# Sprint 5 - Matching vectorial y derecho a explicación

Estado: implementado en backend (`functions`) y Firestore.

## Componentes entregados

1. Embeddings con Vertex AI (+ fallback)
- Utilidad: `functions/src/utils/embeddings.ts`
- Modelo por defecto: `text-embedding-005` en `europe-west4`.
- Fallback automático determinista si Vertex no responde (útil en emulador/local).
- Variables opcionales:
  - `VERTEX_AI_LOCATION`
  - `VERTEX_AI_EMBEDDING_MODEL`
  - `EMBEDDING_VECTOR_DIMENSION` (default `256`)
  - `DISABLE_VERTEX_EMBEDDINGS=1` para forzar fallback.

2. Pipeline de refresco de embeddings
- Trigger CV: `onCurriculumWriteRefreshEmbedding`
  - Documento: `candidates/{candidateUid}/curriculum/{curriculumId}`
  - Salida: `candidateEmbeddings/{candidateUid}.profileEmbedding`
- Trigger oferta: `onJobOfferWriteRefreshEmbedding`
  - Documento: `jobOffers/{offerId}`
  - Salida: `jobOffers/{offerId}.requirementsEmbedding`

3. Matching vectorial real
- Callable: `matchCandidateVector`
- Archivo: `functions/src/callable/ai/matchCandidateVector.ts`
- Entrada: `applicationId` (y `limit` opcional).
- Salida:
  - score global
  - score semántico (vectorial)
  - descomposición por componentes (`semantic`, `skills`, `location`, `experience`)
  - vecinos de vector search
  - explicación y recomendaciones.

4. Logs explicables y auditoría
- Colección: `aiDecisionLogs`
- Utilidad común: `functions/src/utils/aiDecisionLogs.ts`
- Campos incluidos:
  - `weights` (`semanticWeight`, `skillsWeight`, `locationWeight`, `experienceWeight`)
  - `model` (provider/model/version/source)
  - `executionId`, `requestId`
  - `features` consideradas.
- También se generan entradas en `auditLogs`.

5. Revisión humana y override
- Endpoint revisión: `getAiDecisionReview` (consulta por `applicationId`).
- Override reforzado: `overrideAiDecision`
  - valida permisos de empresa/recruiter
  - persiste override en `applications.humanOverride`
  - registra `aiDecisionLogs` + `auditLogs`.

## Firestore

- Reglas añadidas:
  - `candidateEmbeddings`
  - `aiDecisionLogs`
- Índices añadidos:
  - `aiDecisionLogs(applicationId, createdAt desc)`
  - `aiDecisionLogs(companyId, createdAt desc)`
- Vector config (`indexes` con `vectorConfig`):
  - `jobOffers.requirementsEmbedding`
  - `candidateEmbeddings.profileEmbedding`

## Verificación local

En `functions/`:

```bash
npm run build
npm test
```
