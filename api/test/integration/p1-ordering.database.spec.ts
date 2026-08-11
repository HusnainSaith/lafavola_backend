import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { MenuSort } from '../../src/modules/menu/dto/menu-query.dto';
import { MenuItemRepository } from '../../src/modules/menu/repositories/menu-item.repository';
import { PromotionRedemption } from '../../src/modules/promotions/entities/promotion-redemption.entity';
import { PromotionsService } from '../../src/modules/promotions/promotions.service';
import { PromotionRepository } from '../../src/modules/promotions/repositories/promotion.repository';
import {
  createTestDataSource,
  ensureTestDatabase,
  resetIsolatedTestDatabase,
} from '../utils/test-data-source';

jest.setTimeout(120_000);
const enabled = process.env.RUN_DB_TESTS === 'true';

(enabled ? describe : describe.skip)('P1 PostgreSQL ordering queries', () => {
  let dataSource: DataSource;
  let restaurantId: string;
  let categoryId: string;
  let ingredientId: string;
  let customerId: string;
  let itemIds: string[];

  beforeAll(async () => {
    dataSource = createTestDataSource(await ensureTestDatabase());
    await resetIsolatedTestDatabase(dataSource);
    await dataSource.runMigrations({ transaction: 'each' });
    [{ id: restaurantId }] = await dataSource.query(
      `INSERT INTO restaurants (name, slug) VALUES ('P1 Test', 'p1-test') RETURNING id`,
    );
    [{ id: categoryId }] = await dataSource.query(
      `INSERT INTO menu_categories (restaurant_id, name, slug)
       VALUES ($1, 'Pizza', 'pizza') RETURNING id`,
      [restaurantId],
    );
    [{ id: ingredientId }] = await dataSource.query(
      `INSERT INTO ingredients
        (restaurant_id, name, slug, is_vegetarian, is_vegan, is_gluten_free)
       VALUES ($1, 'Basil', 'basil', true, true, true) RETURNING id`,
      [restaurantId],
    );
    const items: Array<{ id: string }> = await dataSource.query(
      `INSERT INTO menu_items
        (restaurant_id, category_id, name, slug, is_vegetarian, is_vegan,
         is_gluten_free, is_spicy, is_popular, popularity_score, created_at)
       VALUES
        ($1,$2,'Margherita','margherita',true,false,false,false,true,90,NOW()-INTERVAL '5 days'),
        ($1,$2,'Vegan Garden','vegan-garden',true,true,true,false,false,50,NOW()-INTERVAL '4 days'),
        ($1,$2,'Spicy Diavola','spicy-diavola',false,false,false,true,true,100,NOW()-INTERVAL '3 days'),
        ($1,$2,'Inactive','inactive',true,false,false,false,false,1,NOW()-INTERVAL '2 days'),
        ($1,$2,'Future','future',true,false,false,false,false,2,NOW()-INTERVAL '1 day')
       RETURNING id`,
      [restaurantId, categoryId],
    );
    itemIds = items.map(({ id }) => id);
    await dataSource.query(
      `UPDATE menu_items SET is_active=false WHERE id=$1`,
      [itemIds[3]],
    );
    await dataSource.query(
      `UPDATE menu_items SET available_from=NOW()+INTERVAL '1 day' WHERE id=$1`,
      [itemIds[4]],
    );
    await dataSource.query(
      `INSERT INTO menu_item_sizes (menu_item_id,size_code,display_name,base_price_minor)
       VALUES ($1,'single','Single',1000),($2,'single','Single',1200),($3,'single','Single',1400),
              ($4,'single','Single',900),($5,'single','Single',800)`,
      itemIds,
    );
    await dataSource.query(
      `INSERT INTO menu_item_ingredients (menu_item_id,ingredient_id)
       VALUES ($1,$2)`,
      [itemIds[0], ingredientId],
    );
    const [{ id: roleId }] = await dataSource.query(
      `INSERT INTO roles (name,is_system) VALUES ('customer',true) RETURNING id`,
    );
    [{ id: customerId }] = await dataSource.query(
      `INSERT INTO users (email,full_name,role_id)
       VALUES ('p1@example.com','P1 Customer',$1) RETURNING id`,
      [roleId],
    );
  });

  afterAll(async () => {
    if (dataSource?.isInitialized) await dataSource.destroy();
  });

  it('applies pagination/count and excludes inactive/unavailable rows', async () => {
    const repository = new MenuItemRepository(dataSource);
    const first = await repository.findPublicMenu({ page: 1, limit: 2 });
    const second = await repository.findPublicMenu({ page: 2, limit: 2 });
    expect(first.total).toBe(3);
    expect(first.items).toHaveLength(2);
    expect(second.items).toHaveLength(1);
  });

  it('supports name, ingredient, category and dietary filters', async () => {
    const repository = new MenuItemRepository(dataSource);
    expect(
      (await repository.findPublicMenu({ search: 'Diavola' })).items,
    ).toHaveLength(1);
    expect(
      (await repository.findPublicMenu({ ingredientId })).items.map(
        ({ name }) => name,
      ),
    ).toEqual(['Margherita']);
    expect((await repository.findPublicMenu({ categoryId })).total).toBe(3);
    expect((await repository.findPublicMenu({ vegetarian: true })).total).toBe(
      2,
    );
    expect((await repository.findPublicMenu({ vegan: true })).total).toBe(1);
    expect((await repository.findPublicMenu({ glutenFree: true })).total).toBe(
      1,
    );
    expect((await repository.findPublicMenu({ spicy: true })).total).toBe(1);
  });

  it('supports price filters and deterministic sorts', async () => {
    const repository = new MenuItemRepository(dataSource);
    expect(
      (
        await repository.findPublicMenu({
          minPriceMinor: 1100,
          maxPriceMinor: 1300,
        })
      ).items.map(({ name }) => name),
    ).toEqual(['Vegan Garden']);
    expect(
      (await repository.findPublicMenu({ sort: MenuSort.POPULAR })).items[0]
        .name,
    ).toBe('Spicy Diavola');
    expect(
      (await repository.findPublicMenu({ sort: MenuSort.NEWEST })).items[0]
        .name,
    ).toBe('Spicy Diavola');
    expect(
      (await repository.findPublicMenu({ sort: MenuSort.PRICE_ASC })).items.map(
        ({ name }) => name,
      ),
    ).toEqual(['Margherita', 'Vegan Garden', 'Spicy Diavola']);
    expect(
      (
        await repository.findPublicMenu({ sort: MenuSort.PRICE_DESC })
      ).items.map(({ name }) => name),
    ).toEqual(['Spicy Diavola', 'Vegan Garden', 'Margherita']);
  });

  it('evaluates priority, stacking groups, coupon compatibility and unsupported types deterministically', async () => {
    const rows: Array<{ id: string }> = await dataSource.query(
      `INSERT INTO promotions
        (restaurant_id,name,promotion_type,discount_value,starts_at,priority,stacking_group,conditions)
       VALUES
        ($1,'Lower','fixed_amount',300,NOW()-INTERVAL '1 day',5,'seasonal','{"couponCompatible":true}'),
        ($1,'Higher','percentage',20,NOW()-INTERVAL '1 day',10,'seasonal','{"couponCompatible":true}'),
        ($1,'Delivery','free_delivery',0,NOW()-INTERVAL '1 day',1,'delivery','{"couponCompatible":true}'),
        ($1,'Unsafe Bogo','bogo',0,NOW()-INTERVAL '1 day',20,'bogo','{"couponCompatible":true}')
       RETURNING id`,
      [restaurantId],
    );
    const service = new PromotionsService(
      new PromotionRepository(dataSource),
      dataSource,
    );
    const result = await dataSource.transaction((manager) =>
      service.evaluateAutomatic(manager, {
        restaurantId,
        customerId,
        subtotalMinor: 2_000,
        deliveryFeeMinor: 250,
        hasCoupon: true,
        lines: [{ menuItemId: itemIds[0], categoryId, lineTotalMinor: 2_000 }],
      }),
    );
    expect(result.appliedPromotions.map(({ name }) => name)).toEqual([
      'Higher',
      'Delivery',
    ]);
    expect(result.promotionDiscountMinor).toBe(400);
    expect(result.deliveryDiscountMinor).toBe(250);
    expect(result.unsupportedPromotions).toEqual([
      expect.objectContaining({ id: rows[3].id, type: 'bogo' }),
    ]);
  });

  it('enforces item exclusions and usage limits from PostgreSQL counts', async () => {
    const [{ id: promotionId }] = await dataSource.query(
      `INSERT INTO promotions
        (restaurant_id,name,promotion_type,discount_value,starts_at,total_usage_limit,per_customer_limit,priority)
       VALUES ($1,'Limited','fixed_amount',100,NOW()-INTERVAL '1 day',1,1,100)
       RETURNING id`,
      [restaurantId],
    );
    await dataSource.query(
      `INSERT INTO promotion_redemptions (promotion_id,customer_id,discount_minor)
       VALUES ($1,$2,100)`,
      [promotionId, customerId],
    );
    const service = new PromotionsService(
      new PromotionRepository(dataSource),
      dataSource,
    );
    const result = await dataSource.transaction((manager) =>
      service.evaluateAutomatic(manager, {
        restaurantId,
        customerId,
        subtotalMinor: 2_000,
        deliveryFeeMinor: 0,
        hasCoupon: false,
        lines: [{ menuItemId: itemIds[0], categoryId, lineTotalMinor: 2_000 }],
      }),
    );
    expect(result.appliedPromotions.some(({ id }) => id === promotionId)).toBe(
      false,
    );
  });

  it('serializes concurrent final-use promotion claims', async () => {
    const [{ id: promotionId }] = await dataSource.query(
      `INSERT INTO promotions
        (restaurant_id,name,promotion_type,discount_value,starts_at,total_usage_limit,priority,stacking_group)
       VALUES ($1,'Final Use','fixed_amount',100,NOW()-INTERVAL '1 day',1,1000,'final-use')
       RETURNING id`,
      [restaurantId],
    );
    const service = new PromotionsService(
      new PromotionRepository(dataSource),
      dataSource,
    );
    const claim = () =>
      dataSource.transaction(async (manager) => {
        const result = await service.evaluateAutomatic(manager, {
          restaurantId,
          customerId,
          subtotalMinor: 2_000,
          deliveryFeeMinor: 0,
          hasCoupon: false,
          lock: true,
          lines: [
            { menuItemId: itemIds[0], categoryId, lineTotalMinor: 2_000 },
          ],
        });
        const applied = result.appliedPromotions.find(
          ({ id }) => id === promotionId,
        );
        if (applied) {
          await manager.getRepository(PromotionRedemption).save({
            promotionId,
            customerId,
            discountMinor: applied.discountMinor,
          });
        }
        return Boolean(applied);
      });
    const claims = await Promise.all([claim(), claim()]);
    expect(claims.filter(Boolean)).toHaveLength(1);
    expect(
      await dataSource.getRepository(PromotionRedemption).count({
        where: { promotionId },
      }),
    ).toBe(1);
  });

  it('rolls back failed redemption and rejects duplicate order redemption', async () => {
    const [{ id: promotionId }] = await dataSource.query(
      `INSERT INTO promotions
        (restaurant_id,name,promotion_type,discount_value,starts_at,priority)
       VALUES ($1,'Rollback','fixed_amount',100,NOW()-INTERVAL '1 day',2000)
       RETURNING id`,
      [restaurantId],
    );
    await expect(
      dataSource.transaction(async (manager) => {
        await manager.getRepository(PromotionRedemption).save({
          promotionId,
          customerId,
          discountMinor: 100,
        });
        throw new Error('checkout failed');
      }),
    ).rejects.toThrow('checkout failed');
    expect(
      await dataSource.getRepository(PromotionRedemption).count({
        where: { promotionId },
      }),
    ).toBe(0);

    const [{ id: orderId }] = await dataSource.query(
      `INSERT INTO orders
        (restaurant_id,customer_id,order_type,subtotal_minor,grand_total_minor)
       VALUES ($1,$2,'pickup',1000,1000) RETURNING id`,
      [restaurantId, customerId],
    );
    await dataSource.getRepository(PromotionRedemption).save({
      promotionId,
      customerId,
      orderId,
      discountMinor: 100,
    });
    await expect(
      dataSource.getRepository(PromotionRedemption).save({
        promotionId,
        customerId,
        orderId,
        discountMinor: 100,
      }),
    ).rejects.toThrow();
  });
});
