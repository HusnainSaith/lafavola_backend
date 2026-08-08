import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddSumUpPaymentIntegrity1700000000019 implements MigrationInterface {
  name = 'AddSumUpPaymentIntegrity1700000000019';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE payment_transactions DROP CONSTRAINT IF EXISTS payment_transactions_provider_check;
      ALTER TABLE payment_transactions ADD CONSTRAINT payment_transactions_provider_check CHECK (provider IN ('stripe','sumup','cash','external_terminal'));
      ALTER TABLE payment_transactions ADD COLUMN provider_checkout_id varchar(255), ADD COLUMN checkout_reference varchar(90), ADD COLUMN provider_transaction_id varchar(255), ADD COLUMN request_hash char(64);
      CREATE UNIQUE INDEX uq_payment_provider_checkout ON payment_transactions (provider, provider_checkout_id) WHERE provider_checkout_id IS NOT NULL;
      CREATE UNIQUE INDEX uq_payment_checkout_reference ON payment_transactions (checkout_reference) WHERE checkout_reference IS NOT NULL;
      CREATE UNIQUE INDEX uq_payment_provider_transaction ON payment_transactions (provider, provider_transaction_id) WHERE provider_transaction_id IS NOT NULL;
      ALTER TABLE refunds ADD COLUMN idempotency_key varchar(255);
      CREATE UNIQUE INDEX uq_refund_transaction_idempotency ON refunds (payment_transaction_id, idempotency_key) WHERE idempotency_key IS NOT NULL;
      CREATE UNIQUE INDEX uq_payment_receipt_transaction ON payment_receipts (payment_transaction_id) WHERE payment_transaction_id IS NOT NULL;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DROP INDEX IF EXISTS uq_payment_receipt_transaction;
      DROP INDEX IF EXISTS uq_refund_transaction_idempotency;
      ALTER TABLE refunds DROP COLUMN IF EXISTS idempotency_key;
      DROP INDEX IF EXISTS uq_payment_provider_transaction;
      DROP INDEX IF EXISTS uq_payment_checkout_reference;
      DROP INDEX IF EXISTS uq_payment_provider_checkout;
      ALTER TABLE payment_transactions DROP COLUMN IF EXISTS request_hash, DROP COLUMN IF EXISTS provider_transaction_id, DROP COLUMN IF EXISTS checkout_reference, DROP COLUMN IF EXISTS provider_checkout_id;
      ALTER TABLE payment_transactions DROP CONSTRAINT IF EXISTS payment_transactions_provider_check;
      ALTER TABLE payment_transactions ADD CONSTRAINT payment_transactions_provider_check CHECK (provider IN ('stripe','cash','external_terminal'));
    `);
  }
}
