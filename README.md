# Frontend Flutter – InfoJobs

Este proyecto contiene la reimplementación Flutter del frontend existente en React. La aplicación ahora consume directamente Firebase (Authentication + Cloud Firestore) para persistir candidatos, empresas y ofertas, por lo que no depende del backend Dart legado (la carpeta `lib/backend/` puede eliminarse si ya no la necesitas).

## Requisitos

- Flutter 3.16 o superior instalado y en el PATH.
- Dart 3.2 o superior.
- Proyecto de Firebase configurado mediante `flutterfire configure` (genera `lib/firebase_options.dart`).

## Puesta en marcha

```bash
flutter pub get
flutter run -d chrome # o dispositivo preferido
```

Firebase se inicializa automáticamente con las credenciales de `firebase_options.dart`, así que no es necesario definir URLs de API.

## IA (opcional)

La app incluye un botón "Mejorar con IA" en el módulo de Curriculum que llama a un backend propio (no expongas API keys en Flutter).

- Configura el endpoint con `--dart-define=AI_BASE_URL=https://tu-backend.com`
- Nota: en Android emulator, usa `http://10.0.2.2:<puerto>` en vez de `http://localhost:<puerto>` para apuntar a tu máquina.
- La app envía `Authorization: Bearer <Firebase ID Token>` y un JSON `{ "cv": {...}, "locale": "es-ES" }` a `POST /ai/improve-cv-summary`
- El backend debe responder `200` con `{ "summary": "..." }` (puede incluir `cached: true/false`)

También hay un botón "Match" en el detalle de oferta:

- La app envía `Authorization: Bearer <Firebase ID Token>` y un JSON `{ "cv": {...}, "offer": {...}, "locale": "es-ES" }` a `POST /ai/match-offer-candidate`
- El backend debe responder `200` con `{ "score": 0-100, "summary": "...", "reasons": ["...", "..."] }` (puede incluir `cached: true/false`)

Para empresas, hay un botón "Generar con IA" al crear una oferta:

- La app envía `Authorization: Bearer <Firebase ID Token>` y un JSON `{ "criteria": {...}, "locale": "es-ES", "quality": "flash|pro" }` a `POST /ai/generate-job-offer`
- El backend debe responder `200` con `{ "title": "...", "description": "...", "location": "...", "job_type": "...", "salary_min": "...", "salary_max": "...", "education": "...", "key_indicators": "..." }` (puede incluir `cached: true/false`)

Notas para MVP:

- La app recorta el payload antes de enviarlo (skills/resumen + últimos 3 ítems de experiencia/educación; descripciones truncadas).
- El backend debería cachear el match por `(uid, offerId, cv.updated_at)` para no recalcular si el CV no cambió (TTL opcional).
- Por defecto usa modelo barato (`quality: "flash"`); si quieres más calidad puedes enviar `quality: "pro"`.

### Cloud Run

En `cloud_run/ai_service` tienes un servicio Node listo para Cloud Run con:

- Verificación de Firebase ID Token (Firebase Admin)
- Gemini en Vertex AI (`flash` vs `pro`)
- Caché en Firestore (`ai_cache_matches` y `ai_cache_cv_summary`) con `expiresAt` (TTL opcional)
- Soporte CORS configurable para Flutter Web (`CORS_ORIGINS`)

## Configuración de Firebase

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com/) y habilita Authentication (correo/contraseña) y Cloud Firestore.
2. Ejecuta `flutterfire configure` para tu app y plataformas objetivo. Esto generará/actualizará `lib/firebase_options.dart`.
3. (Opcional) Usa los emuladores de Firebase cuando desarrolles localmente: `firebase emulators:start --only auth,firestore`.
4. Prepara las colecciones `candidates`, `companies` y `jobOffers` con la estructura esperada (`id`, `name`, `email`, etc.) si necesitas datos de ejemplo.
5. (Web) Configura CORS en Firebase Storage para servir imágenes desde la app web:

```bash
gsutil cors set storage.cors.json gs://<tu-bucket>
```

Si estás en desarrollo y el puerto cambia, añade el origen correspondiente en `storage.cors.json` o usa un origen fijo.

## Semillas y emuladores

Contamos con un script sencillo que rellena datos de ejemplo para las colecciones clave cuando trabajas con el emulador de Firestore:

```bash
# En una terminal: lanza los emuladores con tu proyecto
firebase emulators:start --only auth,firestore

# En otra terminal: exporta las variables esperadas por el seeder y ejecútalo
export FIREBASE_PROJECT_ID=opti-job
export FIRESTORE_EMULATOR_HOST=localhost:8080
dart run tool/firestore_seed.dart
```

El script usa la API REST del emulador, por lo que no necesitas credenciales adicionales. Ajusta `FIREBASE_PROJECT_ID` si tu `firebase_options.dart` apunta a otro proyecto. Si quieres conservar el estado al reiniciar los emuladores, añade `--import ./firebase/emulator-cache --export-on-exit` al comando anterior y vuelve a ejecutar el seeder cada vez que limpies ese directorio.

