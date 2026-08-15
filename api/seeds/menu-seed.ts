import { AppDataSource } from '../src/config/data-source';

type SeedItem = {
  category: string;
  name: string;
  slug: string;
  description: string;
  type: string;
  calories: number;
  minutes: number;
  vegetarian: boolean;
  vegan: boolean;
  spicy: boolean;
  popular: boolean;
  score: string;
  sizes: ReadonlyArray<readonly [string, string, number, number]>;
};

const categories = [
  ['Pizza', 'pizza', 'Pizze classiche preparate al momento', 1],
  ['Calzoni', 'calzoni', 'Calzoni al forno', 2],
  ['Dolci', 'dolci', 'Dessert della casa', 3],
  ['Bevande', 'bevande', 'Bibite fresche', 4],
] as const;

const items: SeedItem[] = [
  {
    category: 'pizza',
    name: 'Margherita',
    slug: 'margherita',
    description: 'Pomodoro, mozzarella e basilico',
    type: 'modifiable',
    calories: 720,
    minutes: 12,
    vegetarian: true,
    vegan: false,
    spicy: false,
    popular: true,
    score: '100',
    sizes: [
      ['small', 'Piccola', 700, 560],
      ['medium', 'Media', 900, 720],
      ['large', 'Grande', 1150, 900],
    ],
  },
  {
    category: 'pizza',
    name: 'Diavola',
    slug: 'diavola',
    description: 'Pomodoro, mozzarella e salame piccante',
    type: 'modifiable',
    calories: 830,
    minutes: 14,
    vegetarian: false,
    vegan: false,
    spicy: true,
    popular: true,
    score: '95',
    sizes: [
      ['small', 'Piccola', 850, 650],
      ['medium', 'Media', 1050, 830],
      ['large', 'Grande', 1300, 1030],
    ],
  },
  {
    category: 'pizza',
    name: 'Quattro Formaggi',
    slug: 'quattro-formaggi',
    description: 'Mozzarella e selezione di quattro formaggi',
    type: 'modifiable',
    calories: 910,
    minutes: 14,
    vegetarian: true,
    vegan: false,
    spicy: false,
    popular: true,
    score: '85',
    sizes: [
      ['small', 'Piccola', 900, 700],
      ['medium', 'Media', 1150, 910],
      ['large', 'Grande', 1400, 1120],
    ],
  },
  {
    category: 'pizza',
    name: 'Marinara',
    slug: 'marinara',
    description: 'Pomodoro, aglio, origano e olio extravergine',
    type: 'modifiable',
    calories: 590,
    minutes: 11,
    vegetarian: true,
    vegan: true,
    spicy: false,
    popular: false,
    score: '60',
    sizes: [
      ['small', 'Piccola', 600, 450],
      ['medium', 'Media', 800, 590],
      ['large', 'Grande', 1000, 740],
    ],
  },
  {
    category: 'calzoni',
    name: 'Calzone Classico',
    slug: 'calzone-classico',
    description: 'Pomodoro, mozzarella e prosciutto cotto',
    type: 'standard',
    calories: 880,
    minutes: 16,
    vegetarian: false,
    vegan: false,
    spicy: false,
    popular: true,
    score: '75',
    sizes: [['single', 'Porzione', 1100, 880]],
  },
  {
    category: 'dolci',
    name: 'Tiramisu',
    slug: 'tiramisu',
    description: 'Tiramisu tradizionale della casa',
    type: 'other',
    calories: 430,
    minutes: 2,
    vegetarian: true,
    vegan: false,
    spicy: false,
    popular: true,
    score: '80',
    sizes: [['single', 'Porzione', 550, 430]],
  },
  {
    category: 'bevande',
    name: 'Coca-Cola',
    slug: 'coca-cola',
    description: 'Lattina da 330 ml',
    type: 'drink',
    calories: 139,
    minutes: 0,
    vegetarian: true,
    vegan: true,
    spicy: false,
    popular: false,
    score: '50',
    sizes: [['single', '330 ml', 300, 139]],
  },
];

