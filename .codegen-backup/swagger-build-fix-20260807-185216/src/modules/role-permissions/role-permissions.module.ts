import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RolePermission } from './entities/role-permission.entity';
import { Role } from '../roles/entities/role.entity';
import { Permission } from '../permissions/entities/permission.entity';
import { RolePermissionsService } from './role-permissions.service';
import { RolePermissionsController } from './role-permissions.controller';

@Module({
  imports: [TypeOrmModule.forFeature([RolePermission, Role, Permission])],
  providers: [RolePermissionsService],
  controllers: [RolePermissionsController],
  exports: [RolePermissionsService],
})
export class RolePermissionsModule {}
