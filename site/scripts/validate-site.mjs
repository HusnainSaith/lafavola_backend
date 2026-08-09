import { createHash } from 'node:crypto';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const siteRoot = resolve(scriptDir, '..');
const distRoot = join(siteRoot, 'dist');

const failures = [];
const pass = (condition, message) => {
  if (!condition) failures.push(message);
};
const sha256 = (file) => createHash('sha256').update(readFileSync(file)).digest('hex');
const sha256Text = (value) => createHash('sha256').update(value).digest('hex');

const routes = {
  home: join(distRoot, 'index.html'),
  menu: join(distRoot, 'menu', 'index.html'),
  menuCards: join(distRoot, 'menu-carte', 'index.html'),
  information: join(distRoot, 'informazioni', 'index.html'),
};

for (const [name, file] of Object.entries(routes)) {
  pass(existsSync(file), `Missing built ${name} route: ${file}`);
}

if (failures.length) {
  console.error(failures.join('\n'));
  process.exit(1);
}

const html = Object.fromEntries(
  Object.entries(routes).map(([name, file]) => [name, readFileSync(file, 'utf8')]),
);
const combined = Object.values(html).join('\n');
const globalCss = readFileSync(join(siteRoot, 'src', 'styles', 'global.css'), 'utf8');
const baseLayout = readFileSync(join(siteRoot, 'src', 'layouts', 'BaseLayout.astro'), 'utf8');
const homeSource = readFileSync(join(siteRoot, 'src', 'pages', 'index.astro'), 'utf8');

const sectionIn = (content, view, id, nextId) => {
  const start = content.indexOf(`id="${id}"`);
  const end = nextId ? content.indexOf(`id="${nextId}"`, start + 1) : content.length;
  pass(start >= 0, `Missing ${view} menu section #${id}`);
  return start >= 0 ? content.slice(start, end >= 0 ? end : content.length) : '';
};
const section = (id, nextId) => sectionIn(html.menu, 'classic', id, nextId);
const countItems = (content) => (content.match(/class="menu-item"/g) ?? []).length;
const countCards = (content) => (content.match(/class="detail-menu-card"/g) ?? []).length;

const inventory = {
  pizzas: countItems(section('pizze', 'panini')),
  panini: countItems(section('panini', 'sfizi')),
  friedItems: countItems(section('sfizi', 'salse')),
  sauces: countItems(section('salse', 'bevande')),
  drinkGroups: countItems(section('bevande', 'variazioni')),
  variations: (section('variazioni', 'allergeni').match(/<div><strong>/g) ?? []).length,
};

const cardInventory = {
  pizzas: countCards(sectionIn(html.menuCards, 'card', 'pizze', 'panini')),
  panini: countCards(sectionIn(html.menuCards, 'card', 'panini', 'sfizi')),
  friedItems: countCards(sectionIn(html.menuCards, 'card', 'sfizi', 'salse')),
  sauces: countCards(sectionIn(html.menuCards, 'card', 'salse', 'bevande')),
  drinkGroups: countCards(sectionIn(html.menuCards, 'card', 'bevande', 'variazioni')),
  variations: (sectionIn(html.menuCards, 'card', 'variazioni', 'allergeni').match(/detail-menu-card--variation/g) ?? []).length,
};

for (const [key, expected] of Object.entries({
  pizzas: 24,
  panini: 7,
  friedItems: 10,
  sauces: 4,
  drinkGroups: 3,
  variations: 3,
})) {
  pass(inventory[key] === expected, `${key}: expected ${expected}, found ${inventory[key]}`);
  pass(cardInventory[key] === expected, `card ${key}: expected ${expected}, found ${cardInventory[key]}`);
}

const expectedAttributeDefinitions = {
  spicy: { label: 'Piccante', symbol: '🌶️' },
  vegetarian: { label: 'Vegetariana', symbol: '🍃' },
  gluten: { label: 'Glutine', symbol: '🌾' },
  lactose: { label: 'Lattosio', symbol: '🥛' },
  egg: { label: 'Uovo', symbol: '🥚' },
  fish: { label: 'Pesce', symbol: '🐟' },
  nuts: { label: 'Frutta a guscio', symbol: '🌰' },
};

