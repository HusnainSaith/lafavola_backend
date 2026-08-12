import { readFileSync } from 'fs';
import { resolve } from 'path';
import * as ts from 'typescript';

type Json = Record<string, any>;
type MenuItem = {
  name: string;
  price?: string;
  description?: string;
  note?: string;
  attributes?: string[];
};
type MenuSection = {
  id: string;
  title: string;
  eyebrow: string;
  intro?: string;
  items: MenuItem[];
};

class Api {
  constructor(private readonly baseUrl: string) {}
  private token?: string;

  async login(email: string, password: string) {
    const data = await this.request('POST', '/auth/login', {
      email,
      password,
    });
    this.token = data.accessToken;
    if (!this.token) throw new Error('Login response did not include a token');
    return data;
  }

  get(path: string) {
    return this.request('GET', path);
  }
  post(path: string, body?: Json) {
    return this.request('POST', path, body);
  }
  patch(path: string, body?: Json) {
    return this.request('PATCH', path, body);
  }
  delete(path: string, body?: Json) {
    return this.request('DELETE', path, body);
  }
  put(path: string, body?: Json) {
    return this.request('PUT', path, body);
  }

  private async request(method: string, path: string, body?: Json) {
    const response = await fetch(
      `${this.baseUrl.replace(/\/$/, '')}/${path.replace(/^\//, '')}`,
      {
        method,
        headers: {
          Accept: 'application/json',
          ...(body ? { 'Content-Type': 'application/json' } : {}),
          ...(this.token ? { Authorization: `Bearer ${this.token}` } : {}),
          'X-Correlation-Id': `admin-seed-${Date.now()}`,
        },
        body: body ? JSON.stringify(body) : undefined,
      },
    );
    const raw = await response.text();
    const decoded = raw ? JSON.parse(raw) : undefined;
    if (!response.ok) {
      const details = Array.isArray(decoded?.details)
        ? `: ${decoded.details.join('; ')}`
        : '';
      throw new Error(
        `${method} ${path} failed (${response.status}): ${decoded?.message ?? raw}${details}`,
      );
    }
    return unwrap(decoded);
  }
}

export type AdminDemoSeedOptions = {
  baseUrl: string;
  adminEmail: string;
  adminPassword: string;
  demoPassword: string;
  namespace?: string;
};

