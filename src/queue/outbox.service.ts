import { Injectable } from '@nestjs/common';
import { EntityManager } from 'typeorm';
import { OutboxEvent } from '../modules/audit/entities/outbox-event.entity';

@Injectable()
export class OutboxService {
  async enqueue(
    manager: EntityManager,
    input: {
      aggregateType: string;
      aggregateId?: string;
      eventType: string;
      payload: Record<string, unknown>;
    },
  ) {
    const repository = manager.getRepository(OutboxEvent);
    return repository.save(
      repository.create({
        ...input,
        status: 'pending',
        attempts: 0,
        availableAt: new Date(),
      }),
    );
  }
}
