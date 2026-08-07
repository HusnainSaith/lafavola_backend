import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateCustomerProfilesAddressesAndPreferences1700000000003 implements MigrationInterface {
  name = 'CreateCustomerProfilesAddressesAndPreferences1700000000003';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
CREATE TABLE customer_profiles (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id uuid NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
        avatar_url text,
        date_of_birth date,
        preferred_language varchar(10) NOT NULL DEFAULT 'it',
        loyalty_opt_in boolean NOT NULL DEFAULT false,
        marketing_opt_in boolean NOT NULL DEFAULT false,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE customer_addresses (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        customer_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        label varchar(80),
        recipient_name varchar(160),
        phone varchar(32),
        address_line1 varchar(255) NOT NULL,
        address_line2 varchar(255),
        city varchar(120) NOT NULL,
        province varchar(120),
        postal_code varchar(24) NOT NULL,
        country_code char(2) NOT NULL DEFAULT 'IT',
        latitude numeric(9,6),
        longitude numeric(9,6),
        delivery_instructions text,
        is_default boolean NOT NULL DEFAULT false,
        is_active boolean NOT NULL DEFAULT true,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE UNIQUE INDEX uq_customer_default_address
        ON customer_addresses (customer_id)
        WHERE is_default = true AND is_active = true;

      CREATE TABLE customer_preferences (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        customer_id uuid NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
        vegetarian_preference boolean NOT NULL DEFAULT false,
        vegan_preference boolean NOT NULL DEFAULT false,
        gluten_free_preference boolean NOT NULL DEFAULT false,
        spicy_preference boolean NOT NULL DEFAULT false,
        default_payment_method_id uuid,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE privacy_consents (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        consent_type varchar(60) NOT NULL,
        policy_version varchar(40) NOT NULL,
        granted boolean NOT NULL,
        granted_at timestamptz,
        withdrawn_at timestamptz,
        ip_address inet,
        user_agent text,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE privacy_requests (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        request_type varchar(30) NOT NULL CHECK (request_type IN ('export','rectification','deletion','restriction')),
        status varchar(30) NOT NULL DEFAULT 'pending'
          CHECK (status IN ('pending','processing','completed','rejected')),
        requested_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        completed_at timestamptz,
        notes text
      );

      CREATE INDEX idx_customer_addresses_customer
        ON customer_addresses (customer_id, is_active);

      CREATE INDEX idx_privacy_requests_user_status
        ON privacy_requests (user_id, status);

      CREATE TRIGGER trg_customer_profiles_updated_at
      BEFORE UPDATE ON customer_profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_customer_addresses_updated_at
      BEFORE UPDATE ON customer_addresses FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_customer_preferences_updated_at
      BEFORE UPDATE ON customer_preferences FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
DROP TABLE IF EXISTS privacy_requests;
      DROP TABLE IF EXISTS privacy_consents;
      DROP TABLE IF EXISTS customer_preferences;
      DROP TABLE IF EXISTS customer_addresses;
      DROP TABLE IF EXISTS customer_profiles;
    `);
  }
}
