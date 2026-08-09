export interface AuthenticatedUser {
  id: string;
  email?: string;
  fullName?: string;
  role?: { name?: string } | string;
  permissions?: unknown[];
}