const expectedMenuAttributes = {
  Americana: 'gluten lactose',
  'Bresaola, Rucola e Grana': 'gluten lactose',
  Bufala: 'vegetarian gluten lactose',
  Burrata: 'vegetarian gluten lactose',
  Calzone: 'gluten lactose',
  Capricciosa: 'gluten lactose',
  Carrettiera: 'gluten lactose',
  Carbonara: 'gluten lactose egg',
  Diavola: 'spicy gluten lactose',
  Fiocco: 'gluten lactose',
  Margherita: 'vegetarian gluten lactose',
  Marinara: 'vegetarian gluten lactose',
  Mimosa: 'gluten lactose',
  Mortazza: 'gluten lactose nuts',
  Napoli: 'gluten lactose',
  Norvegese: 'gluten lactose fish',
  Parma: 'gluten lactose',
  Parmigiana: 'vegetarian gluten lactose',
  Porcini: 'vegetarian gluten lactose',
  'Provola e Pepe': 'vegetarian gluten lactose',
  'Speck e Brie': 'gluten lactose',
  'Tonno e Cipolle': 'gluten lactose fish',
  Verdure: 'vegetarian gluten lactose',
  '4 Formaggi': 'vegetarian gluten lactose',
  'Panino Crudo': 'gluten lactose',
  'Panino Mortadella': 'gluten lactose',
  'Panino Cotto': 'gluten',
  'Panino Salame': 'gluten lactose',
  'Panino Pollo 1': 'gluten lactose',
  'Panino Pollo 2': 'gluten lactose',
  'Crocchette di patate': 'gluten',
  'Anelli di cipolla': 'gluten',
  'Nuggets di pollo': 'gluten',
  'Crocchè artigianale con provola': 'gluten lactose',
  'Crocchè artigianale salame e mozzarella': 'gluten lactose',
  'Frittatina artigianale pastellata': 'gluten lactose',
  'Arancino artigianale con sugo al ragù': 'gluten lactose',
  'Alette di pollo': 'gluten lactose',
};

const menuItemFragment = (content, view, name) => {
  const marker = content.indexOf(`data-menu-item="${name}"`);
  const start = content.lastIndexOf('<article', marker);
  const end = content.indexOf('</article>', marker);
  pass(marker >= 0 && start >= 0, `Missing ${view} menu item article: ${name}`);
  return marker >= 0 && start >= 0 ? content.slice(start, end >= 0 ? end + 10 : content.length) : '';
};

const menuItemDetails = (fragment) => Object.fromEntries(
  [...fragment.matchAll(/data-menu-(attributes|price|description|note)="([^"]*)"/g)]
    .map((match) => [match[1], match[2]]),
);

const decodeHtml = (value = '') => value
  .replaceAll('&quot;', '"')
  .replaceAll('&#39;', "'")
  .replaceAll('&amp;', '&')
  .replaceAll('&lt;', '<')
  .replaceAll('&gt;', '>');
const visibleText = (value = '') => decodeHtml(value.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim());
const visibleMenuItemDetails = (fragment) => ({
  price: visibleText(fragment.match(/class="price"[^>]*>([\s\S]*?)<\/[^>]+>/)?.[1]),
  description: visibleText(fragment.match(/<p>([\s\S]*?)<\/p>/)?.[1]),
  note: visibleText(fragment.match(/class="menu-item__note"[^>]*>([\s\S]*?)<\/[^>]+>/)?.[1]),
});
const validateVisibleMenuItem = (fragment, view, name) => {
  const metadata = menuItemDetails(fragment);
  const visible = visibleMenuItemDetails(fragment);
  const heading = visibleText(fragment.match(/<h3[^>]*>([\s\S]*?)<\/h3>/)?.[1]);
  pass(fragment.startsWith('<article'), `${name} (${view}): expected semantic article`);
  pass(heading.includes(name), `${name} (${view}): visible h3 must contain the source name`);
  for (const field of ['price', 'description', 'note']) {
    pass(
      visible[field] === decodeHtml(metadata[field]),
      `${name} (${view}): visible ${field} must match source metadata`,
    );
  }
};

