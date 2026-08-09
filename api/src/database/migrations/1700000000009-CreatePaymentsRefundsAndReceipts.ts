import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreatePaymentsRefundsAndReceipts1700000000009 implements MigrationInterface {
  name = 'CreatePaymentsRefundsAndReceipts1700000000009';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
CREATE TABLE customer_payment_methods (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        customer_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        provider varchar(30) NOT NULL DEFAULT 'stripe'
          CHECK (provider IN ('stripe','external')),
        provider_customer_id varchar(255),
        provider_payment_method_id varchar(255),
        payment_method_type varchar(40) NOT NULL
          CHECK (payment_method_type IN ('card','apple_pay','google_pay','satispay','other_wallet')),
        card_brand varchar(40),
        card_last4 char(4),
        exp_month smallint CHECK (exp_month IS NULL OR exp_month BETWEEN 1 AND 12),
        exp_year smallint,
        label varchar(80),
        is_default boolean NOT NULL DEFAULT false,
        archived_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_customer_provider_method UNIQUE (customer_id, provider, provider_payment_method_id)
      );

      CREATE UNIQUE INDEX uq_customer_default_payment_method
        ON customer_payment_methods (customer_id)
        WHERE is_default = true AND archived_at IS NULL;

      ALTER TABLE customer_preferences
        ADD CONSTRAINT fk_customer_preferences_default_payment
        FOREIGN KEY (default_payment_method_id)
        REFERENCES customer_payment_methods(id)
        ON DELETE SET NULL;

      CREATE TABLE payment_transactions (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        order_id uuid NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
        customer_id uuid REFERENCES users(id) ON DELETE SET NULL,
        payment_method_id uuid REFERENCES customer_payment_methods(id) ON DELETE SET NULL,
        provider varchar(40) NOT NULL
          CHECK (provider IN ('stripe','cash','external_terminal')),
        payment_method_type varchar(40) NOT NULL
          CHECK (payment_method_type IN (
            'card','apple_pay','google_pay','satispay','cash','card_on_delivery','other_wallet'
          )),
        provider_payment_intent_id varchar(255),
        provider_charge_id varchar(255),
        amount_minor integer NOT NULL CHECK (amount_minor >= 0),
        currency char(3) NOT NULL DEFAULT 'EUR' CHECK (currency = 'EUR'),
        status varchar(40) NOT NULL DEFAULT 'pending'
          CHECK (status IN (
            'pending','requires_action','authorized','captured','failed',
            'collection_pending','cancelled','partially_refunded','refunded'
          )),
        idempotency_key varchar(255),
        failure_code varchar(120),
        failure_message text,
        authorized_at timestamptz,
        captured_at timestamptz,
        failed_at timestamptz,
        metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE UNIQUE INDEX uq_payment_transaction_idempotency
        ON payment_transactions (order_id, idempotency_key)
        WHERE idempotency_key IS NOT NULL;

      CREATE UNIQUE INDEX uq_payment_provider_intent
        ON payment_transactions (provider, provider_payment_intent_id)
        WHERE provider_payment_intent_id IS NOT NULL;

      CREATE TABLE payment_webhook_events (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        provider varchar(30) NOT NULL DEFAULT 'stripe',
        provider_event_id varchar(255) NOT NULL,
        event_type varchar(160) NOT NULL,
        payload jsonb NOT NULL,
        processing_status varchar(30) NOT NULL DEFAULT 'pending'
          CHECK (processing_status IN ('pending','processed','ignored','failed')),
        attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
        processed_at timestamptz,
        last_error text,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_payment_webhook_provider_event UNIQUE (provider, provider_event_id)
      );

      CREATE TABLE refunds (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        order_id uuid NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
        payment_transaction_id uuid REFERENCES payment_transactions(id) ON DELETE SET NULL,
        requested_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
        provider_refund_id varchar(255),
        amount_minor integer NOT NULL CHECK (amount_minor > 0),
        reason varchar(80) NOT NULL,
        customer_reason text,
        status varchar(30) NOT NULL DEFAULT 'requested'
          CHECK (status IN ('requested','approved','processing','refunded','rejected','failed','cancelled')),
        staff_note text,
        requested_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        processed_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE payment_receipts (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
        payment_transaction_id uuid REFERENCES payment_transactions(id) ON DELETE SET NULL,
        receipt_number varchar(80) NOT NULL UNIQUE,
        issued_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        amount_minor integer NOT NULL CHECK (amount_minor >= 0),
        tax_minor integer NOT NULL DEFAULT 0 CHECK (tax_minor >= 0),
        currency char(3) NOT NULL DEFAULT 'EUR' CHECK (currency = 'EUR'),
        provider_receipt_url text,
        receipt_data jsonb NOT NULL DEFAULT '{}'::jsonb,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX idx_payment_transactions_order
        ON payment_transactions (order_id, created_at);

      CREATE INDEX idx_refunds_order
        ON refunds (order_id, created_at);

      CREATE TRIGGER trg_customer_payment_methods_updated_at
      BEFORE UPDATE ON customer_payment_methods FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_payment_transactions_updated_at
      BEFORE UPDATE ON payment_transactions FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_refunds_updated_at
      BEFORE UPDATE ON refunds FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
DROP TABLE IF EXISTS payment_receipts;
      DROP TABLE IF EXISTS refunds;
      DROP TABLE IF EXISTS payment_webhook_events;
      DROP TABLE IF EXISTS payment_transactions;
      ALTER TABLE customer_preferences DROP CONSTRAINT IF EXISTS fk_customer_preferences_default_payment;
      DROP TABLE IF EXISTS customer_payment_methods;
    `);
  }
}
