import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddFinalIntegrityRulesAndIndexes1700000000016 implements MigrationInterface {
  name = 'AddFinalIntegrityRulesAndIndexes1700000000016';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
CREATE INDEX idx_menu_items_newest
        ON menu_items (restaurant_id, created_at DESC)
        WHERE is_active = true AND archived_at IS NULL;

      CREATE INDEX idx_menu_item_sizes_price
        ON menu_item_sizes (base_price_minor)
        WHERE is_active = true;

      CREATE INDEX idx_orders_payment_status
        ON orders (restaurant_id, payment_status, created_at DESC);

      CREATE INDEX idx_orders_scheduled
        ON orders (restaurant_id, scheduled_for)
        WHERE scheduled_for IS NOT NULL
          AND status NOT IN ('cancelled','rejected','closed');

      CREATE INDEX idx_payment_webhook_processing
        ON payment_webhook_events (processing_status, created_at)
        WHERE processing_status IN ('pending','failed');

      CREATE INDEX idx_refunds_status
        ON refunds (status, created_at);

      CREATE INDEX idx_coupon_expiration_notifications
        ON coupons (expires_at)
        WHERE is_active = true AND expires_at IS NOT NULL;

      CREATE INDEX idx_promotions_homepage
        ON promotions (restaurant_id, priority DESC, starts_at DESC)
        WHERE is_active = true;

      ALTER TABLE orders
        ADD CONSTRAINT chk_order_delivery_address
        CHECK (
          order_type <> 'delivery'
          OR delivery_address_snapshot IS NOT NULL
        );

      ALTER TABLE orders
        ADD CONSTRAINT chk_order_grand_total_consistency
        CHECK (
          grand_total_minor =
            GREATEST(
              0,
              subtotal_minor
              + option_charges_minor
              + delivery_fee_minor
              + tax_minor
              - discount_minor
              - loyalty_discount_minor
            )
        );

      ALTER TABLE payment_transactions
        ADD CONSTRAINT chk_cash_has_no_provider_intent
        CHECK (
          provider <> 'cash'
          OR provider_payment_intent_id IS NULL
        );

      ALTER TABLE delivery_tracking
        ADD CONSTRAINT chk_tracking_coordinates_pair
        CHECK (
          (current_latitude IS NULL AND current_longitude IS NULL)
          OR
          (current_latitude IS NOT NULL AND current_longitude IS NOT NULL)
        );
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
ALTER TABLE delivery_tracking DROP CONSTRAINT IF EXISTS chk_tracking_coordinates_pair;
      ALTER TABLE payment_transactions DROP CONSTRAINT IF EXISTS chk_cash_has_no_provider_intent;
      ALTER TABLE orders DROP CONSTRAINT IF EXISTS chk_order_grand_total_consistency;
      ALTER TABLE orders DROP CONSTRAINT IF EXISTS chk_order_delivery_address;

      DROP INDEX IF EXISTS idx_promotions_homepage;
      DROP INDEX IF EXISTS idx_coupon_expiration_notifications;
      DROP INDEX IF EXISTS idx_refunds_status;
      DROP INDEX IF EXISTS idx_payment_webhook_processing;
      DROP INDEX IF EXISTS idx_orders_scheduled;
      DROP INDEX IF EXISTS idx_orders_payment_status;
      DROP INDEX IF EXISTS idx_menu_item_sizes_price;
      DROP INDEX IF EXISTS idx_menu_items_newest;
    `);
  }
}
