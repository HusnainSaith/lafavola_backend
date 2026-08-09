import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateDeliveryAndLiveTracking1700000000010 implements MigrationInterface {
  name = 'CreateDeliveryAndLiveTracking1700000000010';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
CREATE TABLE delivery_assignments (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        order_id uuid NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
        driver_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
        assigned_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
        status varchar(30) NOT NULL DEFAULT 'assigned'
          CHECK (status IN ('assigned','accepted','picked_up','en_route','arriving','delivered','failed','cancelled')),
        assigned_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        accepted_at timestamptz,
        picked_up_at timestamptz,
        completed_at timestamptz,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE delivery_tracking (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        order_id uuid NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
        assignment_id uuid REFERENCES delivery_assignments(id) ON DELETE SET NULL,
        status varchar(30) NOT NULL DEFAULT 'assigned'
          CHECK (status IN ('assigned','preparing','cooking','packing','driver_assigned','en_route','arriving','delivered','failed')),
        current_latitude numeric(9,6),
        current_longitude numeric(9,6),
        heading_degrees numeric(6,2),
        speed_kph numeric(7,2),
        remaining_minutes integer CHECK (remaining_minutes IS NULL OR remaining_minutes >= 0),
        estimated_arrival_at timestamptz,
        last_pinged_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE delivery_tracking_events (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        tracking_id uuid NOT NULL REFERENCES delivery_tracking(id) ON DELETE CASCADE,
        status varchar(30),
        latitude numeric(9,6),
        longitude numeric(9,6),
        remaining_minutes integer CHECK (remaining_minutes IS NULL OR remaining_minutes >= 0),
        source varchar(30) NOT NULL DEFAULT 'system'
          CHECK (source IN ('system','driver','staff')),
        occurred_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX idx_delivery_assignments_driver_status
        ON delivery_assignments (driver_user_id, status);

      CREATE INDEX idx_delivery_tracking_events_tracking
        ON delivery_tracking_events (tracking_id, occurred_at);

      CREATE TRIGGER trg_delivery_assignments_updated_at
      BEFORE UPDATE ON delivery_assignments FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_delivery_tracking_updated_at
      BEFORE UPDATE ON delivery_tracking FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
DROP TABLE IF EXISTS delivery_tracking_events;
      DROP TABLE IF EXISTS delivery_tracking;
      DROP TABLE IF EXISTS delivery_assignments;
    `);
  }
}
