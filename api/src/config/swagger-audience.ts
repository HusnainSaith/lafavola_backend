import { OpenAPIObject } from '@nestjs/swagger';

const ADMIN_TAGS = new Set([
  'Admin Dashboard',
  'Admin POS',
  'Audit',
  'Pricing',
  'Reports',
  'Restaurants',
  'Role Permissions',
  'Roles',
  'Staff',
  'Users',
  'permissions',
]);

const CUSTOMER_TAGS = new Set([
  'Deliveries',
  'Media',
  'Refunds',
]);

const HTTP_METHODS = new Set([
  'get',
  'post',
  'put',
  'patch',
  'delete',
  'options',
  'head',
]);

/** Adds a visible audience prefix to each operation in Swagger UI. */
export function labelSwaggerAudiences(document: OpenAPIObject): void {
  for (const [path, pathItem] of Object.entries(document.paths)) {
    for (const [method, rawOperation] of Object.entries(pathItem ?? {})) {
      if (!HTTP_METHODS.has(method) || !rawOperation) continue;
      const operation = rawOperation as unknown as Record<string, unknown>;
      const tags = (operation.tags as string[] | undefined) ?? [];
      const audience = audienceFor(operation, tags, path);
      const prefix = `[${audience.toUpperCase()}]`;
      const summary = String(operation.summary ?? 'Operation');
      if (!summary.startsWith('[')) operation.summary = `${prefix} ${summary}`;
      const description = String(operation.description ?? '').trim();
      operation.description = `Audience: ${audience}${
        description ? `\n\n${description}` : ''
      }`;
      operation['x-audience-label'] = audience;
      operation.tags = [sectionTag(tags, audience)];
      if (audience.startsWith('Public')) operation.security = [];
    }
  }
}

function sectionTag(tags: string[], audience: string): string {
  const rawSection =
    tags.find((tag) => !tag.startsWith('Audience: ')) ?? 'General';
  const section = rawSection.replace(
    /^(Customer App|Admin App|Support App|Staff Apps?)\s*-\s*/,
    '',
  );
  if (audience.includes('Admin App') && audience.includes('Employee')) {
    return `Staff Apps - ${section}`;
  }
  if (audience === 'Admin App') return `Admin App - ${section}`;
  if (audience === 'Support App') return `Support App - ${section}`;
  if (audience.includes('Employee')) return `Driver App - ${section}`;
  if (audience.includes('Infrastructure')) return `Public API - ${section}`;
  return `Customer App - ${section}`;
}

function audienceFor(
  operation: Record<string, unknown>,
  tags: string[],
  path: string,
): string {
  const roles = operation['x-required-roles'];
  if (Array.isArray(roles) && roles.length) {
    return roles.map((role) => roleLabel(String(role))).join(' / ');
  }

  const explicitAudience = operation['x-audience'];
  if (typeof explicitAudience === 'string') return explicitAudience;
  const audienceTag = tags.find((tag) => tag.startsWith('Audience: '));
  if (audienceTag) return audienceTag.slice('Audience: '.length);

  if (tags.some((tag) => tag.startsWith('Customer App - '))) {
    return path.includes('/admin') ? 'Admin App' : 'Customer App';
  }
  if (tags.includes('System')) return 'Public / Infrastructure';
  if (tags.some((tag) => ADMIN_TAGS.has(tag)) || path.includes('/admin/')) {
    return 'Admin App';
  }
  if (tags.some((tag) => CUSTOMER_TAGS.has(tag))) return 'Customer App';
  return 'Admin App';
}

function roleLabel(role: string): string {
  switch (role) {
    case 'admin':
      return 'Admin App';
    case 'employee':
      return 'Employee / Driver App';
    case 'support':
      return 'Support App';
    case 'client':
      return 'Customer App';
    default:
      return role;
  }
}
