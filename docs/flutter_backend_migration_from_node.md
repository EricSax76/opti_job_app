# Plan de migración: `backend` (Node.js) → `flutter_backend` (Dart shelf)

Este documento resume cómo portar la API original ubicada en `backend/` a la implementación en Dart que vive en `flutter_backend/`. Úsalo como checklist para replicar la funcionalidad existente.

## 1. Panorama del backend Node
- `package.json` define un servidor Express (`src/index.js`) con dependencias clave: `express`, `pg`, `dotenv`, `jsonwebtoken`, `bcryptjs`, `cors`.
- Capas funcionales:
  - **`controllers/`**: lógica HTTP (auth, candidates, companies, offers, dashboard, filters).
  - **`models/`**: operaciones SQL manuales sobre PostgreSQL (`dbClient.js`).
  - **`routes/`**: routers Express que conectan endpoints con controladores.
  - **`middlewares/`**: autorización JWT, validaciones y CORS.
  - **`database/`**: conexión principal y scripts auxiliares.
  - **`tests/`**: utilidades para comprobar endpoints (supertest/jest).

## 2. Estructura objetivo en Dart
`flutter_backend/lib/` ya contiene middlewares y utilidades base. Amplíalo siguiendo esta correspondencia:

| Node (`backend/`) | Dart (`flutter_backend/lib/`) | Notas de migración |
|-------------------|------------------------------|--------------------|
| `src/index.js`    | `bin/server.dart`            | Configura `Pipeline` + `Router` (shelf). |
| `controllers/authController.js` | `features/auth/auth_controller.dart` | Refactoriza a funciones que reciben `Request` y devuelven `Response`. |
| `controllers/candidateController.js` | `features/candidates/candidates_controller.dart` | Mantén estructura async/await con `postgres` y mapea errores a `jsonError()`. |
| `controllers/companyController.js`, `offerController.js`, `dashboardController.js`, `filterController.js`, `utilsController.js` | Controllers Dart equivalentes en `features/...`. |
| `models/*Model.js` | `data/repositories/*.dart` + `data/models/*.dart` | Sustituye SQL crudo por consultas en `package:postgres`. |
| `middlewares/authMiddleware.js`, `middlewares/validationMiddleware.js`, `cors` | `middleware/auth_guard.dart`, `middleware/cors.dart`, crear `validation.dart`. |
| `routes/*.js` | `router.dart` + módulos de rutas (`features/.../routes.dart`) | Usa `shelf_router`. |
| `tests/` | `test/features/..._test.dart` | `package:test` + `shelf_router/testing`. |

## 3. Paso a paso sugerido
1. **Configura entorno**  
   - Usa `.env` de Node como referencia (`PORT`, `DB_*`, `JWT_SECRET`). Implementa carga en `lib/config/env.dart`.
   - Crea `PgPool` en `lib/data/database.dart` con los mismos parámetros que `backend/models/dbClient.js`.

2. **Modelos y repositorios**  
   - Toma cada archivo de `backend/models/` y transforma cada función SQL en métodos del repositorio Dart. Ejemplo:
     - `createUser` → `UserRepository.createUser` devolviendo una clase `User`.
     - `getAllCandidates` → `CandidateRepository.findAll`.
   - Opcional: usa `freezed`/`json_serializable` para los DTOs.

3. **Servicios/Controladores**  
   - Revisa `controllers/*.js` para entender las validaciones y respuestas.  
   - Replica la lógica en funciones Dart que usan los repositorios.  
   - Utiliza `jsonResponse`/`jsonError` para estandarizar respuestas.

4. **Rutas**  
   - Cada archivo en `routes/` define un grupo Express. Conviértelo a `Router` (shelf_router) y monta en `bin/server.dart`.  
   - Ejemplo: `routes/jobOffers.js` → `Router jobOffersRouter()` con un handler `post('/')`.

5. **Middlewares**  
   - `middleware/auth_guard.dart` ya cubre la verificación JWT. Ajusta mensajes de error replicando los del controlador Node.  
   - Crea un middleware de validación en Dart si en Node se utilizaban `validationMiddleware.js`.

6. **Flujo de autenticación**  
   - Node usa `jsonwebtoken` y `bcryptjs`. En Dart emplea `dart_jsonwebtoken` y `package:bcrypt`.  
   - Replica `register`/`login` de `authController.js` mapeando claims (`id`, `role`) para compatibilidad con frontend.

7. **Dashboard y filtros**  
   - Los controladores de dashboard/filters ejecutan consultas agregadas. Traduce las mismas sentencias SQL y asegúrate de serializar los resultados en el mismo formato.

8. **Pruebas**  
   - Convierte los tests de `backend/tests/` a `package:test`.  
   - Usa `shelf_router/testing` o `shelf_test` para simular requests.  
   - Para pruebas de repositorio, puedes usar una BD PostgreSQL temporaria o `docker-compose` como en Node.

9. **Tareas automáticas**  
   - Añade scripts de análisis (`dart analyze`) y pruebas (`dart test`) en el CI.  
   - Considera escribir migraciones SQL en `lib/data/migrations/` si se usaban scripts manuales en Node.

## 4. Checklist de endpoints a portar
| Endpoint Node (`routes/`) | Estado en Dart |
|---------------------------|----------------|
| `POST /api/auth/register`, `POST /api/auth/login` | **Pendiente** → implementar en `features/auth`. |
| `GET /api/candidates`, `GET /api/candidates/:id`, `POST /api/candidates` | **Pendiente** → `features/candidates`. |
| `POST /api/companies`, `POST /api/companies/login`, `GET /api/companies` | **Pendiente** → `features/companies`. |
| `POST /api/job_offers`, `GET /api/job_offers`, `GET /api/job_offers/:id` | **Pendiente** → `features/job_offers`. |
| `GET /api/dashboard/metrics` | **Pendiente** → replicar consultas en módulo dashboard. |
| `GET /api/filters/options` | **Pendiente** → replicar en módulo filters. |

Actualiza esta tabla a medida que portes cada módulo.

## 5. Recursos adicionales
- [package:shelf](https://pub.dev/packages/shelf) documentación oficial.
- [package:postgres](https://pub.dev/packages/postgres) para SQL parametrizado.
- [jwt.io](https://jwt.io/) para verificar tokens generados.
- [`backend/`](../backend/) (inspection mediante `git show`) sirve como referencia de queries y payloads esperados.

> Consejos: migra módulo por módulo, montando pruebas unitarias tras cada paso. Mantén la paridad de respuestas JSON para no romper la app Flutter ni otros consumidores de la API.