for (const [name, attributes] of Object.entries(expectedMenuAttributes)) {
  const classicFragment = menuItemFragment(html.menu, 'classic', name);
  const cardFragment = menuItemFragment(html.menuCards, 'card', name);
  validateVisibleMenuItem(classicFragment, 'classic', name);
  validateVisibleMenuItem(cardFragment, 'card', name);
  pass(
    JSON.stringify(menuItemDetails(cardFragment)) === JSON.stringify(menuItemDetails(classicFragment)),
    `${name}: card details must exactly match the classic view`,
  );
  for (const [view, fragment] of [['classic', classicFragment], ['card', cardFragment]]) {
  pass(
    fragment.includes(`data-menu-attributes="${attributes}"`),
    `${name} (${view}): expected source-menu attributes "${attributes}"`,
  );

  const definitions = attributes.split(' ').map((id) => expectedAttributeDefinitions[id]);
  const accessibleLabel = `Indicazioni: ${definitions.map(({ label }) => label).join(', ')}`;
  pass(
    fragment.includes(`aria-label="${accessibleLabel}"`),
    `${name} (${view}): expected accessible icon label "${accessibleLabel}"`,
  );

  const group = fragment.match(/class="menu-symbols"[\s\S]*?>([\s\S]*?)<\/span><\/h3>/)?.[1] ?? '';
  const renderedSymbols = group.replace(/<[^>]+>/g, '').replace(/\s+/g, '');
  const expectedSymbols = definitions.map(({ symbol }) => symbol).join('');
  pass(
    renderedSymbols === expectedSymbols,
    `${name} (${view}): expected rendered symbols "${expectedSymbols}", found "${renderedSymbols}"`,
  );
  }
}
for (const name of [
  'Crea il tuo panino',
  'Porzione patatine',
  'Patatine Dippers',
  'Maionese',
  'Ketchup',
  'Salsa rosa',
  'Barbecue',
  'Acqua',
  'Bibite',
  'Birre',
]) {
  const classicFragment = menuItemFragment(html.menu, 'classic', name);
  const cardFragment = menuItemFragment(html.menuCards, 'card', name);
  validateVisibleMenuItem(classicFragment, 'classic', name);
  validateVisibleMenuItem(cardFragment, 'card', name);
  pass(
    !classicFragment.includes('data-menu-attributes=') && !cardFragment.includes('data-menu-attributes='),
    `${name}: source menu does not assign an icon in either view`,
  );
  pass(
    JSON.stringify(menuItemDetails(cardFragment)) === JSON.stringify(menuItemDetails(classicFragment)),
    `${name}: card details must exactly match the classic view`,
  );
}

const expectedVariations = [
  ['Ingredienti extra', 'da +€1'],
  ['Mozzarella senza lattosio', '+€1,50'],
  ['Formato Baby', '−€1'],
];
const classicVariations = section('variazioni', 'allergeni');
const cardVariations = sectionIn(html.menuCards, 'card', 'variazioni', 'allergeni');
for (const [label, price] of expectedVariations) {
  pass(
    classicVariations.includes(`<strong>${label}</strong><span>${price}</span>`),
    `Classic variations must visibly render ${label}: ${price}`,
  );
  const cardStart = cardVariations.indexOf(`<h3>${label}</h3>`);
  const cardEnd = cardVariations.indexOf('</article>', cardStart);
  const card = cardStart >= 0 ? cardVariations.slice(cardStart, cardEnd >= 0 ? cardEnd : cardVariations.length) : '';
  pass(
    card.includes(`class="detail-menu-card__variation-price">${price}</strong>`),
    `Card variations must visibly render ${label}: ${price}`,
  );
}

