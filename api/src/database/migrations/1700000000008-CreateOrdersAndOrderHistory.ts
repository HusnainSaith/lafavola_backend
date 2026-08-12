import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateOrdersAndOrderHistory1700000000008 implements MigrationInterface {
  name = 'CreateOrdersAndOrderHistory1700000000008';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
CREATE SEQUENCE order_number_seq START WITH 1000 INCREMENT BY 1;

      CREATE TABLE orders (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        order_number varchar(40) NOT NULL UNIQUE
          DEFAULT ('LF-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(nextval('order_number_seq')::text, 6, '0')),
        restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE RESTRICT,
        customer_id uuid REFERENCES users(id) ON DELETE SET NULL,
        cart_id uuid REFERENCES carts(id) ON DELETE SET NULL,
        order_type varchar(20) NOT NULL DEFAULT 'delivery'
          CHECK (order_type IN ('delivery','pickup')),
        status varchar(40) NOT NULL DEFAULT 'pending_payment'
          CHECK (status IN (
            'pending_payment','placed','accepted','preparing','baking','packing',
            'ready','driver_assigned','out_for_delivery','delivered','closed',
            'cancelled','rejected'
          )),
        payment_status varchar(40) NOT NULL DEFAULT 'pending'
          CHECK (payment_status IN (
            'pending','authorized','paid','collection_pending','partially_refunded',
            'refunded','failed','cancelled'
          )),
        payment_method varchar(40)
          CHECK (payment_method IS NULL OR payment_method IN (
            'card','apple_pay','google_pay','satispay','cash','card_on_delivery','other_wallet'
          )),
        currency char(3) NOT NULL DEFAULT 'EUR' CHECK (currency = 'EUR'),
        subtotal_minor integer NOT NULL CHECK (subtotal_minor >= 0),
        option_charges_minor integer NOT NULL DEFAULT 0 CHECK (option_charges_minor >= 0),
        discount_minor integer NOT NULL DEFAULT 0 CHECK (discount_minor >= 0),
        loyalty_discount_minor integer NOT NULL DEFAULT 0 CHECK (loyalty_discount_minor >= 0),
        delivery_fee_minor integer NOT NULL DEFAULT 0 CHECK (delivery_fee_minor >= 0),
        tax_minor integer NOT NULL DEFAULT 0 CHECK (tax_minor >= 0),
        grand_total_minor integer NOT NULL CHECK (grand_total_minor >= 0),
        delivery_address_snapshot jsonb,
        delivery_instructions text,
        customer_note text,
        estimated_ready_at timestamptz,
        estimated_delivery_at timestamptz,
        scheduled_for timestamptz,
        placed_at timestamptz,
        accepted_at timestamptz,
        delivered_at timestamptz,
        cancelled_at timestamptz,
        cancellation_reason text,
        pricing_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
        version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE order_items (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
        menu_item_id uuid REFERENCES menu_items(id) ON DELETE SET NULL,
        menu_item_size_id uuid REFERENCES menu_item_sizes(id) ON DELETE SET NULL,
        item_name_snapshot varchar(180) NOT NULL,
        size_name_snapshot varchar(80),
        quantity integer NOT NULL CHECK (quantity > 0),
        base_unit_price_minor integer NOT NULL CHECK (base_unit_price_minor >= 0),
        options_unit_price_minor integer NOT NULL DEFAULT 0,
        unit_price_minor integer NOT NULL CHECK (unit_price_minor >= 0),
        line_total_minor integer NOT NULL CHECK (line_total_minor >= 0),
        special_instructions text,
        configuration_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE order_item_options (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        order_item_id uuid NOT NULL REFERENCES order_items(id) ON DELETE CASCADE,
        option_group_id uuid REFERENCES option_groups(id) ON DELETE SET NULL,
        option_choice_id uuid REFERENCES option_choices(id) ON DELETE SET NULL,
        ingredient_id uuid REFERENCES ingredients(id) ON DELETE SET NULL,
        action varchar(20) NOT NULL DEFAULT 'add' CHECK (action IN ('add','remove','replace')),
        option_name_snapshot varchar(140) NOT NULL,
        quantity numeric(8,2) NOT NULL DEFAULT 1 CHECK (quantity > 0),
        unit_price_adjustment_minor integer NOT NULL DEFAULT 0,
        total_price_adjustment_minor integer NOT NULL DEFAULT 0,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE order_status_history (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
        previous_status varchar(40),
        new_status varchar(40) NOT NULL,
        changed_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
        note text,
        occurred_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      ALTER TABLE coupon_redemptions
        ADD CONSTRAINT fk_coupon_redemptions_order
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL;

      ALTER TABLE promotion_redemptions
        ADD CONSTRAINT fk_promotion_redemptions_order
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL;

      CREATE INDEX idx_orders_customer_history
        ON orders (customer_id, created_at DESC);

      CREATE INDEX idx_orders_restaurant_status
        ON orders (restaurant_id, status, created_at DESC);

      CREATE INDEX idx_orders_delivery_queue
        ON orders (restaurant_id, status, estimated_delivery_at)
        WHERE status NOT IN ('delivered','closed','cancelled','rejected');

      CREATE INDEX idx_order_status_history_order
        ON order_status_history (order_id, occurred_at);

      CREATE TRIGGER trg_orders_updated_at
      BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
ALTER TABLE promotion_redemptions DROP CONSTRAINT IF EXISTS fk_promotion_redemptions_order;
      ALTER TABLE coupon_redemptions DROP CONSTRAINT IF EXISTS fk_coupon_redemptions_order;
      DROP TABLE IF EXISTS order_status_history;
      DROP TABLE IF EXISTS order_item_options;
      DROP TABLE IF EXISTS order_items;
      DROP TABLE IF EXISTS orders;
      DROP SEQUENCE IF EXISTS order_number_seq;
    `);
  }
}
