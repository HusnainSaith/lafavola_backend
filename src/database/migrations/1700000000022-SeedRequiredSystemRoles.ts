import { MigrationInterface, QueryRunner } from 'typeorm';

export class SeedRequiredSystemRoles1700000000022 implements MigrationInterface {
  name = 'SeedRequiredSystemRoles1700000000022';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      INSERT INTO roles (name, description, is_system)
      VALUES
        ('admin', 'System administrator', true),
        ('guest', 'Unauthenticated or limited guest', true),
        ('client', 'Restaurant customer', true),
        ('employee', 'Restaurant or delivery employee', true),
        ('project_manager', 'Project manager', true),
        ('developer', 'Developer', true),
        ('support', 'Customer support agent', true),
        ('assistant', 'Administrative assistant', true)
      ON CONFLICT (name) DO UPDATE SET is_system = true
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DELETE FROM roles r
      WHERE r.name IN (
        'admin','guest','client','employee','project_manager','developer',
        'support','assistant'
      )
      AND NOT EXISTS (SELECT 1 FROM users u WHERE u.role_id = r.id)
    `);
  }
}