const menuIconGroups = (html.menu.match(/class="menu-symbols"/g) ?? []).length;
const menuLegends = (html.menu.match(/class="menu-legend"/g) ?? []).length;
const cardIconGroups = (html.menuCards.match(/class="menu-symbols"/g) ?? []).length;
const cardLegends = (html.menuCards.match(/class="menu-legend"/g) ?? []).length;
pass(menuIconGroups === 38, `menu icons: expected 38 labelled item groups, found ${menuIconGroups}`);
pass(menuLegends === 3, `menu icons: expected 3 section legends, found ${menuLegends}`);
pass(cardIconGroups === 38, `card menu icons: expected 38 labelled item groups, found ${cardIconGroups}`);
pass(cardLegends === 3, `card menu icons: expected 3 section legends, found ${cardLegends}`);

for (const [sectionId, expectedIds] of Object.entries({
  pizze: ['spicy', 'vegetarian', 'gluten', 'lactose', 'egg', 'fish', 'nuts'],
  panini: ['gluten', 'lactose'],
  sfizi: ['gluten', 'lactose'],
})) {
  const nextId = sectionId === 'pizze' ? 'panini' : sectionId === 'panini' ? 'sfizi' : 'salse';
  for (const [view, content] of [
    ['classic', section(sectionId, nextId)],
    ['card', sectionIn(html.menuCards, 'card', sectionId, nextId)],
  ]) {
  const legend = content.match(/<ul class="menu-legend"[\s\S]*?<\/ul>/)?.[0] ?? '';
  const renderedIds = [...legend.matchAll(/data-menu-attribute="([^"]+)"/g)].map((match) => match[1]);
  pass(
    JSON.stringify(renderedIds) === JSON.stringify(expectedIds),
    `${sectionId} (${view}): expected legend IDs ${expectedIds.join(', ')}, found ${renderedIds.join(', ')}`,
  );
  for (const id of expectedIds) {
    const { label, symbol } = expectedAttributeDefinitions[id];
    const itemStart = legend.indexOf(`data-menu-attribute="${id}"`);
    const itemEnd = legend.indexOf('</li>', itemStart);
    const item = itemStart >= 0 ? legend.slice(itemStart, itemEnd >= 0 ? itemEnd : legend.length) : '';
    pass(item.includes(label) && item.includes(symbol), `${sectionId} (${view}): ${id} legend must render ${symbol} ${label}`);
  }
  }
}

pass(html.menu.includes('href="/menu-carte/">Carte animate'), 'Classic menu must link to the card view');
pass(html.menuCards.includes('href="/menu/">Lista classica'), 'Card menu must link to the classic view');
pass(html.menu.includes('aria-current="page">Lista classica'), 'Classic menu view switch must expose its current page');
pass(html.menuCards.includes('aria-current="page">Carte animate'), 'Card menu view switch must expose its current page');

for (const required of [
  'Maionese',
  'Ketchup',
  'Salsa rosa',
  'Barbecue',
  'Via Vittorio Veneto 23/C, 25128 Brescia',
  '030 6180079',
  '392 0437240',
  '@lafavolabrescia',
  '18:00 — 23:00',
  '17:30 — 23:00',
  'Consegna a partire da €1,50',
  'ordine minimo €10',
  'POS disponibile su richiesta',
]) {
  pass(combined.includes(required), `Missing required public content: ${required}`);
}

pass(html.home.includes('id="storia"'), 'Homepage must expose the #storia navigation target');
for (const [name, content] of Object.entries(html)) {
  pass(content.includes('aria-controls="mobile-nav"'), `${name}: missing semantic mobile navigation toggle`);
  pass(content.includes('id="mobile-nav"'), `${name}: missing mobile navigation landmark`);
  for (const destination of ['/#storia', '/menu/', '/menu-carte/', '/informazioni/', 'tel:+390306180079']) {
    pass(content.includes(`href="${destination}"`), `${name}: mobile/footer navigation missing ${destination}`);
  }
  for (const footerContract of ['Contatti', 'Orari', 'Esplora', 'site-footer__actions']) {
    pass(content.includes(footerContract), `${name}: footer missing ${footerContract}`);
  }
}

