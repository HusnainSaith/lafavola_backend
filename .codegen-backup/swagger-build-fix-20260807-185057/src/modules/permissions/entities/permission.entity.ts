import {
  Column,
  Entity,
  ManyToMany,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { RolePermission } from '../../role-permissions/entities/role-permission.entity';
import { UserPermission } from '../../users/entities/user-permission.entity';
import { Role } from '../../roles/entities/role.entity';
import { User } from '../../users/entities/user.entity';

@Entity('permissions')
export class Permission {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 120, unique: true })
  name: string;

  @Column({ type: 'text', nullable: true })
  description?: string;

  @Column({ type: 'varchar', length: 100 })
  resource: string;

  @Column({ type: 'varchar', length: 60 })
  action: string;

  @OneToMany(
    () => RolePermission,
    (rolePermission) => rolePermission.permission,
  )
  rolePermissions: RolePermission[];

  @OneToMany(
    () => UserPermission,
    (userPermission) => userPermission.permission,
  )
  userPermissions: UserPermission[];

  @ManyToMany(() => Role, (role) => role.permissions)
  roles: Role[];

  @ManyToMany(() => User, (user) => user.permissions)
  users: User[];

  @Column({
    name: 'created_at',
    type: 'timestamptz',
    default: () => 'CURRENT_TIMESTAMP',
  })
  createdAt: Date;

  @Column({
    name: 'updated_at',
    type: 'timestamptz',
    default: () => 'CURRENT_TIMESTAMP',
  })
  updatedAt: Date;
}
