import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateRestaurantStaffAndMedia1700000000004 implements MigrationInterface {
  name = 'CreateRestaurantStaffAndMedia1700000000004';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
CREATE TABLE restaurants (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        name varchar(160) NOT NULL,
        slug varchar(180) NOT NULL UNIQUE,
        phone varchar(32),
        email varchar(320),
        address_line1 varchar(255),
        address_line2 varchar(255),
        city varchar(120),
        province varchar(120),
        postal_code varchar(24),
        country_code char(2) NOT NULL DEFAULT 'IT',
        currency char(3) NOT NULL DEFAULT 'EUR' CHECK (currency = 'EUR'),
        timezone varchar(80) NOT NULL DEFAULT 'Europe/Rome',
        default_delivery_minutes integer NOT NULL DEFAULT 30 CHECK (default_delivery_minutes > 0),
        delivery_fee_minor integer NOT NULL DEFAULT 0 CHECK (delivery_fee_minor >= 0),
        minimum_order_minor integer NOT NULL DEFAULT 0 CHECK (minimum_order_minor >= 0),
        tax_rate_basis_points integer NOT NULL DEFAULT 0 CHECK (tax_rate_basis_points BETWEEN 0 AND 10000),
        tax_behavior varchar(20) NOT NULL DEFAULT 'included'
          CHECK (tax_behavior IN ('included','excluded','not_applicable')),
        is_active boolean NOT NULL DEFAULT true,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE business_hours (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
        day_of_week smallint NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
        opens_at time,
        closes_at time,
        is_closed boolean NOT NULL DEFAULT false,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_business_hours_restaurant_day UNIQUE (restaurant_id, day_of_week),
        CONSTRAINT chk_business_hours_times CHECK (
          is_closed = true OR (opens_at IS NOT NULL AND closes_at IS NOT NULL)
        )
      );

      CREATE TABLE staff_members (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id uuid NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
        restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE RESTRICT,
        employee_code varchar(80),
        job_title varchar(120),
        is_active boolean NOT NULL DEFAULT true,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_staff_employee_code UNIQUE (restaurant_id, employee_code)
      );

      CREATE TABLE media_assets (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        restaurant_id uuid REFERENCES restaurants(id) ON DELETE CASCADE,
        uploaded_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
        storage_provider varchar(30) NOT NULL DEFAULT 'aws_s3' CHECK (storage_provider = 'aws_s3'),
        bucket varchar(255) NOT NULL,
        object_key varchar(1024) NOT NULL UNIQUE,
        public_url text,
        mime_type varchar(120) NOT NULL,
        size_bytes bigint CHECK (size_bytes IS NULL OR size_bytes >= 0),
        width integer,
        height integer,
        alt_text varchar(255),
        status varchar(30) NOT NULL DEFAULT 'active'
          CHECK (status IN ('pending','active','archived','failed')),
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TRIGGER trg_restaurants_updated_at
      BEFORE UPDATE ON restaurants FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_business_hours_updated_at
      BEFORE UPDATE ON business_hours FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_staff_members_updated_at
      BEFORE UPDATE ON staff_members FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_media_assets_updated_at
      BEFORE UPDATE ON media_assets FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
DROP TABLE IF EXISTS media_assets;
      DROP TABLE IF EXISTS staff_members;
      DROP TABLE IF EXISTS business_hours;
      DROP TABLE IF EXISTS restaurants;
    `);
  }
}