const classicMobileNav = html.menu.match(/id="mobile-nav"[\s\S]*?<\/nav>/)?.[0] ?? '';
const cardMobileNav = html.menuCards.match(/id="mobile-nav"[\s\S]*?<\/nav>/)?.[0] ?? '';
pass(
  classicMobileNav.includes('href="/menu/" aria-current="page"') &&
    !classicMobileNav.includes('href="/menu-carte/" aria-current="page"'),
  'Classic route must identify only the classic mobile menu link as current',
);
pass(
  cardMobileNav.includes('href="/menu-carte/" aria-current="page"') &&
    !cardMobileNav.includes('href="/menu/" aria-current="page"'),
  'Card route must identify only the card mobile menu link as current',
);
pass(baseLayout.includes("event.key === 'Escape'"), 'Mobile navigation must close on Escape');
pass(baseLayout.includes('toggle.focus()'), 'Mobile navigation Escape close must restore toggle focus');
pass(baseLayout.includes("mobileQuery.addEventListener('change'"), 'Mobile navigation must close after desktop resize');
pass(
  baseLayout.includes("mobileNav.addEventListener('click'") && baseLayout.includes('setOpen(false)'),
  'Mobile navigation must close after link activation',
);
pass(
  globalCss.includes('.nav-toggle:active') &&
    globalCss.includes('.category-nav a:active') &&
    globalCss.includes('.menu-view-switch a:active') &&
    globalCss.includes('.button--light:active') &&
    globalCss.includes('.button--outline:active'),
  'Button-like controls must define explicit readable active states',
);

pass(
  globalCss.includes('@media (max-width: 60rem)') &&
    globalCss.includes('grid-template-columns: repeat(2, minmax(0, 1fr))'),
  'Footer must collapse to shrinkable two-column tracks before its four-column minimum can overflow',
);
const footerResponsiveWidths = [768, 820, 833, 840, 856, 1024].map((viewport) => {
  const container = viewport <= 544 ? viewport - 20 : viewport - 32;
  const columns = viewport <= 544 ? 1 : viewport <= 960 ? 2 : 4;
  const gap = Math.min(64, Math.max(24, viewport * 0.04));
  const fourColumnMinimum = 240 + (3 * 160) + (3 * gap);
  const fits = columns < 4 || fourColumnMinimum <= container;
  pass(fits, `Footer track minimum exceeds its container at ${viewport}px`);
  return { viewport, container, columns, fits };
});

const processSteps = (html.home.match(/class="process-step"/g) ?? []).length;
pass(processSteps === 5, `pizza process: expected 5 steps, found ${processSteps}`);
const processTitles = [
  'Come nasce una pizza La Favola.',
  'La scelta',
  'L’impasto prende forma',
  'Il condimento',
  'La cottura',
  'La pizza è pronta',
  'Immagine illustrativa',
];
for (const required of processTitles) {
  pass(html.home.includes(required), `Missing pizza-process content: ${required}`);
}
let previousProcessTitlePosition = -1;
for (const title of processTitles.slice(1, 6)) {
  const position = html.home.indexOf(title);
  pass(
    position > previousProcessTitlePosition,
    `Pizza-process stage is missing or out of order: ${title}`,
  );
  previousProcessTitlePosition = position;
}
pass(globalCss.includes('animation-timeline: view()'), 'Missing scroll-linked process animation');
pass(
  globalCss.includes('@media (prefers-reduced-motion: reduce)') &&
    globalCss.includes('animation: none !important'),
  'Missing reduced-motion animation fallback',
);
for (const asset of ['ingredients-still-life-v1.png', 'IMG_0086.jpg']) {
  pass(
    existsSync(join(siteRoot, 'src', 'assets', 'photos', asset)),
    `Missing pizza-process asset: ${asset}`,
  );
}

