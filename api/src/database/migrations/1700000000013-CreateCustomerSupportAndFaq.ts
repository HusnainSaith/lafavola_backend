import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateCustomerSupportAndFaq1700000000013 implements MigrationInterface {
  name = 'CreateCustomerSupportAndFaq1700000000013';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
CREATE TABLE support_tickets (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        customer_id uuid REFERENCES users(id) ON DELETE SET NULL,
        order_id uuid REFERENCES orders(id) ON DELETE SET NULL,
        assigned_staff_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
        category varchar(30) NOT NULL
          CHECK (category IN ('order_issue','refund_request','payment_issue','delivery_issue','complaint','general')),
        subject varchar(200) NOT NULL,
        status varchar(30) NOT NULL DEFAULT 'open'
          CHECK (status IN ('open','in_progress','waiting_customer','resolved','closed')),
        priority varchar(20) NOT NULL DEFAULT 'normal'
          CHECK (priority IN ('low','normal','high','urgent')),
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        resolved_at timestamptz,
        closed_at timestamptz
      );

      CREATE TABLE support_messages (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        ticket_id uuid NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
        author_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
        author_type varchar(20) NOT NULL CHECK (author_type IN ('customer','staff','system')),
        body text NOT NULL,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE support_message_attachments (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        support_message_id uuid NOT NULL REFERENCES support_messages(id) ON DELETE CASCADE,
        media_asset_id uuid NOT NULL REFERENCES media_assets(id) ON DELETE RESTRICT,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_support_message_attachment UNIQUE (support_message_id, media_asset_id)
      );

      CREATE TABLE faq_categories (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        restaurant_id uuid REFERENCES restaurants(id) ON DELETE CASCADE,
        name varchar(120) NOT NULL,
        slug varchar(140) NOT NULL,
        display_order integer NOT NULL DEFAULT 0,
        is_active boolean NOT NULL DEFAULT true,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_faq_category_slug UNIQUE (restaurant_id, slug)
      );

      CREATE TABLE faq_articles (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        restaurant_id uuid REFERENCES restaurants(id) ON DELETE CASCADE,
        category_id uuid REFERENCES faq_categories(id) ON DELETE SET NULL,
        question text NOT NULL,
        answer text NOT NULL,
        display_order integer NOT NULL DEFAULT 0,
        is_active boolean NOT NULL DEFAULT true,
        archived_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX idx_support_tickets_customer_status
        ON support_tickets (customer_id, status, created_at DESC);

      CREATE INDEX idx_support_messages_ticket
        ON support_messages (ticket_id, created_at);

      CREATE TRIGGER trg_support_tickets_updated_at
      BEFORE UPDATE ON support_tickets FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_faq_categories_updated_at
      BEFORE UPDATE ON faq_categories FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE TRIGGER trg_faq_articles_updated_at
      BEFORE UPDATE ON faq_articles FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
DROP TABLE IF EXISTS faq_articles;
      DROP TABLE IF EXISTS faq_categories;
      DROP TABLE IF EXISTS support_message_attachments;
      DROP TABLE IF EXISTS support_messages;
      DROP TABLE IF EXISTS support_tickets;
    `);
  }
}
