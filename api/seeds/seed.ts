import 'reflect-metadata';
import { AppDataSource } from '../src/config/data-source';
import { Role } from '../src/modules/roles/entities/role.entity';
import { User } from '../src/modules/users/entities/user.entity';
import * as bcrypt from 'bcryptjs';
import { RoleEnum } from '../src/modules/roles/role.enum';
import { SecurityUtil } from '../src/common/utils/security.util';

// Import the permissions seeding function
import { seedPermissions } from './permissions-seed';

function requiredSeedVariable(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(name + ' is required for local seeding');
  return value;
}

async function seed() {
  await AppDataSource.initialize(); // Initialize connection once

  try {
    const roleRepo = AppDataSource.getRepository(Role);
    const userRepo = AppDataSource.getRepository(User);

    // Seed roles...
    // ... (Your roles seeding logic) ...
    const rolesToSeed = [
      { name: RoleEnum.ADMIN, description: 'Administrator with full access' },
      { name: RoleEnum.GUEST, description: 'Guest user with limited access' },
      { name: RoleEnum.CLIENT, description: 'Client user with limited access' },
      {
        name: RoleEnum.EMPLOYEE,
        description: 'Employee user with limited access',
      },
      {
        name: RoleEnum.PROJECT_MANAGER,
        description: 'Project manager with project access',
      },
      { name: RoleEnum.SUPPORT, description: 'Support user for tickets' },
    ];
    for (const roleData of rolesToSeed) {
      let role = await roleRepo.findOne({ where: { name: roleData.name } });
      if (!role) {
        role = roleRepo.create(roleData);
        await roleRepo.save(role);
        console.log(
          `Role "${SecurityUtil.sanitizeLogMessage(roleData.name)}" created.`,
        );
      } else {
        console.log(
          `Role "${SecurityUtil.sanitizeLogMessage(roleData.name)}" already exists.`,
        );
      }
    }

    // Seed admin user...
    // ... (Your admin user seeding logic) ...
    const adminEmail = requiredSeedVariable('SEED_ADMIN_EMAIL');
    let adminUser = await userRepo.findOne({ where: { email: adminEmail } });
    if (!adminUser) {
      const adminRole = await roleRepo.findOne({
        where: { name: RoleEnum.ADMIN },
      });
      const password = await bcrypt.hash(
        requiredSeedVariable('SEED_ADMIN_PASSWORD'),
        10,
      );
      adminUser = userRepo.create({
        email: adminEmail,
        password,
        fullName: 'Super Admin',
        roleId: adminRole.id,
      });
      await userRepo.save(adminUser);
      console.log(
        `Admin user "${SecurityUtil.sanitizeLogMessage(adminEmail)}" created.`,
      );
    } else {
      console.log(`Admin user "${adminEmail}" already exists.`);
    }

    // Now, run the permissions seed function, which will use the existing connection
    await seedPermissions();

    console.log('✅ All seeding tasks completed successfully!');
  } catch (e) {
    console.error('Seeding error:', e);
    process.exit(1);
  } finally {
    await AppDataSource.destroy(); // Close the connection at the very end
    console.log('🆑 Database connection closed.');
  }

  process.exit(0);
}

seed();
