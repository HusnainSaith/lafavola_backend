import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { CustomerProfileRepository } from './repositories/customer-profile.repository';
import { CustomerProfile } from './entities/customer-profile.entity';
import { CustomerPreference } from './entities/customer-preference.entity';
import { UpdateCustomerProfileDto } from './dto/update-customer-profile.dto';
import { UpdateCustomerPreferencesDto } from './dto/update-customer-preferences.dto';

@Injectable()
export class CustomersService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly profiles: CustomerProfileRepository,
  ) {}

  async profile(userId: string) {
    let profile = await this.profiles.findOne({ where: { userId } });
    if (!profile) {
      profile = await this.profiles.save(
        this.profiles.create({
          userId,
          preferredLanguage: 'it',
          loyaltyOptIn: false,
          marketingOptIn: false,
        }),
      );
    }
    return profile;
  }

  async updateProfile(userId: string, dto: UpdateCustomerProfileDto) {
    const profile = await this.profile(userId);
    Object.assign(profile, dto);
    return this.profiles.save(profile);
  }

  async preferences(userId: string) {
    const repo = this.dataSource.getRepository(CustomerPreference);
    let preference = await repo.findOne({ where: { customerId: userId } });
    if (!preference) {
      preference = await repo.save(repo.create({ customerId: userId }));
    }
    return preference;
  }

  async updatePreferences(userId: string, dto: UpdateCustomerPreferencesDto) {
    const repo = this.dataSource.getRepository(CustomerPreference);
    const preference = await this.preferences(userId);
    Object.assign(preference, dto);
    return repo.save(preference);
  }
}
