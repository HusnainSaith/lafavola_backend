import { MigrationInterface, QueryRunner } from 'typeorm';

export class ExpandNotificationTypes1700000000028 implements MigrationInterface {
  name = 'ExpandNotificationTypes1700000000028';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
      ALTER TABLE notifications ADD CONSTRAINT notifications_type_check CHECK (type IN (
        'order_confirmed','order_accepted','order_preparing','order_baking',
        'order_packing','order_ready','order_out_for_delivery','driver_arriving',
        'order_delivered','order_completed','order_cancelled','order_rejected',
        'new_order_admin','order_cancelled_admin','delivery_assigned',
        'promotion','discount','coupon_expiring','support_reply',
        'support_customer_message','support_ticket_assigned',
        'support_status_changed','system'
      ));
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE notifications SET type='system' WHERE type NOT IN (
        'order_confirmed','order_preparing','order_baking','order_out_for_delivery',
        'driver_arriving','order_delivered','promotion','discount','coupon_expiring',
        'support_reply','system'
      );
      ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
      ALTER TABLE notifications ADD CONSTRAINT notifications_type_check CHECK (type IN (
        'order_confirmed','order_preparing','order_baking','order_out_for_delivery',
        'driver_arriving','order_delivered','promotion','discount','coupon_expiring',
        'support_reply','system'
      ));
    `);
  }
}
