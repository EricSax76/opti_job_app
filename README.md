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

## Configuración de Firebase
1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com/) y habilita Authentication (correo/contraseña) y Cloud Firestore.
2. Ejecuta `flutterfire configure` para tu app y plataformas objetivo. Esto generará/actualizará `lib/firebase_options.dart`.
3. (Opcional) Usa los emuladores de Firebase cuando desarrolles localmente: `firebase emulators:start --only auth,firestore`.
4. Prepara las colecciones `candidates`, `companies` y `jobOffers` con la estructura esperada (`id`, `name`, `email`, etc.) si necesitas datos de ejemplo.

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
- `lib/data/services`: servicios que consumen FirebaseAuth y Cloud Firestore.
- `lib/firebase_options.dart`: credenciales generadas por `flutterfire`.

## Próximos pasos
- Añadir internacionalización (`flutter_localizations`).
- Reforzar pruebas de widgets y dorado (`golden tests`).
