import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { OutboxWorker } from './queue/outbox.worker';

const logger = new Logger('WorkerBootstrap');

async function delay(milliseconds: number) {
  await new Promise<void>((resolve) => setTimeout(resolve, milliseconds));
}

async function bootstrapWorker() {
  const app = await NestFactory.createApplicationContext(AppModule);
  app.enableShutdownHooks();
  const worker = app.get(OutboxWorker);
  const pollInterval = Number(process.env.WORKER_POLL_INTERVAL_MS ?? 2000);
  const batchSize = Number(process.env.WORKER_BATCH_SIZE ?? 20);
  let stopping = false;

  const stop = () => {
    stopping = true;
  };
  process.once('SIGTERM', stop);
  process.once('SIGINT', stop);
  logger.log(
    `Outbox worker started (batch=${batchSize}, poll=${pollInterval}ms)`,
  );

  try {
    while (!stopping) {
      const processed = await worker.processBatch(batchSize);
      if (processed === 0) await delay(pollInterval);
    }
  } finally {
    logger.log('Outbox worker stopping after current batch');
    await app.close();
  }
}

bootstrapWorker().catch((error: unknown) => {
  logger.error(
    error instanceof Error ? error.message : 'Worker startup failed',
  );
  process.exitCode = 1;
});