export async function seedAdminDemo(options: AdminDemoSeedOptions) {
  const { baseUrl, adminEmail, adminPassword, demoPassword } = options;
  const namespace = options.namespace?.trim() || 'lafavola-demo';
  const alwaysOpen = process.env.SEED_ALWAYS_OPEN === 'true';
  const menuSections = loadPublicMenu();
  const admin = new Api(baseUrl);
  await admin.login(adminEmail, adminPassword);

  const restaurant = await admin.get('/restaurants');
  const restaurantId = restaurant.id as string;
  if (!restaurantId) throw new Error('La Favola restaurant is not configured');
  await admin.patch('/restaurants', {
    name: 'La Favola Restaurant',
    slug: 'la-favola-restaurant',
    phone: '+390306180079',
    email: adminEmail,
    addressLine1: 'Via Vittorio Veneto 23/C',
    city: 'Brescia',
    province: 'Brescia',
    postalCode: '25128',
    countryCode: 'IT',
    timezone: 'Europe/Rome',
    deliveryFeeMinor: 150,
    minimumOrderMinor: 1000,
    taxBehavior: 'included',
    isActive: true,
  });
  for (let day = 0; day < 7; day += 1) {
    await admin.put('/restaurants/hours', {
      dayOfWeek: day,
      opensAt: alwaysOpen ? '00:00' : day >= 5 ? '17:30' : '18:00',
      closesAt: alwaysOpen ? '23:59' : '23:00',
      isClosed: false,
    });
  }

  const categories = asList(
    await admin.get(`/categories?restaurantId=${restaurantId}`),
  );
  const categoryBySlug = new Map<string, Json>();
  for (let index = 0; index < menuSections.length; index += 1) {
    const section = menuSections[index];
    const body = {
      restaurantId,
      name: section.title,
      slug: section.id,
      description: section.intro ?? section.eyebrow,
      displayOrder: index,
      isActive: true,
    };
    const existing = categories.find((row) => row.slug === section.id);
    const saved = existing
      ? await admin.patch(`/categories/${existing.id}`, body)
      : await admin.post('/categories', body);
    categoryBySlug.set(section.id, saved);
  }

  const currentMenu = asList(
    await admin.get(`/menu?restaurantId=${restaurantId}&limit=100`),
  );
  let menuCreated = 0;
  let menuUpdated = 0;
  for (const section of menuSections) {
    const category = categoryBySlug.get(section.id)!;
    for (let index = 0; index < section.items.length; index += 1) {
      const item = section.items[index];
      const slug = `${section.id}-${slugify(item.name)}`;
      const body = {
        restaurantId,
        categoryId: category.id,
        name: item.name,
        slug,
        description:
          [item.description, item.note].filter(Boolean).join(' · ') ||
          undefined,
        itemType: menuItemType(section.id),
        isVegetarian: item.attributes?.includes('vegetarian') ?? false,
        isVegan: false,
        isGlutenFree: !(item.attributes?.includes('gluten') ?? false),
        isSpicy: item.attributes?.includes('spicy') ?? false,
        isPopular:
          section.id === 'pizze' &&
          ['Margherita', 'Diavola', 'Mortazza'].includes(item.name),
        isActive: true,
      };
      const existing = currentMenu.find((row) => row.slug === slug);
      if (existing) {
        await admin.patch(`/menu/${existing.id}`, body);
        menuUpdated += 1;
      } else {
        await admin.post('/menu', {
          ...body,
          sizes: [
            {
              sizeCode: section.id === 'pizze' ? 'medium' : 'single',
              displayName: section.id === 'pizze' ? 'Media' : 'Porzione',
              basePriceMinor: priceMinor(item.price),
              displayOrder: index,
              isActive: true,
            },
          ],
        });
        menuCreated += 1;
      }
    }
  }

  const ingredientFixtures = [
    ['Pomodoro', 'pomodoro', true, true, true, []],
    ['Fiordilatte', 'fiordilatte', true, false, true, ['lactose']],
    ['Burrata', 'burrata', true, false, true, ['lactose']],
    ['Provola', 'provola', true, false, true, ['lactose']],
    ['Prosciutto cotto', 'prosciutto-cotto', false, false, true, []],
    ['Salame piccante', 'salame-piccante', false, false, true, []],
    ['Funghi', 'funghi', true, true, true, []],
    ['Olive', 'olive', true, true, true, []],
    ['Tonno', 'tonno', false, false, true, ['fish']],
    ['Cipolla rossa', 'cipolla-rossa', true, true, true, []],
  ] as const;
  const ingredients = asList(
    await admin.get(`/ingredients?restaurantId=${restaurantId}`),
  );
  const ingredientBySlug = new Map<string, Json>();
  for (const fixture of ingredientFixtures) {
    const [name, slug, vegetarian, vegan, glutenFree, allergens] = fixture;
    const body = {
      restaurantId,
      name,
      slug,
      extraPriceMinor: 100,
      isVegetarian: vegetarian,
      isVegan: vegan,
      isGlutenFree: glutenFree,
      containsAllergens: allergens,
      isActive: true,
    };
    const existing = ingredients.find((row) => row.slug === slug);
    const saved = existing
      ? await admin.patch(`/ingredients/${existing.id}`, body)
      : await admin.post('/ingredients', body);
    ingredientBySlug.set(slug, saved);
  }

  const groups = asList(
    await admin.get(`/option-groups?restaurantId=${restaurantId}`),
  );
  let extras = groups.find((row) => row.code === 'pizza-extras');
  if (!extras) {
    extras = await admin.post('/option-groups', {
      restaurantId,
      name: 'Ingredienti extra',
      code: 'pizza-extras',
      optionType: 'extra',
      minSelect: 0,
      maxSelect: 6,
      allowQuantity: true,
      isActive: true,
    });
  }
  extras = await admin.get(`/option-groups/${extras.id}`);
  const choices = asList(extras.choices);
  for (const slug of ['fiordilatte', 'funghi', 'olive', 'salame-piccante']) {
    const ingredient = ingredientBySlug.get(slug)!;
    const code = `extra-${slug}`;
    if (!choices.some((choice) => choice.code === code)) {
      await admin.post(`/option-groups/${extras.id}/choices`, {
        ingredientId: ingredient.id,
        name: ingredient.name,
        code,
        priceAdjustmentMinor: 100,
        isActive: true,
      });
    }
  }

  await upsertFaq(
    admin,
    restaurantId,
    'Come posso ordinare?',
    'Puoi ordinare dal tablet o telefonando direttamente a La Favola.',
    1,
  );
  await upsertFaq(
    admin,
    restaurantId,
    'Quali sono gli orari?',
    'Siamo aperti ogni sera; consulta la sezione Ristorante per gli orari aggiornati.',
    2,
  );
  await upsertFaq(
    admin,
    restaurantId,
    'È disponibile la consegna?',
    'Sì, la consegna parte da €1,50 con ordine minimo di €10.',
    3,
  );

  const startsAt = new Date(Date.now() - 86_400_000).toISOString();
  const endsAt = new Date(Date.now() + 365 * 86_400_000).toISOString();
  const promotions = asList(await admin.get('/promotions'));
  let promotion = promotions.find((row) => row.name === 'Benvenuto La Favola');
  if (!promotion) {
    promotion = await admin.post('/promotions', {
      restaurantId,
      name: 'Benvenuto La Favola',
      description: 'Promozione dimostrativa per il collaudo amministrativo.',
      promotionType: 'percentage',
      discountValue: 10,
      minOrderMinor: 1000,
      maxDiscountMinor: 500,
      startsAt,
      endsAt,
      perCustomerLimit: 1,
      priority: 10,
      isAutomatic: false,
      isActive: true,
    });
  }
  const coupons = asList(await admin.get('/coupons'));
  if (!coupons.some((row) => row.code === 'LAFAVOLA10')) {
    await admin.post('/coupons', {
      restaurantId,
      promotionId: promotion.id,
      code: 'LAFAVOLA10',
      description: 'Coupon dimostrativo admin',
      discountType: 'percentage',
      discountValue: 10,
      minOrderMinor: 1000,
      maxDiscountMinor: 500,
      startsAt,
      expiresAt: endsAt,
      totalUsageLimit: 100,
      perCustomerLimit: 1,
      isActive: true,
    });
  }

  const driverEmail = `${namespace}-driver@lafavola.example`;
  let drivers = asList(await admin.get('/deliveries/drivers'));
  let driver = drivers.find(
    (row) => row.email === driverEmail || row.user?.email === driverEmail,
  );
  if (!driver) {
    driver = await admin.post('/deliveries/drivers', {
      fullName: 'Mario Driver Demo',
      email: driverEmail,
      phone: '+393920000001',
      temporaryPassword: demoPassword,
      employeeCode: 'LF-DRV-DEMO',
    });
  }
  driver = {
    ...driver,
    userId: driver.userId ?? driver.user?.id,
    email: driver.email ?? driver.user?.email,
  };

  const roles = asList(await admin.get('/roles'));
  const clientRole = roles.find((role) => role.name === 'client');
  if (!clientRole) throw new Error('Client role not found');
  const customerEmail = `${namespace}-customer@lafavola.example`;
  const users = asList(await admin.get('/users'));
  const existingCustomer = users.find((user) => user.email === customerEmail);
  if (existingCustomer) {
    await admin.patch(`/users/${existingCustomer.id}`, {
      password: demoPassword,
      roleId: clientRole.id,
      status: 'active',
    });
  } else {
    await admin.post('/users', {
      fullName: 'Cliente Demo La Favola',
      email: customerEmail,
      password: demoPassword,
      roleId: clientRole.id,
      status: 'active',
    });
  }

  const catalog = await admin.get('/admin/pos/catalog');
  const catalogItems = asList(catalog.items ?? catalog.menuItems ?? catalog);
  const margherita = catalogItems.find((item) => item.name === 'Margherita');
  const margheritaSize = asList(margherita?.sizes).find(
    (size) => size.isActive !== false,
  );
  if (!margherita || !margheritaSize)
    throw new Error('Margherita POS fixture was not available');
  const posOrder = await admin.post('/admin/pos/orders', {
    orderType: 'takeaway',
    customerName: 'Cliente asporto demo',
    customerPhone: '+393920000002',
    customerNote: 'Creato dal seed API-only',
    paymentMethod: 'cash',
    idempotencyKey: `${namespace}-pos-takeaway-v1`,
    items: [
      { menuItemId: margherita.id, sizeId: margheritaSize.id, quantity: 2 },
    ],
  });
  const posOrderId = posOrder.order?.id ?? posOrder.id;
  await admin.post(`/admin/pos/orders/${posOrderId}/collect`, {
    orderId: posOrderId,
    paymentMethodType: 'cash',
    idempotencyKey: `${namespace}-pos-payment-v1`,
  });
  await admin.post('/admin/pos/orders', {
    orderType: 'dine_in',
    tableLabel: 'Tavolo Demo 4',
    customerName: 'Cliente sala demo',
    paymentMethod: 'cash',
    idempotencyKey: `${namespace}-pos-dine-in-v1`,
    items: [
      { menuItemId: margherita.id, sizeId: margheritaSize.id, quantity: 1 },
    ],
  });

  const customer = new Api(baseUrl);
  await customer.login(customerEmail, demoPassword);
  const addresses = asList(await customer.get('/customers/me/addresses'));
  let address = addresses.find((row) => row.label === 'Seed API');
  if (!address) {
    address = await customer.post('/customers/me/addresses', {
      label: 'Seed API',
      recipientName: 'Cliente Demo La Favola',
      phone: '+393920000002',
      addressLine1: 'Via San Faustino 10',
      city: 'Brescia',
      province: 'Brescia',
      postalCode: '25122',
      countryCode: 'IT',
      isDefault: true,
    });
  }
  const history = asList(await customer.get('/orders/me?page=1&limit=100'));
  let deliveryOrder = history.find(
    (order) => order.customerNote === 'LF-DEMO-SEED',
  );
  if (!deliveryOrder) {
    await customer.delete(`/cart?restaurantId=${restaurantId}`);
    await customer.post(`/cart/items?restaurantId=${restaurantId}`, {
      menuItemId: margherita.id,
      menuItemSizeId: margheritaSize.id,
      quantity: 2,
    });
    const currentCart = await customer.get(
      `/cart?restaurantId=${restaurantId}`,
    );
    const checkout = await customer.post('/checkout', {
      cartId: currentCart.cart?.id,
      orderType: 'delivery',
      deliveryAddressId: address.id,
      paymentMethod: 'cash',
      customerNote: 'LF-DEMO-SEED',
      deliveryInstructions: 'Suonare al citofono Demo',
      scheduledFor: nextSeedFulfilmentTime(),
      idempotencyKey: `${namespace}-delivery-checkout-v1`,
    });
    deliveryOrder = checkout.order ?? {
      ...checkout,
      id: checkout.orderId,
      customerNote: 'LF-DEMO-SEED',
    };
  }
  if (!deliveryOrder.id)
    throw new Error('Delivery checkout did not return an order ID');
  const orderProgression = [
    'placed',
    'accepted',
    'preparing',
    'baking',
    'packing',
    'ready',
  ];
  const currentProgress = orderProgression.indexOf(
    String(deliveryOrder.status),
  );
  if (currentProgress >= 0) {
    for (const status of orderProgression.slice(currentProgress + 1)) {
      deliveryOrder = await admin.patch(
        `/orders/admin/${deliveryOrder.id}/status`,
        { status, note: 'Avanzamento seed API-only' },
      );
    }
  }
  if (['ready', 'driver_assigned'].includes(String(deliveryOrder.status))) {
    await admin.post(`/deliveries/orders/${deliveryOrder.id}/assign`, {
      driverUserId: driver.userId,
    });
  }

  const tickets = asList(await customer.get('/support/tickets'));
  let ticket = tickets.find((row) => row.subject === 'Ordine demo API');
  if (!ticket) {
    ticket = await customer.post('/support/tickets', {
      orderId: deliveryOrder.id,
      category: 'delivery_issue',
      subject: 'Ordine demo API',
      priority: 'normal',
      message: 'Messaggio creato tramite il flusso di seed HTTP.',
    });
  }
  if (!ticket.assignedStaffUserId) {
    ticket = await admin.post(`/support/agent/tickets/${ticket.id}/claim`);
  }
  const messages = asList(
    await admin.get(`/support/tickets/${ticket.id}/messages`),
  );
  if (
    !messages.some((message) => message.body === 'Risposta demo dello staff.')
  ) {
    await admin.post(`/support/tickets/${ticket.id}/messages`, {
      body: 'Risposta demo dello staff.',
    });
  }

  return {
    success: true,
    transport: 'authenticated HTTP only',
    restaurantId,
    categories: menuSections.length,
    menuItems: menuSections.reduce(
      (sum, section) => sum + section.items.length,
      0,
    ),
    menuCreated,
    menuUpdated,
    ingredients: ingredientFixtures.length,
    drivers: 1,
    customers: 1,
    posOrders: 2,
    deliveryOrders: 1,
    supportTickets: 1,
    providerGated: [
      'media upload requires S3',
      'SumUp refund requires captured provider payment',
    ],
  };
}

