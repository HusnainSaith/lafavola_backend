import { MigrationInterface, QueryRunner } from 'typeorm';

export class UseActiveSixDigitVerificationCodes1700000000026
  implements MigrationInterface
{
  name = 'UseActiveSixDigitVerificationCodes1700000000026';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE verification_tokens
        DROP CONSTRAINT IF EXISTS verification_tokens_token_hash_key;

      CREATE UNIQUE INDEX IF NOT EXISTS uq_verification_tokens_active_code_hash
        ON verification_tokens (token_hash)
        WHERE consumed_at IS NULL;
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DROP INDEX IF EXISTS uq_verification_tokens_active_code_hash;
      DELETE FROM verification_tokens a
      USING verification_tokens b
      WHERE a.id > b.id AND a.token_hash = b.token_hash;
      ALTER TABLE verification_tokens
        ADD CONSTRAINT verification_tokens_token_hash_key UNIQUE (token_hash);
    `);
  }
}
