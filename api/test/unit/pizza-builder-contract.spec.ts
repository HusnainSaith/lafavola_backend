import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { MenuItem } from '../../src/modules/menu/entities/menu-item.entity';
import { MenuItemSize } from '../../src/modules/menu/entities/menu-item-size.entity';
import { OptionChoice } from '../../src/modules/option-groups/entities/option-choice.entity';
import { OptionGroup } from '../../src/modules/option-groups/entities/option-group.entity';
import { BuildPizzaDto } from '../../src/modules/pizza-builder/dto/build-pizza.dto';
import { PizzaBuilderService } from '../../src/modules/pizza-builder/pizza-builder.service';

describe('PizzaBuilderService contract', () => {
  const rule = {
    id: 'rule-1',
    menuItemId: 'item-1',
    doughGroupId: 'grp-dough',
    sauceGroupId: 'grp-sauce',
    cheeseGroupId: 'grp-cheese',
    toppingsGroupId: 'grp-toppings',
    freeToppingCount: 0,
    maxTotalToppings: 4,
  };

  const groups = [
    {
      id: 'grp-dough',
      name: 'Dough',
      isRequired: true,
      minSelect: 1,
      maxSelect: 1,
    },
    {
      id: 'grp-sauce',
      name: 'Sauce',
      isRequired: true,
      minSelect: 1,
      maxSelect: 1,
    },
    {
      id: 'grp-cheese',
      name: 'Cheese',
      isRequired: true,
      minSelect: 1,
      maxSelect: 1,
    },
    {
      id: 'grp-toppings',
      name: 'Toppings',
      isRequired: false,
      minSelect: 0,
      maxSelect: undefined,
    },
  ];

  const choices = [
    {
      id: 'ch-dough',
      optionGroupId: 'grp-dough',
      name: 'Classica',
      priceAdjustmentMinor: 0,
      caloriesAdjustment: 0,
      isDefault: true,
    },
    {
      id: 'ch-sauce',
      optionGroupId: 'grp-sauce',
      name: 'Pomodoro',
      priceAdjustmentMinor: 100,
      caloriesAdjustment: 0,
      isDefault: true,
    },
    {
      id: 'ch-cheese',
      optionGroupId: 'grp-cheese',
      name: 'Fior di latte',
      priceAdjustmentMinor: 200,
      caloriesAdjustment: 0,
      isDefault: true,
    },
    {
      id: 'ch-top1',
      optionGroupId: 'grp-toppings',
      name: 'Funghi',
      priceAdjustmentMinor: 150,
      caloriesAdjustment: 20,
      isDefault: false,
    },
    {
      id: 'ch-top2',
      optionGroupId: 'grp-toppings',
      name: 'Salsiccia',
      priceAdjustmentMinor: 200,
      caloriesAdjustment: 30,
      isDefault: false,
    },
  ];

  function buildDataSource() {
    const makeRepo = () => ({
      findOne: jest.fn().mockResolvedValue(null),
      find: jest.fn().mockResolvedValue([]),
      save: jest.fn(),
      create: jest.fn((input: unknown) => input),
      count: jest.fn().mockResolvedValue(0),
    });
    const repos: Record<string, ReturnType<typeof makeRepo>> = {
      [MenuItem.name]: makeRepo(),
      [MenuItemSize.name]: makeRepo(),
      [OptionGroup.name]: makeRepo(),
      [OptionChoice.name]: makeRepo(),
    };
    return {
      getRepository: jest.fn((entity: unknown) => {
        const key =
          typeof entity === 'function'
            ? (entity as { name: string }).name
            : String(entity);
        return repos[key];
      }),
    } as never;
  }
  it('loads the builder configuration grouped by dough/sauce/cheese/toppings', async () => {
    const rules = {
      findOne: jest.fn().mockResolvedValue(rule),
      create: jest.fn(),
      save: jest.fn(),
    };
    const dataSource = buildDataSource();
    const repoFor = (entity: unknown) =>
      (
        dataSource as {
          getRepository: jest.Mock<{ findOne: jest.Mock; find: jest.Mock }>;
        }
      ).getRepository(entity);

    repoFor(MenuItem).findOne.mockResolvedValue({
      id: 'item-1',
      name: 'Personalizza',
      description: null,
      isActive: true,
    });
    repoFor(MenuItemSize).find.mockResolvedValue([
      {
        id: 'size-1',
        sizeCode: 'media',
        displayName: 'Media',
        basePriceMinor: 1000,
        calories: 700,
      },
    ]);
    repoFor(OptionGroup).find.mockResolvedValue(groups);
    repoFor(OptionChoice).find.mockResolvedValue(choices);

    const service = new PizzaBuilderService(
      rules as never,
      {} as never,
      dataSource,
    );

    const result = await service.getConfiguration('item-1');

    expect(result.menuItem?.id).toBe('item-1');
    expect(result.sizes).toEqual([
      expect.objectContaining({
        id: 'size-1',
        code: 'media',
        basePriceMinor: 1000,
      }),
    ]);
    expect(result.groups.map((group) => group.type)).toEqual([
      'dough',
      'sauce',
      'cheese',
      'toppings',
    ]);
    const dough = result.groups.find((group) => group.type === 'dough');
    const toppings = result.groups.find((group) => group.type === 'toppings');
    expect(dough?.required).toBe(true);
    expect(dough?.maxSelections).toBe(1);
    // Toppings max is overridden by the builder rule.
    expect(toppings?.maxSelections).toBe(4);
    expect(toppings?.choices.map((choice) => choice.name)).toEqual([
      'Funghi',
      'Salsiccia',
    ]);
    expect(result.rules).toEqual({ freeToppingCount: 0, maxTotalToppings: 4 });
  });
  it('returns a selection summary and delegates authoritative pricing on build', async () => {
    const rules = {
      findOne: jest.fn().mockResolvedValue(rule),
      create: jest.fn(),
      save: jest.fn(),
    };
    const pricing = {
      calculate: jest.fn().mockResolvedValue({
        basePriceMinor: 1000,
        optionAdjustmentsMinor: 650,
        unitPriceMinor: 1650,
        quantity: 1,
        lineTotalMinor: 1650,
      }),
    };
    const dataSource = buildDataSource();
    const repoFor = (entity: unknown) =>
      (
        dataSource as {
          getRepository: jest.Mock<{ find: jest.Mock }>;
        }
      ).getRepository(entity);
    repoFor(OptionChoice).find.mockResolvedValue(choices);

    const service = new PizzaBuilderService(
      rules as never,
      pricing as never,
      dataSource,
    );

    const result = await service.build({
      menuItemId: 'item-1',
      menuItemSizeId: 'size-1',
      doughChoiceId: 'ch-dough',
      sauceChoiceId: 'ch-sauce',
      cheeseChoiceId: 'ch-cheese',
      toppingChoiceIds: ['ch-top1', 'ch-top2'],
    });

    expect(result.menuItemId).toBe('item-1');
    expect(result.ruleId).toBe('rule-1');
    expect(result.configuration).toEqual({
      menuItemSizeId: 'size-1',
      doughChoiceId: 'ch-dough',
      sauceChoiceId: 'ch-sauce',
      cheeseChoiceId: 'ch-cheese',
      toppingChoiceIds: ['ch-top1', 'ch-top2'],
    });
    expect(result.selectionSummary.map((entry) => entry.type)).toEqual([
      'dough',
      'sauce',
      'cheese',
      'topping',
      'topping',
    ]);
    // All selected choice ids (excluding size) are passed to the pricing service.
    expect(pricing.calculate).toHaveBeenCalledWith({
      menuItemId: 'item-1',
      sizeId: 'size-1',
      optionChoiceIds: [
        'ch-dough',
        'ch-sauce',
        'ch-cheese',
        'ch-top1',
        'ch-top2',
      ],
      quantity: 1,
    });
    expect(result.price).toEqual(
      expect.objectContaining({ unitPriceMinor: 1650, lineTotalMinor: 1650 }),
    );
  });

  it('rejects invalid build payloads through class-validator', async () => {
    const invalid = plainToInstance(BuildPizzaDto, {
      menuItemId: 'not-a-uuid',
      toppingChoiceIds: ['not-a-uuid'],
    });
    const errors = await validate(invalid);
    expect(errors.some((error) => error.property === 'menuItemId')).toBe(true);
    expect(errors.some((error) => error.property === 'menuItemSizeId')).toBe(
      true,
    );
  });
});
