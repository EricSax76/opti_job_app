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
