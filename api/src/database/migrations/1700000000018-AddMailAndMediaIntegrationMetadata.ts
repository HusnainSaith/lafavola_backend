import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddMailAndMediaIntegrationMetadata1700000000018 implements MigrationInterface {
  name = 'AddMailAndMediaIntegrationMetadata1700000000018';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE media_assets
        ADD COLUMN original_file_name varchar(255),
        ADD COLUMN purpose varchar(40) NOT NULL DEFAULT 'legacy',
        ADD COLUMN target_id uuid;
      CREATE INDEX idx_media_assets_owner_status
        ON media_assets (uploaded_by_user_id, status, created_at DESC);
      CREATE INDEX idx_media_assets_purpose_target
        ON media_assets (purpose, target_id);
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DROP INDEX IF EXISTS idx_media_assets_purpose_target;
      DROP INDEX IF EXISTS idx_media_assets_owner_status;
      ALTER TABLE media_assets
        DROP COLUMN IF EXISTS target_id,
        DROP COLUMN IF EXISTS purpose,
        DROP COLUMN IF EXISTS original_file_name;
    `);
  }
}