### Migración de esquema de applications (legacy -> canónico)

Para normalizar documentos antiguos de `applications` (ej. `job_offer_id`, `company_uid`) y dejar solo campos canónicos (`jobOfferId`, `companyUid`, `candidateId`):

```bash
cd functions

# 1) Simulación (sin escribir)
npm run migrate:applications -- --dry-run

# 2) Aplicar cambios reales
npm run migrate:applications -- --apply

# Opcional: corrida parcial
npm run migrate:applications -- --apply --max-documents=5000
```

El script usa `firebase-admin`, por lo que debes ejecutarlo con credenciales válidas (ADC o `GOOGLE_APPLICATION_CREDENTIALS`).
Si no detecta el proyecto automáticamente, añade `--project-id=<tu-project-id>`.

Se crean automáticamente cuentas de ejemplo en ambos emuladores (correo / contraseña):

- `lucia@app.dev` / `Secret123!` (candidata)
- `diego@app.dev` / `Secret123!` (candidato)
- `talent@optijob.dev` / `Secret123!` (empresa)
- `hr@nexthire.dev` / `Secret123!` (empresa)

Para que la app Flutter apunte al emulador durante el desarrollo:

```bash
flutter run \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 \
  --dart-define=FIRESTORE_EMULATOR_HOST=localhost:8080
```

## Reglas de seguridad

Incluimos las reglas completas en `firestore.rules`. Para aplicarlas:

```bash
# Emulador
firebase emulators:start --only firestore --project opti-job \
  --import ./firebase/emulator-cache --export-on-exit --rules firestore.rules

# Producción
firebase deploy --only firestore:rules --project opti-job
```

Las reglas permiten lecturas públicas de `jobOffers`, restringen la escritura de ofertas a empresas autenticadas (se comprueba la existencia del documento en `companies/{uid}`) y limitan el acceso lectura/escritura de candidatos/empresas a su propio UID.

## Estructura destacada

- `lib/app.dart`: MaterialApp y configuración de temas.
- `lib/router/app_router.dart`: declaración de rutas con GoRouter.
- `lib/features/*`: pantallas migradas (landing, ofertas, dashboards, auth).
- `lib/features/video_curriculum/README.md`: límites, dependencias y contratos de la feature de videocurrículum.
- `lib/data/services`: servicios que consumen FirebaseAuth y Cloud Firestore.
- `lib/firebase_options.dart`: credenciales generadas por `flutterfire`.

## Arquitectura por features

| Feature            | Responsabilidad principal                      | Fuera de alcance                  | Entrada                                                           |
| ------------------ | ---------------------------------------------- | --------------------------------- | ----------------------------------------------------------------- |
| `cover_letter`     | Generar/mejorar/guardar carta de presentación. | Grabación/subida de vídeo.        | `lib/features/cover_letter/view/cover_letter_screen.dart`         |
| `video_curriculum` | Grabar, previsualizar y subir videocurrículum. | Gestión de carta de presentación. | `lib/features/video_curriculum/view/video_curriculum_screen.dart` |

Notas de frontera:

- No importar BLoC/servicios/repositorios de `video_curriculum` desde `cover_letter` (ni viceversa).
- Compartir integración por DI, navegación y contratos públicos de cada feature.

## Próximos pasos

- Añadir internacionalización (`flutter_localizations`).
- Reforzar pruebas de widgets y dorado (`golden tests`).

## Mantenimiento y Scripts (Phase 8)

### Feature Flags

La app utiliza `lib/core/config/feature_flags.dart` para controlar la visibilidad del módulo de Entrevistas.

- `FeatureFlags.interviews = true` (default): Habilita pestañas y navegación.
- Para deshabilitar en release rápido, cambiar a `false` y redesplegar (o integrar Remote Config).

### Backfill de Entrevistas

Para aplicaciones antiguas que estén en estado `interview` pero no tengan documento en `interviews/`, ejecutar el script de backfill:

```bash
cd functions
# Instalar dependencias si hace falta
npm install
# Ejecutar script (asegúrate de tener credenciales de admin o usar emulador si configuras las env vars)
npx ts-node scripts/backfillInterviews.ts
```

### Logging

Las Cloud Functions ahora incluyen logs estructurados para el sync de calendario. Ver logs en Google Cloud Console filtering por `jsonPayload.interviewId`.

## Pruebas Manuales (QA Checklist)

1. **Flujo Entrevista**: Empresa inicia entrevista -> Candidato recibe notificación -> Chat habilitado.
2. **Video**: Verificar botón de videollamada y que abra el link (Zoom/Meet).
3. **Calendario**: Al agendar/aceptar propuesta, verificar que aparezca en el panel de calendario del dashboard.
