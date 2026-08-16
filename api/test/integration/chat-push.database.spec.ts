import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { OutboxService } from '../../src/queue/outbox.service';
import { OutboxWorker } from '../../src/queue/outbox.worker';
import { SupportService } from '../../src/modules/support/support.service';
import { SupportTicketRepository } from '../../src/modules/support/repositories/support-ticket.repository';
import { SupportTicketCategory } from '../../src/modules/support/enums/support-ticket-category.enum';
import {
  createTestDataSource,
  ensureTestDatabase,
  resetIsolatedTestDatabase,
} from '../utils/test-data-source';

jest.setTimeout(120_000);
const enabled = process.env.RUN_DB_TESTS === 'true';
(enabled ? describe : describe.skip)(
  'live chat and push PostgreSQL integrity',
  () => {
    let dataSource: DataSource;
    let customerId: string;
    let agentA: string;
    let agentB: string;
    let service: SupportService;

    beforeAll(async () => {
      dataSource = createTestDataSource(await ensureTestDatabase());
      await resetIsolatedTestDatabase(dataSource);
      await dataSource.runMigrations({ transaction: 'each' });
      const [{ id: customerRole }] = await dataSource.query(
        `INSERT INTO roles(name,is_system) VALUES ('customer',true) RETURNING id`,
      );
      const [{ id: supportRole }] = await dataSource.query(
        `SELECT id FROM roles WHERE name='support'`,
      );
      [{ id: customerId }] = await dataSource.query(
        `INSERT INTO users(email,full_name,role_id) VALUES ('chat@example.com','Chat Customer',$1) RETURNING id`,
        [customerRole],
      );
      [{ id: agentA }, { id: agentB }] = await dataSource.query(
        `INSERT INTO users(email,full_name,role_id) VALUES ('agent-a@example.com','Agent A',$1),('agent-b@example.com','Agent B',$1) RETURNING id`,
        [supportRole],
      );
      service = new SupportService(
        dataSource,
        new SupportTicketRepository(dataSource),
        new OutboxService(),
      );
    });
    afterAll(async () => {
      if (dataSource?.isInitialized) await dataSource.destroy();
    });

    it('persists messages and their realtime outbox event atomically with unread state', async () => {
      const ticket = await service.create(customerId, {
        category: SupportTicketCategory.GENERAL,
        subject: 'Need help',
        message: 'Initial message',
      });
      const result = await service.history(customerId, ticket.id, 'customer');
      expect(result.items).toHaveLength(1);
      const [stored] = await dataSource.query(
        `SELECT staff_unread_count FROM support_tickets WHERE id=$1`,
        [ticket.id],
      );
      const [{ count }] = await dataSource.query(
        `SELECT COUNT(*)::int count FROM outbox_events WHERE aggregate_id=$1 AND event_type='support.message.created'`,
        [result.items[0].id],
      );
      expect(stored.staff_unread_count).toBe(1);
      expect(count).toBe(1);
    });

    it('allows exactly one agent to claim an unassigned conversation concurrently', async () => {
      const ticket = await service.create(customerId, {
        category: SupportTicketCategory.GENERAL,
        subject: 'Claim me',
        message: 'Hello',
      });
      const results = await Promise.allSettled([
        service.claim(agentA, ticket.id),
        service.claim(agentB, ticket.id),
      ]);
      expect(
        results.filter((result) => result.status === 'fulfilled'),
      ).toHaveLength(1);
      expect(
        results.filter((result) => result.status === 'rejected'),
      ).toHaveLength(1);
    });

    it('tracks staff/customer unread state and rejects closed-conversation messages', async () => {
      const ticket = await service.create(customerId, {
        category: SupportTicketCategory.GENERAL,
        subject: 'Read state',
        message: 'Hello',
      });
      await service.claim(agentA, ticket.id);
      await service.markRead(agentA, ticket.id, 'support');
      await service.addMessage(agentA, ticket.id, 'support', { body: 'Reply' });
      const [unread] = await dataSource.query(
        `SELECT staff_unread_count,customer_unread_count FROM support_tickets WHERE id=$1`,
        [ticket.id],
      );
      expect(unread).toEqual({
        staff_unread_count: 0,
        customer_unread_count: 1,
      });
      await service.markRead(customerId, ticket.id, 'customer');
      await service.changeStatus(agentA, ticket.id, 'support', 'closed');
      await expect(
        service.addMessage(customerId, ticket.id, 'customer', {
          body: 'Too late',
        }),
      ).rejects.toBeDefined();
    });

    it('persists support notifications and deactivates an invalid FCM token', async () => {
      const ticket = await service.create(customerId, {
        category: SupportTicketCategory.GENERAL,
        subject: 'Push reply',
        message: 'Hello',
      });
      await service.claim(agentA, ticket.id);
      await dataSource.query(
        `INSERT INTO device_tokens(user_id,platform,token) VALUES ($1,'ios','invalid-token')`,
        [customerId],
      );
      await service.addMessage(agentA, ticket.id, 'support', {
        body: 'Agent reply',
      });
      const push = {
        sendToDevice: jest.fn().mockResolvedValue({ permanentFailure: true }),
      };
      const worker = new OutboxWorker(
        dataSource,
        { send: jest.fn() } as any,
        { publish: jest.fn() } as any,
        push as any,
      );
      await worker.processBatch(100);
      const [token] = await dataSource.query(
        `SELECT is_active FROM device_tokens WHERE token='invalid-token'`,
      );
      const [{ count }] = await dataSource.query(
        `SELECT COUNT(*)::int count FROM notifications WHERE user_id=$1 AND type='support_reply'`,
        [customerId],
      );
      const [{ staffCount }] = await dataSource.query(
        `SELECT COUNT(*)::int AS "staffCount" FROM notifications
         WHERE user_id IN ($1,$2) AND type='support_customer_message'`,
        [agentA, agentB],
      );
      const [{ statusCount }] = await dataSource.query(
        `SELECT COUNT(*)::int AS "statusCount" FROM notifications
         WHERE user_id=$1 AND type='support_status_changed'`,
        [customerId],
      );
      expect(token.is_active).toBe(false);
      expect(count).toBe(2);
      expect(staffCount).toBeGreaterThan(0);
      expect(statusCount).toBeGreaterThan(0);
      expect(push.sendToDevice).toHaveBeenCalledTimes(1);
    });
  },
);
