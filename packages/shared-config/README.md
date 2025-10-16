# Shared Config

Configuraciones comunes (p. ej. clientes BullMQ, parámetros de observabilidad, claves de feature flags).

- Exportar helpers para leer `Idempotency-Key`, `trace-id` y demás cabeceras estándar.
- Centralizar carga de `.env` y validaciones de configuración.
- Evitar duplicar lógica en BFF, agentes y workers.
