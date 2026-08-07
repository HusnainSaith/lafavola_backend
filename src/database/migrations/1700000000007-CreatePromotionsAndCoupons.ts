import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreatePromotionsAndCoupons1700000000007 implements MigrationInterface {
  name = 'CreatePromotionsAndCoupons1700000000007';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
CREATE TABLE promotions (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
        name varchar(180) NOT NULL,
        description text,
        promotion_type varchar(40) NOT NULL
          CHECK (promotion_type IN ('percentage','fixed_amount','free_delivery','bogo','free_item','bundle','student','custom')),
        discount_value integer NOT NULL DEFAULT 0 CHECK (discount_value >= 0),
        min_order_minor integer NOT NULL DEFAULT 0 CHECK (min_order_minor >= 0),
        max_discount_minor integer CHECK (max_discount_minor IS NULL OR max_discount_minor >= 0),
        starts_at timestamptz NOT NULL,
        ends_at timestamptz,
        days_of_week smallint[] NOT NULL DEFAULT ARRAY[]::smallint[],
        total_usage_limit integer CHECK (total_usage_limit IS NULL OR total_usage_limit > 0),
        per_customer_limit integer CHECK (per_customer_limit IS NULL OR per_customer_limit > 0),
        priority integer NOT NULL DEFAULT 0,
        stacking_group varchar(80),
        is_automatic boolean NOT NULL DEFAULT true,
        is_active boolean NOT NULL DEFAULT true,
        conditions jsonb NOT NULL DEFAULT '{}'::jsonb,
        actions jsonb NOT NULL DEFAULT '{}'::jsonb,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT chk_promotion_dates CHECK (ends_at IS NULL OR ends_at > starts_at)
      );

      CREATE TABLE promotion_items (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        promotion_id uuid NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
        menu_item_id uuid REFERENCES menu_items(id) ON DELETE CASCADE,
        category_id uuid REFERENCES menu_categories(id) ON DELETE CASCADE,
        eligibility_type varchar(20) NOT NULL DEFAULT 'eligible'
          CHECK (eligibility_type IN ('eligible','reward','excluded')),
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT chk_promotion_item_target CHECK (
          (menu_item_id IS NOT NULL AND category_id IS NULL)
          OR (menu_item_id IS NULL AND category_id IS NOT NULL)
        )
      );

      CREATE TABLE coupons (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
        promotion_id uuid REFERENCES promotions(id) ON DELETE SET NULL,
        code varchar(80) NOT NULL,
        description text,
        discount_type varchar(30) NOT NULL
          CHECK (discount_type IN ('percentage','fixed_amount','free_delivery')),
        discount_value integer NOT NULL DEFAULT 0 CHECK (discount_value >= 0),
        min_order_minor integer NOT NULL DEFAULT 0 CHECK (min_order_minor >= 0),
        max_discount_minor integer CHECK (max_discount_minor IS NULL OR max_discount_minor >= 0),
        starts_at timestamptz,
        expires_at timestamptz,
        total_usage_limit integer CHECK (total_usage_limit IS NULL OR total_usage_limit > 0),
        per_customer_limit integer CHECK (per_customer_limit IS NULL OR per_customer_limit > 0),
        is_active boolean NOT NULL DEFAULT true,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_coupon_code UNIQUE (restaurant_id, code),
        CONSTRAINT chk_coupon_dates CHECK (
          expires_at IS NULL OR starts_at IS NULL OR expires_at > starts_at
        )
      );

      CREATE TABLE coupon_redemptions (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        coupon_id uuid NOT NULL REFERENCES coupons(id) ON DELETE RESTRICT,
        customer_id uuid REFERENCES users(id) ON DELETE SET NULL,
        order_id uuid,
        discount_minor integer NOT NULL DEFAULT 0 CHECK (discount_minor >= 0),
        redeemed_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE promotion_redemptions (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        promotion_id uuid NOT NULL REFERENCES promotions(id) ON DELETE RESTRICT,
        customer_id uuid REFERENCES users(id) ON DELETE SET NULL,
        order_id uuid,
        discount_minor integer NOT NULL DEFAULT 0 CHECK (discount_minor >= 0),
        redeemed_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX idx_promotions_active_window
        ON promotions (restaurant_id, is_active, starts_at, ends_at);

      CREATE INDEX idx_coupons_active_code
        ON coupons (restaurant_id, is_active, code);

      CREATE INDEX idx_coupon_redemptions_customer
        ON coupon_redemptions (coupon_id, customer_id);

      CREATE INDEX idx_promotion_redemptions_customer
        ON promotion_redemptions (promotion_id, customer_id);

      CREATE TRIGGER trg_promotions_updated_at
      BEFORE UPDATE ON promotions FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_coupons_updated_at
      BEFORE UPDATE ON coupons FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
DROP TABLE IF EXISTS promotion_redemptions;
      DROP TABLE IF EXISTS coupon_redemptions;
      DROP TABLE IF EXISTS coupons;
      DROP TABLE IF EXISTS promotion_items;
      DROP TABLE IF EXISTS promotions;
    `);
  }
}
