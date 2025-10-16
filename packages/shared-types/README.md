# Shared Types

Contratos TypeScript/Dart compartidos entre el BFF, agentes y la app Flutter.

- DTOs de dominios (`Offer`, `Candidate`, `Application`, etc.).
- Tipos para eventos y jobs de BullMQ (`OfferCreated`, `matching:compute`, ...).
- Interfaces serializables pensadas para generar clientes en Dart/TypeScript.

Los tipos viven en `src/` y se distribuyen como paquete npm local.
