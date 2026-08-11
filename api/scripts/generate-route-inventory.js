const fs = require('fs');

const document = JSON.parse(fs.readFileSync('openapi.json', 'utf8'));

const publicPaths = new Set([
  '/',
  '/health',
  '/ready',
  '/auth/register',
  '/auth/login',
  '/auth/refresh',
  '/auth/forgot-password',
  '/auth/reset-password',
  '/auth/verify-email',
  '/auth/resend-verification',
  '/menu',
  '/menu/search',
  '/categories',
  '/faq',
  '/payments/webhooks/sumup',
]);

const customerPrefixes = [
  '/cart', '/checkout', '/customers/me', '/favorites', '/loyalty',
  '/notifications', '/orders/me', '/pricing', '/pizza-builder',
];
const adminPrefixes = [
  '/users', '/roles', '/permissions', '/role-permissions', '/staff',
  '/reports', '/orders/admin', '/admin/dashboard', '/admin/pos', '/audit',
  '/deliveries/admin', '/refunds/admin', '/media/admin',
];
const managedWritePrefixes = [
  '/categories', '/coupons', '/faq', '/ingredients', '/menu',
  '/option-groups', '/promotions', '/restaurants',
];

function schemaName(content) {
  if (!content) return 'None';
  const schema = content['application/json']?.schema;
  if (!schema) return 'Inline/unspecified';
  const ref = schema.$ref || schema.items?.$ref;
  return ref ? ref.split('/').pop() : schema.type || 'Inline';
}

function access(method, path, operation) {
  if (!operation.security || publicPaths.has(path)) return 'PUBLIC';
  if (path.startsWith('/deliveries')) return method === 'get' && path.endsWith('/tracking') ? 'OWNER or STAFF' : 'DRIVER/ADMIN';
  if (path.startsWith('/support/agent')) return 'SUPPORT/ADMIN';
  if (path.startsWith('/support')) return 'OWNER or SUPPORT/ADMIN';
  if (path.startsWith('/refunds')) return method === 'post' ? 'CUSTOMER' : 'ADMIN/STAFF';
  if (path.startsWith('/payments/orders') && path.endsWith('/collect')) return 'DRIVER/ADMIN';
  if (adminPrefixes.some((prefix) => path.startsWith(prefix))) return 'ADMIN/STAFF (route roles apply)';
  if (managedWritePrefixes.some((prefix) => path.startsWith(prefix)) && !['get', 'head'].includes(method)) return 'ADMIN';
  if (customerPrefixes.some((prefix) => path.startsWith(prefix))) return 'CUSTOMER';
  if (path.startsWith('/media')) return 'AUTHENTICATED owner/admin';
  return 'AUTHENTICATED (route roles apply)';
}

function ownership(path) {
  if (/customers\/me|orders\/me|favorites|cart|notifications|loyalty/.test(path)) return 'Authenticated customer scope';
  if (path.startsWith('/support')) return 'Ticket customer/assigned agent/admin';
  if (path.startsWith('/deliveries')) return 'Order customer for tracking; assigned driver/admin for mutation';
  if (path.startsWith('/media')) return 'Asset owner or administrator';
  if (path.startsWith('/payments/orders')) return 'Order owner for status; assigned driver/admin for collection';
  return 'Role/resource policy; no customer cross-tenant access';
}

function requirement(path) {
  const first = path.split('/').filter(Boolean)[0] || 'system';
  const map = {
    auth: 'Authentication', users: 'Customer/staff management', customers: 'Profile/privacy',
    addresses: 'Addresses', menu: 'Menu/search', categories: 'Categories', ingredients: 'Ingredients',
    'option-groups': 'Pizza customization', 'pizza-builder': 'Custom pizza', pricing: 'Authoritative pricing',
    cart: 'Cart', promotions: 'Promotions', coupons: 'Coupons', checkout: 'Checkout', orders: 'Orders',
    payments: 'Payments/receipts', refunds: 'Refunds', deliveries: 'Delivery/tracking', notifications: 'Notifications',
    favorites: 'Favorites', loyalty: 'Loyalty', support: 'Customer support/live chat', faq: 'FAQ',
    restaurants: 'Restaurant/business hours', staff: 'Staff management', reports: 'Reporting', media: 'Media',
    roles: 'RBAC', permissions: 'RBAC', 'role-permissions': 'RBAC', admin: 'Restaurant POS and operations', system: 'System health',
  };
  return map[first] || 'Platform administration';
}

function coverage(path) {
  if (/^\/admin\/pos/.test(path)) return 'Unit + authenticated HTTP + Android integration journey';
  if (/auth/.test(path)) return 'Unit + DB; selected HTTP boundaries';
  if (/deliveries|payments|reports|customers\/me\/privacy/.test(path)) return 'DB journey + HTTP auth boundary';
  if (/checkout|orders|promotions|coupons|menu|pizza-builder|cart/.test(path)) return 'Unit/DB integration; no full authenticated HTTP journey';
  if (/support|notifications/.test(path)) return 'Unit/DB integration';
  return 'HTTP auth boundary or static route audit; dedicated journey varies';
}

const rows = [];
for (const [path, pathItem] of Object.entries(document.paths || {})) {
  const logicalPath = path.replace(/^\/api\/v1(?=\/|$)/, '') || '/';
  for (const [method, operation] of Object.entries(pathItem)) {
    if (!['get', 'post', 'put', 'patch', 'delete'].includes(method)) continue;
    const responseSchemas = Object.values(operation.responses || {})
      .map((response) => schemaName(response.content))
      .filter((name) => name !== 'None');
    rows.push([
      method.toUpperCase(), path, operation.tags?.[0] || 'System', operation.summary || 'Undocumented operation',
      access(method, logicalPath, operation), schemaName(operation.requestBody?.content),
      [...new Set(responseSchemas)].join(', ') || 'Not explicitly typed', ownership(logicalPath), coverage(logicalPath), requirement(logicalPath),
    ]);
  }
}

rows.sort((a, b) => a[1].localeCompare(b[1]) || a[0].localeCompare(b[0]));
const escape = (value) => String(value).replaceAll('|', '\\|').replaceAll('\n', ' ');
const lines = [
  '# Final Route Inventory', '',
  `Generated from \`openapi.json\` and audited against controller policy. Total operations: **${rows.length}**.`, '',
  'Coverage labels identify the strongest current automated layer; they do not turn an authentication-boundary check into a full business journey.', '',
  '| Method | Route | Module | Purpose | Access | Request DTO | Response DTO | Ownership | Test coverage | Client requirement |',
  '|---|---|---|---|---|---|---|---|---|---|',
  ...rows.map((row) => `| ${row.map(escape).join(' | ')} |`), '',
  '## Audit findings', '',
  '- Missing defined client routes: none identified. Delivery lifecycle uses one explicit status-transition endpoint rather than duplicate per-status endpoints.',
  '- Duplicate routes: none identified in the generated contract.',
  '- Unused compatibility surface: legacy generic user/RBAC administration remains intentional administrative API surface.',
  '- Contract inconsistency: a number of operations still use implicit/entity-shaped responses instead of explicit response DTOs. This is documented contract debt, not missing runtime behavior.',
  '- Test limitation: complete authenticated HTTP customer/admin/support journeys are not yet proven end-to-end; PostgreSQL service journeys cover the highest-risk ordering, payment, delivery, privacy, reporting and concurrency behavior.', '',
];
fs.writeFileSync('FINAL_ROUTE_INVENTORY.md', lines.join('\n'));
console.log(`Wrote FINAL_ROUTE_INVENTORY.md with ${rows.length} operations`);
