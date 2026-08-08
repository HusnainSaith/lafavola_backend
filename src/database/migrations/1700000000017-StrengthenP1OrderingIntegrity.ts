import { MigrationInterface, QueryRunner } from 'typeorm';

export class StrengthenP1OrderingIntegrity1700000000017 implements MigrationInterface {
  name = 'StrengthenP1OrderingIntegrity1700000000017';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE orders
        ADD COLUMN promotion_discount_minor integer NOT NULL DEFAULT 0
          CHECK (promotion_discount_minor >= 0),
        ADD COLUMN coupon_discount_minor integer NOT NULL DEFAULT 0
          CHECK (coupon_discount_minor >= 0);

      CREATE UNIQUE INDEX uq_coupon_redemption_order
        ON coupon_redemptions (coupon_id, order_id)
        WHERE order_id IS NOT NULL;
      CREATE UNIQUE INDEX uq_promotion_redemption_order
        ON promotion_redemptions (promotion_id, order_id)
        WHERE order_id IS NOT NULL;

      CREATE INDEX idx_menu_items_public_catalog
        ON menu_items (restaurant_id, is_active, category_id, created_at DESC)
        WHERE archived_at IS NULL;
      CREATE INDEX idx_menu_item_sizes_active_price
        ON menu_item_sizes (menu_item_id, is_active, base_price_minor);
      CREATE INDEX idx_orders_customer_created
        ON orders (customer_id, created_at DESC);
      CREATE INDEX idx_promotion_items_item
        ON promotion_items (promotion_id, menu_item_id, eligibility_type);
      CREATE INDEX idx_promotion_items_category
        ON promotion_items (promotion_id, category_id, eligibility_type);
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DROP INDEX IF EXISTS idx_promotion_items_category;
      DROP INDEX IF EXISTS idx_promotion_items_item;
      DROP INDEX IF EXISTS idx_orders_customer_created;
      DROP INDEX IF EXISTS idx_menu_item_sizes_active_price;
      DROP INDEX IF EXISTS idx_menu_items_public_catalog;
      DROP INDEX IF EXISTS uq_promotion_redemption_order;
      DROP INDEX IF EXISTS uq_coupon_redemption_order;
      ALTER TABLE orders
        DROP COLUMN IF EXISTS coupon_discount_minor,
        DROP COLUMN IF EXISTS promotion_discount_minor;
    `);
  }
}
