export const menuAttributeDefinitions = [
  { id: 'spicy', label: 'Piccante', symbol: '🌶️' },
  { id: 'vegetarian', label: 'Vegetariana', symbol: '🍃' },
  { id: 'gluten', label: 'Glutine', symbol: '🌾' },
  { id: 'lactose', label: 'Lattosio', symbol: '🥛' },
  { id: 'egg', label: 'Uovo', symbol: '🥚' },
  { id: 'fish', label: 'Pesce', symbol: '🐟' },
  { id: 'nuts', label: 'Frutta a guscio', symbol: '🌰' },
] as const;

export type MenuAttribute = (typeof menuAttributeDefinitions)[number]['id'];

export type MenuItem = {
  name: string;
  price?: string;
  description?: string;
  note?: string;
  attributes?: MenuAttribute[];
};

export type MenuSection = {
  id: string;
  title: string;
  eyebrow: string;
  intro?: string;
  items: MenuItem[];
};

export const pizzas: MenuItem[] = [
  { name: 'Americana', price: '€9', description: 'Pomodoro, fiordilatte, Pecorino DOP, würstel, patatine Dippers.', attributes: ['gluten', 'lactose'] },
  { name: 'Bresaola, Rucola e Grana', price: '€10', description: 'Pomodoro, fiordilatte, bresaola sottofesa IGP, rucola, scaglie di Grana Padano, olio EVO.', attributes: ['gluten', 'lactose'] },
  { name: 'Bufala', price: '€10', description: 'Pomodoro, Bufala Campana DOP, basilico, pomodorini, olio EVO.', attributes: ['vegetarian', 'gluten', 'lactose'] },
  { name: 'Burrata', price: '€10', description: 'Pomodoro, Burrata Pugliese, pomodorini, basilico, olio EVO.', attributes: ['vegetarian', 'gluten', 'lactose'] },
  { name: 'Calzone', price: '€8', description: 'Prosciutto cotto Casa Modena, Pecorino DOP, fiordilatte, pomodoro, basilico, olio EVO.', attributes: ['gluten', 'lactose'] },
  { name: 'Capricciosa', price: '€10', description: 'Pomodoro, fiordilatte, Pecorino DOP, prosciutto cotto Casa Modena, funghi, olive Taggiasche, carciofi, basilico, olio EVO.', attributes: ['gluten', 'lactose'] },
  { name: 'Carrettiera', price: '€10', description: 'Friarielli, salsiccia a punta di coltello, provola, Pecorino DOP, basilico, olio EVO.', attributes: ['gluten', 'lactose'] },
  { name: 'Carbonara', price: '€10', description: 'Fiordilatte, guanciale, uovo, Pecorino DOP, basilico, olio EVO.', attributes: ['gluten', 'lactose', 'egg'] },
  { name: 'Diavola', price: '€9', description: 'Pomodoro, provola, Pecorino DOP, spianata calabrese, basilico, olio EVO.', attributes: ['spicy', 'gluten', 'lactose'] },
  { name: 'Fiocco', price: '€12', description: 'Fiordilatte, provola, prosciutto cotto Casa Modena, pecorino, pepe nero, crocchè fritti, basilico, olio EVO.', attributes: ['gluten', 'lactose'] },
  { name: 'Margherita', price: '€7', description: 'Pomodoro, fiordilatte, Pecorino DOP, basilico, olio EVO.', attributes: ['vegetarian', 'gluten', 'lactose'] },
  { name: 'Marinara', price: '€5,50', description: 'Pomodoro, aglio, origano, basilico, olio EVO.', attributes: ['vegetarian', 'gluten', 'lactose'] },
  { name: 'Mimosa', price: '€9', description: 'Panna, fiordilatte, prosciutto cotto Casa Modena, Pecorino DOP, mais, olio EVO.', attributes: ['gluten', 'lactose'] },
  { name: 'Mortazza', price: '€13', description: 'Fiordilatte, Mortadella IGP Bologna, Burrata Pugliese, granella di pistacchio.', attributes: ['gluten', 'lactose', 'nuts'] },
  { name: 'Napoli', price: '€8', description: 'Pomodoro, fiordilatte, origano, acciughe di Cetara, olive Taggiasche, basilico, olio EVO.', attributes: ['gluten', 'lactose'] },
  { name: 'Norvegese', price: '€9', description: 'Fiordilatte, salmone, panna.', attributes: ['gluten', 'lactose', 'fish'] },
  { name: 'Parma', price: '€13', description: 'Pomodoro, fiordilatte, basilico, crudo di Parma 24 mesi, rucola selvatica, scaglie di Grana Padano, olio EVO.', attributes: ['gluten', 'lactose'] },
  { name: 'Parmigiana', price: '€9', description: 'Pomodoro, fiordilatte, melanzane fritte, pomodorini, scaglie di Grana Padano, basilico, olio EVO.', attributes: ['vegetarian', 'gluten', 'lactose'] },
  { name: 'Porcini', price: '€8', description: 'Pomodoro, fiordilatte, Pecorino DOP, porcini, basilico, olio EVO.', attributes: ['vegetarian', 'gluten', 'lactose'] },
  { name: 'Provola e Pepe', price: '€8', description: 'Pomodoro, provola, Pecorino DOP, basilico, pepe nero, olio EVO.', attributes: ['vegetarian', 'gluten', 'lactose'] },
  { name: 'Speck e Brie', price: '€9', description: 'Pomodoro, fiordilatte, Pecorino DOP, speck Alto Adige, brie, Pecorino DOP, olio EVO.', attributes: ['gluten', 'lactose'] },
  { name: 'Tonno e Cipolle', price: '€8,50', description: 'Pomodoro, fiordilatte, Pecorino DOP, tonno, cipolla rossa di Tropea, basilico.', attributes: ['gluten', 'lactose', 'fish'] },
  { name: 'Verdure', price: '€10', description: 'Pomodoro, fiordilatte, Pecorino DOP, zucchine, peperoni, melanzane, crema di verdure, basilico, olio EVO.', attributes: ['vegetarian', 'gluten', 'lactose'] },
  { name: '4 Formaggi', price: '€9', description: 'Fiordilatte, gorgonzola, brie, provola, Pecorino DOP, olio EVO.', attributes: ['vegetarian', 'gluten', 'lactose'] },
];

