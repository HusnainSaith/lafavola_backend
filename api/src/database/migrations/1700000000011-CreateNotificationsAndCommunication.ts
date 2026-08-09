import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateNotificationsAndCommunication1700000000011 implements MigrationInterface {
  name = 'CreateNotificationsAndCommunication1700000000011';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
CREATE TABLE device_tokens (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        platform varchar(20) NOT NULL CHECK (platform IN ('ios','android','web')),
        provider varchar(30) NOT NULL DEFAULT 'fcm' CHECK (provider = 'fcm'),
        token text NOT NULL UNIQUE,
        is_active boolean NOT NULL DEFAULT true,
        last_seen_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE notification_preferences (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id uuid NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
        push_order_updates boolean NOT NULL DEFAULT true,
        sms_order_updates boolean NOT NULL DEFAULT false,
        email_order_updates boolean NOT NULL DEFAULT true,
        push_promotions boolean NOT NULL DEFAULT true,
        sms_promotions boolean NOT NULL DEFAULT false,
        email_promotions boolean NOT NULL DEFAULT false,
        coupon_expiration_alerts boolean NOT NULL DEFAULT true,
        quiet_hours_start time,
        quiet_hours_end time,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE notifications (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id uuid REFERENCES users(id) ON DELETE CASCADE,
        order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
        promotion_id uuid REFERENCES promotions(id) ON DELETE SET NULL,
        coupon_id uuid REFERENCES coupons(id) ON DELETE SET NULL,
        type varchar(50) NOT NULL
          CHECK (type IN (
            'order_confirmed','order_preparing','order_baking','order_out_for_delivery',
            'driver_arriving','order_delivered','promotion','discount','coupon_expiring',
            'support_reply','system'
          )),
        title varchar(180) NOT NULL,
        body text NOT NULL,
        payload jsonb NOT NULL DEFAULT '{}'::jsonb,
        read_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE notification_deliveries (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        notification_id uuid NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
        channel varchar(20) NOT NULL CHECK (channel IN ('push','sms','email','in_app')),
        provider varchar(40),
        provider_message_id varchar(255),
        destination_masked varchar(255),
        status varchar(30) NOT NULL DEFAULT 'pending'
          CHECK (status IN ('pending','sent','delivered','failed','skipped')),
        attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
        last_error text,
        sent_at timestamptz,
        delivered_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX idx_notifications_user_unread
        ON notifications (user_id, created_at DESC)
        WHERE read_at IS NULL;

      CREATE INDEX idx_notification_deliveries_status
        ON notification_deliveries (status, created_at);

      CREATE TRIGGER trg_device_tokens_updated_at
      BEFORE UPDATE ON device_tokens FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_notification_preferences_updated_at
      BEFORE UPDATE ON notification_preferences FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
DROP TABLE IF EXISTS notification_deliveries;
      DROP TABLE IF EXISTS notifications;
      DROP TABLE IF EXISTS notification_preferences;
      DROP TABLE IF EXISTS device_tokens;
    `);
  }
}
