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

La app usa `firebase_ai` directamente desde Flutter (sin backend HTTP propio ni Cloud Run para estas funciones).

Parámetros útiles al ejecutar la app:

- `--dart-define=FIREBASE_AI_BACKEND=vertex` (default) o `google`
- `--dart-define=FIREBASE_AI_LOCATION=europe-southwest1`
- `--dart-define=FIREBASE_AI_MODEL=gemini-2.0-flash`

Funciones de IA disponibles:

- Mejorar resumen de CV
- Calcular match candidato/oferta
- Generar borrador de oferta
- Mejorar carta de presentación

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

## Refactors de arquitectura

- Fase 4 (DI): contención de GetIt/locator en composition root y páginas raíz, con dependencias explícitas por constructor: `docs/fase_4_contencion_getit.md`.
- Fase 5 (Data/Firebase): inversion de dependencias en capa data para eliminar construccion implicita de infraestructura: `docs/fase_5_inversion_dependencias_data_firebase.md`.
- Guardrail automático de locator/get_it (escanea todos los `.dart` trackeados): `bash tool/check_locator_policy.sh` (también corre en CI).
- Guardrail automático de Firebase DI (bloquea `?? Firebase*.instance` fuera de `lib/bootstrap/*` y `lib/main.dart`): `bash tool/check_firebase_di_policy.sh` (también corre en CI).

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
