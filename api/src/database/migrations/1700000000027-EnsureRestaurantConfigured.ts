import { MigrationInterface, QueryRunner } from 'typeorm';

/** Ensures the single-restaurant deployment always has its required tenant. */
export class EnsureRestaurantConfigured1700000000027
  implements MigrationInterface
{
  name = 'EnsureRestaurantConfigured1700000000027';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      INSERT INTO restaurants (
        name,
        slug,
        country_code,
        currency,
        timezone,
        default_delivery_minutes,
        delivery_fee_minor,
        minimum_order_minor,
        tax_rate_basis_points,
        tax_behavior,
        is_active
      )
      SELECT
        'La Favola Restaurant',
        'la-favola-restaurant',
        'IT',
        'EUR',
        'Europe/Rome',
        30,
        0,
        0,
        0,
        'included',
        true
      WHERE NOT EXISTS (SELECT 1 FROM restaurants)
    `);

    // This application deliberately supports one restaurant. Repair an
    // accidentally disabled singleton so public and cart routes remain usable.
    await queryRunner.query(`
      UPDATE restaurants
      SET is_active = true
      WHERE is_active = false
    `);
  }

  public async down(_queryRunner: QueryRunner): Promise<void> {
    // Data-repair migration: never delete a restaurant that may have acquired
    // orders, staff, menu items, or other production relationships.
  }
}
