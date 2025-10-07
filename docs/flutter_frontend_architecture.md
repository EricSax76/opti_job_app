# Arquitectura propuesta: Frontend Flutter

## Tecnologías clave
- **Flutter 3.x** con **Dart** para UI multiplataforma (web, iOS, Android, desktop).
- **Material Design 3** (`useMaterial3: true`) para estilos coherentes.
- **GoRouter** para navegación declarativa y deep links (`/`, `/job-offer/:id`, etc.).
- **Riverpod** para gestión de estado reactivo y desacoplado.
- **Dio** para consumo HTTP de la API existente (o de la versión migrada a Dart).
- **SharedPreferences** para persistencia ligera (token, usuario autenticado).

## Estructura de carpetas
```
lib/
 ├── app.dart               # MaterialApp + GoRouter
 ├── bootstrap.dart         # Inicialización (env, servicios)
 ├── main.dart              # Punto de entrada
 ├── theme/
 │   ├── color_schemes.dart
 │   └── theme.dart
 ├── data/
 │   ├── models/            # DTOs: JobOffer, Candidate, Company
 │   ├── repositories/      # Abstracciones y contratos
 │   └── services/          # ApiClient, AuthService, JobOfferService
 ├── features/
 │   ├── landing/
 │   ├── auth/
 │   ├── job_offers/
 │   ├── dashboards/
 │   └── shared/            # Widgets comunes (Navbar, Footer)
 └── utils/
     ├── exceptions.dart
     └── formatters.dart
```

## Mapeo de pantallas actuales → Flutter
| React | Flutter |
|-------|---------|
| `LandingPage` | `features/landing/landing_screen.dart` con widgets para secciones y CTA |
| `JobOfferPage` | `features/job_offers/job_offer_list_screen.dart` + `JobOfferFilterBar` |
| `JobOfferDetail` | `features/job_offers/job_offer_detail_screen.dart` con carga diferida por ID |
| `DashboardCandidate` | `features/dashboards/candidate_dashboard_screen.dart` consumiendo `jobOfferProvider` |
| `DashboardCompany` | `features/dashboards/company_dashboard_screen.dart` para publicar/gestionar ofertas |
| `CandidateLogin` & `CandidateRegister` | `features/auth/candidate_login_screen.dart`, `candidate_register_screen.dart` |
| `CompanyLogin` & `CompanyRegister` | Pantallas equivalentes en `features/auth/` |
| `Footer`, `Navbar` | Widgets reutilizables en `features/shared/widgets/` |

## Gestión de estado
- `ProviderScope` en `main.dart`.
- Providers por feature (`jobOfferProvider`, `authProvider`).
- Formularios utilizando `Form` + `TextEditingController` gestionados por `StateNotifier`.

## Consumo de la API existente
```dart
final dio = Dio(BaseOptions(
  baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5001/api'),
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 15),
));

class JobOfferService {
  JobOfferService(this._dio);
  final Dio _dio;

  Future<List<JobOffer>> fetchAll({String? jobType}) async {
    final response = await _dio.get('/job_offers', queryParameters: {
      if (jobType?.isNotEmpty ?? false) 'job_type': jobType,
    });
    return (response.data as List<dynamic>)
        .map((json) => JobOffer.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
```

## Estados de carga y error
- `AsyncValue` de Riverpod para mostrar `CircularProgressIndicator`, mensajes de error y reintentos.
- Manejo global de errores HTTP (401/403 → logout, 500 → diálogo genérico).

## Responsividad Web/Mobile
- Widgets `LayoutBuilder` + `Breakpoints` personalizados.
- Soporte para gestos y scroll web (`Scrollbar`, `SingleChildScrollView`).

## Internacionalización
- Estructura lista para `flutter_localizations` (ES, EN) con `arb`.

## Tests
- `flutter_test` para widgets principales.
- `mocktail` para servicios simulados.
- Golden tests para componentes estáticos (Landing sections).

