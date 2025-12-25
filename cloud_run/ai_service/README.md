# AI service (Cloud Run)

HTTP service para:

- `POST /ai/improve-cv-summary`
- `POST /ai/match-offer-candidate`
- `POST /ai/generate-job-offer`

Autenticación: `Authorization: Bearer <Firebase ID Token>` (verificado con Firebase Admin).

## Variables de entorno

- `GOOGLE_CLOUD_PROJECT` (o `GCP_PROJECT`): id del proyecto
- `GCP_LOCATION`: región (ej. `europe-west1`)
- `AI_MODEL_FLASH`: modelo barato (default `gemini-1.5-flash`)
- `AI_MODEL_PRO`: modelo de mayor calidad (default `gemini-1.5-pro`)
- `CACHE_TTL_DAYS`: TTL de caché (default `7`)
- `DISABLE_AUTH`: `true` para desarrollo local sin token (no usar en prod)

## Caché en Firestore

- Match: colección `ai_cache_matches`, doc id `${uid}_${offerId}` con `cvUpdatedAtMs` + `expiresAt`
- Improve CV: colección `ai_cache_cv_summary`, doc id `${uid}_${cvUpdatedAtMs}` con `expiresAt`
- Generar oferta: colección `ai_cache_job_offers`, doc id `${uid}_${criteriaHash}` con `expiresAt`

TTL opcional: en Firebase Console puedes habilitar TTL usando el campo `expiresAt`.

## Deploy (ejemplo)

```bash
gcloud run deploy opti-ai \
  --source . \
  --region europe-west1 \
  --allow-unauthenticated \
  --set-env-vars GCP_LOCATION=europe-west1
```

Nota: aunque el servicio sea público, igual requiere Firebase ID Token (salvo `DISABLE_AUTH=true`).