function nextSeedFulfilmentTime(): string {
  const formatter = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Europe/Rome',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  });
  const candidate = new Date();
  for (let step = 0; step < 14 * 24 * 60; step += 1) {
    candidate.setUTCMinutes(candidate.getUTCMinutes() + 1);
    const parts = Object.fromEntries(
      formatter
        .formatToParts(candidate)
        .filter((part) => part.type !== 'literal')
        .map((part) => [part.type, part.value]),
    );
    if (parts.hour === '20' && parts.minute === '00') {
      return candidate.toISOString();
    }
  }
  throw new Error('No valid demo fulfilment slot found within 14 days');
}
async function upsertFaq(
  api: Api,
  restaurantId: string,
  question: string,
  answer: string,
  displayOrder: number,
) {
  const faqs = asList(await api.get('/faq'));
  const existing = faqs.find((row) => row.question === question);
  const body = { restaurantId, question, answer, displayOrder, isActive: true };
  return existing
    ? api.patch(`/faq/${existing.id}`, body)
    : api.post('/faq', body);
}

function loadPublicMenu(): MenuSection[] {
  const sourcePath = resolve(process.cwd(), '../site/src/data/menu.ts');
  const source = readFileSync(sourcePath, 'utf8');
  const output = ts.transpileModule(source, {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2022,
    },
  }).outputText;
  const module = { exports: {} as Json };
  new Function('exports', 'module', output)(module.exports, module);
  return module.exports.menuSections as MenuSection[];
}

