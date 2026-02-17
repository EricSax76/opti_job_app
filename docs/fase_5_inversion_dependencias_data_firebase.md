# Fase 5: Inversion de Dependencias en Data (Firebase)

## Objetivo
Eliminar construccion implicita de infraestructura Firebase dentro de la capa data para que toda dependencia se resuelva en composition root y llegue por constructor explicito.

## Problema que resuelve
Cuando un repository/data source crea internamente clientes Firebase por fallback estatico, se pierde trazabilidad y testabilidad:
- Se ocultan dependencias reales.
- Se dificulta mockear/stubear en pruebas.
- Se acopla el dominio de datos a singletons globales.
- Se incrementa riesgo de configuraciones inconsistentes por entorno.

## Politica de arquitectura (Fase 5)
Permitido:
- Resolver `FirebaseAuth`, `FirebaseFirestore`, `FirebaseStorage`, `FirebaseFunctions` en bootstrap/composition root.
- Inyectar instancias por constructor en repositories/data sources.

No permitido en data:
- `?? Firebase*.instance`
- `?? FirebaseFunctions.instanceFor(...)`
- `Firebase*.instance` dentro de metodos de repository/data source.

Regla principal:
- La capa data no crea infraestructura; solo la consume.

## Anti-patron a retirar
```dart
class AnyRepository {
  AnyRepository({FirebaseFirestore? fs})
    : _fs = fs ?? FirebaseFirestore.instance;
}
```

## Patron objetivo
```dart
class AnyRepository {
  AnyRepository({required FirebaseFirestore fs}) : _fs = fs;
}
```

## Bootstrap objetivo
```dart
locator.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
locator.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
locator.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

locator.registerLazySingleton<AuthRepository>(
  () => AuthRepository(firebaseAuth: locator<FirebaseAuth>()),
);
```

## Alcance
En alcance:
- `lib/modules/**/repositories/*`
- `lib/modules/**/data/*`
- `lib/modules/**/services/*` cuando actuen como adaptadores de infraestructura.

Fuera de alcance (para esta fase):
- Refactor funcional de UI.
- Cambios de comportamiento de negocio.
- Reescritura de contratos de dominio que no dependan de Firebase.

## Plan de ejecucion recomendado

### Fase 5.1 - Inventario y clasificacion
Objetivo:
- Detectar toda construccion implicita de Firebase en data.

Comandos:
1. `rg -n "Firebase[A-Za-z0-9_]*\\?\\s*|\\?\\?\\s*Firebase[A-Za-z0-9_]*\\.instance|FirebaseFunctions\\.instanceFor|Firebase[A-Za-z0-9_]*\\.instance" lib/modules -g '*.dart'`
2. `rg -n "\\?\\?\\s*Firebase" lib/modules -g '*.dart'`

Entregable:
- Inventario por archivo con estado `migrar` o `ok`.

### Fase 5.2 - Contratos explicitos en constructores
Objetivo:
- Hacer visibles las dependencias Firebase en firma publica.

Acciones:
1. Reemplazar parametros opcionales por `required`.
2. Asignar dependencia directa sin fallback.
3. Mantener nombres tipados (`firestore`, `storage`, `firebaseAuth`, `functions`).

Entregable:
- Repositories/data sources sin fallback estatico.

### Fase 5.3 - Wiring en bootstrap
Objetivo:
- Construir infraestructura Firebase solo en composition root.

Acciones:
1. Registrar singletons de primitives Firebase.
2. Construir repositories/data sources usando esas instancias registradas.
3. Evitar `new` de clients Firebase fuera de bootstrap.

Entregable:
- Bootstrap como unico punto de construccion de infraestructura.

### Fase 5.4 - Propagacion de firmas aguas arriba
Objetivo:
- Ajustar factories, providers y rutas raiz tras cambios de constructor.

Acciones:
1. Actualizar `GetIt`/AppDependencies wiring.
2. Ajustar entry points que creen cubits/services dependientes.
3. Corregir tests afectados por nuevas dependencias requeridas.

Entregable:
- Compilacion limpia sin constructores incompletos.

### Fase 5.5 - Pruebas y validacion tecnica
Objetivo:
- Verificar que el refactor no cambie comportamiento funcional.

Acciones:
1. `flutter analyze`
2. `flutter test`
3. Smokes de flujos criticos:
   - Auth
   - Publicacion de oferta
   - Candidaturas/aplicantes

Entregable:
- Evidencia de estabilidad post-refactor.

### Fase 5.6 - Guardrails de regresion
Objetivo:
- Evitar reintroduccion de fallbacks implicitos.

Acciones:
1. Agregar chequeo automatizado CI para fallar si aparece:
   - `?? Firebase*.instance`
   - `Firebase*.instance` en capa data.
2. Mantener allowlist explicita para bootstrap.

Entregable:
- Regla automatica activa en CI.

### Fase 5.7 - Cierre de fase
Objetivo:
- Documentar cumplimiento y deuda residual.

Acciones:
1. Re-ejecutar auditoria global.
2. Generar acta con:
   - archivos migrados
   - riesgos abiertos
   - pendientes (si existen)

Entregable:
- Acta de cierre de Fase 5.

## Riesgos y mitigaciones
Riesgo:
- Ruptura de wiring por constructores con nuevos `required`.
Mitigacion:
- Migrar primero bootstrap y despues callsites.

Riesgo:
- Tests rotos por dependencias nuevas.
Mitigacion:
- Crear test doubles/fakes en soporte comun.

Riesgo:
- Regresion futura por fallback agregado en PR nuevo.
Mitigacion:
- Guardrail CI + checklist de revision.

## Definition of Done (DoD)
Se considera completada la Fase 5 cuando:
1. Cero `?? Firebase*.instance` en capa data (`lib/modules/**/(repositories|data|services)`).
2. Cero `Firebase*.instance` dentro de metodos de repositories/data sources.
3. Todas las dependencias de infraestructura son visibles en constructores publicos.
4. Bootstrap registra primitives Firebase y construye data layer con esas instancias.
5. `flutter analyze` y `flutter test` en verde.
6. Guardrail automatizado activo en CI para prevenir regresiones.

## Checklist operativo por PR (Fase 5)
1. Este cambio agrega fallback `?? Firebase*.instance` en data: no.
2. Las nuevas dependencias quedan tipadas y visibles en constructor: si.
3. El wiring de bootstrap fue actualizado: si/no (justificar).
4. Se actualizo test setup/fakes donde aplica: si/no (justificar).
5. Se ejecuto analyze y test: si.

## Metricas de seguimiento sugeridas
- `metric_1`: conteo de `?? Firebase*.instance` en data (target: 0).
- `metric_2`: conteo de `Firebase*.instance` fuera de bootstrap (target: 0, salvo allowlist).
- `metric_3`: numero de constructores data con dependencias `required` (tendencia creciente hasta cobertura total).
