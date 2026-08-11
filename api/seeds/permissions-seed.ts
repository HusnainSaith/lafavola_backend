import 'reflect-metadata';
import { AppDataSource } from '../src/config/data-source';
import { Role } from '../src/modules/roles/entities/role.entity';
import { Permission } from '../src/modules/permissions/entities/permission.entity';
import { RolePermission } from '../src/modules/role-permissions/entities/role-permission.entity';
import { RoleEnum } from '../src/modules/roles/role.enum';
import { PermissionActionEnum } from '../src/common/enums/permission-actions.enum';
import { In } from 'typeorm';

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
    const allPermissions: Array<
      Pick<Permission, 'name' | 'description' | 'resource' | 'action'>
    > = [];
    for (const resourceName in FEATURE_PERMISSIONS) {
      if (
        Object.prototype.hasOwnProperty.call(FEATURE_PERMISSIONS, resourceName)
      ) {
        const feature = FEATURE_PERMISSIONS[resourceName];
        for (const action of feature.actions) {
          allPermissions.push({
            name: `${resourceName}.${action}`,
            description: `${feature.description} - ${action}`,
            resource: resourceName,
            action,
          });
        }
      }
    }

    console.log('💾 Upserting permissions...');
    await permissionRepo.upsert(allPermissions, ['name']);
    const savedPermissions = await permissionRepo.find({
      where: { name: In(allPermissions.map((permission) => permission.name)) },
    });

    console.log('🔗 Linking permissions to roles...');
    // Admin gets all permissions. This is idempotent so a production repair
    // never removes an already-assigned permission from another role.
    const assignments: RolePermission[] = [];
    for (const permission of savedPermissions) {
      const existing = await rolePermissionRepo.findOne({
        where: { roleId: adminRole.id, permissionId: permission.id },
      });
      if (!existing) {
        assignments.push(
          rolePermissionRepo.create({
            roleId: adminRole.id,
            permissionId: permission.id,
          }),
        );
      }
    }

    // Basic read permissions for operational employees.
    const basicPermissions = savedPermissions.filter(
      (perm) => perm.action === PermissionActionEnum.READ,
    );
    for (const permission of basicPermissions) {
      const existing = await rolePermissionRepo.findOne({
        where: { roleId: employeeRole.id, permissionId: permission.id },
      });
      if (!existing) {
        assignments.push(
          rolePermissionRepo.create({
            roleId: employeeRole.id,
            permissionId: permission.id,
          }),
        );
      }
    }

    if (assignments.length > 0) await rolePermissionRepo.save(assignments);

    console.log('✅ Permissions and role-permissions seeded successfully!');
  } catch (err) {
    // You can remove the process.exit here since the main script handles it.
    throw new Error(`❌ Error seeding permissions: ${err.message}`);
  }
}

async function main() {
  await AppDataSource.initialize();
  try {
    await seedPermissions();
  } finally {
    await AppDataSource.destroy();
  }
}

if (require.main === module) {
  void main().catch((error: unknown) => {
    console.error('Permission seed failed');
    if (error instanceof Error) console.error(error.message);
    process.exitCode = 1;
  });
}
