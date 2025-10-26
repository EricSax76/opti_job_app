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
  DB_NAME=infojobs_new
  DB_USER=ericmoscoso
  DB_PASSWORD=Megustaelsaxo.76
  JWT_SECRET=Melisa76
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
