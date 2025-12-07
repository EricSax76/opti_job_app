# Frontend Flutter – InfoJobs

Este proyecto contiene la reimplementación Flutter del frontend existente en React. Se ofrece soporte multiplataforma (web/móvil/desktop) reutilizando el backend actual vía HTTP.

## Requisitos
- Flutter 3.16 o superior instalado y en el PATH
- Dart 3.2 o superior

## Puesta en marcha
```bash
flutter pub get
flutter run -d chrome # o dispositivo preferido
```

Configura la URL de la API mediante variables de entorno en tiempo de compilación:
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:5001/api
```

## Estructura destacada
- `lib/app.dart`: MaterialApp y configuración de temas.
- `lib/routing/app_router.dart`: declaración de rutas con GoRouter.
- `lib/features/*`: pantallas migradas (landing, ofertas, dashboards, auth).
- `lib/data/services`: servicios HTTP usando Dio.
- `lib/providers`: capa Riverpod para estados compartidos.

## Próximos pasos
- Añadir internacionalización (`flutter_localizations`).
- Integrar autenticación segura con tokens JWT del nuevo backend en Dart.
- Reforzar pruebas de widgets y dorado (`golden tests`).


## Backend Dart (shelf) – InfoJobs

Servidor HTTP que replica la API Node existente usando `shelf` y PostgreSQL.

### Requisitos
- Dart SDK 3.2 o superior
- Base de datos PostgreSQL con el mismo esquema que usa la versión Node
- Archivo `.env` con las variables:
  ```
  PORT=5001
  DB_HOST=localhost
  DB_PORT=5432
  DB_NAME=infojobs
  DB_USER=postgres
  DB_PASSWORD=postgres
  JWT_SECRET=change-me
  ```

### Ejecución
```bash
dart pub get
dart run bin/server.dart
```

### Endpoints incluidos
- `GET /api/job_offers`
- `GET /api/job_offers/:id`
- `POST /api/job_offers`
- `POST /api/candidates` (registro)
- `POST /api/candidates/login`
- `GET /api/candidates`
- `GET /api/candidates/:id`
- `POST /api/companies` (registro)
- `POST /api/companies/login`

### Pruebas
```bash
dart test
```