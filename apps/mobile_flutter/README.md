# Mobile Flutter Skeleton

Este árbol define la estructura objetivo para la app Flutter dentro del modo agente.

- `lib/core/`: configuración de `dio`, interceptores JWT/refresh e inicialización de dependencias.
- `lib/features/*`: módulos funcionales por dominio (auth, ofertas, candidatos, aplicaciones, entrevistas).
- `lib/features/<feature>/presentation`: pantallas y widgets (Bloc/Riverpod).
- `lib/features/<feature>/data`: repositorios y DTOs conectados al BFF.
- `lib/features/<feature>/domain`: modelos de negocio y casos de uso.

> Nota: el código existente en `flutter_app/` puede migrarse aquí de forma progresiva. Mantener ambos árboles hasta completar la transición.