async function seedMenu() {
  await AppDataSource.initialize();
  await AppDataSource.transaction(async (manager) => {
    const restaurants = await manager.query(
      'SELECT id, name FROM restaurants WHERE is_active=true ORDER BY created_at LIMIT 2',
    );
    if (!restaurants.length)
      throw new Error('No active restaurant found. Run migrations first.');
    if (restaurants.length > 1)
      throw new Error(
        'More than one active restaurant found; this seed is for the single-restaurant setup.',
      );
    const restaurantId = restaurants[0].id as string;
    const categoryIds = new Map<string, string>();

    for (const [name, slug, description, order] of categories) {
      const [row] = await manager.query(
        `INSERT INTO menu_categories (restaurant_id,name,slug,description,display_order,is_active)
         VALUES ($1,$2,$3,$4,$5,true)
         ON CONFLICT (restaurant_id,slug) DO UPDATE SET name=EXCLUDED.name,
           description=EXCLUDED.description,display_order=EXCLUDED.display_order,
           is_active=true,updated_at=CURRENT_TIMESTAMP RETURNING id`,
        [restaurantId, name, slug, description, order],
      );
      categoryIds.set(slug, row.id);
    }

    for (const item of items) {
      const [row] = await manager.query(
        `INSERT INTO menu_items
          (restaurant_id,category_id,name,slug,description,item_type,calories,
           preparation_minutes,is_vegetarian,is_vegan,is_gluten_free,is_spicy,
           is_popular,popularity_score,is_active,archived_at)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,false,$11,$12,$13,true,NULL)
         ON CONFLICT (restaurant_id,slug) DO UPDATE SET category_id=EXCLUDED.category_id,
           name=EXCLUDED.name,description=EXCLUDED.description,item_type=EXCLUDED.item_type,
           calories=EXCLUDED.calories,preparation_minutes=EXCLUDED.preparation_minutes,
           is_vegetarian=EXCLUDED.is_vegetarian,is_vegan=EXCLUDED.is_vegan,
           is_spicy=EXCLUDED.is_spicy,is_popular=EXCLUDED.is_popular,
           popularity_score=EXCLUDED.popularity_score,is_active=true,archived_at=NULL,
           updated_at=CURRENT_TIMESTAMP RETURNING id`,
        [
          restaurantId,
          categoryIds.get(item.category),
          item.name,
          item.slug,
          item.description,
          item.type,
          item.calories,
          item.minutes,
          item.vegetarian,
          item.vegan,
          item.spicy,
          item.popular,
          item.score,
        ],
      );

      for (let index = 0; index < item.sizes.length; index += 1) {
        const [code, name, price, calories] = item.sizes[index];
        await manager.query(
          `INSERT INTO menu_item_sizes
            (menu_item_id,size_code,display_name,base_price_minor,calories,display_order,is_active)
           VALUES ($1,$2,$3,$4,$5,$6,true)
           ON CONFLICT (menu_item_id,size_code) DO UPDATE SET display_name=EXCLUDED.display_name,
             base_price_minor=EXCLUDED.base_price_minor,calories=EXCLUDED.calories,
             display_order=EXCLUDED.display_order,is_active=true,updated_at=CURRENT_TIMESTAMP`,
          [row.id, code, name, price, calories, index + 1],
        );
      }
    }

    console.log(
      `Seeded ${categories.length} categories and ${items.length} menu items for ${restaurants[0].name}.`,
    );
  });
}

seedMenu()
  .catch((error) => {
    console.error(
      'Menu seed failed:',
      error instanceof Error ? error.message : error,
    );
    process.exitCode = 1;
  })
  .finally(async () => {
    if (AppDataSource.isInitialized) await AppDataSource.destroy();
  });
