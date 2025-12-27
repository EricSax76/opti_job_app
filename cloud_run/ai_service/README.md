# AI service (Cloud Run)

HTTP service para:

- `POST /ai/improve-cv-summary`
- `POST /ai/match-offer-candidate`
- `POST /ai/generate-job-offer`

Autenticación: `Authorization: Bearer <Firebase ID Token>` (verificado con Firebase Admin).

## Variables de entorno

- `GOOGLE_CLOUD_PROJECT` (o `GCP_PROJECT`): id del proyecto
- `GCP_LOCATION`: región/location de Vertex AI (ej. `global`, `europe-west1`)
- `AI_MODEL_FLASH`: modelo barato (default `gemini-2.0-flash-001`)
- `AI_MODEL_PRO`: modelo de mayor calidad (default `gemini-1.5-pro`)
- `AI_TEMPERATURE`: temperatura por defecto (default `0.3`)
- `AI_TOP_P`: topP por defecto (default `0.95`)
- `AI_SAFETY_THRESHOLD`: threshold (default `OFF`)
- `CACHE_TTL_DAYS`: TTL de caché (default `7`)
- `DISABLE_AUTH`: `true` para desarrollo local sin token (no usar en prod)
- `CORS_ORIGINS`: lista de orígenes permitidos para Flutter Web (separados por coma) o `*` (ej. `http://localhost:51234,https://tu-dominio.com`)

## Caché en Firestore

- Match: colección `ai_cache_matches`, doc id `${uid}_${offerId}` con `cvUpdatedAtMs` + `expiresAt`
- Improve CV: colección `ai_cache_cv_summary`, doc id `${uid}_${cvUpdatedAtMs}` con `expiresAt`
- Generar oferta: colección `ai_cache_job_offers`, doc id `${uid}_${criteriaHash}` con `expiresAt`

TTL opcional: en Firebase Console puedes habilitar TTL usando el campo `expiresAt`.

## Requisitos en Google Cloud (Vertex AI + IAM)

1. En el proyecto de GCP, habilita la API de Vertex AI.
2. Asegura que la cuenta de servicio que ejecuta Cloud Run tenga permisos:
   - Vertex AI: `roles/aiplatform.user`
   - Firestore (cache): `roles/datastore.user` (o superior)

Nota: Cloud Run provee credenciales por defecto (ADC) vía la cuenta de servicio del servicio; no necesitas API keys.

## Desarrollo local

Requiere instalar dependencias Node (si ejecutas `node src/server.js` directamente te saldrá `Cannot find module 'express'`).

```bash
cd cloud_run/ai_service
npm install
DISABLE_AUTH=true GOOGLE_CLOUD_PROJECT=tu-proyecto GCP_LOCATION=global npm start
```

Recomendado: Node 20 (el `Dockerfile` usa `node:20-slim`).

## Deploy (ejemplo)

```bash
gcloud config set project TU_PROJECT_ID

gcloud run deploy opti-ai \
  --source . \
  --project TU_PROJECT_ID \
  --region europe-west1 \
  --allow-unauthenticated \
  --set-env-vars GCP_LOCATION=europe-west1,GOOGLE_CLOUD_PROJECT=TU_PROJECT_ID
```

Nota: aunque el servicio sea público, igual requiere Firebase ID Token (salvo `DISABLE_AUTH=true`).
