# Fase 4: Contencion de GetIt (locator)

## Objetivo
Mantener `GetIt` como herramienta de bootstrap e inyeccion en puntos raiz, evitando que se convierta en acoplamiento global en toda la app.

## Politica de arquitectura
Permitido:
- Bootstrap de aplicacion (`lib/main.dart`, `lib/bootstrap/*`).
- Inyeccion en paginas o contenedores raiz de cada feature.

Evitar:
- Uso de `locator`/`GetIt` dentro de widgets presentacionales.
- Uso de `locator`/`GetIt` dentro de logica interna de UI (controllers de widget, helpers visuales, builders).

Obligatorio en capas inferiores:
- Dependencias por constructor explicito en `Cubit`, `Bloc`, `Controller`, `Service`, `Repository`.
- Firmas publicas con dependencias visibles y tipadas.

## Linea base actual (2026-02-17)
- `get_it` esta declarado en `pubspec.yaml`.
- No hay referencias activas en `lib/` a `GetIt` o `locator`.
- El proyecto ya tiene un composition root explicito con `AppDependencies` y `AppScope`:
  - `lib/bootstrap/app_dependencies.dart`
  - `lib/app/app_scope.dart`

Esta fase define como mantener esa trazabilidad si se usa `GetIt`.

## Plan por subfases

### Fase 4.1 - Inventario y frontera de uso
Objetivo:
- Definir frontera permitida y detectar usos actuales/futuros fuera de politica.

Acciones:
1. Ejecutar auditoria de uso:
   - `rg -n "GetIt|get_it|locator|GetIt\\.I|GetIt\\.instance" lib test`
2. Clasificar hallazgos por zona:
   - `bootstrap`
   - `paginas/contenedores raiz`
   - `ui presentacional`
   - `logica interna de ui`
   - `capas inferiores`
3. Crear backlog de refactor con archivo, responsable y riesgo.

Entregable:
- Inventario de usos de locator con clasificacion `permitido` o `migrar`.

### Fase 4.2 - Encapsular GetIt en composition root
Objetivo:
- Concentrar registro/resolucion en bootstrap.

Acciones:
1. Definir un unico modulo de registro (por ejemplo `lib/bootstrap/get_it_bootstrap.dart`).
2. Registrar dependencias de infraestructura y repositorios en ese modulo.
3. Resolver dependencias una sola vez al construir el arbol raiz.
4. Exponer dependencias tipadas a traves de `AppDependencies` o equivalente.

Entregable:
- Un unico punto de configuracion del locator, sin resoluciones dispersas.

### Fase 4.3 - Inyeccion en paginas/contenedores raiz
Objetivo:
- Limitar consumo de locator a entry points.

Acciones:
1. En cada feature, resolver dependencias solo en pagina/contenedor raiz.
2. Pasar dependencias por constructor hacia widgets hijos y capas inferiores.
3. Evitar lecturas de locator en `build()` de widgets no raiz.

Entregable:
- Entry points con inyeccion explicita; arbol interno sin llamadas a locator.

### Fase 4.4 - Eliminar locator de UI presentacional
Objetivo:
- Hacer UI reusable y testeable sin dependencias globales implicitas.

Acciones:
1. Refactorizar widgets presentacionales para recibir callbacks/modelos por constructor.
2. Mover resolucion de servicios a contenedores o cubits.
3. Asegurar que archivos de `ui/widgets` no importen `get_it`.

Patron esperado:
```dart
// Antes (no permitido)
class OfferCard extends StatelessWidget {
  final _repo = GetIt.I<JobOfferRepository>();
}

// Despues (permitido)
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.onApply});
  final VoidCallback onApply;
}
```

Entregable:
- Widgets presentacionales sin locator ni acceso a servicios.

### Fase 4.5 - Capas inferiores con constructor explicito
Objetivo:
- Trazabilidad de dependencias en firmas publicas.

Acciones:
1. `Cubit/Bloc` recibe repositorios por constructor.
2. `Service` recibe clientes o gateways por constructor.
3. `Repository` recibe datasource/clientes por constructor.
4. Prohibir `GetIt.I<T>()` dentro de metodos de dominio.

Patron esperado:
```dart
class JobOffersCubit extends Cubit<JobOffersState> {
  JobOffersCubit({
    required JobOfferRepository jobOfferRepository,
    required ProfileRepository profileRepository,
  }) : _jobOfferRepository = jobOfferRepository,
       _profileRepository = profileRepository,
       super(const JobOffersState.initial());

  final JobOfferRepository _jobOfferRepository;
  final ProfileRepository _profileRepository;
}
```

Entregable:
- Dependencias visibles en constructores publicos.

### Fase 4.6 - Guardrails (analisis y CI)
Objetivo:
- Evitar regresiones hacia acoplamiento global.

Acciones:
1. Agregar chequeo de arquitectura en CI para bloquear imports de `get_it` fuera de rutas permitidas.
2. Mantener allowlist de rutas permitidas:
   - `lib/bootstrap/*`
   - `lib/main.dart`
   - paginas/contenedores raiz definidos por arquitectura
3. Incluir checklist en code review:
   - "No locator en presentacionales"
   - "Dependencias visibles en firmas"

Entregable:
- Regla automatica que falla PR cuando se rompe la politica.

### Fase 4.7 - Cierre y validacion DoD
Objetivo:
- Confirmar cumplimiento total de la fase.

Acciones:
1. Re-ejecutar auditoria global de locator.
2. Revisar trazabilidad de 3 flujos criticos end-to-end:
   - Auth
   - Publicacion de oferta
   - Aplicaciones/candidaturas
3. Documentar resultados y deuda residual.

Entregable:
- Acta de cierre de Fase 4 con estado por modulo.

## Definition of Done (DoD)
Se considera completada la Fase 4 cuando:
1. No existe uso de `GetIt`/`locator` fuera de bootstrap y paginas/contenedores raiz aprobados.
2. Widgets presentacionales y logica interna de UI no importan `get_it`.
3. En capas inferiores, todas las dependencias se observan en firmas publicas.
4. La trazabilidad de dependencias se puede seguir desde entry point hasta infraestructura sin "magia" implicita.
5. El chequeo automatizado de arquitectura queda activo en CI.

## Checklist operativo por PR
1. Este cambio introduce `GetIt` fuera de rutas permitidas: no.
2. Este cambio agrega o mantiene dependencias explicitas en constructores: si.
3. Se elimina algun acceso implicito por locator en UI: si/no (justificar).
4. Se actualizaron pruebas o smoke tests de wiring si aplica: si/no (justificar).

## Orden recomendado de ejecucion
1. Fase 4.1 y 4.2 en una PR de infraestructura.
2. Fase 4.3, 4.4 y 4.5 por modulo (auth, job_offers, applications, profiles, companies).
3. Fase 4.6 en paralelo al primer modulo migrado.
4. Fase 4.7 al finalizar la ultima migracion.
