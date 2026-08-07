import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateShoppingCart1700000000006 implements MigrationInterface {
  name = 'CreateShoppingCart1700000000006';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
CREATE TABLE carts (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        customer_id uuid REFERENCES users(id) ON DELETE CASCADE,
        restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
        session_key varchar(160),
        status varchar(30) NOT NULL DEFAULT 'active'
          CHECK (status IN ('active','converted','abandoned','expired')),
        currency char(3) NOT NULL DEFAULT 'EUR' CHECK (currency = 'EUR'),
        expires_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT chk_cart_owner CHECK (customer_id IS NOT NULL OR session_key IS NOT NULL)
      );

      CREATE TABLE cart_items (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        cart_id uuid NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
        menu_item_id uuid NOT NULL REFERENCES menu_items(id) ON DELETE RESTRICT,
        menu_item_size_id uuid REFERENCES menu_item_sizes(id) ON DELETE RESTRICT,
        quantity integer NOT NULL CHECK (quantity > 0),
        item_name_snapshot varchar(180) NOT NULL,
        size_name_snapshot varchar(80),
        base_unit_price_minor integer NOT NULL CHECK (base_unit_price_minor >= 0),
        options_unit_price_minor integer NOT NULL DEFAULT 0,
        unit_price_minor integer NOT NULL CHECK (unit_price_minor >= 0),
        line_total_minor integer NOT NULL CHECK (line_total_minor >= 0),
        special_instructions text,
        configuration_hash varchar(128),
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE cart_item_options (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        cart_item_id uuid NOT NULL REFERENCES cart_items(id) ON DELETE CASCADE,
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

      CREATE INDEX idx_carts_customer_status ON carts (customer_id, status);
      CREATE INDEX idx_cart_items_cart ON cart_items (cart_id);

      CREATE TRIGGER trg_carts_updated_at
      BEFORE UPDATE ON carts FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_cart_items_updated_at
      BEFORE UPDATE ON cart_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
DROP TABLE IF EXISTS cart_item_options;
      DROP TABLE IF EXISTS cart_items;
      DROP TABLE IF EXISTS carts;
    `);
  }
}
