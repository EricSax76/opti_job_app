# API Node Skeleton

Estructura propuesta para el Gateway/API y agentes Node.js.

- `src/main.ts`: arranque de NestJS o Express con middlewares comunes (auth, logging, rate limit).
- `src/modules/*`: módulos HTTP que exponen endpoints REST consumidos por Flutter.
- `src/agents/*`: servicios especializados orquestados por BullMQ (matching, calendarios, notificaciones, antifraude, analytics).
- `src/queues/`: configuración compartida de BullMQ, procesadores y workers.

Sugerencia de scripts en `package.json`:

```json
{
  "scripts": {
    "start": "node dist/main.js",
    "start:dev": "ts-node-dev --respawn src/main.ts",
    "queue:worker": "ts-node src/queues/worker.ts"
  }
}
```

> Alinear DTOs y contratos con los eventos descritos en `docs/mode_agent_architecture.md`.
