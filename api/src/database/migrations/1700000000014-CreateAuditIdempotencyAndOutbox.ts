import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateAuditIdempotencyAndOutbox1700000000014 implements MigrationInterface {
  name = 'CreateAuditIdempotencyAndOutbox1700000000014';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
CREATE TABLE audit_logs (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        actor_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
        action varchar(120) NOT NULL,
        resource_type varchar(120) NOT NULL,
        resource_id uuid,
        restaurant_id uuid REFERENCES restaurants(id) ON DELETE SET NULL,
        correlation_id varchar(120),
        ip_address inet,
        user_agent text,
        before_data jsonb,
        after_data jsonb,
        metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE idempotency_keys (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        actor_user_id uuid REFERENCES users(id) ON DELETE CASCADE,
        scope varchar(120) NOT NULL,
        key_hash varchar(128) NOT NULL,
        request_hash varchar(128),
        response_status integer,
        response_body jsonb,
        locked_until timestamptz,
        expires_at timestamptz NOT NULL,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_idempotency_actor_scope_key UNIQUE (actor_user_id, scope, key_hash)
      );

      CREATE TABLE outbox_events (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        aggregate_type varchar(120) NOT NULL,
        aggregate_id uuid,
        event_type varchar(160) NOT NULL,
        payload jsonb NOT NULL,
        status varchar(30) NOT NULL DEFAULT 'pending'
          CHECK (status IN ('pending','processing','published','failed','dead_letter')),
        attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
        available_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        claimed_at timestamptz,
        published_at timestamptz,
        last_error text,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX idx_audit_logs_resource
        ON audit_logs (resource_type, resource_id, created_at DESC);

      CREATE INDEX idx_audit_logs_actor
        ON audit_logs (actor_user_id, created_at DESC);

      CREATE INDEX idx_outbox_pending
        ON outbox_events (status, available_at, created_at)
        WHERE status IN ('pending','failed');

      CREATE INDEX idx_idempotency_expiry
        ON idempotency_keys (expires_at);

      CREATE TRIGGER trg_idempotency_keys_updated_at
      BEFORE UPDATE ON idempotency_keys FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
DROP TABLE IF EXISTS outbox_events;
      DROP TABLE IF EXISTS idempotency_keys;
      DROP TABLE IF EXISTS audit_logs;
    `);
  }
}