function unwrap(value: any): any {
  let current = value;
  while (
    current &&
    typeof current === 'object' &&
    current.success === true &&
    Object.prototype.hasOwnProperty.call(current, 'data')
  ) {
    current = current.data;
  }
  return current;
}

function asList(value: any): Json[] {
  const candidate = value?.items ?? value?.data ?? value?.results ?? value;
  return Array.isArray(candidate) ? candidate : [];
}

function required(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`${name} is required`);
  return value;
}

function menuItemType(section: string) {
  if (section === 'pizze' || section === 'panini') return 'modifiable';
  if (section === 'sfizi') return 'side';
  if (section === 'bevande') return 'drink';
  return 'other';
}

function priceMinor(raw?: string): number {
  if (!raw) return 0;
  const match = raw.replace(',', '.').match(/\d+(?:\.\d+)?/);
  return match ? Math.round(Number(match[0]) * 100) : 0;
}

function slugify(value: string) {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
}

if (require.main === module) {
  void seedAdminDemo({
    baseUrl: required('SEED_API_BASE_URL'),
    adminEmail: required('SEED_ADMIN_EMAIL'),
    adminPassword: required('SEED_ADMIN_PASSWORD'),
    demoPassword: required('SEED_DEMO_PASSWORD'),
    namespace: process.env.SEED_NAMESPACE,
  })
    .then((summary) => console.log(JSON.stringify(summary, null, 2)))
    .catch((error) => {
      console.error(error instanceof Error ? error.message : error);
      process.exitCode = 1;
    });
}