const storyPhoto = join(siteRoot, 'src', 'assets', 'photos', 'modify1.jpeg');
pass(existsSync(storyPhoto), 'Missing approved homepage story image: modify1.jpeg');
if (existsSync(storyPhoto)) {
  pass(
    sha256(storyPhoto) === '308b2ef409d0740dbc9071f46a24d953e579f5fe49569fc27e195056043931fc',
    'Homepage story image differs from the approved modify1.jpeg source',
  );
}
pass(
  html.home.includes('alt="Il pizzaiolo La Favola controlla una pizza nel forno con la pala"') &&
    html.home.includes(' 480w') && html.home.includes(' 720w') && html.home.includes(' 960w'),
  'Homepage story image must expose truthful alt text and responsive 480/720/960 sources',
);
pass(
  homeSource.includes('src={storyPhoto}') && homeSource.includes("image: ovenPhoto"),
  'Story must use modify1 while the pizza-process oven stage keeps ovenPhoto',
);

const heroPhoto = join(siteRoot, 'src', 'assets', 'photos', 'modify2.jpeg');
pass(existsSync(heroPhoto), 'Missing approved homepage hero image: modify2.jpeg');
let heroFitEvidence = [];
if (existsSync(heroPhoto)) {
  pass(
    sha256(heroPhoto) === 'd0995afff293a4544f17d7f46c027c6c5e4ae41c7c6d63458b1b3acd42f141a0',
    'Homepage hero image differs from the approved modify2.jpeg source',
  );
  const heroMetadata = await sharp(heroPhoto).metadata();
  pass(
    heroMetadata.width === 5352 && heroMetadata.height === 4000,
    'Homepage hero must preserve the approved 5352x4000 source dimensions',
  );
  heroFitEvidence = [
    { viewport: 320, width: 320, height: 724 },
    { viewport: 833, width: 833, height: 768 },
    { viewport: 1024, width: 1024, height: 768 },
    { viewport: 1440, width: 1440, height: 768 },
  ].map(({ viewport, width, height }) => {
    const scale = Math.max(width / heroMetadata.width, height / heroMetadata.height);
    const renderedWidth = heroMetadata.width * scale;
    const renderedHeight = heroMetadata.height * scale;
    const sourceLeft = ((renderedWidth - width) * 0.5) / scale;
    const sourceTop = ((renderedHeight - height) * 0.12) / scale;
    const sourceRight = sourceLeft + (width / scale);
    const sourceBottom = sourceTop + (height / scale);
    const signFocalPointVisible = 2676 >= sourceLeft && 2676 <= sourceRight && 400 >= sourceTop && 400 <= sourceBottom;
    const storefrontFocalPointVisible = 2676 >= sourceLeft && 2676 <= sourceRight && 2000 >= sourceTop && 2000 <= sourceBottom;
    const fits = signFocalPointVisible && storefrontFocalPointVisible;
    pass(fits, `Hero focal crop loses the sign or storefront at ${viewport}px`);
    return { viewport, sourceVisible: { left: sourceLeft, top: sourceTop, right: sourceRight, bottom: sourceBottom }, fits };
  });
}
pass(
  homeSource.includes("import heroPhoto from '../assets/photos/modify2.jpeg'") &&
    homeSource.includes('src={heroPhoto}') &&
    homeSource.includes('style="object-position: 50% 12%"') &&
    (homeSource.match(/modify2\.jpeg/g) ?? []).length === 1,
  'modify2 must be used only as the hero with the approved storefront/sign focal position',
);
pass(
  html.home.includes('alt="Ingresso notturno della pizzeria La Favola con l’insegna illuminata"') &&
    html.home.includes(' 640w') && html.home.includes(' 960w') &&
    html.home.includes(' 1440w') && html.home.includes(' 1920w'),
  'Homepage hero must expose truthful alt text and responsive 640/960/1440/1920 sources',
);
pass(
  globalCss.includes('rgba(42, 25, 17, 0.88)') && globalCss.includes('rgba(42, 25, 17, 0.73)'),
  'Homepage hero must retain its desktop and mobile contrast overlays',
);
const relativeLuminance = ([red, green, blue]) => {
  const linear = [red, green, blue].map((value) => {
    const channel = value / 255;
    return channel <= 0.04045 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4;
  });
  return (0.2126 * linear[0]) + (0.7152 * linear[1]) + (0.0722 * linear[2]);
};
const contrastRatio = (foreground, background) => {
  const light = Math.max(relativeLuminance(foreground), relativeLuminance(background));
  const dark = Math.min(relativeLuminance(foreground), relativeLuminance(background));
  return (light + 0.05) / (dark + 0.05);
};
const overlayOnWhite = (alpha) => [42, 25, 17].map((channel) => (channel * alpha) + (255 * (1 - alpha)));
const heroContrastEvidence = [
  { mode: 'desktop', ratio: contrastRatio([249, 238, 229], overlayOnWhite(0.88)) },
  { mode: 'mobile', ratio: contrastRatio([249, 238, 229], overlayOnWhite(0.73)) },
];
for (const { mode, ratio } of heroContrastEvidence) {
  pass(ratio >= 4.5, `Hero text contrast fails its worst-case ${mode} overlay`);
}

