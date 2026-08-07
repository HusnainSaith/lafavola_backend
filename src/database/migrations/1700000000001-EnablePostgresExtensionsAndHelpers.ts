import { MigrationInterface, QueryRunner } from 'typeorm';

export class EnablePostgresExtensionsAndHelpers1700000000001 implements MigrationInterface {
  name = 'EnablePostgresExtensionsAndHelpers1700000000001';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
CREATE EXTENSION IF NOT EXISTS pgcrypto;
      CREATE EXTENSION IF NOT EXISTS pg_trgm;

      CREATE OR REPLACE FUNCTION set_updated_at()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
DROP FUNCTION IF EXISTS set_updated_at();
      DROP EXTENSION IF EXISTS pg_trgm;
      -- pgcrypto may be shared by other schemas/applications, so it is intentionally retained.
    `);
  }
}
