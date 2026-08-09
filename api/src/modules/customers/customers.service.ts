import { Injectable } from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { UpdateCustomerPreferencesDto } from './dto/update-customer-preferences.dto';
import { UpdateCustomerProfileDto } from './dto/update-customer-profile.dto';
import { CreatePrivacyRequestDto } from './dto/create-privacy-request.dto';
import { RecordPrivacyConsentDto } from './dto/record-privacy-consent.dto';
import { CustomerPreference } from './entities/customer-preference.entity';
import { PrivacyConsent } from './entities/privacy-consent.entity';
import { PrivacyRequest } from './entities/privacy-request.entity';
import { CustomerProfileRepository } from './repositories/customer-profile.repository';

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

  privacyRequests(userId: string) {
    return this.dataSource.getRepository(PrivacyRequest).find({
      where: { userId },
      order: { requestedAt: 'DESC' },
      take: 100,
    });
  }

  createPrivacyRequest(userId: string, dto: CreatePrivacyRequestDto) {
    const repo = this.dataSource.getRepository(PrivacyRequest);
    return repo.save(
      repo.create({ userId, requestType: dto.requestType, status: 'pending' }),
    );
  }

  privacyConsents(userId: string) {
    return this.dataSource.getRepository(PrivacyConsent).find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: 100,
    });
  }

  recordPrivacyConsent(userId: string, dto: RecordPrivacyConsentDto) {
    const repo = this.dataSource.getRepository(PrivacyConsent);
    const now = new Date();
    return repo.save(
      repo.create({
        userId,
        consentType: dto.consentType,
        policyVersion: dto.policyVersion,
        granted: dto.granted,
        grantedAt: dto.granted ? now : undefined,
        withdrawnAt: dto.granted ? undefined : now,
      }),
    );
  }

  async fulfillPrivacyRequest(userId: string, requestId: string) {
    return this.dataSource.transaction('REPEATABLE READ', async (manager) => {
      const request = await manager.getRepository(PrivacyRequest).findOne({
        where: { id: requestId, userId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!request) throw new NotFoundException('Privacy request not found');
      if (request.status === 'completed')
        throw new BadRequestException('Privacy request is already completed');

      request.status = 'processing';
      await manager.getRepository(PrivacyRequest).save(request);
      let result: Record<string, unknown>;
      if (request.requestType === 'export') {
        result = await this.buildExport(manager, userId);
      } else if (request.requestType === 'restriction') {
        await manager.query(
          `UPDATE users SET processing_restricted_at=NOW() WHERE id=$1`,
          [userId],
        );
        result = { processingRestricted: true };
      } else if (request.requestType === 'deletion') {
        result = await this.anonymizeAccount(manager, userId);
      } else {
        throw new BadRequestException(
          'Rectification requires a reviewed customer profile update',
        );
      }
      request.status = 'completed';
      request.completedAt = new Date();
      request.notes =
        request.requestType === 'deletion'
          ? 'Account anonymized; financial/privacy audit records retained'
          : 'Technically fulfilled by customer request';
      await manager.getRepository(PrivacyRequest).save(request);
      return { request, result };
    });
  }

  private async buildExport(manager: EntityManager, userId: string) {
    const one = async (sql: string) =>
      (await manager.query(sql, [userId]))[0] ?? null;
    const many = (sql: string) => manager.query(sql, [userId]);
    const [
      account,
      profile,
      addresses,
      preferences,
      consents,
      orders,
      favorites,
      loyalty,
      support,
      privacyRequests,
    ] = await Promise.all([
      one(
        `SELECT id,email,phone,full_name AS "fullName",status,email_verified_at AS "emailVerifiedAt",phone_verified_at AS "phoneVerifiedAt",created_at AS "createdAt" FROM users WHERE id=$1`,
      ),
      one(
        `SELECT avatar_url AS "avatarUrl",date_of_birth AS "dateOfBirth",preferred_language AS "preferredLanguage",loyalty_opt_in AS "loyaltyOptIn",marketing_opt_in AS "marketingOptIn" FROM customer_profiles WHERE user_id=$1`,
      ),
      many(
        `SELECT id,label,recipient_name AS "recipientName",phone,address_line1 AS "addressLine1",address_line2 AS "addressLine2",city,province,postal_code AS "postalCode",country_code AS "countryCode",delivery_instructions AS "deliveryInstructions",is_default AS "isDefault",is_active AS "isActive" FROM customer_addresses WHERE customer_id=$1 ORDER BY created_at`,
      ),
      one(
        `SELECT vegetarian_preference AS vegetarian,vegan_preference AS vegan,gluten_free_preference AS "glutenFree",spicy_preference AS spicy FROM customer_preferences WHERE customer_id=$1`,
      ),
      many(
        `SELECT consent_type AS "consentType",policy_version AS "policyVersion",granted,granted_at AS "grantedAt",withdrawn_at AS "withdrawnAt",created_at AS "createdAt" FROM privacy_consents WHERE user_id=$1 ORDER BY created_at`,
      ),
      many(
        `SELECT id,order_number AS "orderNumber",status,payment_status AS "paymentStatus",payment_method AS "paymentMethod",currency,grand_total_minor AS "grandTotalMinor",created_at AS "createdAt" FROM orders WHERE customer_id=$1 ORDER BY created_at`,
      ),
      many(
        `SELECT id,restaurant_id AS "restaurantId",menu_item_id AS "menuItemId",created_at AS "createdAt" FROM favorites WHERE customer_id=$1 ORDER BY created_at`,
      ),
      many(
        `SELECT lt.type,lt.points_delta AS "pointsDelta",lt.balance_after AS "balanceAfter",lt.description,lt.created_at AS "createdAt" FROM loyalty_transactions lt JOIN loyalty_accounts la ON la.id=lt.loyalty_account_id WHERE la.customer_id=$1 ORDER BY lt.created_at`,
      ),
      many(
        `SELECT t.id,t.subject,t.status,t.created_at AS "createdAt",COALESCE(json_agg(json_build_object('body',m.body,'authorType',m.author_type,'createdAt',m.created_at) ORDER BY m.created_at) FILTER (WHERE m.id IS NOT NULL),'[]') AS messages FROM support_tickets t LEFT JOIN support_messages m ON m.ticket_id=t.id WHERE t.customer_id=$1 GROUP BY t.id ORDER BY t.created_at`,
      ),
      many(
        `SELECT id,request_type AS "requestType",status,requested_at AS "requestedAt",completed_at AS "completedAt" FROM privacy_requests WHERE user_id=$1 ORDER BY requested_at`,
      ),
    ]);
    return {
      account,
      profile,
      addresses,
      preferences,
      consents,
      orders,
      favorites,
      loyalty,
      support,
      privacyRequests,
    };
  }

  private async anonymizeAccount(manager: EntityManager, userId: string) {
    await manager.query(`DELETE FROM refresh_tokens WHERE user_id=$1`, [
      userId,
    ]);
    await manager.query(`DELETE FROM verification_tokens WHERE user_id=$1`, [
      userId,
    ]);
    await manager.query(`DELETE FROM social_accounts WHERE user_id=$1`, [
      userId,
    ]);
    await manager.query(`DELETE FROM device_tokens WHERE user_id=$1`, [userId]);
    await manager.query(`DELETE FROM notifications WHERE user_id=$1`, [userId]);
    await manager.query(`DELETE FROM favorites WHERE customer_id=$1`, [userId]);
    await manager.query(`DELETE FROM customer_addresses WHERE customer_id=$1`, [
      userId,
    ]);
    await manager.query(
      `DELETE FROM customer_preferences WHERE customer_id=$1`,
      [userId],
    );
    await manager.query(`DELETE FROM customer_profiles WHERE user_id=$1`, [
      userId,
    ]);
    await manager.query(
      `UPDATE orders SET customer_id=NULL,delivery_address_snapshot=CASE WHEN order_type='delivery' THEN '{"redacted":true}'::jsonb ELSE NULL END,delivery_instructions=NULL,customer_note=NULL WHERE customer_id=$1`,
      [userId],
    );
    await manager.query(
      `UPDATE payment_transactions SET customer_id=NULL WHERE customer_id=$1`,
      [userId],
    );
    await manager.query(
      `UPDATE support_messages SET author_user_id=NULL WHERE author_user_id=$1`,
      [userId],
    );
    await manager.query(
      `UPDATE support_tickets SET customer_id=NULL WHERE customer_id=$1`,
      [userId],
    );
    await manager.query(
      `UPDATE users SET email=NULL,phone=NULL,password=NULL,full_name='Deleted account',status='deleted',email_verified_at=NULL,phone_verified_at=NULL,last_login_at=NULL,archived_at=NOW(),processing_restricted_at=NOW() WHERE id=$1`,
      [userId],
    );
    return {
      anonymized: true,
      retained: [
        'orders and monetary records without customer/address identifiers',
        'privacy consent/request audit trail',
        'support content without customer/author linkage',
      ],
    };
  }
}