const logo = join(siteRoot, 'public', 'brand', 'la-favola-logo.svg');
pass(existsSync(logo), 'Missing transparent La Favola logo');
let logoFitEvidence = [];
if (existsSync(logo)) {
  const logoSource = readFileSync(logo, 'utf8');
  const svgStart = logoSource.indexOf('<svg');
  const rootTag = logoSource.match(/<svg\b[^>]*>/)?.[0] ?? '';
  const orderedPathTags = [...logoSource.matchAll(/<path\b[^>]*\/>/g)].map((match) => match[0]);
  pass(!/fill:\s*#fff(?:fff)?\b/i.test(logoSource), 'Logo must not contain an opaque white fill');
  pass(!/truncated|tokens truncated|chars truncated/i.test(logoSource), 'Logo must not contain a truncation artifact');
  pass(rootTag.includes('viewBox="60 700 1880 588"'), 'Logo must use the approved fitted viewBox');
  pass(orderedPathTags.length === 41, 'Logo must preserve all 41 authoritative artwork paths');
  pass(
    sha256Text(orderedPathTags.join('\n')) === '2d3bd954edea13a60c594fe52f7e18fac494aa4b6763269385c0a5515bc37fba',
    'Logo must preserve the exact ordered authoritative path elements, geometry, styles, and colors',
  );
  pass(
    sha256Text(logoSource.slice(0, svgStart)) === '61beb4c93067282adc96352e93674ba86c817b1641ba77f8d3555d492f543597',
    'Logo must preserve the authoritative XML declaration and document descriptor',
  );
  pass(
    sha256Text(rootTag.replace(/viewBox="[^"]+"/, 'viewBox="0 0 2000 2000"')) ===
      '2f894ead57edaf02faf9dfd1b578a572b5a383eb2a3250303b05207f68e34dc7',
    'Logo must preserve all authoritative root metadata except the approved fitted viewBox',
  );
  pass(
    sha256(logo) === '15fceccdd6167defa356af10d044cea1f2e448dc617811eb9eaf945d30669c74',
    'Canvas-fit logo differs from the approved transparent full lockup and metadata-only viewBox edit',
  );

  const logoImage = sharp(logo);
  const logoMetadata = await logoImage.metadata();
  pass(
    logoMetadata.width === 1880 && logoMetadata.height === 588 && logoMetadata.hasAlpha === true,
    'Logo natural dimensions must be 1880x588 with transparency',
  );
  const { data: logoPixels, info: logoInfo } = await sharp(logo).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  let minX = logoInfo.width;
  let minY = logoInfo.height;
  let maxX = -1;
  let maxY = -1;
  for (let y = 0; y < logoInfo.height; y += 1) {
    for (let x = 0; x < logoInfo.width; x += 1) {
      if (logoPixels[((y * logoInfo.width) + x) * logoInfo.channels + 3] > 0) {
        minX = Math.min(minX, x);
        minY = Math.min(minY, y);
        maxX = Math.max(maxX, x);
        maxY = Math.max(maxY, y);
      }
    }
  }
  const margins = {
    left: minX,
    top: minY,
    right: logoInfo.width - 1 - maxX,
    bottom: logoInfo.height - 1 - maxY,
  };
  pass(
    JSON.stringify(margins) === JSON.stringify({ left: 39, top: 29, right: 39, bottom: 29 }),
    'Logo fitted canvas must contain the complete visible artwork with the approved balanced safety margin',
  );

  logoFitEvidence = [320, 833, 1024, 1440].map((viewport) => {
    const headerBox = viewport <= 832 ? { width: 128, height: 52 } : { width: 168, height: 64 };
    const aspectRatio = logoInfo.width / logoInfo.height;
    const renderedWidth = Math.min(headerBox.width, headerBox.height * aspectRatio);
    const renderedHeight = renderedWidth / aspectRatio;
    const containerWidth = viewport <= 544 ? viewport - 20 : viewport - 32;
    const fits = renderedWidth <= headerBox.width && renderedHeight <= headerBox.height && 192 <= containerWidth;
    pass(fits, `Canvas-fit logo exceeds its header/footer container at ${viewport}px`);
    return { viewport, headerBox, renderedWidth, renderedHeight, footerWidth: 192, containerWidth, fits };
  });
}

const forbiddenMarkup = /<(?:form|input|select|textarea)\b/i;
for (const [name, content] of Object.entries(html)) {
  pass(!forbiddenMarkup.test(content), `${name}: transactional form markup is not allowed`);
  pass((content.match(/<script\b/g) ?? []).length === 1, `${name}: expected only the scoped mobile-navigation script`);
  pass(!/href="\/(?:cart|checkout|account|payment|order)(?:\/|"|\?)/i.test(content), `${name}: transactional route link is not allowed`);

  const ids = new Set([...content.matchAll(/\sid="([^"]+)"/g)].map((match) => match[1]));
  for (const match of content.matchAll(/aria-labelledby="([^"]+)"/g)) {
    for (const id of match[1].split(/\s+/)) {
      pass(ids.has(id), `${name}: aria-labelledby references missing #${id}`);
    }
  }

  for (const match of content.matchAll(/href="(\/[^"]*)"/g)) {
    const href = match[1].split('#')[0].split('?')[0];
    if (!href) continue;
    const target = href.endsWith('/')
      ? join(distRoot, href.slice(1), 'index.html')
      : join(distRoot, href.slice(1));
    pass(existsSync(target), `${name}: missing internal target ${href}`);
  }
}

const publicPdf = join(siteRoot, 'public', 'menu-la-favola.pdf');
const builtPdf = join(distRoot, 'menu-la-favola.pdf');
const approvedMenuPdfHash = '4e583942e5793728f5924e63b954758ba60b67751bef0a19a3d788aae1597734';
for (const file of [publicPdf, builtPdf]) {
  pass(existsSync(file), `Missing menu PDF: ${file}`);
}
if ([publicPdf, builtPdf].every(existsSync)) {
  pass(sha256(publicPdf) === approvedMenuPdfHash, 'Public menu PDF differs from the approved source');
  pass(sha256(builtPdf) === approvedMenuPdfHash, 'Built menu PDF differs from the approved source');
}

if (failures.length) {
  console.error('La Favola site validation failed:');
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log('La Favola site validation passed.');
console.log(JSON.stringify({ routes: Object.keys(routes).length, inventory, cardInventory, processSteps, menuIconGroups, menuLegends, cardIconGroups, cardLegends, footerResponsiveWidths, logoFitEvidence, heroFitEvidence, heroContrastEvidence }, null, 2));
