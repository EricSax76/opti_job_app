# Feature: Video Curriculum

Este módulo es responsable de la grabación, previsualización y subida del videocurrículum del candidato.

## Alcance
- Gestionar flujo de grabación local (cámara/micrófono, intentos y auto-stop).
- Mostrar estado de vídeo local grabado y vídeo subido en Firebase Storage.
- Subir vídeo y persistir metadatos en Firestore.

Fuera de alcance:
- Carta de presentación (feature `cover_letter`).
- Perfil completo del candidato.
- Navegación global y composición del dashboard.

## Estructura
- `bloc/`: estado y eventos de la feature (`VideoCurriculumBloc`).
- `services/`: acceso a Firebase Storage y Firestore.
- `repositories/`: fachada de acceso a datos para la UI/BLoC.
- `view/`: pantallas y controladores de pantalla.
- `widgets/`: componentes UI y controladores de cámara.

## Dependencias permitidas
- Compartidas: `flutter`, `flutter_bloc`, `camera`, `video_player`, `firebase_*`.
- Del dominio app:
  - `modules/candidates/cubits/candidate_auth_cubit.dart` (UID autenticado).
  - `modules/profiles/cubits/profile_cubit.dart` (refresh post-subida).

Dependencias no permitidas:
- Importar BLoC/servicios/repositorios de `features/cover_letter`.
- Acoplar lógica de videocurrículum dentro de pantallas de otras features.

## Contratos de integración
- Entrada principal de UI: `view/video_curriculum_screen.dart`.
- Registro en DI: `AppDependencies.videoCurriculumRepository`.
- Contrato de subida:
  - `VideoCurriculumRepository.uploadVideoCurriculum({candidateUid, filePath})`.
- Efecto esperado tras éxito de guardado:
  - `ProfileCubit.refreshProfile()` para refrescar metadatos del candidato.

## Reglas de mantenimiento
- Mantener esta feature autocontenida en `features/video_curriculum`.
- Si otro módulo necesita funcionalidad de vídeo, exponerla vía API pública del módulo (screen/controller/repository), no accediendo a internals.
- Cualquier cambio de esquema o contrato de datos debe actualizar tests de:
  - `test/features/video_curriculum/bloc/`
  - `test/features/video_curriculum/services/`
