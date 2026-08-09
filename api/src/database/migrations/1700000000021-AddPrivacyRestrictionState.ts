import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddPrivacyRestrictionState1700000000021 implements MigrationInterface {
  name = 'AddPrivacyRestrictionState1700000000021';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE users ADD COLUMN processing_restricted_at timestamptz;
      ALTER TABLE users DROP CONSTRAINT chk_users_login_identifier;
      ALTER TABLE users ADD CONSTRAINT chk_users_login_identifier
        CHECK (status='deleted' OR email IS NOT NULL OR phone IS NOT NULL);
      CREATE INDEX idx_users_processing_restricted
        ON users (processing_restricted_at)
        WHERE processing_restricted_at IS NOT NULL;
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DROP INDEX IF EXISTS idx_users_processing_restricted;
      ALTER TABLE users DROP CONSTRAINT chk_users_login_identifier;
      ALTER TABLE users ADD CONSTRAINT chk_users_login_identifier
        CHECK (email IS NOT NULL OR phone IS NOT NULL);
      ALTER TABLE users DROP COLUMN IF EXISTS processing_restricted_at;
    `);
  }
}
