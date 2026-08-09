import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateIdentityAndAccessControl1700000000002 implements MigrationInterface {
  name = 'CreateIdentityAndAccessControl1700000000002';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
CREATE TABLE roles (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        name varchar(80) NOT NULL UNIQUE,
        description text,
        is_system boolean NOT NULL DEFAULT false,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE permissions (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        name varchar(120) NOT NULL UNIQUE,
        description text,
        resource varchar(100) NOT NULL,
        action varchar(60) NOT NULL,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_permissions_resource_action UNIQUE (resource, action)
      );

      CREATE TABLE users (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        email varchar(320),
        phone varchar(32),
        password varchar(255),
        full_name varchar(160) NOT NULL,
        role_id uuid NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
        status varchar(30) NOT NULL DEFAULT 'active'
          CHECK (status IN ('pending_verification','active','suspended','disabled','deleted')),
        email_verified_at timestamptz,
        phone_verified_at timestamptz,
        last_login_at timestamptz,
        archived_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT chk_users_login_identifier CHECK (email IS NOT NULL OR phone IS NOT NULL)
      );

      CREATE UNIQUE INDEX uq_users_email_ci
        ON users (LOWER(email))
        WHERE email IS NOT NULL AND archived_at IS NULL;

      CREATE UNIQUE INDEX uq_users_phone
        ON users (phone)
        WHERE phone IS NOT NULL AND archived_at IS NULL;

      CREATE TABLE role_permissions (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        role_id uuid NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
        permission_id uuid NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_role_permissions UNIQUE (role_id, permission_id)
      );

      CREATE TABLE user_permissions (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        permission_id uuid NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_user_permissions UNIQUE (user_id, permission_id)
      );

      CREATE TABLE refresh_tokens (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        token varchar(512) NOT NULL UNIQUE,
        user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        expires_at timestamptz NOT NULL,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        is_revoked boolean NOT NULL DEFAULT false,
        revoked_at timestamptz
      );

      CREATE TABLE social_accounts (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        provider varchar(30) NOT NULL CHECK (provider IN ('google','apple')),
        provider_subject varchar(255) NOT NULL,
        provider_email varchar(320),
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_social_account_provider_subject UNIQUE (provider, provider_subject)
      );

      CREATE TABLE verification_tokens (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        type varchar(30) NOT NULL CHECK (type IN ('email_verify','phone_verify','password_reset')),
        token_hash varchar(255) NOT NULL UNIQUE,
        attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
        expires_at timestamptz NOT NULL,
        consumed_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX idx_refresh_tokens_user_active
        ON refresh_tokens (user_id, expires_at)
        WHERE is_revoked = false;

      CREATE INDEX idx_verification_tokens_user_type
        ON verification_tokens (user_id, type, expires_at);

      CREATE TRIGGER trg_roles_updated_at
      BEFORE UPDATE ON roles FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_permissions_updated_at
      BEFORE UPDATE ON permissions FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_users_updated_at
      BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_social_accounts_updated_at
      BEFORE UPDATE ON social_accounts FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
DROP TABLE IF EXISTS verification_tokens;
      DROP TABLE IF EXISTS social_accounts;
      DROP TABLE IF EXISTS refresh_tokens;
      DROP TABLE IF EXISTS user_permissions;
      DROP TABLE IF EXISTS role_permissions;
      DROP TABLE IF EXISTS users;
      DROP TABLE IF EXISTS permissions;
      DROP TABLE IF EXISTS roles;
    `);
  }
}
