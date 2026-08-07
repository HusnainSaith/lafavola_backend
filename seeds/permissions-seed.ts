import 'reflect-metadata';
import { AppDataSource } from '../src/config/data-source';
import { Role } from '../src/modules/roles/entities/role.entity';
import { Permission } from '../src/modules/permissions/entities/permission.entity';
import { RolePermission } from '../src/modules/role-permissions/entities/role-permission.entity';
import { RoleEnum } from '../src/modules/roles/role.enum';
import { PermissionActionEnum } from '../src/common/enums/permission-actions.enum';

// Define features with their specific available actions (only existing modules)
const FEATURE_PERMISSIONS = {
  users: {
    description: 'User management system',
    actions: [
      PermissionActionEnum.CREATE,
      PermissionActionEnum.READ,
      PermissionActionEnum.UPDATE,
      PermissionActionEnum.DELETE,
      PermissionActionEnum.ASSIGN,
      PermissionActionEnum.VIEW_ALL,
    ],
  },

  roles: {
    description: 'Role management system',
    actions: [
      PermissionActionEnum.CREATE,
      PermissionActionEnum.READ,
      PermissionActionEnum.UPDATE,
      PermissionActionEnum.DELETE,
      PermissionActionEnum.ASSIGN,
      PermissionActionEnum.MANAGE,
    ],
  },

  permissions: {
    description: 'Permission management system',
    actions: [
      PermissionActionEnum.CREATE,
      PermissionActionEnum.READ,
      PermissionActionEnum.UPDATE,
      PermissionActionEnum.DELETE,
      PermissionActionEnum.ASSIGN,
      PermissionActionEnum.MANAGE,
    ],
  },


};

export async function seedPermissions() {
  try {
    console.log('Starting permissions seeding...');

    const roleRepo = AppDataSource.getRepository(Role);
    const permissionRepo = AppDataSource.getRepository(Permission);
    const rolePermissionRepo = AppDataSource.getRepository(RolePermission);

    console.log('🧹 Clearing existing permissions and role-permissions...');
    await rolePermissionRepo.query('TRUNCATE TABLE role_permissions CASCADE;');
    await permissionRepo.query('TRUNCATE TABLE permissions CASCADE;');

    console.log('🔍 Fetching roles...');
    const adminRole = await roleRepo.findOneBy({ name: RoleEnum.ADMIN });
    const clientRole = await roleRepo.findOneBy({ name: RoleEnum.CLIENT });
    const employeeRole = await roleRepo.findOneBy({ name: RoleEnum.EMPLOYEE });
    const supportRole = await roleRepo.findOneBy({ name: RoleEnum.SUPPORT }); // Don't forget to fetch the support role.
    const managerRole = await roleRepo.findOneBy({
      name: RoleEnum.PROJECT_MANAGER,
    });

    // Check if roles exist
    if (
      !adminRole ||
      !clientRole ||
      !employeeRole ||
      !supportRole ||
      !managerRole
    ) {
      throw new Error(
        '❌ One or more roles not found. Please ensure the main seed script runs correctly first.',
      );
    }

    console.log('📜 Defining permissions...');
    const allPermissions = [];
    // ... (your permission creation logic) ...
    for (const resourceName in FEATURE_PERMISSIONS) {
      if (
        Object.prototype.hasOwnProperty.call(FEATURE_PERMISSIONS, resourceName)
      ) {
        const feature = FEATURE_PERMISSIONS[resourceName];
        for (const action of feature.actions) {
          const permission = new Permission();
          permission.name = `${resourceName}.${action}`;
          permission.description = `${feature.description} - ${action}`;
          permission.resource = resourceName;
          permission.action = action;
          allPermissions.push(permission);
        }
      }
    }

    console.log('💾 Saving permissions...');
    const savedPermissions = await permissionRepo.save(allPermissions);

    console.log('🔗 Linking permissions to roles...');
    const rolePermissions = [];
    
    // Admin gets all permissions
    savedPermissions.forEach((perm) => {
      rolePermissions.push(
        rolePermissionRepo.create({
          roleId: adminRole.id,
          permissionId: perm.id,
        })
      );
    });
    
    // Basic permissions for other roles
    const basicPermissions = savedPermissions.filter(
      (perm) => perm.action === PermissionActionEnum.READ
    );
    
    basicPermissions.forEach((perm) => {
      rolePermissions.push(
        rolePermissionRepo.create({
          roleId: employeeRole.id,
          permissionId: perm.id,
        })
      );
    });

    await rolePermissionRepo.save(rolePermissions);

    console.log('✅ Permissions and role-permissions seeded successfully!');
  } catch (err) {
    // You can remove the process.exit here since the main script handles it.
    throw new Error(`❌ Error seeding permissions: ${err.message}`);
  }
}
