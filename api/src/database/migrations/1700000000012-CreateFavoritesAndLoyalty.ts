import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateFavoritesAndLoyalty1700000000012 implements MigrationInterface {
  name = 'CreateFavoritesAndLoyalty1700000000012';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
CREATE TABLE favorites (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        customer_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
        menu_item_id uuid REFERENCES menu_items(id) ON DELETE CASCADE,
        source_order_item_id uuid REFERENCES order_items(id) ON DELETE SET NULL,
        label varchar(120),
        configuration_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX idx_favorites_customer
        ON favorites (customer_id, created_at DESC);

      CREATE TABLE loyalty_accounts (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        customer_id uuid NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
        points_balance integer NOT NULL DEFAULT 0 CHECK (points_balance >= 0),
        lifetime_points_earned integer NOT NULL DEFAULT 0 CHECK (lifetime_points_earned >= 0),
        tier varchar(40) NOT NULL DEFAULT 'standard',
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE loyalty_transactions (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        loyalty_account_id uuid NOT NULL REFERENCES loyalty_accounts(id) ON DELETE CASCADE,
        order_id uuid REFERENCES orders(id) ON DELETE SET NULL,
        type varchar(30) NOT NULL
          CHECK (type IN ('earned','bonus','redeemed','expired','adjustment','refund_reversal')),
        points_delta integer NOT NULL CHECK (points_delta <> 0),
        balance_after integer NOT NULL CHECK (balance_after >= 0),
        description varchar(255),
        expires_at timestamptz,
        created_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX idx_loyalty_transactions_account
        ON loyalty_transactions (loyalty_account_id, created_at DESC);

      CREATE INDEX idx_loyalty_transactions_expiry
        ON loyalty_transactions (expires_at)
        WHERE expires_at IS NOT NULL;

      CREATE TRIGGER trg_favorites_updated_at
      BEFORE UPDATE ON favorites FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_loyalty_accounts_updated_at
      BEFORE UPDATE ON loyalty_accounts FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
DROP TABLE IF EXISTS loyalty_transactions;
      DROP TABLE IF EXISTS loyalty_accounts;
      DROP TABLE IF EXISTS favorites;
    `);
  }
}