export const menuSections: MenuSection[] = [
  {
    id: 'pizze',
    title: 'Le pizze',
    eyebrow: 'Dal forno',
    intro: 'Ventiquattro storie, dalla Marinara alla Mortazza. Ingredienti e prezzi sono trascritti dal menù fornito da La Favola.',
    items: pizzas,
  },
  {
    id: 'panini',
    title: 'I panini',
    eyebrow: 'Fatti come vuoi',
    items: [
      { name: 'Panino Crudo', price: '€8', description: 'Crudo, pomodoro, formaggio, salsa a scelta.', attributes: ['gluten', 'lactose'] },
      { name: 'Panino Mortadella', price: '€8', description: 'Mortadella, mozzarella fiordilatte, pomodoro, salsa a scelta.', attributes: ['gluten', 'lactose'] },
      { name: 'Panino Cotto', price: '€8', description: 'Prosciutto cotto, pomodoro, salsa a scelta.', attributes: ['gluten'] },
      { name: 'Panino Salame', price: '€8', description: 'Salame dolce, pomodoro, mozzarella, salsa a scelta.', attributes: ['gluten', 'lactose'] },
      { name: 'Panino Pollo 1', price: '€8', description: 'Pollo fritto, insalata, pomodoro, ketchup, cheddar.', attributes: ['gluten', 'lactose'] },
      { name: 'Panino Pollo 2', price: '€8', description: 'Pollo fritto, mozzarella fiordilatte, pomodoro, insalata, maionese, cipolla cotta.', attributes: ['gluten', 'lactose'] },
      { name: 'Crea il tuo panino', price: 'da €6' },
    ],
  },
  {
    id: 'sfizi',
    title: 'Sfizi e fritti',
    eyebrow: 'Da condividere, forse',
    items: [
      { name: 'Porzione patatine', price: '€3,50' },
      { name: 'Patatine Dippers', price: '€4' },
      { name: 'Crocchette di patate', price: '€3,50', attributes: ['gluten'] },
      { name: 'Anelli di cipolla', price: '€5', note: '6 pezzi', attributes: ['gluten'] },
      { name: 'Nuggets di pollo', price: '€3,50', note: '6 pezzi', attributes: ['gluten'] },
      { name: 'Crocchè artigianale con provola', price: '€3,50', note: '110 g', attributes: ['gluten', 'lactose'] },
      { name: 'Crocchè artigianale salame e mozzarella', price: '€3,50', note: '110 g', attributes: ['gluten', 'lactose'] },
      { name: 'Frittatina artigianale pastellata', price: '€3,50', note: '110 g', attributes: ['gluten', 'lactose'] },
      { name: 'Arancino artigianale con sugo al ragù', price: '€3,50', note: '110 g', attributes: ['gluten', 'lactose'] },
      { name: 'Alette di pollo', price: '€4,50', note: '4 pezzi', attributes: ['gluten', 'lactose'] },
    ],
  },
  {
    id: 'salse',
    title: 'Le salse',
    eyebrow: 'Un ultimo tocco',
    items: [
      { name: 'Maionese' },
      { name: 'Ketchup' },
      { name: 'Salsa rosa' },
      { name: 'Barbecue' },
    ],
  },
  {
    id: 'bevande',
    title: 'Da bere',
    eyebrow: 'Fresco in tavola',
    items: [
      { name: 'Acqua', price: '€1' },
      { name: 'Bibite', price: '€2,50', note: '33 cl' },
      { name: 'Birre', price: 'da €3' },
    ],
  },
];

export const variations = [
  { label: 'Ingredienti extra', price: 'da +€1' },
  { label: 'Mozzarella senza lattosio', price: '+€1,50' },
  { label: 'Formato Baby', price: '−€1' },
];

export const restaurant = {
  address: 'Via Vittorio Veneto 23/C, 25128 Brescia',
  phonePrimary: '030 6180079',
  phonePrimaryHref: 'tel:+390306180079',
  phoneSecondary: '392 0437240',
  phoneSecondaryHref: 'tel:+393920437240',
  instagram: '@lafavolabrescia',
  instagramHref: 'https://www.instagram.com/lafavolabrescia/',
  mapsHref: 'https://www.google.com/maps/search/?api=1&query=Via%20Vittorio%20Veneto%2023%2FC%2C%20Brescia',
  hours: [
    { days: 'Lunedì — Giovedì', time: '18:00 — 23:00' },
    { days: 'Venerdì — Domenica', time: '17:30 — 23:00' },
  ],
  delivery: 'Consegna a partire da €1,50 · ordine minimo €10',
  payment: 'Pagamento con POS disponibile su richiesta.',
};
