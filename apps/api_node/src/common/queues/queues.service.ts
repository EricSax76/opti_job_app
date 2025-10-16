import { Inject, Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { Queue } from 'bullmq';
import type { AppConfig } from '@infojobs/shared-config';
import { buildBullConnection } from '@infojobs/shared-config';

import { APP_CONFIG } from '../config/app-config.provider.js';

@Injectable()
export class QueuesService implements OnModuleDestroy {
  private readonly logger = new Logger(QueuesService.name);
  private readonly queues = new Map<string, Queue>();

  constructor(@Inject(APP_CONFIG) private readonly config: AppConfig) {}

  getQueue(name: string): Queue {
    if (!this.queues.has(name)) {
      const queue = new Queue(name, {
        connection: buildBullConnection(this.config)
      });
      this.queues.set(name, queue);
      this.logger.debug(`Queue ${name} instantiated`);
    }
    return this.queues.get(name)!;
  }

  async onModuleDestroy() {
    await Promise.all(
      Array.from(this.queues.values()).map(async (queue) => {
        await queue.close();
      })
    );
  }
}
