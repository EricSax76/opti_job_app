# Shared Types

Contratos TypeScript/Dart compartidos entre el BFF, agentes y la app Flutter.

- Definir DTOs de eventos (`OfferCreated`, `MatchingComputed`, etc.).
- Generar clientes typed (p. ej. con `openapi-typescript` o `ts-json-schema-generator`).
- Exportar tipos reutilizables para que los agentes y el frontend mantengan sincronía.
