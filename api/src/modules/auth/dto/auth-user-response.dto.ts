import { User } from '../../users/entities/user.entity';

export class AuthUserResponseDto {
  id: string;
  email?: string;
  phone?: string;
  fullName: string;
  status: string;
  role?: { id: string; name: string };

  static from(user: User): AuthUserResponseDto {
    return {
      id: user.id,
      email: user.email,
      phone: user.phone,
      fullName: user.fullName,
      status: user.status,
      role: user.role ? { id: user.role.id, name: user.role.name } : undefined,
    };
  }
}
