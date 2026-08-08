import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddLiveChatAndPushIntegrity1700000000020 implements MigrationInterface {
  name = 'AddLiveChatAndPushIntegrity1700000000020';
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE support_tickets
        ADD COLUMN assigned_at timestamptz,
        ADD COLUMN last_message_at timestamptz,
        ADD COLUMN customer_last_read_at timestamptz,
        ADD COLUMN staff_last_read_at timestamptz,
        ADD COLUMN customer_unread_count integer NOT NULL DEFAULT 0 CHECK (customer_unread_count >= 0),
        ADD COLUMN staff_unread_count integer NOT NULL DEFAULT 0 CHECK (staff_unread_count >= 0);
      CREATE INDEX idx_support_queue ON support_tickets
        (status, priority, staff_unread_count DESC, last_message_at, created_at)
        WHERE status NOT IN ('resolved','closed');
      ALTER TABLE notifications ADD COLUMN event_key varchar(255);
      CREATE UNIQUE INDEX uq_notification_user_event ON notifications (user_id, event_key) WHERE event_key IS NOT NULL;
      ALTER TABLE notification_deliveries ADD COLUMN device_token_id uuid REFERENCES device_tokens(id) ON DELETE SET NULL;
      CREATE UNIQUE INDEX uq_notification_push_device ON notification_deliveries (notification_id, device_token_id)
        WHERE channel='push' AND device_token_id IS NOT NULL;
    `);
  }
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DROP INDEX IF EXISTS uq_notification_push_device;
      ALTER TABLE notification_deliveries DROP COLUMN IF EXISTS device_token_id;
      DROP INDEX IF EXISTS uq_notification_user_event;
      ALTER TABLE notifications DROP COLUMN IF EXISTS event_key;
      DROP INDEX IF EXISTS idx_support_queue;
      ALTER TABLE support_tickets DROP COLUMN IF EXISTS staff_unread_count, DROP COLUMN IF EXISTS customer_unread_count,
        DROP COLUMN IF EXISTS staff_last_read_at, DROP COLUMN IF EXISTS customer_last_read_at,
        DROP COLUMN IF EXISTS last_message_at, DROP COLUMN IF EXISTS assigned_at;
    `);
  }
}
