import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddEstimatedReadyAt1700000000025 implements MigrationInterface {
  name = 'AddEstimatedReadyAt1700000000025';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE orders
      ADD COLUMN IF NOT EXISTS estimated_ready_at timestamptz
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE orders
      DROP COLUMN IF EXISTS estimated_ready_at
    `);
  }
}
