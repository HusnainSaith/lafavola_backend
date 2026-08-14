import { applyDecorators, SetMetadata } from '@nestjs/common';
import { ApiExtension, ApiTags } from '@nestjs/swagger';
import { RoleEnum } from '../../modules/roles/role.enum';

export const ROLES_KEY = 'roles';
export const Roles = (...roles: RoleEnum[]) =>
  applyDecorators(
    SetMetadata(ROLES_KEY, roles),
    ApiExtension('x-required-roles', roles),
    ApiTags(`Audience: ${roles.map(roleLabel).join(' / ')}`),
  );

function roleLabel(role: RoleEnum): string {
  switch (role) {
    case RoleEnum.ADMIN:
      return 'Admin App';
    case RoleEnum.SUPPORT:
      return 'Support App';
    case RoleEnum.EMPLOYEE:
      return 'Employee / Driver App';
    default:
      return role;
  }
}
