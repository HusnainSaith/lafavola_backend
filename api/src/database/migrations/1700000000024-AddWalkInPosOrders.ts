import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddWalkInPosOrders1700000000024 implements MigrationInterface {
  name = 'AddWalkInPosOrders1700000000024';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_order_type_check;
      ALTER TABLE orders
        ADD CONSTRAINT orders_order_type_check
        CHECK (order_type IN ('delivery','pickup','dine_in','takeaway'));

      ALTER TABLE orders
        ADD COLUMN table_label varchar(40),
        ADD COLUMN walk_in_customer_name varchar(120),
        ADD COLUMN walk_in_customer_phone varchar(32),
        ADD COLUMN created_by_staff_user_id uuid REFERENCES users(id) ON DELETE SET NULL;

      ALTER TABLE restaurants
        ADD COLUMN vat_number varchar(32),
        ADD COLUMN fiscal_code varchar(32);

      ALTER TABLE orders
        ADD CONSTRAINT chk_walk_in_table_label
        CHECK (
          (order_type = 'dine_in' AND NULLIF(BTRIM(table_label), '') IS NOT NULL)
          OR (order_type <> 'dine_in' AND table_label IS NULL)
        );

      CREATE INDEX idx_orders_walk_in_queue
        ON orders (restaurant_id, order_type, created_at DESC)
        WHERE order_type IN ('dine_in','takeaway');
      CREATE INDEX idx_orders_created_by_staff
        ON orders (created_by_staff_user_id, created_at DESC)
        WHERE created_by_staff_user_id IS NOT NULL;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DROP INDEX IF EXISTS idx_orders_created_by_staff;
      DROP INDEX IF EXISTS idx_orders_walk_in_queue;
      ALTER TABLE orders DROP CONSTRAINT IF EXISTS chk_walk_in_table_label;
      ALTER TABLE restaurants
        DROP COLUMN IF EXISTS fiscal_code,
        DROP COLUMN IF EXISTS vat_number;
      ALTER TABLE orders
        DROP COLUMN IF EXISTS created_by_staff_user_id,
        DROP COLUMN IF EXISTS walk_in_customer_phone,
        DROP COLUMN IF EXISTS walk_in_customer_name,
        DROP COLUMN IF EXISTS table_label;
      ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_order_type_check;
      ALTER TABLE orders
        ADD CONSTRAINT orders_order_type_check
        CHECK (order_type IN ('delivery','pickup'));
    `);
  }
}
