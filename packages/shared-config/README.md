# Shared Config

Configuraciones comunes (p. ej. clientes BullMQ, parámetros de observabilidad, claves de feature flags).

- `loadConfig` valida variables de entorno críticas.
- `headers.ts` contiene helpers para `Idempotency-Key`, `trace-id`, etc.
- `bullmq.ts` expone opciones de conexión compartidas.

Evita duplicar lógica en BFF, agentes y workers.
