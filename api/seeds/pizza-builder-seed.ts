import 'reflect-metadata';
import { AppDataSource } from '../src/config/data-source';
import { Restaurant } from '../src/modules/restaurants/entities/restaurant.entity';
import { MenuCategory } from '../src/modules/categories/entities/menu-category.entity';
import { MenuItem } from '../src/modules/menu/entities/menu-item.entity';
import { MenuItemSize } from '../src/modules/menu/entities/menu-item-size.entity';
import { OptionGroup } from '../src/modules/option-groups/entities/option-group.entity';
import { OptionChoice } from '../src/modules/option-groups/entities/option-choice.entity';
import { MenuItemOptionGroup } from '../src/modules/option-groups/entities/menu-item-option-group.entity';
import { PizzaBuilderRule } from '../src/modules/pizza-builder/entities/pizza-builder-rule.entity';

// EUR minor units: 250 = €2.50. Matches the menu-seed value so every
// product detail exposes the same admin-configured delivery fee.
const TEST_DELIVERY_FEE_MINOR = 250;
const TEST_DELIVERY_MINUTES = 30;

async function seedPizzaBuilder() {
  await AppDataSource.initialize();

  try {
    // 1. Get or create a restaurant with all required fields.
    let restaurant = await AppDataSource.getRepository(Restaurant).findOne({
      where: { isActive: true },
      order: { createdAt: 'ASC' },
    });

    if (!restaurant) {
      restaurant = await AppDataSource.getRepository(Restaurant).save(
        AppDataSource.getRepository(Restaurant).create({
          name: 'La Favola Test',
          slug: 'la-favola-test',
          countryCode: 'IT',
          currency: 'EUR',
          timezone: 'Europe/Rome',
          defaultDeliveryMinutes: TEST_DELIVERY_MINUTES,
          deliveryFeeMinor: TEST_DELIVERY_FEE_MINOR,
          minimumOrderMinor: 0,
          taxRateBasisPoints: 2200,
          taxBehavior: 'tax_included',
          isActive: true,
        }),
      );
    }

    // 2. Create the category for build-your-own pizzas.
    const repoCategory = AppDataSource.getRepository(MenuCategory);
    const existingCategory = await repoCategory.findOne({
      where: { restaurantId: restaurant.id, slug: 'build-your-own' },
    });
    const category =
      existingCategory ??
      (await repoCategory.save(
        repoCategory.create({
          restaurantId: restaurant.id,
          name: 'Crea la tua pizza',
          slug: 'build-your-own',
          description:
            'Crea la tua pizza con impasto, salsa, formaggio e toppings',
          displayOrder: 1,
          isActive: true,
        }),
      ));

    // 3. Create the build-your-own menu item.
    const repoItem = AppDataSource.getRepository(MenuItem);
    const existingItem = await repoItem.findOne({
      where: { restaurantId: restaurant.id, slug: 'personalizza' },
    });
    const menuItem =
      existingItem ??
      (await repoItem.save(
        repoItem.create({
          restaurantId: restaurant.id,
          categoryId: category.id,
          name: 'Personalizza',
          slug: 'personalizza',
          description:
            'Crea la tua pizza con impasto, salsa, formaggio e toppings',
          itemType: 'build_your_own',
          calories: 0,
          preparationMinutes: 15,
          isVegetarian: true,
          isVegan: false,
          isGlutenFree: false,
          isSpicy: false,
          isPopular: true,
          popularityScore: '100',
          isActive: true,
        }),
      ));

    // 4. Create menu item sizes (Small / Medium / Large).
    const repoSize = AppDataSource.getRepository(MenuItemSize);
    const sizes = [
      { code: 'small', name: 'Piccola', price: 500, order: 1 },
      { code: 'medium', name: 'Media', price: 800, order: 2 },
      { code: 'large', name: 'Grande', price: 1150, order: 3 },
    ];
    for (const size of sizes) {
      const existing = await repoSize.findOne({
        where: { menuItemId: menuItem.id, sizeCode: size.code },
      });
      if (!existing) {
        await repoSize.save(
          repoSize.create({
            menuItemId: menuItem.id,
            sizeCode: size.code,
            displayName: size.name,
            basePriceMinor: size.price,
            calories: 0,
            displayOrder: size.order,
            isActive: true,
          }),
        );
      }
    }

    // 5. Create option groups — all must be awaited with .save() so they get
    //    persisted and assigned a real UUID id.
    const repoGroup = AppDataSource.getRepository(OptionGroup);

    const doughGroup = await repoGroup.save(
      repoGroup.create({
        restaurantId: restaurant.id,
        name: 'Impasto',
        code: 'dough',
        optionType: 'dough',
        minSelect: 1,
        maxSelect: 1,
        isRequired: true,
        allowQuantity: false,
        displayOrder: 10,
        isActive: true,
      }),
    );

    const sauceGroup = await repoGroup.save(
      repoGroup.create({
        restaurantId: restaurant.id,
        name: 'Salsa',
        code: 'sauce',
        optionType: 'sauce',
        minSelect: 1,
        maxSelect: 1,
        isRequired: true,
        allowQuantity: false,
        displayOrder: 20,
        isActive: true,
      }),
    );

    const cheeseGroup = await repoGroup.save(
      repoGroup.create({
        restaurantId: restaurant.id,
        name: 'Formaggio',
        code: 'cheese',
        optionType: 'cheese',
        minSelect: 1,
        maxSelect: 1,
        isRequired: true,
        allowQuantity: false,
        displayOrder: 30,
        isActive: true,
      }),
    );

    const toppingsGroup = await repoGroup.save(
      repoGroup.create({
        restaurantId: restaurant.id,
        name: 'Toppings',
        code: 'toppings',
        optionType: 'topping',
        minSelect: 0,
        maxSelect: 4,
        isRequired: false,
        allowQuantity: true,
        displayOrder: 40,
        isActive: true,
      }),
    );

    // 6. Create option choices.
    const repoChoice = AppDataSource.getRepository(OptionChoice);

    const choices: Array<{
      groupId: string;
      name: string;
      code: string;
      price: number;
      calories: number;
      isDefault: boolean;
      order: number;
    }> = [
      // Dough
      {
        groupId: doughGroup.id,
        name: 'Classica',
        code: 'classica',
        price: 0,
        calories: 0,
        isDefault: true,
        order: 1,
      },
      {
        groupId: doughGroup.id,
        name: 'Napoli',
        code: 'napoli',
        price: 50,
        calories: 10,
        isDefault: false,
        order: 2,
      },
      // Sauce
      {
        groupId: sauceGroup.id,
        name: 'Pomodoro',
        code: 'pomodoro',
        price: 100,
        calories: 20,
        isDefault: true,
        order: 1,
      },
      {
        groupId: sauceGroup.id,
        name: 'Besciamella',
        code: 'white-sauce',
        price: 150,
        calories: 30,
        isDefault: false,
        order: 2,
      },
      // Cheese
      {
        groupId: cheeseGroup.id,
        name: 'Fior di latte',
        code: 'fior-di-latte',
        price: 200,
        calories: 50,
        isDefault: true,
        order: 1,
      },
      {
        groupId: cheeseGroup.id,
        name: 'Mozzarella',
        code: 'mozzarella',
        price: 100,
        calories: 30,
        isDefault: false,
        order: 2,
      },
      // Toppings
      {
        groupId: toppingsGroup.id,
        name: 'Funghi',
        code: 'funghi',
        price: 100,
        calories: 15,
        isDefault: false,
        order: 1,
      },
      {
        groupId: toppingsGroup.id,
        name: 'Salsiccia',
        code: 'salsiccia',
        price: 150,
        calories: 25,
        isDefault: false,
        order: 2,
      },
      {
        groupId: toppingsGroup.id,
        name: 'Peperoni',
        code: 'peperoni',
        price: 80,
        calories: 10,
        isDefault: false,
        order: 3,
      },
      {
        groupId: toppingsGroup.id,
        name: 'Olive',
        code: 'olive',
        price: 70,
        calories: 5,
        isDefault: false,
        order: 4,
      },
    ];
    for (const ch of choices) {
      const existing = await repoChoice.findOne({
        where: { optionGroupId: ch.groupId, code: ch.code },
      });
      if (!existing) {
        await repoChoice.save(
          repoChoice.create({
            optionGroupId: ch.groupId,
            name: ch.name,
            code: ch.code,
            priceAdjustmentMinor: ch.price,
            caloriesAdjustment: ch.calories,
            isDefault: ch.isDefault,
            displayOrder: ch.order,
            isActive: true,
          }),
        );
      }
    }

    // 7. Link option groups to the menu item (required by PricingService).
    const repoMapping = AppDataSource.getRepository(MenuItemOptionGroup);
    const groupMappings = [
      { groupId: doughGroup.id, order: 10 },
      { groupId: sauceGroup.id, order: 20 },
      { groupId: cheeseGroup.id, order: 30 },
      { groupId: toppingsGroup.id, order: 40 },
    ];
    for (const mapping of groupMappings) {
      const existing = await repoMapping.findOne({
        where: { menuItemId: menuItem.id, optionGroupId: mapping.groupId },
      });
      if (!existing) {
        await repoMapping.save(
          repoMapping.create({
            menuItemId: menuItem.id,
            optionGroupId: mapping.groupId,
            displayOrder: mapping.order,
          }),
        );
      }
    }

    // 8. Create the pizza builder rule (ruleConfig and freeToppingCount are required).
    const repoRule = AppDataSource.getRepository(PizzaBuilderRule);
    const existingRule = await repoRule.findOne({
      where: { menuItemId: menuItem.id },
    });
    if (!existingRule) {
      await repoRule.save(
        repoRule.create({
          restaurantId: restaurant.id,
          menuItemId: menuItem.id,
          name: 'Personalizza Builder',
          sizeGroupId: null,
          doughGroupId: doughGroup.id,
          sauceGroupId: sauceGroup.id,
          cheeseGroupId: cheeseGroup.id,
          toppingsGroupId: toppingsGroup.id,
          maxTotalToppings: 4,
          freeToppingCount: 0,
          ruleConfig: {},
          isActive: true,
        }),
      );
    }

    console.log('✅ Pizza builder seed data created successfully');
    console.log(`  Restaurant: ${restaurant.name}`);
    console.log(`  Menu item: ${menuItem.name} (itemType: build_your_own)`);
    console.log(`  Category: ${category.name}`);
    console.log('  Option groups: dough, sauce, cheese, toppings');
    console.log('  Pizza builder rule created and active');
  } catch (error) {
    console.error(
      'Pizza builder seed failed:',
      error instanceof Error ? error.message : error,
    );
    process.exitCode = 1;
  } finally {
    if (AppDataSource.isInitialized) await AppDataSource.destroy();
  }
}

seedPizzaBuilder();
