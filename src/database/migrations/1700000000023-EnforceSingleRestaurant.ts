import { MigrationInterface, QueryRunner } from 'typeorm';

export class EnforceSingleRestaurant1700000000023 implements MigrationInterface {
  name = 'EnforceSingleRestaurant1700000000023';

  public async up(queryRunner: QueryRunner): Promise<void> {
    const [{ count }] = await queryRunner.query(
      'SELECT COUNT(*)::integer AS count FROM restaurants',
    );
    if (count > 1) {
      throw new Error(
        'Single-restaurant migration requires existing restaurant records to be consolidated first',
      );
    }
    await queryRunner.query(
      `UPDATE restaurants SET name='La Favola Restaurant', slug='la-favola-restaurant'`,
    );
    await queryRunner.query(
      'CREATE UNIQUE INDEX uq_restaurants_singleton ON restaurants ((true))',
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP INDEX IF EXISTS uq_restaurants_singleton');
  }
}
