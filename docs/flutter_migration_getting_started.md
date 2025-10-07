# Migración Flutter/Dart – Guía rápida

Esta carpeta contiene dos nuevos proyectos que reescriben la solución original de InfoJobs:

- `flutter_app/`: frontend Flutter (Material 3, GoRouter, Riverpod, Dio).
- `flutter_backend/`: backend Dart con `shelf`, PostgreSQL y autenticación JWT.

## Pasos para ejecutarlos

### Frontend (`flutter_app/`)
1. Instala Flutter ≥ 3.16 y activa el canal estable.
2. Desde `flutter_app/` ejecuta:
   ```bash
   flutter pub get
   flutter run --dart-define=API_BASE_URL=http://localhost:5001/api
   ```
3. Las rutas disponibles replican la app original (`/`, `/job-offer`, `/job-offer/:id`, dashboards y formularios de auth).

### Backend (`flutter_backend/`)
1. Crea un `.env` en la raíz del proyecto (ver plantilla en `flutter_backend/README.md`).
2. Ejecuta:
   ```bash
   dart pub get
   dart run bin/server.dart
   ```
3. Apunta a la misma base PostgreSQL que usaba el backend Node. Se espera el mismo esquema (tablas `users`, `candidates`, `companies`, `job_offers`, etc.).

## Funcionalidades incluidas
- Listado, filtrado y detalle de ofertas de trabajo.
- Dashboard de candidato con ofertas destacadas.
- Dashboard de empresas con formulario para crear ofertas.
- Flujos de registro/login para candidatos y empresas con hash `bcrypt` y emisión de JWT.

## Próximos pasos recomendados
- Añadir persistencia local (SharedPreferences) y refresco de tokens en el frontend.
- Proteger la creación de ofertas en el backend usando `authGuardMiddleware`.
- Migrar el resto de endpoints de Node (filtros avanzados, dashboards específicos, etc.).
- Configurar CI/CD y pruebas unitarias/integración para ambos proyectos.
