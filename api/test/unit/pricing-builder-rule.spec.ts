import { MenuItem } from '../../src/modules/menu/entities/menu-item.entity';
import { MenuItemSize } from '../../src/modules/menu/entities/menu-item-size.entity';
import { MenuItemIngredient } from '../../src/modules/menu/entities/menu-item-ingredient.entity';
import { MenuItemOptionGroup } from '../../src/modules/option-groups/entities/menu-item-option-group.entity';
import { OptionChoice } from '../../src/modules/option-groups/entities/option-choice.entity';
import { OptionIncompatibility } from '../../src/modules/option-groups/entities/option-incompatibility.entity';
import { PizzaBuilderRule } from '../../src/modules/pizza-builder/entities/pizza-builder-rule.entity';
import { PricingService } from '../../src/modules/pricing/pricing.service';

describe('PricingService build-your-own builder rules', () => {
  const restaurantId = 'rest-1';

  function group(id: string, name: string, maxSelect?: number) {
    return {
      id,
      name,
      isActive: true,
      restaurantId,
      minSelect: 0,
      maxSelect,
      isRequired: false,
      allowQuantity: false,
    };
  }

  function choice(
    id: string,
    groupId: string,
    price: number,
    owner: ReturnType<typeof group>,
  ) {
    return {
      id,
      optionGroupId: groupId,
      priceAdjustmentMinor: price,
      name: id,
      isDefault: false,
      optionGroup: owner,
    };
  }

  function itemRepo(item: Record<string, unknown>) {
    return { findOne: jest.fn().mockResolvedValue(item) };
  }

  function buildDataSource(
    item: Record<string, unknown>,
    size: Record<string, unknown>,
    selectedChoices: ReturnType<typeof choice>[],
    mappings: Array<{
      optionGroupId: string;
      optionGroup: ReturnType<typeof group>;
    }>,
    rule: Record<string, unknown> | null,
  ) {
    const repositories: Record<string, Record<string, jest.Mock>> = {
      [MenuItem.name]: itemRepo(item),
      [MenuItemSize.name]: { findOne: jest.fn().mockResolvedValue(size) },
      [OptionChoice.name]: {
        find: jest.fn().mockResolvedValue(selectedChoices),
      },
      [MenuItemOptionGroup.name]: {
        find: jest.fn().mockResolvedValue(
          mappings.map((mapping) => ({
            menuItemId: (item as { id: string }).id,
            ...mapping,
          })),
        ),
      },
      [PizzaBuilderRule.name]: { findOne: jest.fn().mockResolvedValue(rule) },
      [OptionIncompatibility.name]: {
        createQueryBuilder: jest.fn(() => ({
          where: jest.fn().mockReturnThis(),
          getOne: jest.fn().mockResolvedValue(null),
        })),
      },
      [MenuItemIngredient.name]: { count: jest.fn().mockResolvedValue(0) },
    };
    return {
      getRepository: jest.fn((entity: unknown) => {
        const key =
          typeof entity === 'function'
            ? (entity as { name: string }).name
            : String(entity);
        return repositories[key];
      }),
    } as never;
  }

  const item = {
    id: 'build-1',
    restaurantId,
    restaurant: { id: restaurantId, isActive: true },
    isActive: true,
    archivedAt: null,
    availableFrom: null,
    availableUntil: null,
    itemType: 'build_your_own',
  };

  it('calculates a price and applies the free-topping deduction', async () => {
    const dough = group('grp-dough', 'Dough');
    const sauce = group('grp-sauce', 'Sauce');
    const cheese = group('grp-cheese', 'Cheese');
    const toppings = group('grp-toppings', 'Toppings');
    const selected = [
      choice('dough-1', 'grp-dough', 0, dough),
      choice('sauce-1', 'grp-sauce', 100, sauce),
      choice('cheese-1', 'grp-cheese', 200, cheese),
      choice('top-1', 'grp-toppings', 150, toppings),
      choice('top-2', 'grp-toppings', 150, toppings),
    ];
    const mappings = [
      { optionGroupId: 'grp-dough', optionGroup: dough },
      { optionGroupId: 'grp-sauce', optionGroup: sauce },
      { optionGroupId: 'grp-cheese', optionGroup: cheese },
      { optionGroupId: 'grp-toppings', optionGroup: toppings },
    ];
    const rule = {
      doughGroupId: 'grp-dough',
      sauceGroupId: 'grp-sauce',
      cheeseGroupId: 'grp-cheese',
      toppingsGroupId: 'grp-toppings',
      maxTotalToppings: 3,
      freeToppingCount: 1,
    };
    const dataSource = buildDataSource(
      item,
      { id: 'size-1', basePriceMinor: 1000 },
      selected,
      mappings,
      rule,
    );
    const service = new PricingService(dataSource);

    const price = await service.calculate({
      menuItemId: 'build-1',
      sizeId: 'size-1',
      optionChoiceIds: ['dough-1', 'sauce-1', 'cheese-1', 'top-1', 'top-2'],
    });

    // base 1000 + (0 + 100 + 200 + 150 + 150) - 1 free topping (150)
    expect(price.unitPriceMinor).toBe(1450);
    expect(price.optionAdjustmentsMinor).toBe(450);
    expect(price.lineTotalMinor).toBe(1450);
  });
  function builderGroups() {
    return {
      dough: group('grp-dough', 'Dough'),
      sauce: group('grp-sauce', 'Sauce'),
      cheese: group('grp-cheese', 'Cheese'),
      toppings: group('grp-toppings', 'Toppings'),
    };
  }

  function builderMappings(
    dough: ReturnType<typeof group>,
    sauce: ReturnType<typeof group>,
    cheese: ReturnType<typeof group>,
    toppings: ReturnType<typeof group>,
  ) {
    return [
      { optionGroupId: 'grp-dough', optionGroup: dough },
      { optionGroupId: 'grp-sauce', optionGroup: sauce },
      { optionGroupId: 'grp-cheese', optionGroup: cheese },
      { optionGroupId: 'grp-toppings', optionGroup: toppings },
    ];
  }

  function builderRule(maxTotalToppings: number, freeToppingCount = 0) {
    return {
      doughGroupId: 'grp-dough',
      sauceGroupId: 'grp-sauce',
      cheeseGroupId: 'grp-cheese',
      toppingsGroupId: 'grp-toppings',
      maxTotalToppings,
      freeToppingCount,
    };
  }

  it('rejects a build-your-own pizza without a required dough', async () => {
    const g = builderGroups();
    const selected = [
      choice('sauce-1', 'grp-sauce', 100, g.sauce),
      choice('cheese-1', 'grp-cheese', 200, g.cheese),
      choice('top-1', 'grp-toppings', 150, g.toppings),
    ];
    const dataSource = buildDataSource(
      item,
      { id: 'size-1', basePriceMinor: 1000 },
      selected,
      builderMappings(g.dough, g.sauce, g.cheese, g.toppings),
      builderRule(3),
    );
    const service = new PricingService(dataSource);

    await expect(
      service.calculate({
        menuItemId: 'build-1',
        sizeId: 'size-1',
        optionChoiceIds: ['sauce-1', 'cheese-1', 'top-1'],
      }),
    ).rejects.toThrow(/A dough selection is required/);
  });

  it('rejects a build-your-own pizza exceeding the topping limit', async () => {
    const g = builderGroups();
    const selected = [
      choice('dough-1', 'grp-dough', 0, g.dough),
      choice('sauce-1', 'grp-sauce', 100, g.sauce),
      choice('cheese-1', 'grp-cheese', 200, g.cheese),
      choice('top-1', 'grp-toppings', 150, g.toppings),
      choice('top-2', 'grp-toppings', 150, g.toppings),
      choice('top-3', 'grp-toppings', 150, g.toppings),
    ];
    const dataSource = buildDataSource(
      item,
      { id: 'size-1', basePriceMinor: 1000 },
      selected,
      builderMappings(g.dough, g.sauce, g.cheese, g.toppings),
      builderRule(2),
    );
    const service = new PricingService(dataSource);

    await expect(
      service.calculate({
        menuItemId: 'build-1',
        sizeId: 'size-1',
        optionChoiceIds: [
          'dough-1',
          'sauce-1',
          'cheese-1',
          'top-1',
          'top-2',
          'top-3',
        ],
      }),
    ).rejects.toThrow(/At most 2 toppings may be selected/);
  });

  it('rejects a build-your-own pizza without a configured builder rule', async () => {
    const g = builderGroups();
    const selected = [
      choice('dough-1', 'grp-dough', 0, g.dough),
      choice('sauce-1', 'grp-sauce', 100, g.sauce),
      choice('cheese-1', 'grp-cheese', 200, g.cheese),
    ];
    const dataSource = buildDataSource(
      item,
      { id: 'size-1', basePriceMinor: 1000 },
      selected,
      builderMappings(g.dough, g.sauce, g.cheese, g.toppings),
      null,
    );
    const service = new PricingService(dataSource);

    await expect(
      service.calculate({
        menuItemId: 'build-1',
        sizeId: 'size-1',
        optionChoiceIds: ['dough-1', 'sauce-1', 'cheese-1'],
      }),
    ).rejects.toThrow(/Pizza builder configuration is unavailable/);
  });
});
