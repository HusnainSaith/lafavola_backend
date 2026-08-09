import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateReportingAndAnalytics1700000000015 implements MigrationInterface {
  name = 'CreateReportingAndAnalytics1700000000015';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
CREATE TABLE daily_sales_metrics (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
        metric_date date NOT NULL,
        total_orders integer NOT NULL DEFAULT 0 CHECK (total_orders >= 0),
        delivered_orders integer NOT NULL DEFAULT 0 CHECK (delivered_orders >= 0),
        cancelled_orders integer NOT NULL DEFAULT 0 CHECK (cancelled_orders >= 0),
        gross_revenue_minor bigint NOT NULL DEFAULT 0 CHECK (gross_revenue_minor >= 0),
        discounts_minor bigint NOT NULL DEFAULT 0 CHECK (discounts_minor >= 0),
        refunds_minor bigint NOT NULL DEFAULT 0 CHECK (refunds_minor >= 0),
        delivery_fees_minor bigint NOT NULL DEFAULT 0 CHECK (delivery_fees_minor >= 0),
        tax_minor bigint NOT NULL DEFAULT 0 CHECK (tax_minor >= 0),
        net_revenue_minor bigint NOT NULL DEFAULT 0,
        average_order_value_minor integer NOT NULL DEFAULT 0 CHECK (average_order_value_minor >= 0),
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_daily_sales_metric UNIQUE (restaurant_id, metric_date)
      );

      CREATE TABLE item_sales_metrics (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
        menu_item_id uuid REFERENCES menu_items(id) ON DELETE SET NULL,
        metric_date date NOT NULL,
        item_name_snapshot varchar(180) NOT NULL,
        quantity_sold integer NOT NULL DEFAULT 0 CHECK (quantity_sold >= 0),
        revenue_minor bigint NOT NULL DEFAULT 0 CHECK (revenue_minor >= 0),
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_item_sales_metric UNIQUE (restaurant_id, menu_item_id, metric_date)
      );

      CREATE INDEX idx_daily_sales_metrics_range
        ON daily_sales_metrics (restaurant_id, metric_date DESC);

      CREATE INDEX idx_item_sales_metrics_popular
        ON item_sales_metrics (restaurant_id, metric_date DESC, quantity_sold DESC);

      CREATE VIEW current_popular_menu_items AS
      SELECT
        mis.restaurant_id,
        mis.menu_item_id,
        MAX(mis.item_name_snapshot) AS item_name,
        SUM(mis.quantity_sold) AS quantity_sold,
        SUM(mis.revenue_minor) AS revenue_minor
      FROM item_sales_metrics mis
      WHERE mis.metric_date >= CURRENT_DATE - INTERVAL '30 days'
      GROUP BY mis.restaurant_id, mis.menu_item_id;

      CREATE TRIGGER trg_daily_sales_metrics_updated_at
      BEFORE UPDATE ON daily_sales_metrics FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_item_sales_metrics_updated_at
      BEFORE UPDATE ON item_sales_metrics FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
DROP VIEW IF EXISTS current_popular_menu_items;
      DROP TABLE IF EXISTS item_sales_metrics;
      DROP TABLE IF EXISTS daily_sales_metrics;
    `);
  }
}
