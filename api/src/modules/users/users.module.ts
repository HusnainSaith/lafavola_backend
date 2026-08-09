import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { GuardsModule } from '../../common/modules/guards.module';
import { TokenUtil } from '../../common/utils/jwt.util';
import { Permission } from '../permissions/entities/permission.entity';
import { RolePermission } from '../role-permissions/entities/role-permission.entity';
import { Role } from '../roles/entities/role.entity';
import { SharedModule } from '../shared/shared.module';
import { UserPermission } from './entities/user-permission.entity';
import { User } from './entities/user.entity';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      UserPermission,
      Role,
      Permission,
      RolePermission,
    ]),
    SharedModule,
    GuardsModule,

    JwtModule.register({
      secret: process.env.JWT_SECRET,
      signOptions: { expiresIn: process.env.JWT_EXPIRES_IN },
    }),
  ],
  controllers: [UsersController],
  providers: [UsersService, TokenUtil],
  exports: [UsersService, TokenUtil, TypeOrmModule],
})
export class UsersModule {}
