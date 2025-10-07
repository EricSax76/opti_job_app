# Estrategia propuesta: Backend en Dart/Flutter

Aunque Flutter se orienta al frontend, es posible reescribir el backend en Dart empleando el *ecosistema server-side*:

## Stack tecnológico
- **Dart 3.x** ejecutado con `dart run`.
- **shelf** para servidor HTTP modular.
- **shelf_router** para enrutar endpoints REST (`/api/job_offers`, `/api/candidates`, etc.).
- **postgres** (`postgres: ^3.x`) como cliente nativo para la BD existente.
- **dart_jsonwebtoken** para autenticación JWT (equivalente a sesiones actuales).
- **bcrypt** (`bcrypt: ^1.x`) para hashing como en Node.
- **dotenv** (`dotenv: ^4.x`) para gestionar variables de entorno.
- **build_runner** + `freezed`/`json_serializable` para generar modelos inmutables.

## Estructura del proyecto
```
bin/
 └── server.dart            # Punto de arranque
lib/
 ├── config/
 │   ├── env.dart           # Carga de .env
 │   └── logger.dart
 ├── data/
 │   ├── datasource/
 │   │   ├── pg_pool.dart   # Pool de conexiones PostgreSQL
 │   │   └── migrations/    # Scripts SQL (portados desde Node)
 │   ├── repositories/      # Interfaces + implementación
 │   └── models/            # DTOs (JobOffer, User, Candidate)
 ├── features/
 │   ├── auth/
 │   │   ├── auth_controller.dart
 │   │   └── auth_routes.dart
 │   ├── candidates/
 │   ├── companies/
 │   └── job_offers/
 ├── middleware/
 │   ├── cors.dart
 │   ├── logging.dart
 │   └── auth_guard.dart
 └── utils/
     ├── exceptions.dart
     └── response.dart      # Helpers para respuestas JSON
test/
```

## Adaptación de endpoints
- **GET /api/job_offers** → `JobOfferRepository.findAll()` reutilizando SQL existente.
- **GET /api/job_offers/:id** → método `findById`.
- **POST /api/job_offers** → validación con `package:validator` + inserción parametrizada.
- **POST /api/candidates** (registro) → hashing con `bcrypt` y transacción para `users` + `candidates`.
- **POST /api/candidates/login** → verificación con `bcrypt` y emisión de JWT.
- **GET /api/candidates`** y `/:id` → consultas con JOIN como en Node.
- Rutas de empresas (`/api/companies`) y usuarios (`/api/users`) replican la lógica actual.

## Conexión BD
```dart
final connection = PgPool(
  PgEndpoint(
    host: env.dbHost,
    port: env.dbPort,
    database: env.dbName,
    username: env.dbUser,
    password: env.dbPassword,
  ),
  settings: const PgPoolSettings(maxConnectionAge: Duration(hours: 1)),
);
```

- Reutilizar el mismo esquema PostgreSQL; portar migraciones SQL desde `database/`.
- Preparar un `docker-compose` opcional con PostgreSQL para desarrollo.

## Middleware
- `createCorsHeaders()` para dominios web/app.
- `logRequests()` con `package:logging`.
- `verifyJwt()` para proteger dashboards.

## Pruebas
- `package:test` + `shelf_router/testing` para pruebas de integración.
- Emplear `postgres_pool` en memoria o base temporal para tests.

## Roadmap sugerido
1. Crear proyecto Dart (`dart create -t console-full infojobs_backend`).
2. Portar modelos (`JobOffer`, `User`, etc.) con `freezed`.
3. Implementar repositorios SQL replicando consultas de `models/`.
4. Montar rutas equivalentes usando `shelf_router`.
5. Añadir autenticación JWT y middlewares.
6. Migrar scripts de tests existentes (`backend/tests`) a `package:test`.
7. Preparar CI (GitHub Actions) para ejecutar `dart analyze` + `dart test`.

