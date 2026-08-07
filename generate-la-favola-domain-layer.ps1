param(
    [string]$Root = (Get-Location).Path,
    [switch]$NoBackup
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Ensure-Directory {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

$Root = [System.IO.Path]::GetFullPath($Root)

if (-not (Test-Path -LiteralPath (Join-Path $Root "package.json"))) {
    throw "package.json was not found in '$Root'. Run this script from the NestJS backend root or pass -Root."
}

if (-not (Test-Path -LiteralPath (Join-Path $Root "src"))) {
    throw "src folder was not found in '$Root'."
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = Join-Path $Root ".codegen-backup\$timestamp"

function Write-CodeFile {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $target = Join-Path $Root $RelativePath
    Ensure-Directory (Split-Path -Parent $target)

    if ((Test-Path -LiteralPath $target) -and (-not $NoBackup)) {
        $backup = Join-Path $backupRoot $RelativePath
        Ensure-Directory (Split-Path -Parent $backup)
        Copy-Item -LiteralPath $target -Destination $backup -Force
    }

    Set-Content -LiteralPath $target -Value $Content -Encoding UTF8
    Write-Host "[WRITE] $RelativePath"
}

Write-Host ""
Write-Host "La Favola domain-layer generator"
Write-Host "Backend root: $Root"
Write-Host "Scope: DTOs, entities, enums, interfaces, repositories"
Write-Host "Migration files are NOT modified."
if (-not $NoBackup) {
    Write-Host "Existing generated-target files will be backed up to: $backupRoot"
}
Write-Host ""
$content = @'
export interface MoneyBreakdown {
  currency: 'EUR';
  subtotalMinor: number;
  optionChargesMinor: number;
  discountMinor: number;
  loyaltyDiscountMinor: number;
  deliveryFeeMinor: number;
  taxMinor: number;
  grandTotalMinor: number;
}
'@
Write-CodeFile -RelativePath 'src\common\interfaces\money.interface.ts' -Content $content

$content = @'
export interface PaginationMeta {
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
}

export interface PaginatedResult<T> {
  data: T[];
  pagination: PaginationMeta;
}
'@
Write-CodeFile -RelativePath 'src\common\interfaces\pagination.interface.ts' -Content $content

$content = @'
import {
  DataSource,
  DeepPartial,
  EntityTarget,
  FindManyOptions,
  FindOneOptions,
  FindOptionsWhere,
  ObjectLiteral,
  Repository,
} from 'typeorm';

export abstract class BaseRepository<T extends ObjectLiteral> {
  protected readonly repository: Repository<T>;

  protected constructor(
    dataSource: DataSource,
    entity: EntityTarget<T>,
  ) {
    this.repository = dataSource.getRepository(entity);
  }

  create(input: DeepPartial<T>): T {
    return this.repository.create(input);
  }

  save(entity: DeepPartial<T>): Promise<T> {
    return this.repository.save(entity);
  }

  findOne(options: FindOneOptions<T>): Promise<T | null> {
    return this.repository.findOne(options);
  }

  findById(id: string): Promise<T | null> {
    return this.repository.findOne({
      where: { id } as FindOptionsWhere<T>,
    });
  }

  findMany(options?: FindManyOptions<T>): Promise<T[]> {
    return this.repository.find(options);
  }

  count(where?: FindOptionsWhere<T>): Promise<number> {
    return this.repository.count({ where });
  }

  async deleteById(id: string): Promise<boolean> {
    const result = await this.repository.delete(id);
    return (result.affected ?? 0) > 0;
  }
}
'@
Write-CodeFile -RelativePath 'src\common\repositories\base.repository.ts' -Content $content

$content = @'
import {
  IsBoolean,
  IsLatitude,
  IsLongitude,
  IsOptional,
  IsPhoneNumber,
  IsString,
  Length,
  MaxLength,
} from 'class-validator';

export class CreateAddressDto {
  @IsOptional()
  @IsString()
  @MaxLength(80)
  label?: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
  recipientName?: string;

  @IsOptional()
  @IsPhoneNumber()
  phone?: string;

  @IsString()
  @MaxLength(255)
  addressLine1: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  addressLine2?: string;

  @IsString()
  @MaxLength(120)
  city: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  province?: string;

  @IsString()
  @MaxLength(24)
  postalCode: string;

  @IsOptional()
  @IsString()
  @Length(2, 2)
  countryCode?: string;

  @IsOptional()
  @IsLatitude()
  latitude?: string;

  @IsOptional()
  @IsLongitude()
  longitude?: string;

  @IsOptional()
  @IsString()
  deliveryInstructions?: string;

  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}
'@
Write-CodeFile -RelativePath 'src\modules\addresses\dto\create-address.dto.ts' -Content $content

$content = @'
import { PartialType } from '@nestjs/mapped-types';
import { CreateAddressDto } from './create-address.dto';

export class UpdateAddressDto extends PartialType(CreateAddressDto) {}
'@
Write-CodeFile -RelativePath 'src\modules\addresses\dto\update-address.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('customer_addresses')
export class CustomerAddress {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'customer_id', type: 'uuid' })
  customerId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'customer_id' })
  customer: User;

  @Column({ name: 'label', type: 'varchar', length: 80, nullable: true })
  label?: string;

  @Column({ name: 'recipient_name', type: 'varchar', length: 160, nullable: true })
  recipientName?: string;

  @Column({ name: 'phone', type: 'varchar', length: 32, nullable: true })
  phone?: string;

  @Column({ name: 'address_line1', type: 'varchar', length: 255 })
  addressLine1: string;

  @Column({ name: 'address_line2', type: 'varchar', length: 255, nullable: true })
  addressLine2?: string;

  @Column({ name: 'city', type: 'varchar', length: 120 })
  city: string;

  @Column({ name: 'province', type: 'varchar', length: 120, nullable: true })
  province?: string;

  @Column({ name: 'postal_code', type: 'varchar', length: 24 })
  postalCode: string;

  @Column({ name: 'country_code', type: 'char', length: 2 })
  countryCode: string;

  @Column({ name: 'latitude', type: 'numeric', precision: 9, scale: 6, nullable: true })
  latitude?: string;

  @Column({ name: 'longitude', type: 'numeric', precision: 9, scale: 6, nullable: true })
  longitude?: string;

  @Column({ name: 'delivery_instructions', type: 'text', nullable: true })
  deliveryInstructions?: string;

  @Column({ name: 'is_default', type: 'boolean' })
  isDefault: boolean;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\addresses\entities\customer-address.entity.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { CustomerAddress } from '../entities/customer-address.entity';

@Injectable()
export class CustomerAddressRepository extends BaseRepository<CustomerAddress> {
  constructor(dataSource: DataSource) {
    super(dataSource, CustomerAddress);
  }

  findActiveForCustomer(customerId: string): Promise<CustomerAddress[]> {
    return this.repository.find({
      where: { customerId, isActive: true },
      order: { isDefault: 'DESC', createdAt: 'DESC' },
    });
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\addresses\repositories\customer-address.repository.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';

@Entity('audit_logs')
export class AuditLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'actor_user_id', type: 'uuid', nullable: true })
  actorUserId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'actor_user_id' })
  actorUser?: User;

  @Column({ name: 'action', type: 'varchar', length: 120 })
  action: string;

  @Column({ name: 'resource_type', type: 'varchar', length: 120 })
  resourceType: string;

  @Column({ name: 'resource_id', type: 'uuid', nullable: true })
  resourceId?: string;

  @Column({ name: 'restaurant_id', type: 'uuid', nullable: true })
  restaurantId?: string;

  @ManyToOne(() => Restaurant, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant?: Restaurant;

  @Column({ name: 'correlation_id', type: 'varchar', length: 120, nullable: true })
  correlationId?: string;

  @Column({ name: 'ip_address', type: 'inet', nullable: true })
  ipAddress?: string;

  @Column({ name: 'user_agent', type: 'text', nullable: true })
  userAgent?: string;

  @Column({ name: 'before_data', type: 'jsonb', nullable: true })
  beforeData?: Record<string, unknown>;

  @Column({ name: 'after_data', type: 'jsonb', nullable: true })
  afterData?: Record<string, unknown>;

  @Column({ name: 'metadata', type: 'jsonb' })
  metadata: Record<string, unknown>;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\audit\entities\audit-log.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('idempotency_keys')
export class IdempotencyKey {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'actor_user_id', type: 'uuid', nullable: true })
  actorUserId?: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'actor_user_id' })
  actorUser?: User;

  @Column({ name: 'scope', type: 'varchar', length: 120 })
  scope: string;

  @Column({ name: 'key_hash', type: 'varchar', length: 128 })
  keyHash: string;

  @Column({ name: 'request_hash', type: 'varchar', length: 128, nullable: true })
  requestHash?: string;

  @Column({ name: 'response_status', type: 'integer', nullable: true })
  responseStatus?: number;

  @Column({ name: 'response_body', type: 'jsonb', nullable: true })
  responseBody?: Record<string, unknown>;

  @Column({ name: 'locked_until', type: 'timestamptz', nullable: true })
  lockedUntil?: Date;

  @Column({ name: 'expires_at', type: 'timestamptz' })
  expiresAt: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\audit\entities\idempotency-key.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('outbox_events')
export class OutboxEvent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'aggregate_type', type: 'varchar', length: 120 })
  aggregateType: string;

  @Column({ name: 'aggregate_id', type: 'uuid', nullable: true })
  aggregateId?: string;

  @Column({ name: 'event_type', type: 'varchar', length: 160 })
  eventType: string;

  @Column({ name: 'payload', type: 'jsonb' })
  payload: Record<string, unknown>;

  @Column({ name: 'status', type: 'varchar', length: 30 })
  status: string;

  @Column({ name: 'attempts', type: 'integer' })
  attempts: number;

  @Column({ name: 'available_at', type: 'timestamptz' })
  availableAt: Date;

  @Column({ name: 'claimed_at', type: 'timestamptz', nullable: true })
  claimedAt?: Date;

  @Column({ name: 'published_at', type: 'timestamptz', nullable: true })
  publishedAt?: Date;

  @Column({ name: 'last_error', type: 'text', nullable: true })
  lastError?: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\audit\entities\outbox-event.entity.ts' -Content $content

$content = @'
export enum OutboxStatus {
  PENDING = 'pending',
  PROCESSING = 'processing',
  PUBLISHED = 'published',
  FAILED = 'failed',
  DEAD_LETTER = 'dead_letter',
}
'@
Write-CodeFile -RelativePath 'src\modules\audit\enums\outbox-status.enum.ts' -Content $content

$content = @'
export interface AuditContext {
  actorUserId?: string;
  restaurantId?: string;
  correlationId?: string;
  ipAddress?: string;
  userAgent?: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\audit\interfaces\audit-context.interface.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { AuditLog } from '../entities/audit-log.entity';

@Injectable()
export class AuditLogRepository extends BaseRepository<AuditLog> {
  constructor(dataSource: DataSource) {
    super(dataSource, AuditLog);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\audit\repositories\audit-log.repository.ts' -Content $content

$content = @'
import { IsEnum } from 'class-validator';
import { VerificationTokenType } from '../enums/verification-token-type.enum';

export class RequestVerificationDto {
  @IsEnum(VerificationTokenType)
  type: VerificationTokenType;
}
'@
Write-CodeFile -RelativePath 'src\modules\auth\dto\request-verification.dto.ts' -Content $content

$content = @'
import { IsEnum, IsString, MaxLength } from 'class-validator';
import { SocialProvider } from '../enums/social-provider.enum';

export class SocialLoginDto {
  @IsEnum(SocialProvider)
  provider: SocialProvider;

  @IsString()
  @MaxLength(4096)
  idToken: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\auth\dto\social-login.dto.ts' -Content $content

$content = @'
import { IsString, MaxLength } from 'class-validator';

export class VerifyTokenDto {
  @IsString()
  @MaxLength(512)
  token: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\auth\dto\verify-token.dto.ts' -Content $content

$content = @'
import { Column, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('refresh_tokens')
export class RefreshToken {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 512, unique: true })
  token: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ManyToOne(() => User, (user) => user.refreshTokens, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'expires_at', type: 'timestamptz' })
  expiresAt: Date;

  @Column({ name: 'created_at', type: 'timestamptz', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ name: 'is_revoked', type: 'boolean', default: false })
  isRevoked: boolean;

  @Column({ name: 'revoked_at', type: 'timestamptz', nullable: true })
  revokedAt?: Date;
}
'@
Write-CodeFile -RelativePath 'src\modules\auth\entities\refresh-token.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('social_accounts')
export class SocialAccount {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'provider', type: 'varchar', length: 30 })
  provider: string;

  @Column({ name: 'provider_subject', type: 'varchar', length: 255 })
  providerSubject: string;

  @Column({ name: 'provider_email', type: 'varchar', length: 320, nullable: true })
  providerEmail?: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\auth\entities\social-account.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('verification_tokens')
export class VerificationToken {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'type', type: 'varchar', length: 30 })
  type: string;

  @Column({ name: 'token_hash', type: 'varchar', length: 255, unique: true })
  tokenHash: string;

  @Column({ name: 'attempts', type: 'integer' })
  attempts: number;

  @Column({ name: 'expires_at', type: 'timestamptz' })
  expiresAt: Date;

  @Column({ name: 'consumed_at', type: 'timestamptz', nullable: true })
  consumedAt?: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\auth\entities\verification-token.entity.ts' -Content $content

$content = @'
export enum SocialProvider {
  GOOGLE = 'google',
  APPLE = 'apple',
}
'@
Write-CodeFile -RelativePath 'src\modules\auth\enums\social-provider.enum.ts' -Content $content

$content = @'
export enum VerificationTokenType {
  EMAIL_VERIFY = 'email_verify',
  PHONE_VERIFY = 'phone_verify',
  PASSWORD_RESET = 'password_reset',
}
'@
Write-CodeFile -RelativePath 'src\modules\auth\enums\verification-token-type.enum.ts' -Content $content

$content = @'
import {
  IsArray,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CartItemOptionDto {
  @IsOptional() @IsUUID() optionGroupId?: string;
  @IsOptional() @IsUUID() optionChoiceId?: string;
  @IsOptional() @IsUUID() ingredientId?: string;
  @IsOptional() @IsString() action?: 'add' | 'remove' | 'replace';
  @IsOptional() @Min(0.01) quantity?: number;
}

export class AddCartItemDto {
  @IsUUID() menuItemId: string;
  @IsOptional() @IsUUID() menuItemSizeId?: string;
  @IsInt() @Min(1) quantity: number;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CartItemOptionDto)
  options?: CartItemOptionDto[];

  @IsOptional() @IsString() @MaxLength(1000)
  specialInstructions?: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\carts\dto\add-cart-item.dto.ts' -Content $content

$content = @'
import { IsInt, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class UpdateCartItemDto {
  @IsOptional() @IsInt() @Min(1) quantity?: number;
  @IsOptional() @IsString() @MaxLength(1000) specialInstructions?: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\carts\dto\update-cart-item.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { CartItem } from './cart-item.entity';
import { OptionGroup } from '../../option-groups/entities/option-group.entity';
import { OptionChoice } from '../../option-groups/entities/option-choice.entity';
import { Ingredient } from '../../ingredients/entities/ingredient.entity';

@Entity('cart_item_options')
export class CartItemOption {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'cart_item_id', type: 'uuid' })
  cartItemId: string;

  @ManyToOne(() => CartItem, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'cart_item_id' })
  cartItem: CartItem;

  @Column({ name: 'option_group_id', type: 'uuid', nullable: true })
  optionGroupId?: string;

  @ManyToOne(() => OptionGroup, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'option_group_id' })
  optionGroup?: OptionGroup;

  @Column({ name: 'option_choice_id', type: 'uuid', nullable: true })
  optionChoiceId?: string;

  @ManyToOne(() => OptionChoice, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'option_choice_id' })
  optionChoice?: OptionChoice;

  @Column({ name: 'ingredient_id', type: 'uuid', nullable: true })
  ingredientId?: string;

  @ManyToOne(() => Ingredient, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'ingredient_id' })
  ingredient?: Ingredient;

  @Column({ name: 'action', type: 'varchar', length: 20 })
  action: string;

  @Column({ name: 'option_name_snapshot', type: 'varchar', length: 140 })
  optionNameSnapshot: string;

  @Column({ name: 'quantity', type: 'numeric', precision: 8, scale: 2 })
  quantity: string;

  @Column({ name: 'unit_price_adjustment_minor', type: 'integer' })
  unitPriceAdjustmentMinor: number;

  @Column({ name: 'total_price_adjustment_minor', type: 'integer' })
  totalPriceAdjustmentMinor: number;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\carts\entities\cart-item-option.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Cart } from './cart.entity';
import { MenuItem } from '../../menu/entities/menu-item.entity';
import { MenuItemSize } from '../../menu/entities/menu-item-size.entity';

@Entity('cart_items')
export class CartItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'cart_id', type: 'uuid' })
  cartId: string;

  @ManyToOne(() => Cart, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'cart_id' })
  cart: Cart;

  @Column({ name: 'menu_item_id', type: 'uuid' })
  menuItemId: string;

  @ManyToOne(() => MenuItem, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'menu_item_id' })
  menuItem: MenuItem;

  @Column({ name: 'menu_item_size_id', type: 'uuid', nullable: true })
  menuItemSizeId?: string;

  @ManyToOne(() => MenuItemSize, { onDelete: 'RESTRICT', nullable: true })
  @JoinColumn({ name: 'menu_item_size_id' })
  menuItemSize?: MenuItemSize;

  @Column({ name: 'quantity', type: 'integer' })
  quantity: number;

  @Column({ name: 'item_name_snapshot', type: 'varchar', length: 180 })
  itemNameSnapshot: string;

  @Column({ name: 'size_name_snapshot', type: 'varchar', length: 80, nullable: true })
  sizeNameSnapshot?: string;

  @Column({ name: 'base_unit_price_minor', type: 'integer' })
  baseUnitPriceMinor: number;

  @Column({ name: 'options_unit_price_minor', type: 'integer' })
  optionsUnitPriceMinor: number;

  @Column({ name: 'unit_price_minor', type: 'integer' })
  unitPriceMinor: number;

  @Column({ name: 'line_total_minor', type: 'integer' })
  lineTotalMinor: number;

  @Column({ name: 'special_instructions', type: 'text', nullable: true })
  specialInstructions?: string;

  @Column({ name: 'configuration_hash', type: 'varchar', length: 128, nullable: true })
  configurationHash?: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\carts\entities\cart-item.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';

@Entity('carts')
export class Cart {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'customer_id', type: 'uuid', nullable: true })
  customerId?: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'customer_id' })
  customer?: User;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'session_key', type: 'varchar', length: 160, nullable: true })
  sessionKey?: string;

  @Column({ name: 'status', type: 'varchar', length: 30 })
  status: string;

  @Column({ name: 'currency', type: 'char', length: 3 })
  currency: string;

  @Column({ name: 'expires_at', type: 'timestamptz', nullable: true })
  expiresAt?: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\carts\entities\cart.entity.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Cart } from '../entities/cart.entity';

@Injectable()
export class CartRepository extends BaseRepository<Cart> {
  constructor(dataSource: DataSource) {
    super(dataSource, Cart);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\carts\repositories\cart.repository.ts' -Content $content

$content = @'
import { IsBoolean, IsInt, IsOptional, IsString, IsUUID, MaxLength, Min } from 'class-validator';

export class CreateCategoryDto {
  @IsUUID() restaurantId: string;
  @IsString() @MaxLength(120) name: string;
  @IsString() @MaxLength(140) slug: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsUUID() imageAssetId?: string;
  @IsOptional() @IsInt() @Min(0) displayOrder?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
'@
Write-CodeFile -RelativePath 'src\modules\categories\dto\create-category.dto.ts' -Content $content

$content = @'
import { PartialType } from '@nestjs/mapped-types';
import { CreateCategoryDto } from './create-category.dto';
export class UpdateCategoryDto extends PartialType(CreateCategoryDto) {}
'@
Write-CodeFile -RelativePath 'src\modules\categories\dto\update-category.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';
import { MediaAsset } from '../../media/entities/media-asset.entity';

@Entity('menu_categories')
export class MenuCategory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'name', type: 'varchar', length: 120 })
  name: string;

  @Column({ name: 'slug', type: 'varchar', length: 140 })
  slug: string;

  @Column({ name: 'description', type: 'text', nullable: true })
  description?: string;

  @Column({ name: 'image_asset_id', type: 'uuid', nullable: true })
  imageAssetId?: string;

  @ManyToOne(() => MediaAsset, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'image_asset_id' })
  imageAsset?: MediaAsset;

  @Column({ name: 'display_order', type: 'integer' })
  displayOrder: number;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\categories\entities\menu-category.entity.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { MenuCategory } from '../entities/menu-category.entity';

@Injectable()
export class MenuCategoryRepository extends BaseRepository<MenuCategory> {
  constructor(dataSource: DataSource) {
    super(dataSource, MenuCategory);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\categories\repositories\menu-category.repository.ts' -Content $content

$content = @'
import { IsEnum, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';
import { PaymentMethodType } from '../../payments/enums/payment-method-type.enum';

export class CheckoutDto {
  @IsUUID() cartId: string;
  @IsUUID() deliveryAddressId: string;
  @IsEnum(PaymentMethodType) paymentMethod: PaymentMethodType;
  @IsOptional() @IsUUID() savedPaymentMethodId?: string;
  @IsOptional() @IsString() @MaxLength(80) couponCode?: string;
  @IsOptional() @IsString() @MaxLength(1000) customerNote?: string;
  @IsOptional() @IsString() idempotencyKey?: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\checkout\dto\checkout.dto.ts' -Content $content

$content = @'
export interface CheckoutResult {
  orderId: string;
  orderNumber: string;
  paymentRequired: boolean;
  paymentTransactionId?: string;
  clientSecret?: string;
  estimatedDeliveryAt?: Date;
}
'@
Write-CodeFile -RelativePath 'src\modules\checkout\interfaces\checkout-result.interface.ts' -Content $content

$content = @'
import { IsString, MaxLength } from 'class-validator';

export class ApplyCouponDto {
  @IsString()
  @MaxLength(80)
  code: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\coupons\dto\apply-coupon.dto.ts' -Content $content

$content = @'
import { IsBoolean, IsDateString, IsEnum, IsInt, IsOptional, IsString, IsUUID, MaxLength, Min } from 'class-validator';
import { DiscountType } from '../enums/discount-type.enum';

export class CreateCouponDto {
  @IsUUID() restaurantId: string;
  @IsOptional() @IsUUID() promotionId?: string;
  @IsString() @MaxLength(80) code: string;
  @IsOptional() @IsString() description?: string;
  @IsEnum(DiscountType) discountType: DiscountType;
  @IsOptional() @IsInt() @Min(0) discountValue?: number;
  @IsOptional() @IsInt() @Min(0) minOrderMinor?: number;
  @IsOptional() @IsInt() @Min(0) maxDiscountMinor?: number;
  @IsOptional() @IsDateString() startsAt?: string;
  @IsOptional() @IsDateString() expiresAt?: string;
  @IsOptional() @IsInt() @Min(1) totalUsageLimit?: number;
  @IsOptional() @IsInt() @Min(1) perCustomerLimit?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
'@
Write-CodeFile -RelativePath 'src\modules\coupons\dto\create-coupon.dto.ts' -Content $content

$content = @'
import { PartialType } from '@nestjs/mapped-types';
import { CreateCouponDto } from './create-coupon.dto';
export class UpdateCouponDto extends PartialType(CreateCouponDto) {}
'@
Write-CodeFile -RelativePath 'src\modules\coupons\dto\update-coupon.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Coupon } from './coupon.entity';
import { User } from '../../users/entities/user.entity';

@Entity('coupon_redemptions')
export class CouponRedemption {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'coupon_id', type: 'uuid' })
  couponId: string;

  @ManyToOne(() => Coupon, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'coupon_id' })
  coupon: Coupon;

  @Column({ name: 'customer_id', type: 'uuid', nullable: true })
  customerId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'customer_id' })
  customer?: User;

  @Column({ name: 'order_id', type: 'uuid', nullable: true })
  orderId?: string;

  @Column({ name: 'discount_minor', type: 'integer' })
  discountMinor: number;

  @Column({ name: 'redeemed_at', type: 'timestamptz' })
  redeemedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\coupons\entities\coupon-redemption.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';
import { Promotion } from '../../promotions/entities/promotion.entity';

@Entity('coupons')
export class Coupon {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'promotion_id', type: 'uuid', nullable: true })
  promotionId?: string;

  @ManyToOne(() => Promotion, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'promotion_id' })
  promotion?: Promotion;

  @Column({ name: 'code', type: 'varchar', length: 80 })
  code: string;

  @Column({ name: 'description', type: 'text', nullable: true })
  description?: string;

  @Column({ name: 'discount_type', type: 'varchar', length: 30 })
  discountType: string;

  @Column({ name: 'discount_value', type: 'integer' })
  discountValue: number;

  @Column({ name: 'min_order_minor', type: 'integer' })
  minOrderMinor: number;

  @Column({ name: 'max_discount_minor', type: 'integer', nullable: true })
  maxDiscountMinor?: number;

  @Column({ name: 'starts_at', type: 'timestamptz', nullable: true })
  startsAt?: Date;

  @Column({ name: 'expires_at', type: 'timestamptz', nullable: true })
  expiresAt?: Date;

  @Column({ name: 'total_usage_limit', type: 'integer', nullable: true })
  totalUsageLimit?: number;

  @Column({ name: 'per_customer_limit', type: 'integer', nullable: true })
  perCustomerLimit?: number;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\coupons\entities\coupon.entity.ts' -Content $content

$content = @'
export enum DiscountType {
  PERCENTAGE = 'percentage',
  FIXED_AMOUNT = 'fixed_amount',
  FREE_DELIVERY = 'free_delivery',
}
'@
Write-CodeFile -RelativePath 'src\modules\coupons\enums\discount-type.enum.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Coupon } from '../entities/coupon.entity';

@Injectable()
export class CouponRepository extends BaseRepository<Coupon> {
  constructor(dataSource: DataSource) {
    super(dataSource, Coupon);
  }

  findActiveByCode(restaurantId: string, code: string): Promise<Coupon | null> {
    return this.repository
      .createQueryBuilder('coupon')
      .where('coupon.restaurant_id = :restaurantId', { restaurantId })
      .andWhere('UPPER(coupon.code) = UPPER(:code)', { code })
      .andWhere('coupon.is_active = true')
      .andWhere('(coupon.starts_at IS NULL OR coupon.starts_at <= NOW())')
      .andWhere('(coupon.expires_at IS NULL OR coupon.expires_at > NOW())')
      .getOne();
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\coupons\repositories\coupon.repository.ts' -Content $content

$content = @'
import { IsEnum } from 'class-validator';
import { PrivacyRequestType } from '../enums/privacy-request-type.enum';

export class CreatePrivacyRequestDto {
  @IsEnum(PrivacyRequestType)
  requestType: PrivacyRequestType;
}
'@
Write-CodeFile -RelativePath 'src\modules\customers\dto\create-privacy-request.dto.ts' -Content $content

$content = @'
import { IsBoolean, IsOptional, IsUUID } from 'class-validator';

export class UpdateCustomerPreferencesDto {
  @IsOptional() @IsBoolean() vegetarianPreference?: boolean;
  @IsOptional() @IsBoolean() veganPreference?: boolean;
  @IsOptional() @IsBoolean() glutenFreePreference?: boolean;
  @IsOptional() @IsBoolean() spicyPreference?: boolean;
  @IsOptional() @IsUUID() defaultPaymentMethodId?: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\customers\dto\update-customer-preferences.dto.ts' -Content $content

$content = @'
import {
  IsBoolean,
  IsDateString,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
} from 'class-validator';

export class UpdateCustomerProfileDto {
  @IsOptional()
  @IsUrl({ require_protocol: true })
  avatarUrl?: string;

  @IsOptional()
  @IsDateString()
  dateOfBirth?: string;

  @IsOptional()
  @IsString()
  @MaxLength(10)
  preferredLanguage?: string;

  @IsOptional()
  @IsBoolean()
  loyaltyOptIn?: boolean;

  @IsOptional()
  @IsBoolean()
  marketingOptIn?: boolean;
}
'@
Write-CodeFile -RelativePath 'src\modules\customers\dto\update-customer-profile.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('customer_preferences')
export class CustomerPreference {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'customer_id', type: 'uuid', unique: true })
  customerId: string;

  @OneToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'customer_id' })
  customer: User;

  @Column({ name: 'vegetarian_preference', type: 'boolean' })
  vegetarianPreference: boolean;

  @Column({ name: 'vegan_preference', type: 'boolean' })
  veganPreference: boolean;

  @Column({ name: 'gluten_free_preference', type: 'boolean' })
  glutenFreePreference: boolean;

  @Column({ name: 'spicy_preference', type: 'boolean' })
  spicyPreference: boolean;

  @Column({ name: 'default_payment_method_id', type: 'uuid', nullable: true })
  defaultPaymentMethodId?: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\customers\entities\customer-preference.entity.ts' -Content $content

$content = @'
import { Column, Entity, JoinColumn, OneToOne, PrimaryGeneratedColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('customer_profiles')
export class CustomerProfile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid', unique: true })
  userId: string;

  @OneToOne(() => User, (user) => user.customerProfile, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'avatar_url', type: 'text', nullable: true })
  avatarUrl?: string;

  @Column({ name: 'date_of_birth', type: 'date', nullable: true })
  dateOfBirth?: string;

  @Column({ name: 'preferred_language', type: 'varchar', length: 10 })
  preferredLanguage: string;

  @Column({ name: 'loyalty_opt_in', type: 'boolean' })
  loyaltyOptIn: boolean;

  @Column({ name: 'marketing_opt_in', type: 'boolean' })
  marketingOptIn: boolean;

  @Column({ name: 'created_at', type: 'timestamptz', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz', default: () => 'CURRENT_TIMESTAMP' })
  updatedAt: Date;
}
'@
Write-CodeFile -RelativePath 'src\modules\customers\entities\customer-profile.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('privacy_consents')
export class PrivacyConsent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'consent_type', type: 'varchar', length: 60 })
  consentType: string;

  @Column({ name: 'policy_version', type: 'varchar', length: 40 })
  policyVersion: string;

  @Column({ name: 'granted', type: 'boolean' })
  granted: boolean;

  @Column({ name: 'granted_at', type: 'timestamptz', nullable: true })
  grantedAt?: Date;

  @Column({ name: 'withdrawn_at', type: 'timestamptz', nullable: true })
  withdrawnAt?: Date;

  @Column({ name: 'ip_address', type: 'inet', nullable: true })
  ipAddress?: string;

  @Column({ name: 'user_agent', type: 'text', nullable: true })
  userAgent?: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\customers\entities\privacy-consent.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('privacy_requests')
export class PrivacyRequest {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'request_type', type: 'varchar', length: 30 })
  requestType: string;

  @Column({ name: 'status', type: 'varchar', length: 30 })
  status: string;

  @Column({ name: 'requested_at', type: 'timestamptz' })
  requestedAt: Date;

  @Column({ name: 'completed_at', type: 'timestamptz', nullable: true })
  completedAt?: Date;

  @Column({ name: 'notes', type: 'text', nullable: true })
  notes?: string;

}
'@
Write-CodeFile -RelativePath 'src\modules\customers\entities\privacy-request.entity.ts' -Content $content

$content = @'
export enum PrivacyRequestStatus {
  PENDING = 'pending',
  PROCESSING = 'processing',
  COMPLETED = 'completed',
  REJECTED = 'rejected',
}
'@
Write-CodeFile -RelativePath 'src\modules\customers\enums\privacy-request-status.enum.ts' -Content $content

$content = @'
export enum PrivacyRequestType {
  EXPORT = 'export',
  RECTIFICATION = 'rectification',
  DELETION = 'deletion',
  RESTRICTION = 'restriction',
}
'@
Write-CodeFile -RelativePath 'src\modules\customers\enums\privacy-request-type.enum.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { CustomerProfile } from '../entities/customer-profile.entity';

@Injectable()
export class CustomerProfileRepository extends BaseRepository<CustomerProfile> {
  constructor(dataSource: DataSource) {
    super(dataSource, CustomerProfile);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\customers\repositories\customer-profile.repository.ts' -Content $content

$content = @'
import { IsUUID } from 'class-validator';

export class AssignDriverDto {
  @IsUUID() driverUserId: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\deliveries\dto\assign-driver.dto.ts' -Content $content

$content = @'
import { IsInt, IsLatitude, IsLongitude, IsNumber, IsOptional, Min } from 'class-validator';

export class UpdateLocationDto {
  @IsLatitude() latitude: string;
  @IsLongitude() longitude: string;
  @IsOptional() @IsNumber() headingDegrees?: number;
  @IsOptional() @IsNumber() @Min(0) speedKph?: number;
  @IsOptional() @IsInt() @Min(0) remainingMinutes?: number;
}
'@
Write-CodeFile -RelativePath 'src\modules\deliveries\dto\update-location.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Order } from '../../orders/entities/order.entity';
import { User } from '../../users/entities/user.entity';

@Entity('delivery_assignments')
export class DeliveryAssignment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_id', type: 'uuid', unique: true })
  orderId: string;

  @OneToOne(() => Order, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Column({ name: 'driver_user_id', type: 'uuid', nullable: true })
  driverUserId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'driver_user_id' })
  driverUser?: User;

  @Column({ name: 'assigned_by_user_id', type: 'uuid', nullable: true })
  assignedByUserId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'assigned_by_user_id' })
  assignedByUser?: User;

  @Column({ name: 'status', type: 'varchar', length: 30 })
  status: string;

  @Column({ name: 'assigned_at', type: 'timestamptz' })
  assignedAt: Date;

  @Column({ name: 'accepted_at', type: 'timestamptz', nullable: true })
  acceptedAt?: Date;

  @Column({ name: 'picked_up_at', type: 'timestamptz', nullable: true })
  pickedUpAt?: Date;

  @Column({ name: 'completed_at', type: 'timestamptz', nullable: true })
  completedAt?: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\deliveries\entities\delivery-assignment.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { DeliveryTracking } from './delivery-tracking.entity';

@Entity('delivery_tracking_events')
export class DeliveryTrackingEvent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'tracking_id', type: 'uuid' })
  trackingId: string;

  @ManyToOne(() => DeliveryTracking, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'tracking_id' })
  tracking: DeliveryTracking;

  @Column({ name: 'status', type: 'varchar', length: 30, nullable: true })
  status?: string;

  @Column({ name: 'latitude', type: 'numeric', precision: 9, scale: 6, nullable: true })
  latitude?: string;

  @Column({ name: 'longitude', type: 'numeric', precision: 9, scale: 6, nullable: true })
  longitude?: string;

  @Column({ name: 'remaining_minutes', type: 'integer', nullable: true })
  remainingMinutes?: number;

  @Column({ name: 'source', type: 'varchar', length: 30 })
  source: string;

  @Column({ name: 'occurred_at', type: 'timestamptz' })
  occurredAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\deliveries\entities\delivery-tracking-event.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Order } from '../../orders/entities/order.entity';
import { DeliveryAssignment } from './delivery-assignment.entity';

@Entity('delivery_tracking')
export class DeliveryTracking {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_id', type: 'uuid', unique: true })
  orderId: string;

  @OneToOne(() => Order, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Column({ name: 'assignment_id', type: 'uuid', nullable: true })
  assignmentId?: string;

  @ManyToOne(() => DeliveryAssignment, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'assignment_id' })
  assignment?: DeliveryAssignment;

  @Column({ name: 'status', type: 'varchar', length: 30 })
  status: string;

  @Column({ name: 'current_latitude', type: 'numeric', precision: 9, scale: 6, nullable: true })
  currentLatitude?: string;

  @Column({ name: 'current_longitude', type: 'numeric', precision: 9, scale: 6, nullable: true })
  currentLongitude?: string;

  @Column({ name: 'heading_degrees', type: 'numeric', precision: 6, scale: 2, nullable: true })
  headingDegrees?: string;

  @Column({ name: 'speed_kph', type: 'numeric', precision: 7, scale: 2, nullable: true })
  speedKph?: string;

  @Column({ name: 'remaining_minutes', type: 'integer', nullable: true })
  remainingMinutes?: number;

  @Column({ name: 'estimated_arrival_at', type: 'timestamptz', nullable: true })
  estimatedArrivalAt?: Date;

  @Column({ name: 'last_pinged_at', type: 'timestamptz', nullable: true })
  lastPingedAt?: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\deliveries\entities\delivery-tracking.entity.ts' -Content $content

$content = @'
export enum DeliveryAssignmentStatus {
  ASSIGNED = 'assigned',
  ACCEPTED = 'accepted',
  PICKED_UP = 'picked_up',
  EN_ROUTE = 'en_route',
  ARRIVING = 'arriving',
  DELIVERED = 'delivered',
  FAILED = 'failed',
  CANCELLED = 'cancelled',
}
'@
Write-CodeFile -RelativePath 'src\modules\deliveries\enums\delivery-assignment-status.enum.ts' -Content $content

$content = @'
export enum DeliveryTrackingStatus {
  ASSIGNED = 'assigned',
  PREPARING = 'preparing',
  COOKING = 'cooking',
  PACKING = 'packing',
  DRIVER_ASSIGNED = 'driver_assigned',
  EN_ROUTE = 'en_route',
  ARRIVING = 'arriving',
  DELIVERED = 'delivered',
  FAILED = 'failed',
}
'@
Write-CodeFile -RelativePath 'src\modules\deliveries\enums\delivery-tracking-status.enum.ts' -Content $content

$content = @'
export interface LiveTrackingSnapshot {
  orderId: string;
  status: string;
  latitude?: string;
  longitude?: string;
  remainingMinutes?: number;
  estimatedArrivalAt?: Date;
  lastPingedAt?: Date;
}
'@
Write-CodeFile -RelativePath 'src\modules\deliveries\interfaces\live-tracking.interface.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { DeliveryTracking } from '../entities/delivery-tracking.entity';

@Injectable()
export class DeliveryTrackingRepository extends BaseRepository<DeliveryTracking> {
  constructor(dataSource: DataSource) {
    super(dataSource, DeliveryTracking);
  }

  findByOrderId(orderId: string): Promise<DeliveryTracking | null> {
    return this.repository.findOne({ where: { orderId } });
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\deliveries\repositories\delivery-tracking.repository.ts' -Content $content

$content = @'
import { IsBoolean, IsInt, IsOptional, IsString, IsUUID, Min } from 'class-validator';

export class CreateFaqDto {
  @IsOptional() @IsUUID() restaurantId?: string;
  @IsOptional() @IsUUID() categoryId?: string;
  @IsString() question: string;
  @IsString() answer: string;
  @IsOptional() @IsInt() @Min(0) displayOrder?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
'@
Write-CodeFile -RelativePath 'src\modules\faq\dto\create-faq.dto.ts' -Content $content

$content = @'
import { PartialType } from '@nestjs/mapped-types';
import { CreateFaqDto } from './create-faq.dto';
export class UpdateFaqDto extends PartialType(CreateFaqDto) {}
'@
Write-CodeFile -RelativePath 'src\modules\faq\dto\update-faq.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';
import { FaqCategory } from './faq-category.entity';

@Entity('faq_articles')
export class FaqArticle {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid', nullable: true })
  restaurantId?: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant?: Restaurant;

  @Column({ name: 'category_id', type: 'uuid', nullable: true })
  categoryId?: string;

  @ManyToOne(() => FaqCategory, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'category_id' })
  category?: FaqCategory;

  @Column({ name: 'question', type: 'text' })
  question: string;

  @Column({ name: 'answer', type: 'text' })
  answer: string;

  @Column({ name: 'display_order', type: 'integer' })
  displayOrder: number;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'archived_at', type: 'timestamptz', nullable: true })
  archivedAt?: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\faq\entities\faq-article.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';

@Entity('faq_categories')
export class FaqCategory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid', nullable: true })
  restaurantId?: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant?: Restaurant;

  @Column({ name: 'name', type: 'varchar', length: 120 })
  name: string;

  @Column({ name: 'slug', type: 'varchar', length: 140 })
  slug: string;

  @Column({ name: 'display_order', type: 'integer' })
  displayOrder: number;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\faq\entities\faq-category.entity.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { FaqArticle } from '../entities/faq-article.entity';

@Injectable()
export class FaqArticleRepository extends BaseRepository<FaqArticle> {
  constructor(dataSource: DataSource) {
    super(dataSource, FaqArticle);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\faq\repositories\faq-article.repository.ts' -Content $content

$content = @'
import { IsObject, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateFavoriteDto {
  @IsUUID() restaurantId: string;
  @IsOptional() @IsUUID() menuItemId?: string;
  @IsOptional() @IsUUID() sourceOrderItemId?: string;
  @IsOptional() @IsString() @MaxLength(120) label?: string;
  @IsOptional() @IsObject() configurationSnapshot?: Record<string, unknown>;
}
'@
Write-CodeFile -RelativePath 'src\modules\favorites\dto\create-favorite.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';
import { MenuItem } from '../../menu/entities/menu-item.entity';
import { OrderItem } from '../../orders/entities/order-item.entity';

@Entity('favorites')
export class Favorite {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'customer_id', type: 'uuid' })
  customerId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'customer_id' })
  customer: User;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'menu_item_id', type: 'uuid', nullable: true })
  menuItemId?: string;

  @ManyToOne(() => MenuItem, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'menu_item_id' })
  menuItem?: MenuItem;

  @Column({ name: 'source_order_item_id', type: 'uuid', nullable: true })
  sourceOrderItemId?: string;

  @ManyToOne(() => OrderItem, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'source_order_item_id' })
  sourceOrderItem?: OrderItem;

  @Column({ name: 'label', type: 'varchar', length: 120, nullable: true })
  label?: string;

  @Column({ name: 'configuration_snapshot', type: 'jsonb' })
  configurationSnapshot: Record<string, unknown>;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\favorites\entities\favorite.entity.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Favorite } from '../entities/favorite.entity';

@Injectable()
export class FavoriteRepository extends BaseRepository<Favorite> {
  constructor(dataSource: DataSource) {
    super(dataSource, Favorite);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\favorites\repositories\favorite.repository.ts' -Content $content

$content = @'
import { IsArray, IsBoolean, IsInt, IsOptional, IsString, IsUUID, MaxLength, Min } from 'class-validator';

export class CreateIngredientDto {
  @IsUUID() restaurantId: string;
  @IsOptional() @IsUUID() categoryId?: string;
  @IsString() @MaxLength(140) name: string;
  @IsString() @MaxLength(160) slug: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsUUID() imageAssetId?: string;
  @IsOptional() @IsInt() @Min(0) extraPriceMinor?: number;
  @IsOptional() @IsInt() @Min(0) calories?: number;
  @IsOptional() @IsBoolean() isVegetarian?: boolean;
  @IsOptional() @IsBoolean() isVegan?: boolean;
  @IsOptional() @IsBoolean() isGlutenFree?: boolean;
  @IsOptional() @IsBoolean() isSpicy?: boolean;
  @IsOptional() @IsArray() @IsString({ each: true }) containsAllergens?: string[];
  @IsOptional() @IsBoolean() isActive?: boolean;
}
'@
Write-CodeFile -RelativePath 'src\modules\ingredients\dto\create-ingredient.dto.ts' -Content $content

$content = @'
import { PartialType } from '@nestjs/mapped-types';
import { CreateIngredientDto } from './create-ingredient.dto';
export class UpdateIngredientDto extends PartialType(CreateIngredientDto) {}
'@
Write-CodeFile -RelativePath 'src\modules\ingredients\dto\update-ingredient.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';

@Entity('ingredient_categories')
export class IngredientCategory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'name', type: 'varchar', length: 120 })
  name: string;

  @Column({ name: 'slug', type: 'varchar', length: 140 })
  slug: string;

  @Column({ name: 'display_order', type: 'integer' })
  displayOrder: number;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\ingredients\entities\ingredient-category.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';
import { IngredientCategory } from './ingredient-category.entity';
import { MediaAsset } from '../../media/entities/media-asset.entity';

@Entity('ingredients')
export class Ingredient {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'category_id', type: 'uuid', nullable: true })
  categoryId?: string;

  @ManyToOne(() => IngredientCategory, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'category_id' })
  category?: IngredientCategory;

  @Column({ name: 'name', type: 'varchar', length: 140 })
  name: string;

  @Column({ name: 'slug', type: 'varchar', length: 160 })
  slug: string;

  @Column({ name: 'description', type: 'text', nullable: true })
  description?: string;

  @Column({ name: 'image_asset_id', type: 'uuid', nullable: true })
  imageAssetId?: string;

  @ManyToOne(() => MediaAsset, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'image_asset_id' })
  imageAsset?: MediaAsset;

  @Column({ name: 'extra_price_minor', type: 'integer' })
  extraPriceMinor: number;

  @Column({ name: 'calories', type: 'integer', nullable: true })
  calories?: number;

  @Column({ name: 'is_vegetarian', type: 'boolean' })
  isVegetarian: boolean;

  @Column({ name: 'is_vegan', type: 'boolean' })
  isVegan: boolean;

  @Column({ name: 'is_gluten_free', type: 'boolean' })
  isGlutenFree: boolean;

  @Column({ name: 'is_spicy', type: 'boolean' })
  isSpicy: boolean;

  @Column({ name: 'contains_allergens', type: 'text', array: true })
  containsAllergens: string[];

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\ingredients\entities\ingredient.entity.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Ingredient } from '../entities/ingredient.entity';

@Injectable()
export class IngredientRepository extends BaseRepository<Ingredient> {
  constructor(dataSource: DataSource) {
    super(dataSource, Ingredient);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\ingredients\repositories\ingredient.repository.ts' -Content $content

$content = @'
import { IsInt, IsUUID, Min } from 'class-validator';

export class RedeemLoyaltyPointsDto {
  @IsUUID() orderId: string;
  @IsInt() @Min(1) points: number;
}
'@
Write-CodeFile -RelativePath 'src\modules\loyalty\dto\redeem-loyalty-points.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('loyalty_accounts')
export class LoyaltyAccount {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'customer_id', type: 'uuid', unique: true })
  customerId: string;

  @OneToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'customer_id' })
  customer: User;

  @Column({ name: 'points_balance', type: 'integer' })
  pointsBalance: number;

  @Column({ name: 'lifetime_points_earned', type: 'integer' })
  lifetimePointsEarned: number;

  @Column({ name: 'tier', type: 'varchar', length: 40 })
  tier: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\loyalty\entities\loyalty-account.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { LoyaltyAccount } from './loyalty-account.entity';
import { Order } from '../../orders/entities/order.entity';
import { User } from '../../users/entities/user.entity';

@Entity('loyalty_transactions')
export class LoyaltyTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'loyalty_account_id', type: 'uuid' })
  loyaltyAccountId: string;

  @ManyToOne(() => LoyaltyAccount, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'loyalty_account_id' })
  loyaltyAccount: LoyaltyAccount;

  @Column({ name: 'order_id', type: 'uuid', nullable: true })
  orderId?: string;

  @ManyToOne(() => Order, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'order_id' })
  order?: Order;

  @Column({ name: 'type', type: 'varchar', length: 30 })
  type: string;

  @Column({ name: 'points_delta', type: 'integer' })
  pointsDelta: number;

  @Column({ name: 'balance_after', type: 'integer' })
  balanceAfter: number;

  @Column({ name: 'description', type: 'varchar', length: 255, nullable: true })
  description?: string;

  @Column({ name: 'expires_at', type: 'timestamptz', nullable: true })
  expiresAt?: Date;

  @Column({ name: 'created_by_user_id', type: 'uuid', nullable: true })
  createdByUserId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'created_by_user_id' })
  createdByUser?: User;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\loyalty\entities\loyalty-transaction.entity.ts' -Content $content

$content = @'
export enum LoyaltyTransactionType {
  EARNED = 'earned',
  BONUS = 'bonus',
  REDEEMED = 'redeemed',
  EXPIRED = 'expired',
  ADJUSTMENT = 'adjustment',
  REFUND_REVERSAL = 'refund_reversal',
}
'@
Write-CodeFile -RelativePath 'src\modules\loyalty\enums\loyalty-transaction-type.enum.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { LoyaltyAccount } from '../entities/loyalty-account.entity';

@Injectable()
export class LoyaltyAccountRepository extends BaseRepository<LoyaltyAccount> {
  constructor(dataSource: DataSource) {
    super(dataSource, LoyaltyAccount);
  }

  findByCustomerId(customerId: string): Promise<LoyaltyAccount | null> {
    return this.repository.findOne({ where: { customerId } });
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\loyalty\repositories\loyalty-account.repository.ts' -Content $content

$content = @'
import { IsIn, IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class CreateUploadUrlDto {
  @IsString() @MaxLength(255) fileName: string;

  @IsIn(['image/jpeg', 'image/png', 'image/webp'])
  mimeType: string;

  @IsInt() @Min(1) @Max(5 * 1024 * 1024)
  sizeBytes: number;

  @IsOptional() @IsString() @MaxLength(255)
  altText?: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\media\dto\create-upload-url.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';
import { User } from '../../users/entities/user.entity';

@Entity('media_assets')
export class MediaAsset {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid', nullable: true })
  restaurantId?: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant?: Restaurant;

  @Column({ name: 'uploaded_by_user_id', type: 'uuid', nullable: true })
  uploadedByUserId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'uploaded_by_user_id' })
  uploadedByUser?: User;

  @Column({ name: 'storage_provider', type: 'varchar', length: 30 })
  storageProvider: string;

  @Column({ name: 'bucket', type: 'varchar', length: 255 })
  bucket: string;

  @Column({ name: 'object_key', type: 'varchar', length: 1024, unique: true })
  objectKey: string;

  @Column({ name: 'public_url', type: 'text', nullable: true })
  publicUrl?: string;

  @Column({ name: 'mime_type', type: 'varchar', length: 120 })
  mimeType: string;

  @Column({ name: 'size_bytes', type: 'bigint', nullable: true })
  sizeBytes?: string;

  @Column({ name: 'width', type: 'integer', nullable: true })
  width?: number;

  @Column({ name: 'height', type: 'integer', nullable: true })
  height?: number;

  @Column({ name: 'alt_text', type: 'varchar', length: 255, nullable: true })
  altText?: string;

  @Column({ name: 'status', type: 'varchar', length: 30 })
  status: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\media\entities\media-asset.entity.ts' -Content $content

$content = @'
export enum MediaStatus {
  PENDING = 'pending',
  ACTIVE = 'active',
  ARCHIVED = 'archived',
  FAILED = 'failed',
}
'@
Write-CodeFile -RelativePath 'src\modules\media\enums\media-status.enum.ts' -Content $content

$content = @'
export interface PresignedUploadResult {
  mediaAssetId: string;
  objectKey: string;
  uploadUrl: string;
  expiresInSeconds: number;
  requiredHeaders: Record<string, string>;
}
'@
Write-CodeFile -RelativePath 'src\modules\media\interfaces\presigned-upload.interface.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { MediaAsset } from '../entities/media-asset.entity';

@Injectable()
export class MediaAssetRepository extends BaseRepository<MediaAsset> {
  constructor(dataSource: DataSource) {
    super(dataSource, MediaAsset);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\media\repositories\media-asset.repository.ts' -Content $content

$content = @'
import { IsBoolean, IsEnum, IsInt, IsOptional, IsString, MaxLength, Min } from 'class-validator';
import { PizzaSizeCode } from '../enums/pizza-size-code.enum';

export class CreateMenuItemSizeDto {
  @IsEnum(PizzaSizeCode) sizeCode: PizzaSizeCode;
  @IsString() @MaxLength(80) displayName: string;
  @IsInt() @Min(0) basePriceMinor: number;
  @IsOptional() @IsInt() @Min(0) calories?: number;
  @IsOptional() @IsInt() @Min(0) displayOrder?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
'@
Write-CodeFile -RelativePath 'src\modules\menu\dto\create-menu-item-size.dto.ts' -Content $content

$content = @'
import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  ValidateNested,
  IsArray,
} from 'class-validator';
import { Type } from 'class-transformer';
import { MenuItemType } from '../enums/menu-item-type.enum';
import { CreateMenuItemSizeDto } from './create-menu-item-size.dto';

export class CreateMenuItemDto {
  @IsUUID() restaurantId: string;
  @IsOptional() @IsUUID() categoryId?: string;
  @IsString() @MaxLength(180) name: string;
  @IsString() @MaxLength(200) slug: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsUUID() imageAssetId?: string;
  @IsEnum(MenuItemType) itemType: MenuItemType;
  @IsOptional() @IsInt() @Min(0) calories?: number;
  @IsOptional() @IsInt() @Min(0) preparationMinutes?: number;
  @IsOptional() @IsBoolean() isVegetarian?: boolean;
  @IsOptional() @IsBoolean() isVegan?: boolean;
  @IsOptional() @IsBoolean() isGlutenFree?: boolean;
  @IsOptional() @IsBoolean() isSpicy?: boolean;
  @IsOptional() @IsBoolean() isPopular?: boolean;
  @IsOptional() @IsBoolean() isActive?: boolean;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateMenuItemSizeDto)
  sizes: CreateMenuItemSizeDto[];
}
'@
Write-CodeFile -RelativePath 'src\modules\menu\dto\create-menu-item.dto.ts' -Content $content

$content = @'
import { PartialType } from '@nestjs/mapped-types';
import { CreateMenuItemDto } from './create-menu-item.dto';
export class UpdateMenuItemDto extends PartialType(CreateMenuItemDto) {}
'@
Write-CodeFile -RelativePath 'src\modules\menu\dto\update-menu-item.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { MenuItem } from './menu-item.entity';
import { Ingredient } from '../../ingredients/entities/ingredient.entity';

@Entity('menu_item_ingredients')
export class MenuItemIngredient {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'menu_item_id', type: 'uuid' })
  menuItemId: string;

  @ManyToOne(() => MenuItem, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'menu_item_id' })
  menuItem: MenuItem;

  @Column({ name: 'ingredient_id', type: 'uuid' })
  ingredientId: string;

  @ManyToOne(() => Ingredient, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'ingredient_id' })
  ingredient: Ingredient;

  @Column({ name: 'is_default', type: 'boolean' })
  isDefault: boolean;

  @Column({ name: 'is_removable', type: 'boolean' })
  isRemovable: boolean;

  @Column({ name: 'default_quantity', type: 'numeric', precision: 8, scale: 2 })
  defaultQuantity: string;

  @Column({ name: 'display_order', type: 'integer' })
  displayOrder: number;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\menu\entities\menu-item-ingredient.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { MenuItem } from './menu-item.entity';

@Entity('menu_item_sizes')
export class MenuItemSize {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'menu_item_id', type: 'uuid' })
  menuItemId: string;

  @ManyToOne(() => MenuItem, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'menu_item_id' })
  menuItem: MenuItem;

  @Column({ name: 'size_code', type: 'varchar', length: 30 })
  sizeCode: string;

  @Column({ name: 'display_name', type: 'varchar', length: 80 })
  displayName: string;

  @Column({ name: 'base_price_minor', type: 'integer' })
  basePriceMinor: number;

  @Column({ name: 'calories', type: 'integer', nullable: true })
  calories?: number;

  @Column({ name: 'display_order', type: 'integer' })
  displayOrder: number;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\menu\entities\menu-item-size.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';
import { MenuCategory } from '../../categories/entities/menu-category.entity';
import { MediaAsset } from '../../media/entities/media-asset.entity';

@Entity('menu_items')
export class MenuItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'category_id', type: 'uuid', nullable: true })
  categoryId?: string;

  @ManyToOne(() => MenuCategory, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'category_id' })
  category?: MenuCategory;

  @Column({ name: 'name', type: 'varchar', length: 180 })
  name: string;

  @Column({ name: 'slug', type: 'varchar', length: 200 })
  slug: string;

  @Column({ name: 'description', type: 'text', nullable: true })
  description?: string;

  @Column({ name: 'image_asset_id', type: 'uuid', nullable: true })
  imageAssetId?: string;

  @ManyToOne(() => MediaAsset, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'image_asset_id' })
  imageAsset?: MediaAsset;

  @Column({ name: 'item_type', type: 'varchar', length: 30 })
  itemType: string;

  @Column({ name: 'calories', type: 'integer', nullable: true })
  calories?: number;

  @Column({ name: 'preparation_minutes', type: 'integer' })
  preparationMinutes: number;

  @Column({ name: 'is_vegetarian', type: 'boolean' })
  isVegetarian: boolean;

  @Column({ name: 'is_vegan', type: 'boolean' })
  isVegan: boolean;

  @Column({ name: 'is_gluten_free', type: 'boolean' })
  isGlutenFree: boolean;

  @Column({ name: 'is_spicy', type: 'boolean' })
  isSpicy: boolean;

  @Column({ name: 'is_popular', type: 'boolean' })
  isPopular: boolean;

  @Column({ name: 'popularity_score', type: 'numeric', precision: 12, scale: 4 })
  popularityScore: string;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'available_from', type: 'timestamptz', nullable: true })
  availableFrom?: Date;

  @Column({ name: 'available_until', type: 'timestamptz', nullable: true })
  availableUntil?: Date;

  @Column({ name: 'archived_at', type: 'timestamptz', nullable: true })
  archivedAt?: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\menu\entities\menu-item.entity.ts' -Content $content

$content = @'
export enum MenuItemType {
  STANDARD = 'standard',
  MODIFIABLE = 'modifiable',
  BUILD_YOUR_OWN = 'build_your_own',
  SIDE = 'side',
  DRINK = 'drink',
  OTHER = 'other',
}
'@
Write-CodeFile -RelativePath 'src\modules\menu\enums\menu-item-type.enum.ts' -Content $content

$content = @'
export enum PizzaSizeCode {
  SMALL = 'small',
  MEDIUM = 'medium',
  LARGE = 'large',
  SINGLE = 'single',
}
'@
Write-CodeFile -RelativePath 'src\modules\menu\enums\pizza-size-code.enum.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { MenuItem } from '../entities/menu-item.entity';

@Injectable()
export class MenuItemRepository extends BaseRepository<MenuItem> {
  constructor(dataSource: DataSource) {
    super(dataSource, MenuItem);
  }

  searchActive(restaurantId: string, search: string): Promise<MenuItem[]> {
    return this.repository
      .createQueryBuilder('item')
      .where('item.restaurant_id = :restaurantId', { restaurantId })
      .andWhere('item.is_active = true')
      .andWhere('item.archived_at IS NULL')
      .andWhere('(item.name ILIKE :search OR item.description ILIKE :search)', {
        search: `%${search}%`,
      })
      .orderBy('item.popularity_score', 'DESC')
      .getMany();
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\menu\repositories\menu-item.repository.ts' -Content $content

$content = @'
import { IsEnum, IsString, MaxLength } from 'class-validator';
import { DevicePlatform } from '../enums/device-platform.enum';

export class RegisterDeviceTokenDto {
  @IsEnum(DevicePlatform) platform: DevicePlatform;
  @IsString() @MaxLength(4096) token: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\notifications\dto\register-device-token.dto.ts' -Content $content

$content = @'
import { IsBoolean, IsOptional, IsString } from 'class-validator';

export class UpdateNotificationPreferencesDto {
  @IsOptional() @IsBoolean() pushOrderUpdates?: boolean;
  @IsOptional() @IsBoolean() smsOrderUpdates?: boolean;
  @IsOptional() @IsBoolean() emailOrderUpdates?: boolean;
  @IsOptional() @IsBoolean() pushPromotions?: boolean;
  @IsOptional() @IsBoolean() smsPromotions?: boolean;
  @IsOptional() @IsBoolean() emailPromotions?: boolean;
  @IsOptional() @IsBoolean() couponExpirationAlerts?: boolean;
  @IsOptional() @IsString() quietHoursStart?: string;
  @IsOptional() @IsString() quietHoursEnd?: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\notifications\dto\update-notification-preferences.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('device_tokens')
export class DeviceToken {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'platform', type: 'varchar', length: 20 })
  platform: string;

  @Column({ name: 'provider', type: 'varchar', length: 30 })
  provider: string;

  @Column({ name: 'token', type: 'text', unique: true })
  token: string;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'last_seen_at', type: 'timestamptz', nullable: true })
  lastSeenAt?: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\notifications\entities\device-token.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Notification } from './notification.entity';

@Entity('notification_deliveries')
export class NotificationDelivery {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'notification_id', type: 'uuid' })
  notificationId: string;

  @ManyToOne(() => Notification, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'notification_id' })
  notification: Notification;

  @Column({ name: 'channel', type: 'varchar', length: 20 })
  channel: string;

  @Column({ name: 'provider', type: 'varchar', length: 40, nullable: true })
  provider?: string;

  @Column({ name: 'provider_message_id', type: 'varchar', length: 255, nullable: true })
  providerMessageId?: string;

  @Column({ name: 'destination_masked', type: 'varchar', length: 255, nullable: true })
  destinationMasked?: string;

  @Column({ name: 'status', type: 'varchar', length: 30 })
  status: string;

  @Column({ name: 'attempts', type: 'integer' })
  attempts: number;

  @Column({ name: 'last_error', type: 'text', nullable: true })
  lastError?: string;

  @Column({ name: 'sent_at', type: 'timestamptz', nullable: true })
  sentAt?: Date;

  @Column({ name: 'delivered_at', type: 'timestamptz', nullable: true })
  deliveredAt?: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\notifications\entities\notification-delivery.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('notification_preferences')
export class NotificationPreference {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid', unique: true })
  userId: string;

  @OneToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'push_order_updates', type: 'boolean' })
  pushOrderUpdates: boolean;

  @Column({ name: 'sms_order_updates', type: 'boolean' })
  smsOrderUpdates: boolean;

  @Column({ name: 'email_order_updates', type: 'boolean' })
  emailOrderUpdates: boolean;

  @Column({ name: 'push_promotions', type: 'boolean' })
  pushPromotions: boolean;

  @Column({ name: 'sms_promotions', type: 'boolean' })
  smsPromotions: boolean;

  @Column({ name: 'email_promotions', type: 'boolean' })
  emailPromotions: boolean;

  @Column({ name: 'coupon_expiration_alerts', type: 'boolean' })
  couponExpirationAlerts: boolean;

  @Column({ name: 'quiet_hours_start', type: 'time', nullable: true })
  quietHoursStart?: string;

  @Column({ name: 'quiet_hours_end', type: 'time', nullable: true })
  quietHoursEnd?: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\notifications\entities\notification-preference.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Order } from '../../orders/entities/order.entity';
import { Promotion } from '../../promotions/entities/promotion.entity';
import { Coupon } from '../../coupons/entities/coupon.entity';

@Entity('notifications')
export class Notification {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid', nullable: true })
  userId?: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @Column({ name: 'order_id', type: 'uuid', nullable: true })
  orderId?: string;

  @ManyToOne(() => Order, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'order_id' })
  order?: Order;

  @Column({ name: 'promotion_id', type: 'uuid', nullable: true })
  promotionId?: string;

  @ManyToOne(() => Promotion, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'promotion_id' })
  promotion?: Promotion;

  @Column({ name: 'coupon_id', type: 'uuid', nullable: true })
  couponId?: string;

  @ManyToOne(() => Coupon, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'coupon_id' })
  coupon?: Coupon;

  @Column({ name: 'type', type: 'varchar', length: 50 })
  type: string;

  @Column({ name: 'title', type: 'varchar', length: 180 })
  title: string;

  @Column({ name: 'body', type: 'text' })
  body: string;

  @Column({ name: 'payload', type: 'jsonb' })
  payload: Record<string, unknown>;

  @Column({ name: 'read_at', type: 'timestamptz', nullable: true })
  readAt?: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\notifications\entities\notification.entity.ts' -Content $content

$content = @'
export enum DevicePlatform {
  IOS = 'ios',
  ANDROID = 'android',
  WEB = 'web',
}
'@
Write-CodeFile -RelativePath 'src\modules\notifications\enums\device-platform.enum.ts' -Content $content

$content = @'
export enum NotificationChannel {
  PUSH = 'push',
  SMS = 'sms',
  EMAIL = 'email',
  IN_APP = 'in_app',
}
'@
Write-CodeFile -RelativePath 'src\modules\notifications\enums\notification-channel.enum.ts' -Content $content

$content = @'
export enum NotificationDeliveryStatus {
  PENDING = 'pending',
  SENT = 'sent',
  DELIVERED = 'delivered',
  FAILED = 'failed',
  SKIPPED = 'skipped',
}
'@
Write-CodeFile -RelativePath 'src\modules\notifications\enums\notification-delivery-status.enum.ts' -Content $content

$content = @'
export enum NotificationType {
  ORDER_CONFIRMED = 'order_confirmed',
  ORDER_PREPARING = 'order_preparing',
  ORDER_BAKING = 'order_baking',
  ORDER_OUT_FOR_DELIVERY = 'order_out_for_delivery',
  DRIVER_ARRIVING = 'driver_arriving',
  ORDER_DELIVERED = 'order_delivered',
  PROMOTION = 'promotion',
  DISCOUNT = 'discount',
  COUPON_EXPIRING = 'coupon_expiring',
  SUPPORT_REPLY = 'support_reply',
  SYSTEM = 'system',
}
'@
Write-CodeFile -RelativePath 'src\modules\notifications\enums\notification-type.enum.ts' -Content $content

$content = @'
import { NotificationChannel } from '../enums/notification-channel.enum';
import { NotificationType } from '../enums/notification-type.enum';

export interface NotificationDispatchRequest {
  userId?: string;
  orderId?: string;
  type: NotificationType;
  title: string;
  body: string;
  channels: NotificationChannel[];
  payload?: Record<string, unknown>;
}
'@
Write-CodeFile -RelativePath 'src\modules\notifications\interfaces\notification-dispatch.interface.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Notification } from '../entities/notification.entity';

@Injectable()
export class NotificationRepository extends BaseRepository<Notification> {
  constructor(dataSource: DataSource) {
    super(dataSource, Notification);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\notifications\repositories\notification.repository.ts' -Content $content

$content = @'
import { IsBoolean, IsInt, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateOptionChoiceDto {
  @IsOptional() @IsUUID() ingredientId?: string;
  @IsString() @MaxLength(140) name: string;
  @IsString() @MaxLength(120) code: string;
  @IsOptional() @IsInt() priceAdjustmentMinor?: number;
  @IsOptional() @IsInt() caloriesAdjustment?: number;
  @IsOptional() @IsBoolean() isDefault?: boolean;
  @IsOptional() @IsInt() displayOrder?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
'@
Write-CodeFile -RelativePath 'src\modules\option-groups\dto\create-option-choice.dto.ts' -Content $content

$content = @'
import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { OptionType } from '../enums/option-type.enum';
import { CreateOptionChoiceDto } from './create-option-choice.dto';

export class CreateOptionGroupDto {
  @IsUUID() restaurantId: string;
  @IsString() @MaxLength(140) name: string;
  @IsString() @MaxLength(100) code: string;
  @IsEnum(OptionType) optionType: OptionType;
  @IsOptional() @IsInt() @Min(0) minSelect?: number;
  @IsOptional() @IsInt() @Min(0) maxSelect?: number;
  @IsOptional() @IsBoolean() isRequired?: boolean;
  @IsOptional() @IsBoolean() allowQuantity?: boolean;
  @IsOptional() @IsInt() displayOrder?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateOptionChoiceDto)
  choices?: CreateOptionChoiceDto[];
}
'@
Write-CodeFile -RelativePath 'src\modules\option-groups\dto\create-option-group.dto.ts' -Content $content

$content = @'
import { PartialType } from '@nestjs/mapped-types';
import { CreateOptionGroupDto } from './create-option-group.dto';
export class UpdateOptionGroupDto extends PartialType(CreateOptionGroupDto) {}
'@
Write-CodeFile -RelativePath 'src\modules\option-groups\dto\update-option-group.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { MenuItem } from '../../menu/entities/menu-item.entity';
import { OptionGroup } from './option-group.entity';

@Entity('menu_item_option_groups')
export class MenuItemOptionGroup {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'menu_item_id', type: 'uuid' })
  menuItemId: string;

  @ManyToOne(() => MenuItem, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'menu_item_id' })
  menuItem: MenuItem;

  @Column({ name: 'option_group_id', type: 'uuid' })
  optionGroupId: string;

  @ManyToOne(() => OptionGroup, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'option_group_id' })
  optionGroup: OptionGroup;

  @Column({ name: 'min_select_override', type: 'integer', nullable: true })
  minSelectOverride?: number;

  @Column({ name: 'max_select_override', type: 'integer', nullable: true })
  maxSelectOverride?: number;

  @Column({ name: 'display_order', type: 'integer' })
  displayOrder: number;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\option-groups\entities\menu-item-option-group.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { OptionGroup } from './option-group.entity';
import { Ingredient } from '../../ingredients/entities/ingredient.entity';

@Entity('option_choices')
export class OptionChoice {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'option_group_id', type: 'uuid' })
  optionGroupId: string;

  @ManyToOne(() => OptionGroup, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'option_group_id' })
  optionGroup: OptionGroup;

  @Column({ name: 'ingredient_id', type: 'uuid', nullable: true })
  ingredientId?: string;

  @ManyToOne(() => Ingredient, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'ingredient_id' })
  ingredient?: Ingredient;

  @Column({ name: 'name', type: 'varchar', length: 140 })
  name: string;

  @Column({ name: 'code', type: 'varchar', length: 120 })
  code: string;

  @Column({ name: 'price_adjustment_minor', type: 'integer' })
  priceAdjustmentMinor: number;

  @Column({ name: 'calories_adjustment', type: 'integer' })
  caloriesAdjustment: number;

  @Column({ name: 'is_default', type: 'boolean' })
  isDefault: boolean;

  @Column({ name: 'display_order', type: 'integer' })
  displayOrder: number;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\option-groups\entities\option-choice.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';

@Entity('option_groups')
export class OptionGroup {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'name', type: 'varchar', length: 140 })
  name: string;

  @Column({ name: 'code', type: 'varchar', length: 100 })
  code: string;

  @Column({ name: 'option_type', type: 'varchar', length: 30 })
  optionType: string;

  @Column({ name: 'min_select', type: 'integer' })
  minSelect: number;

  @Column({ name: 'max_select', type: 'integer', nullable: true })
  maxSelect?: number;

  @Column({ name: 'is_required', type: 'boolean' })
  isRequired: boolean;

  @Column({ name: 'allow_quantity', type: 'boolean' })
  allowQuantity: boolean;

  @Column({ name: 'display_order', type: 'integer' })
  displayOrder: number;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\option-groups\entities\option-group.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { OptionChoice } from './option-choice.entity';

@Entity('option_incompatibilities')
export class OptionIncompatibility {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'first_choice_id', type: 'uuid' })
  firstChoiceId: string;

  @ManyToOne(() => OptionChoice, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'first_choice_id' })
  firstChoice: OptionChoice;

  @Column({ name: 'second_choice_id', type: 'uuid' })
  secondChoiceId: string;

  @ManyToOne(() => OptionChoice, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'second_choice_id' })
  secondChoice: OptionChoice;

  @Column({ name: 'reason', type: 'varchar', length: 255, nullable: true })
  reason?: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\option-groups\entities\option-incompatibility.entity.ts' -Content $content

$content = @'
export enum OptionType {
  DOUGH = 'dough',
  SAUCE = 'sauce',
  CHEESE = 'cheese',
  TOPPING = 'topping',
  EXTRA = 'extra',
  REMOVAL = 'removal',
  GENERIC = 'generic',
}
'@
Write-CodeFile -RelativePath 'src\modules\option-groups\enums\option-type.enum.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { OptionGroup } from '../entities/option-group.entity';

@Injectable()
export class OptionGroupRepository extends BaseRepository<OptionGroup> {
  constructor(dataSource: DataSource) {
    super(dataSource, OptionGroup);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\option-groups\repositories\option-group.repository.ts' -Content $content

$content = @'
import { Type } from 'class-transformer';
import { IsDateString, IsEnum, IsInt, IsOptional, Max, Min } from 'class-validator';
import { OrderStatus } from '../enums/order-status.enum';

export class ListOrdersQueryDto {
  @IsOptional() @IsEnum(OrderStatus) status?: OrderStatus;
  @IsOptional() @IsDateString() from?: string;
  @IsOptional() @IsDateString() to?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) page?: number = 1;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100) pageSize?: number = 20;
}
'@
Write-CodeFile -RelativePath 'src\modules\orders\dto\list-orders-query.dto.ts' -Content $content

$content = @'
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { OrderStatus } from '../enums/order-status.enum';

export class UpdateOrderStatusDto {
  @IsEnum(OrderStatus)
  status: OrderStatus;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\orders\dto\update-order-status.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { OrderItem } from './order-item.entity';
import { OptionGroup } from '../../option-groups/entities/option-group.entity';
import { OptionChoice } from '../../option-groups/entities/option-choice.entity';
import { Ingredient } from '../../ingredients/entities/ingredient.entity';

@Entity('order_item_options')
export class OrderItemOption {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_item_id', type: 'uuid' })
  orderItemId: string;

  @ManyToOne(() => OrderItem, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'order_item_id' })
  orderItem: OrderItem;

  @Column({ name: 'option_group_id', type: 'uuid', nullable: true })
  optionGroupId?: string;

  @ManyToOne(() => OptionGroup, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'option_group_id' })
  optionGroup?: OptionGroup;

  @Column({ name: 'option_choice_id', type: 'uuid', nullable: true })
  optionChoiceId?: string;

  @ManyToOne(() => OptionChoice, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'option_choice_id' })
  optionChoice?: OptionChoice;

  @Column({ name: 'ingredient_id', type: 'uuid', nullable: true })
  ingredientId?: string;

  @ManyToOne(() => Ingredient, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'ingredient_id' })
  ingredient?: Ingredient;

  @Column({ name: 'action', type: 'varchar', length: 20 })
  action: string;

  @Column({ name: 'option_name_snapshot', type: 'varchar', length: 140 })
  optionNameSnapshot: string;

  @Column({ name: 'quantity', type: 'numeric', precision: 8, scale: 2 })
  quantity: string;

  @Column({ name: 'unit_price_adjustment_minor', type: 'integer' })
  unitPriceAdjustmentMinor: number;

  @Column({ name: 'total_price_adjustment_minor', type: 'integer' })
  totalPriceAdjustmentMinor: number;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\orders\entities\order-item-option.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Order } from './order.entity';
import { MenuItem } from '../../menu/entities/menu-item.entity';
import { MenuItemSize } from '../../menu/entities/menu-item-size.entity';

@Entity('order_items')
export class OrderItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_id', type: 'uuid' })
  orderId: string;

  @ManyToOne(() => Order, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Column({ name: 'menu_item_id', type: 'uuid', nullable: true })
  menuItemId?: string;

  @ManyToOne(() => MenuItem, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'menu_item_id' })
  menuItem?: MenuItem;

  @Column({ name: 'menu_item_size_id', type: 'uuid', nullable: true })
  menuItemSizeId?: string;

  @ManyToOne(() => MenuItemSize, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'menu_item_size_id' })
  menuItemSize?: MenuItemSize;

  @Column({ name: 'item_name_snapshot', type: 'varchar', length: 180 })
  itemNameSnapshot: string;

  @Column({ name: 'size_name_snapshot', type: 'varchar', length: 80, nullable: true })
  sizeNameSnapshot?: string;

  @Column({ name: 'quantity', type: 'integer' })
  quantity: number;

  @Column({ name: 'base_unit_price_minor', type: 'integer' })
  baseUnitPriceMinor: number;

  @Column({ name: 'options_unit_price_minor', type: 'integer' })
  optionsUnitPriceMinor: number;

  @Column({ name: 'unit_price_minor', type: 'integer' })
  unitPriceMinor: number;

  @Column({ name: 'line_total_minor', type: 'integer' })
  lineTotalMinor: number;

  @Column({ name: 'special_instructions', type: 'text', nullable: true })
  specialInstructions?: string;

  @Column({ name: 'configuration_snapshot', type: 'jsonb' })
  configurationSnapshot: Record<string, unknown>;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\orders\entities\order-item.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Order } from './order.entity';
import { User } from '../../users/entities/user.entity';

@Entity('order_status_history')
export class OrderStatusHistory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_id', type: 'uuid' })
  orderId: string;

  @ManyToOne(() => Order, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Column({ name: 'previous_status', type: 'varchar', length: 40, nullable: true })
  previousStatus?: string;

  @Column({ name: 'new_status', type: 'varchar', length: 40 })
  newStatus: string;

  @Column({ name: 'changed_by_user_id', type: 'uuid', nullable: true })
  changedByUserId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'changed_by_user_id' })
  changedByUser?: User;

  @Column({ name: 'note', type: 'text', nullable: true })
  note?: string;

  @Column({ name: 'occurred_at', type: 'timestamptz' })
  occurredAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\orders\entities\order-status-history.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';
import { User } from '../../users/entities/user.entity';
import { Cart } from '../../carts/entities/cart.entity';

@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_number', type: 'varchar', length: 40, unique: true })
  orderNumber: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'customer_id', type: 'uuid', nullable: true })
  customerId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'customer_id' })
  customer?: User;

  @Column({ name: 'cart_id', type: 'uuid', nullable: true })
  cartId?: string;

  @ManyToOne(() => Cart, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'cart_id' })
  cart?: Cart;

  @Column({ name: 'order_type', type: 'varchar', length: 20 })
  orderType: string;

  @Column({ name: 'status', type: 'varchar', length: 40 })
  status: string;

  @Column({ name: 'payment_status', type: 'varchar', length: 40 })
  paymentStatus: string;

  @Column({ name: 'payment_method', type: 'varchar', length: 40, nullable: true })
  paymentMethod?: string;

  @Column({ name: 'currency', type: 'char', length: 3 })
  currency: string;

  @Column({ name: 'subtotal_minor', type: 'integer' })
  subtotalMinor: number;

  @Column({ name: 'option_charges_minor', type: 'integer' })
  optionChargesMinor: number;

  @Column({ name: 'discount_minor', type: 'integer' })
  discountMinor: number;

  @Column({ name: 'loyalty_discount_minor', type: 'integer' })
  loyaltyDiscountMinor: number;

  @Column({ name: 'delivery_fee_minor', type: 'integer' })
  deliveryFeeMinor: number;

  @Column({ name: 'tax_minor', type: 'integer' })
  taxMinor: number;

  @Column({ name: 'grand_total_minor', type: 'integer' })
  grandTotalMinor: number;

  @Column({ name: 'delivery_address_snapshot', type: 'jsonb', nullable: true })
  deliveryAddressSnapshot?: Record<string, unknown>;

  @Column({ name: 'delivery_instructions', type: 'text', nullable: true })
  deliveryInstructions?: string;

  @Column({ name: 'customer_note', type: 'text', nullable: true })
  customerNote?: string;

  @Column({ name: 'estimated_delivery_at', type: 'timestamptz', nullable: true })
  estimatedDeliveryAt?: Date;

  @Column({ name: 'scheduled_for', type: 'timestamptz', nullable: true })
  scheduledFor?: Date;

  @Column({ name: 'placed_at', type: 'timestamptz', nullable: true })
  placedAt?: Date;

  @Column({ name: 'accepted_at', type: 'timestamptz', nullable: true })
  acceptedAt?: Date;

  @Column({ name: 'delivered_at', type: 'timestamptz', nullable: true })
  deliveredAt?: Date;

  @Column({ name: 'cancelled_at', type: 'timestamptz', nullable: true })
  cancelledAt?: Date;

  @Column({ name: 'cancellation_reason', type: 'text', nullable: true })
  cancellationReason?: string;

  @Column({ name: 'pricing_snapshot', type: 'jsonb' })
  pricingSnapshot: Record<string, unknown>;

  @Column({ name: 'version', type: 'bigint' })
  version: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\orders\entities\order.entity.ts' -Content $content

$content = @'
export enum OrderStatus {
  PENDING_PAYMENT = 'pending_payment',
  PLACED = 'placed',
  ACCEPTED = 'accepted',
  PREPARING = 'preparing',
  BAKING = 'baking',
  PACKING = 'packing',
  READY = 'ready',
  DRIVER_ASSIGNED = 'driver_assigned',
  OUT_FOR_DELIVERY = 'out_for_delivery',
  DELIVERED = 'delivered',
  CLOSED = 'closed',
  CANCELLED = 'cancelled',
  REJECTED = 'rejected',
}
'@
Write-CodeFile -RelativePath 'src\modules\orders\enums\order-status.enum.ts' -Content $content

$content = @'
export enum OrderType {
  DELIVERY = 'delivery',
  PICKUP = 'pickup',
}
'@
Write-CodeFile -RelativePath 'src\modules\orders\enums\order-type.enum.ts' -Content $content

$content = @'
export interface OrderPricingSnapshot {
  menuVersion?: string;
  currency: 'EUR';
  subtotalMinor: number;
  optionChargesMinor: number;
  promotionDiscountMinor: number;
  couponDiscountMinor: number;
  loyaltyDiscountMinor: number;
  deliveryFeeMinor: number;
  taxMinor: number;
  grandTotalMinor: number;
}
'@
Write-CodeFile -RelativePath 'src\modules\orders\interfaces\order-pricing-snapshot.interface.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Order } from '../entities/order.entity';

@Injectable()
export class OrderRepository extends BaseRepository<Order> {
  constructor(dataSource: DataSource) {
    super(dataSource, Order);
  }

  findByOrderNumber(orderNumber: string): Promise<Order | null> {
    return this.repository.findOne({ where: { orderNumber } });
  }

  findCustomerHistory(customerId: string, take = 20, skip = 0): Promise<Order[]> {
    return this.repository.find({
      where: { customerId },
      order: { createdAt: 'DESC' },
      take,
      skip,
    });
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\orders\repositories\order.repository.ts' -Content $content

$content = @'
import { IsEnum, IsString, IsUUID, MaxLength } from 'class-validator';
import { PaymentMethodType } from '../enums/payment-method-type.enum';

export class CollectPaymentDto {
  @IsUUID() orderId: string;
  @IsEnum(PaymentMethodType) paymentMethodType: PaymentMethodType;
  @IsString() @MaxLength(255) idempotencyKey: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\payments\dto\collect-payment.dto.ts' -Content $content

$content = @'
import { IsEnum, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';
import { PaymentMethodType } from '../enums/payment-method-type.enum';

export class CreatePaymentIntentDto {
  @IsUUID() orderId: string;
  @IsEnum(PaymentMethodType) paymentMethodType: PaymentMethodType;
  @IsOptional() @IsUUID() savedPaymentMethodId?: string;
  @IsOptional() @IsString() @MaxLength(255) idempotencyKey?: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\payments\dto\create-payment-intent.dto.ts' -Content $content

$content = @'
import { IsBoolean, IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { PaymentMethodType } from '../enums/payment-method-type.enum';

export class SavePaymentMethodDto {
  @IsEnum(PaymentMethodType) paymentMethodType: PaymentMethodType;
  @IsString() @MaxLength(255) providerPaymentMethodId: string;
  @IsOptional() @IsBoolean() isDefault?: boolean;
  @IsOptional() @IsString() @MaxLength(80) label?: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\payments\dto\save-payment-method.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('customer_payment_methods')
export class CustomerPaymentMethod {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'customer_id', type: 'uuid' })
  customerId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'customer_id' })
  customer: User;

  @Column({ name: 'provider', type: 'varchar', length: 30 })
  provider: string;

  @Column({ name: 'provider_customer_id', type: 'varchar', length: 255, nullable: true })
  providerCustomerId?: string;

  @Column({ name: 'provider_payment_method_id', type: 'varchar', length: 255, nullable: true })
  providerPaymentMethodId?: string;

  @Column({ name: 'payment_method_type', type: 'varchar', length: 40 })
  paymentMethodType: string;

  @Column({ name: 'card_brand', type: 'varchar', length: 40, nullable: true })
  cardBrand?: string;

  @Column({ name: 'card_last4', type: 'char', length: 4, nullable: true })
  cardLast4?: string;

  @Column({ name: 'exp_month', type: 'smallint', nullable: true })
  expMonth?: number;

  @Column({ name: 'exp_year', type: 'smallint', nullable: true })
  expYear?: number;

  @Column({ name: 'label', type: 'varchar', length: 80, nullable: true })
  label?: string;

  @Column({ name: 'is_default', type: 'boolean' })
  isDefault: boolean;

  @Column({ name: 'archived_at', type: 'timestamptz', nullable: true })
  archivedAt?: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\payments\entities\customer-payment-method.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Order } from '../../orders/entities/order.entity';
import { PaymentTransaction } from './payment-transaction.entity';

@Entity('payment_receipts')
export class PaymentReceipt {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_id', type: 'uuid' })
  orderId: string;

  @ManyToOne(() => Order, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Column({ name: 'payment_transaction_id', type: 'uuid', nullable: true })
  paymentTransactionId?: string;

  @ManyToOne(() => PaymentTransaction, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'payment_transaction_id' })
  paymentTransaction?: PaymentTransaction;

  @Column({ name: 'receipt_number', type: 'varchar', length: 80, unique: true })
  receiptNumber: string;

  @Column({ name: 'issued_at', type: 'timestamptz' })
  issuedAt: Date;

  @Column({ name: 'amount_minor', type: 'integer' })
  amountMinor: number;

  @Column({ name: 'tax_minor', type: 'integer' })
  taxMinor: number;

  @Column({ name: 'currency', type: 'char', length: 3 })
  currency: string;

  @Column({ name: 'provider_receipt_url', type: 'text', nullable: true })
  providerReceiptUrl?: string;

  @Column({ name: 'receipt_data', type: 'jsonb' })
  receiptData: Record<string, unknown>;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\payments\entities\payment-receipt.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Order } from '../../orders/entities/order.entity';
import { User } from '../../users/entities/user.entity';
import { CustomerPaymentMethod } from './customer-payment-method.entity';

@Entity('payment_transactions')
export class PaymentTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_id', type: 'uuid' })
  orderId: string;

  @ManyToOne(() => Order, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Column({ name: 'customer_id', type: 'uuid', nullable: true })
  customerId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'customer_id' })
  customer?: User;

  @Column({ name: 'payment_method_id', type: 'uuid', nullable: true })
  paymentMethodId?: string;

  @ManyToOne(() => CustomerPaymentMethod, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'payment_method_id' })
  paymentMethod?: CustomerPaymentMethod;

  @Column({ name: 'provider', type: 'varchar', length: 40 })
  provider: string;

  @Column({ name: 'payment_method_type', type: 'varchar', length: 40 })
  paymentMethodType: string;

  @Column({ name: 'provider_payment_intent_id', type: 'varchar', length: 255, nullable: true })
  providerPaymentIntentId?: string;

  @Column({ name: 'provider_charge_id', type: 'varchar', length: 255, nullable: true })
  providerChargeId?: string;

  @Column({ name: 'amount_minor', type: 'integer' })
  amountMinor: number;

  @Column({ name: 'currency', type: 'char', length: 3 })
  currency: string;

  @Column({ name: 'status', type: 'varchar', length: 40 })
  status: string;

  @Column({ name: 'idempotency_key', type: 'varchar', length: 255, nullable: true })
  idempotencyKey?: string;

  @Column({ name: 'failure_code', type: 'varchar', length: 120, nullable: true })
  failureCode?: string;

  @Column({ name: 'failure_message', type: 'text', nullable: true })
  failureMessage?: string;

  @Column({ name: 'authorized_at', type: 'timestamptz', nullable: true })
  authorizedAt?: Date;

  @Column({ name: 'captured_at', type: 'timestamptz', nullable: true })
  capturedAt?: Date;

  @Column({ name: 'failed_at', type: 'timestamptz', nullable: true })
  failedAt?: Date;

  @Column({ name: 'metadata', type: 'jsonb' })
  metadata: Record<string, unknown>;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\payments\entities\payment-transaction.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('payment_webhook_events')
export class PaymentWebhookEvent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'provider', type: 'varchar', length: 30 })
  provider: string;

  @Column({ name: 'provider_event_id', type: 'varchar', length: 255 })
  providerEventId: string;

  @Column({ name: 'event_type', type: 'varchar', length: 160 })
  eventType: string;

  @Column({ name: 'payload', type: 'jsonb' })
  payload: Record<string, unknown>;

  @Column({ name: 'processing_status', type: 'varchar', length: 30 })
  processingStatus: string;

  @Column({ name: 'attempts', type: 'integer' })
  attempts: number;

  @Column({ name: 'processed_at', type: 'timestamptz', nullable: true })
  processedAt?: Date;

  @Column({ name: 'last_error', type: 'text', nullable: true })
  lastError?: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\payments\entities\payment-webhook-event.entity.ts' -Content $content

$content = @'
export enum OrderPaymentStatus {
  PENDING = 'pending',
  AUTHORIZED = 'authorized',
  PAID = 'paid',
  COLLECTION_PENDING = 'collection_pending',
  PARTIALLY_REFUNDED = 'partially_refunded',
  REFUNDED = 'refunded',
  FAILED = 'failed',
  CANCELLED = 'cancelled',
}
'@
Write-CodeFile -RelativePath 'src\modules\payments\enums\order-payment-status.enum.ts' -Content $content

$content = @'
export enum PaymentMethodType {
  CARD = 'card',
  APPLE_PAY = 'apple_pay',
  GOOGLE_PAY = 'google_pay',
  SATISPAY = 'satispay',
  CASH = 'cash',
  CARD_ON_DELIVERY = 'card_on_delivery',
  OTHER_WALLET = 'other_wallet',
}
'@
Write-CodeFile -RelativePath 'src\modules\payments\enums\payment-method-type.enum.ts' -Content $content

$content = @'
export enum PaymentProvider {
  STRIPE = 'stripe',
  CASH = 'cash',
  EXTERNAL_TERMINAL = 'external_terminal',
}
'@
Write-CodeFile -RelativePath 'src\modules\payments\enums\payment-provider.enum.ts' -Content $content

$content = @'
export enum PaymentTransactionStatus {
  PENDING = 'pending',
  REQUIRES_ACTION = 'requires_action',
  AUTHORIZED = 'authorized',
  CAPTURED = 'captured',
  FAILED = 'failed',
  COLLECTION_PENDING = 'collection_pending',
  CANCELLED = 'cancelled',
  PARTIALLY_REFUNDED = 'partially_refunded',
  REFUNDED = 'refunded',
}
'@
Write-CodeFile -RelativePath 'src\modules\payments\enums\payment-transaction-status.enum.ts' -Content $content

$content = @'
export enum WebhookProcessingStatus {
  PENDING = 'pending',
  PROCESSED = 'processed',
  IGNORED = 'ignored',
  FAILED = 'failed',
}
'@
Write-CodeFile -RelativePath 'src\modules\payments\enums\webhook-processing-status.enum.ts' -Content $content

$content = @'
import { PaymentMethodType } from '../enums/payment-method-type.enum';

export interface CreateProviderPaymentInput {
  orderId: string;
  customerId?: string;
  amountMinor: number;
  currency: 'EUR';
  paymentMethodType: PaymentMethodType;
  providerPaymentMethodId?: string;
  idempotencyKey: string;
}

export interface ProviderPaymentResult {
  providerPaymentIntentId?: string;
  providerChargeId?: string;
  clientSecret?: string;
  status: string;
}

export interface PaymentProviderPort {
  createPayment(input: CreateProviderPaymentInput): Promise<ProviderPaymentResult>;
  refund(providerPaymentIntentId: string, amountMinor: number, idempotencyKey: string): Promise<string>;
}
'@
Write-CodeFile -RelativePath 'src\modules\payments\interfaces\payment-provider.interface.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { PaymentTransaction } from '../entities/payment-transaction.entity';

@Injectable()
export class PaymentTransactionRepository extends BaseRepository<PaymentTransaction> {
  constructor(dataSource: DataSource) {
    super(dataSource, PaymentTransaction);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\payments\repositories\payment-transaction.repository.ts' -Content $content

$content = @'
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

  @OneToMany(() => RolePermission, (rolePermission) => rolePermission.permission)
  rolePermissions: RolePermission[];

  @OneToMany(() => UserPermission, (userPermission) => userPermission.permission)
  userPermissions: UserPermission[];

  @ManyToMany(() => Role, (role) => role.permissions)
  roles: Role[];

  @ManyToMany(() => User, (user) => user.permissions)
  users: User[];

  @Column({ name: 'created_at', type: 'timestamptz', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz', default: () => 'CURRENT_TIMESTAMP' })
  updatedAt: Date;
}
'@
Write-CodeFile -RelativePath 'src\modules\permissions\entities\permission.entity.ts' -Content $content

$content = @'
import { ArrayMaxSize, IsArray, IsOptional, IsUUID } from 'class-validator';

export class BuildPizzaDto {
  @IsUUID() menuItemId: string;
  @IsUUID() menuItemSizeId: string;
  @IsOptional() @IsUUID() doughChoiceId?: string;
  @IsOptional() @IsUUID() sauceChoiceId?: string;
  @IsOptional() @IsUUID() cheeseChoiceId?: string;
  @IsArray() @ArrayMaxSize(30) @IsUUID(undefined, { each: true }) toppingChoiceIds: string[];
}
'@
Write-CodeFile -RelativePath 'src\modules\pizza-builder\dto\build-pizza.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';
import { MenuItem } from '../../menu/entities/menu-item.entity';
import { OptionGroup } from '../../option-groups/entities/option-group.entity';

@Entity('pizza_builder_rules')
export class PizzaBuilderRule {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'menu_item_id', type: 'uuid', nullable: true })
  menuItemId?: string;

  @ManyToOne(() => MenuItem, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'menu_item_id' })
  menuItem?: MenuItem;

  @Column({ name: 'name', type: 'varchar', length: 160 })
  name: string;

  @Column({ name: 'size_group_id', type: 'uuid', nullable: true })
  sizeGroupId?: string;

  @ManyToOne(() => OptionGroup, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'size_group_id' })
  sizeGroup?: OptionGroup;

  @Column({ name: 'dough_group_id', type: 'uuid', nullable: true })
  doughGroupId?: string;

  @ManyToOne(() => OptionGroup, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'dough_group_id' })
  doughGroup?: OptionGroup;

  @Column({ name: 'sauce_group_id', type: 'uuid', nullable: true })
  sauceGroupId?: string;

  @ManyToOne(() => OptionGroup, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'sauce_group_id' })
  sauceGroup?: OptionGroup;

  @Column({ name: 'cheese_group_id', type: 'uuid', nullable: true })
  cheeseGroupId?: string;

  @ManyToOne(() => OptionGroup, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'cheese_group_id' })
  cheeseGroup?: OptionGroup;

  @Column({ name: 'toppings_group_id', type: 'uuid', nullable: true })
  toppingsGroupId?: string;

  @ManyToOne(() => OptionGroup, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'toppings_group_id' })
  toppingsGroup?: OptionGroup;

  @Column({ name: 'max_total_toppings', type: 'integer', nullable: true })
  maxTotalToppings?: number;

  @Column({ name: 'free_topping_count', type: 'integer' })
  freeToppingCount: number;

  @Column({ name: 'rule_config', type: 'jsonb' })
  ruleConfig: Record<string, unknown>;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\pizza-builder\entities\pizza-builder-rule.entity.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { PizzaBuilderRule } from '../entities/pizza-builder-rule.entity';

@Injectable()
export class PizzaBuilderRuleRepository extends BaseRepository<PizzaBuilderRule> {
  constructor(dataSource: DataSource) {
    super(dataSource, PizzaBuilderRule);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\pizza-builder\repositories\pizza-builder-rule.repository.ts' -Content $content

$content = @'
import { MoneyBreakdown } from '../../../common/interfaces/money.interface';

export interface PriceBreakdown extends MoneyBreakdown {
  appliedPromotionIds: string[];
  appliedCouponId?: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\pricing\interfaces\price-breakdown.interface.ts' -Content $content

$content = @'
export interface PricingSelection {
  optionGroupId?: string;
  optionChoiceId?: string;
  ingredientId?: string;
  action: 'add' | 'remove' | 'replace';
  quantity: number;
}

export interface PricingContext {
  restaurantId: string;
  customerId?: string;
  menuItemId: string;
  menuItemSizeId?: string;
  quantity: number;
  selections: PricingSelection[];
  couponCode?: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\pricing\interfaces\pricing-context.interface.ts' -Content $content

$content = @'
import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';
import { PromotionType } from '../enums/promotion-type.enum';

export class CreatePromotionDto {
  @IsUUID() restaurantId: string;
  @IsString() @MaxLength(180) name: string;
  @IsOptional() @IsString() description?: string;
  @IsEnum(PromotionType) promotionType: PromotionType;
  @IsOptional() @IsInt() @Min(0) discountValue?: number;
  @IsOptional() @IsInt() @Min(0) minOrderMinor?: number;
  @IsOptional() @IsInt() @Min(0) maxDiscountMinor?: number;
  @IsDateString() startsAt: string;
  @IsOptional() @IsDateString() endsAt?: string;
  @IsOptional() @IsInt() @Min(1) totalUsageLimit?: number;
  @IsOptional() @IsInt() @Min(1) perCustomerLimit?: number;
  @IsOptional() @IsInt() priority?: number;
  @IsOptional() @IsString() @MaxLength(80) stackingGroup?: string;
  @IsOptional() @IsBoolean() isAutomatic?: boolean;
  @IsOptional() @IsBoolean() isActive?: boolean;
  @IsOptional() @IsObject() conditions?: Record<string, unknown>;
  @IsOptional() @IsObject() actions?: Record<string, unknown>;
}
'@
Write-CodeFile -RelativePath 'src\modules\promotions\dto\create-promotion.dto.ts' -Content $content

$content = @'
import { PartialType } from '@nestjs/mapped-types';
import { CreatePromotionDto } from './create-promotion.dto';
export class UpdatePromotionDto extends PartialType(CreatePromotionDto) {}
'@
Write-CodeFile -RelativePath 'src\modules\promotions\dto\update-promotion.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Promotion } from './promotion.entity';
import { MenuItem } from '../../menu/entities/menu-item.entity';
import { MenuCategory } from '../../categories/entities/menu-category.entity';

@Entity('promotion_items')
export class PromotionItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'promotion_id', type: 'uuid' })
  promotionId: string;

  @ManyToOne(() => Promotion, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'promotion_id' })
  promotion: Promotion;

  @Column({ name: 'menu_item_id', type: 'uuid', nullable: true })
  menuItemId?: string;

  @ManyToOne(() => MenuItem, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'menu_item_id' })
  menuItem?: MenuItem;

  @Column({ name: 'category_id', type: 'uuid', nullable: true })
  categoryId?: string;

  @ManyToOne(() => MenuCategory, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'category_id' })
  category?: MenuCategory;

  @Column({ name: 'eligibility_type', type: 'varchar', length: 20 })
  eligibilityType: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\promotions\entities\promotion-item.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Promotion } from './promotion.entity';
import { User } from '../../users/entities/user.entity';

@Entity('promotion_redemptions')
export class PromotionRedemption {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'promotion_id', type: 'uuid' })
  promotionId: string;

  @ManyToOne(() => Promotion, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'promotion_id' })
  promotion: Promotion;

  @Column({ name: 'customer_id', type: 'uuid', nullable: true })
  customerId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'customer_id' })
  customer?: User;

  @Column({ name: 'order_id', type: 'uuid', nullable: true })
  orderId?: string;

  @Column({ name: 'discount_minor', type: 'integer' })
  discountMinor: number;

  @Column({ name: 'redeemed_at', type: 'timestamptz' })
  redeemedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\promotions\entities\promotion-redemption.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';

@Entity('promotions')
export class Promotion {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'name', type: 'varchar', length: 180 })
  name: string;

  @Column({ name: 'description', type: 'text', nullable: true })
  description?: string;

  @Column({ name: 'promotion_type', type: 'varchar', length: 40 })
  promotionType: string;

  @Column({ name: 'discount_value', type: 'integer' })
  discountValue: number;

  @Column({ name: 'min_order_minor', type: 'integer' })
  minOrderMinor: number;

  @Column({ name: 'max_discount_minor', type: 'integer', nullable: true })
  maxDiscountMinor?: number;

  @Column({ name: 'starts_at', type: 'timestamptz' })
  startsAt: Date;

  @Column({ name: 'ends_at', type: 'timestamptz', nullable: true })
  endsAt?: Date;

  @Column({ name: 'days_of_week', type: 'smallint', array: true })
  daysOfWeek: number[];

  @Column({ name: 'total_usage_limit', type: 'integer', nullable: true })
  totalUsageLimit?: number;

  @Column({ name: 'per_customer_limit', type: 'integer', nullable: true })
  perCustomerLimit?: number;

  @Column({ name: 'priority', type: 'integer' })
  priority: number;

  @Column({ name: 'stacking_group', type: 'varchar', length: 80, nullable: true })
  stackingGroup?: string;

  @Column({ name: 'is_automatic', type: 'boolean' })
  isAutomatic: boolean;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'conditions', type: 'jsonb' })
  conditions: Record<string, unknown>;

  @Column({ name: 'actions', type: 'jsonb' })
  actions: Record<string, unknown>;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\promotions\entities\promotion.entity.ts' -Content $content

$content = @'
export enum PromotionEligibilityType {
  ELIGIBLE = 'eligible',
  REWARD = 'reward',
  EXCLUDED = 'excluded',
}
'@
Write-CodeFile -RelativePath 'src\modules\promotions\enums\promotion-eligibility-type.enum.ts' -Content $content

$content = @'
export enum PromotionType {
  PERCENTAGE = 'percentage',
  FIXED_AMOUNT = 'fixed_amount',
  FREE_DELIVERY = 'free_delivery',
  BOGO = 'bogo',
  FREE_ITEM = 'free_item',
  BUNDLE = 'bundle',
  STUDENT = 'student',
  CUSTOM = 'custom',
}
'@
Write-CodeFile -RelativePath 'src\modules\promotions\enums\promotion-type.enum.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Promotion } from '../entities/promotion.entity';

@Injectable()
export class PromotionRepository extends BaseRepository<Promotion> {
  constructor(dataSource: DataSource) {
    super(dataSource, Promotion);
  }

  findActiveForRestaurant(restaurantId: string): Promise<Promotion[]> {
    return this.repository
      .createQueryBuilder('promotion')
      .where('promotion.restaurant_id = :restaurantId', { restaurantId })
      .andWhere('promotion.is_active = true')
      .andWhere('promotion.starts_at <= NOW()')
      .andWhere('(promotion.ends_at IS NULL OR promotion.ends_at > NOW())')
      .orderBy('promotion.priority', 'DESC')
      .getMany();
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\promotions\repositories\promotion.repository.ts' -Content $content

$content = @'
import { IsInt, IsOptional, IsString, IsUUID, MaxLength, Min } from 'class-validator';

export class CreateRefundDto {
  @IsUUID() orderId: string;
  @IsOptional() @IsUUID() paymentTransactionId?: string;
  @IsInt() @Min(1) amountMinor: number;
  @IsString() @MaxLength(80) reason: string;
  @IsOptional() @IsString() @MaxLength(2000) customerReason?: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\refunds\dto\create-refund.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Order } from '../../orders/entities/order.entity';
import { PaymentTransaction } from '../../payments/entities/payment-transaction.entity';
import { User } from '../../users/entities/user.entity';

@Entity('refunds')
export class Refund {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_id', type: 'uuid' })
  orderId: string;

  @ManyToOne(() => Order, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Column({ name: 'payment_transaction_id', type: 'uuid', nullable: true })
  paymentTransactionId?: string;

  @ManyToOne(() => PaymentTransaction, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'payment_transaction_id' })
  paymentTransaction?: PaymentTransaction;

  @Column({ name: 'requested_by_user_id', type: 'uuid', nullable: true })
  requestedByUserId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'requested_by_user_id' })
  requestedByUser?: User;

  @Column({ name: 'provider_refund_id', type: 'varchar', length: 255, nullable: true })
  providerRefundId?: string;

  @Column({ name: 'amount_minor', type: 'integer' })
  amountMinor: number;

  @Column({ name: 'reason', type: 'varchar', length: 80 })
  reason: string;

  @Column({ name: 'customer_reason', type: 'text', nullable: true })
  customerReason?: string;

  @Column({ name: 'status', type: 'varchar', length: 30 })
  status: string;

  @Column({ name: 'staff_note', type: 'text', nullable: true })
  staffNote?: string;

  @Column({ name: 'requested_at', type: 'timestamptz' })
  requestedAt: Date;

  @Column({ name: 'processed_at', type: 'timestamptz', nullable: true })
  processedAt?: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\refunds\entities\refund.entity.ts' -Content $content

$content = @'
export enum RefundStatus {
  REQUESTED = 'requested',
  APPROVED = 'approved',
  PROCESSING = 'processing',
  REFUNDED = 'refunded',
  REJECTED = 'rejected',
  FAILED = 'failed',
  CANCELLED = 'cancelled',
}
'@
Write-CodeFile -RelativePath 'src\modules\refunds\enums\refund-status.enum.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Refund } from '../entities/refund.entity';

@Injectable()
export class RefundRepository extends BaseRepository<Refund> {
  constructor(dataSource: DataSource) {
    super(dataSource, Refund);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\refunds\repositories\refund.repository.ts' -Content $content

$content = @'
import { IsDateString, IsOptional, IsUUID } from 'class-validator';

export class SalesReportQueryDto {
  @IsOptional() @IsUUID() restaurantId?: string;
  @IsDateString() from: string;
  @IsDateString() to: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\reports\dto\sales-report-query.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';

@Entity('daily_sales_metrics')
export class DailySalesMetric {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'metric_date', type: 'date' })
  metricDate: string;

  @Column({ name: 'total_orders', type: 'integer' })
  totalOrders: number;

  @Column({ name: 'delivered_orders', type: 'integer' })
  deliveredOrders: number;

  @Column({ name: 'cancelled_orders', type: 'integer' })
  cancelledOrders: number;

  @Column({ name: 'gross_revenue_minor', type: 'bigint' })
  grossRevenueMinor: string;

  @Column({ name: 'discounts_minor', type: 'bigint' })
  discountsMinor: string;

  @Column({ name: 'refunds_minor', type: 'bigint' })
  refundsMinor: string;

  @Column({ name: 'delivery_fees_minor', type: 'bigint' })
  deliveryFeesMinor: string;

  @Column({ name: 'tax_minor', type: 'bigint' })
  taxMinor: string;

  @Column({ name: 'net_revenue_minor', type: 'bigint' })
  netRevenueMinor: string;

  @Column({ name: 'average_order_value_minor', type: 'integer' })
  averageOrderValueMinor: number;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\reports\entities\daily-sales-metric.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';
import { MenuItem } from '../../menu/entities/menu-item.entity';

@Entity('item_sales_metrics')
export class ItemSalesMetric {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'menu_item_id', type: 'uuid', nullable: true })
  menuItemId?: string;

  @ManyToOne(() => MenuItem, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'menu_item_id' })
  menuItem?: MenuItem;

  @Column({ name: 'metric_date', type: 'date' })
  metricDate: string;

  @Column({ name: 'item_name_snapshot', type: 'varchar', length: 180 })
  itemNameSnapshot: string;

  @Column({ name: 'quantity_sold', type: 'integer' })
  quantitySold: number;

  @Column({ name: 'revenue_minor', type: 'bigint' })
  revenueMinor: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\reports\entities\item-sales-metric.entity.ts' -Content $content

$content = @'
export interface SalesReportSummary {
  totalOrders: number;
  deliveredOrders: number;
  cancelledOrders: number;
  grossRevenueMinor: number;
  discountsMinor: number;
  refundsMinor: number;
  deliveryFeesMinor: number;
  taxMinor: number;
  netRevenueMinor: number;
  averageOrderValueMinor: number;
}

export interface PopularItemMetric {
  menuItemId?: string;
  itemName: string;
  quantitySold: number;
  revenueMinor: number;
}
'@
Write-CodeFile -RelativePath 'src\modules\reports\interfaces\sales-report.interface.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { DailySalesMetric } from '../entities/daily-sales-metric.entity';

@Injectable()
export class DailySalesMetricRepository extends BaseRepository<DailySalesMetric> {
  constructor(dataSource: DataSource) {
    super(dataSource, DailySalesMetric);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\reports\repositories\daily-sales-metric.repository.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { ItemSalesMetric } from '../entities/item-sales-metric.entity';

@Injectable()
export class ItemSalesMetricRepository extends BaseRepository<ItemSalesMetric> {
  constructor(dataSource: DataSource) {
    super(dataSource, ItemSalesMetric);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\reports\repositories\item-sales-metric.repository.ts' -Content $content

$content = @'
import {
  IsBoolean,
  IsEmail,
  IsEnum,
  IsInt,
  IsOptional,
  IsPhoneNumber,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { TaxBehavior } from '../enums/tax-behavior.enum';

export class CreateRestaurantDto {
  @IsString() @MaxLength(160) name: string;
  @IsString() @MaxLength(180) slug: string;
  @IsOptional() @IsPhoneNumber() phone?: string;
  @IsOptional() @IsEmail() email?: string;
  @IsOptional() @IsString() @MaxLength(255) addressLine1?: string;
  @IsOptional() @IsString() @MaxLength(255) addressLine2?: string;
  @IsOptional() @IsString() @MaxLength(120) city?: string;
  @IsOptional() @IsString() @MaxLength(120) province?: string;
  @IsOptional() @IsString() @MaxLength(24) postalCode?: string;
  @IsOptional() @IsString() @MaxLength(2) countryCode?: string;
  @IsOptional() @IsString() @MaxLength(80) timezone?: string;
  @IsOptional() @IsInt() @Min(1) defaultDeliveryMinutes?: number;
  @IsOptional() @IsInt() @Min(0) deliveryFeeMinor?: number;
  @IsOptional() @IsInt() @Min(0) minimumOrderMinor?: number;
  @IsOptional() @IsInt() @Min(0) @Max(10000) taxRateBasisPoints?: number;
  @IsOptional() @IsEnum(TaxBehavior) taxBehavior?: TaxBehavior;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
'@
Write-CodeFile -RelativePath 'src\modules\restaurants\dto\create-restaurant.dto.ts' -Content $content

$content = @'
import { PartialType } from '@nestjs/mapped-types';
import { CreateRestaurantDto } from './create-restaurant.dto';
export class UpdateRestaurantDto extends PartialType(CreateRestaurantDto) {}
'@
Write-CodeFile -RelativePath 'src\modules\restaurants\dto\update-restaurant.dto.ts' -Content $content

$content = @'
import { IsBoolean, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class UpsertBusinessHoursDto {
  @IsInt() @Min(0) @Max(6) dayOfWeek: number;
  @IsOptional() @IsString() opensAt?: string;
  @IsOptional() @IsString() closesAt?: string;
  @IsOptional() @IsBoolean() isClosed?: boolean;
}
'@
Write-CodeFile -RelativePath 'src\modules\restaurants\dto\upsert-business-hours.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { Restaurant } from './restaurant.entity';

@Entity('business_hours')
export class BusinessHours {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'day_of_week', type: 'smallint' })
  dayOfWeek: number;

  @Column({ name: 'opens_at', type: 'time', nullable: true })
  opensAt?: string;

  @Column({ name: 'closes_at', type: 'time', nullable: true })
  closesAt?: string;

  @Column({ name: 'is_closed', type: 'boolean' })
  isClosed: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\restaurants\entities\business-hours.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('restaurants')
export class Restaurant {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'name', type: 'varchar', length: 160 })
  name: string;

  @Column({ name: 'slug', type: 'varchar', length: 180, unique: true })
  slug: string;

  @Column({ name: 'phone', type: 'varchar', length: 32, nullable: true })
  phone?: string;

  @Column({ name: 'email', type: 'varchar', length: 320, nullable: true })
  email?: string;

  @Column({ name: 'address_line1', type: 'varchar', length: 255, nullable: true })
  addressLine1?: string;

  @Column({ name: 'address_line2', type: 'varchar', length: 255, nullable: true })
  addressLine2?: string;

  @Column({ name: 'city', type: 'varchar', length: 120, nullable: true })
  city?: string;

  @Column({ name: 'province', type: 'varchar', length: 120, nullable: true })
  province?: string;

  @Column({ name: 'postal_code', type: 'varchar', length: 24, nullable: true })
  postalCode?: string;

  @Column({ name: 'country_code', type: 'char', length: 2 })
  countryCode: string;

  @Column({ name: 'currency', type: 'char', length: 3 })
  currency: string;

  @Column({ name: 'timezone', type: 'varchar', length: 80 })
  timezone: string;

  @Column({ name: 'default_delivery_minutes', type: 'integer' })
  defaultDeliveryMinutes: number;

  @Column({ name: 'delivery_fee_minor', type: 'integer' })
  deliveryFeeMinor: number;

  @Column({ name: 'minimum_order_minor', type: 'integer' })
  minimumOrderMinor: number;

  @Column({ name: 'tax_rate_basis_points', type: 'integer' })
  taxRateBasisPoints: number;

  @Column({ name: 'tax_behavior', type: 'varchar', length: 20 })
  taxBehavior: string;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\restaurants\entities\restaurant.entity.ts' -Content $content

$content = @'
export enum TaxBehavior {
  INCLUDED = 'included',
  EXCLUDED = 'excluded',
  NOT_APPLICABLE = 'not_applicable',
}
'@
Write-CodeFile -RelativePath 'src\modules\restaurants\enums\tax-behavior.enum.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Restaurant } from '../entities/restaurant.entity';

@Injectable()
export class RestaurantRepository extends BaseRepository<Restaurant> {
  constructor(dataSource: DataSource) {
    super(dataSource, Restaurant);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\restaurants\repositories\restaurant.repository.ts' -Content $content

$content = @'
import { Column, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { Role } from '../../roles/entities/role.entity';
import { Permission } from '../../permissions/entities/permission.entity';

@Entity('role_permissions')
export class RolePermission {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'role_id', type: 'uuid' })
  roleId: string;

  @ManyToOne(() => Role, (role) => role.rolePermissions, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'role_id' })
  role: Role;

  @Column({ name: 'permission_id', type: 'uuid' })
  permissionId: string;

  @ManyToOne(() => Permission, (permission) => permission.rolePermissions, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'permission_id' })
  permission: Permission;

  @Column({ name: 'created_at', type: 'timestamptz', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;
}
'@
Write-CodeFile -RelativePath 'src\modules\role-permissions\entities\role-permission.entity.ts' -Content $content

$content = @'
import {
  Column,
  Entity,
  JoinTable,
  ManyToMany,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { RolePermission } from '../../role-permissions/entities/role-permission.entity';
import { Permission } from '../../permissions/entities/permission.entity';

@Entity('roles')
export class Role {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 80, unique: true })
  name: string;

  @Column({ type: 'text', nullable: true })
  description?: string;

  @Column({ name: 'is_system', type: 'boolean', default: false })
  isSystem: boolean;

  @OneToMany(() => User, (user) => user.role)
  users: User[];

  @OneToMany(() => RolePermission, (rolePermission) => rolePermission.role)
  rolePermissions: RolePermission[];

  @ManyToMany(() => Permission, (permission) => permission.roles)
  @JoinTable({
    name: 'role_permissions',
    joinColumn: { name: 'role_id', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'permission_id', referencedColumnName: 'id' },
  })
  permissions: Permission[];

  @Column({ name: 'created_at', type: 'timestamptz', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz', default: () => 'CURRENT_TIMESTAMP' })
  updatedAt: Date;
}
'@
Write-CodeFile -RelativePath 'src\modules\roles\entities\role.entity.ts' -Content $content

$content = @'
import { IsBoolean, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateStaffMemberDto {
  @IsUUID() userId: string;
  @IsUUID() restaurantId: string;
  @IsOptional() @IsString() @MaxLength(80) employeeCode?: string;
  @IsOptional() @IsString() @MaxLength(120) jobTitle?: string;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
'@
Write-CodeFile -RelativePath 'src\modules\staff\dto\create-staff-member.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';

@Entity('staff_members')
export class StaffMember {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid', unique: true })
  userId: string;

  @OneToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'employee_code', type: 'varchar', length: 80, nullable: true })
  employeeCode?: string;

  @Column({ name: 'job_title', type: 'varchar', length: 120, nullable: true })
  jobTitle?: string;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\staff\entities\staff-member.entity.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { StaffMember } from '../entities/staff-member.entity';

@Injectable()
export class StaffMemberRepository extends BaseRepository<StaffMember> {
  constructor(dataSource: DataSource) {
    super(dataSource, StaffMember);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\staff\repositories\staff-member.repository.ts' -Content $content

$content = @'
import { IsArray, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateSupportMessageDto {
  @IsString() @MaxLength(5000) body: string;
  @IsOptional() @IsArray() @IsUUID(undefined, { each: true }) attachmentMediaIds?: string[];
}
'@
Write-CodeFile -RelativePath 'src\modules\support\dto\create-support-message.dto.ts' -Content $content

$content = @'
import { IsEnum, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';
import { SupportTicketCategory } from '../enums/support-ticket-category.enum';
import { SupportTicketPriority } from '../enums/support-ticket-priority.enum';

export class CreateSupportTicketDto {
  @IsOptional() @IsUUID() orderId?: string;
  @IsEnum(SupportTicketCategory) category: SupportTicketCategory;
  @IsString() @MaxLength(200) subject: string;
  @IsOptional() @IsEnum(SupportTicketPriority) priority?: SupportTicketPriority;
  @IsString() @MaxLength(5000) message: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\support\dto\create-support-ticket.dto.ts' -Content $content

$content = @'
import { IsEnum, IsOptional, IsUUID } from 'class-validator';
import { SupportTicketPriority } from '../enums/support-ticket-priority.enum';
import { SupportTicketStatus } from '../enums/support-ticket-status.enum';

export class UpdateSupportTicketDto {
  @IsOptional() @IsEnum(SupportTicketStatus) status?: SupportTicketStatus;
  @IsOptional() @IsEnum(SupportTicketPriority) priority?: SupportTicketPriority;
  @IsOptional() @IsUUID() assignedStaffUserId?: string;
}
'@
Write-CodeFile -RelativePath 'src\modules\support\dto\update-support-ticket.dto.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { SupportMessage } from './support-message.entity';
import { MediaAsset } from '../../media/entities/media-asset.entity';

@Entity('support_message_attachments')
export class SupportMessageAttachment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'support_message_id', type: 'uuid' })
  supportMessageId: string;

  @ManyToOne(() => SupportMessage, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'support_message_id' })
  supportMessage: SupportMessage;

  @Column({ name: 'media_asset_id', type: 'uuid' })
  mediaAssetId: string;

  @ManyToOne(() => MediaAsset, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'media_asset_id' })
  mediaAsset: MediaAsset;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\support\entities\support-message-attachment.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { SupportTicket } from './support-ticket.entity';
import { User } from '../../users/entities/user.entity';

@Entity('support_messages')
export class SupportMessage {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'ticket_id', type: 'uuid' })
  ticketId: string;

  @ManyToOne(() => SupportTicket, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'ticket_id' })
  ticket: SupportTicket;

  @Column({ name: 'author_user_id', type: 'uuid', nullable: true })
  authorUserId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'author_user_id' })
  authorUser?: User;

  @Column({ name: 'author_type', type: 'varchar', length: 20 })
  authorType: string;

  @Column({ name: 'body', type: 'text' })
  body: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\support\entities\support-message.entity.ts' -Content $content

$content = @'
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Order } from '../../orders/entities/order.entity';

@Entity('support_tickets')
export class SupportTicket {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'customer_id', type: 'uuid', nullable: true })
  customerId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'customer_id' })
  customer?: User;

  @Column({ name: 'order_id', type: 'uuid', nullable: true })
  orderId?: string;

  @ManyToOne(() => Order, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'order_id' })
  order?: Order;

  @Column({ name: 'assigned_staff_user_id', type: 'uuid', nullable: true })
  assignedStaffUserId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'assigned_staff_user_id' })
  assignedStaffUser?: User;

  @Column({ name: 'category', type: 'varchar', length: 30 })
  category: string;

  @Column({ name: 'subject', type: 'varchar', length: 200 })
  subject: string;

  @Column({ name: 'status', type: 'varchar', length: 30 })
  status: string;

  @Column({ name: 'priority', type: 'varchar', length: 20 })
  priority: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  @Column({ name: 'resolved_at', type: 'timestamptz', nullable: true })
  resolvedAt?: Date;

  @Column({ name: 'closed_at', type: 'timestamptz', nullable: true })
  closedAt?: Date;

}
'@
Write-CodeFile -RelativePath 'src\modules\support\entities\support-ticket.entity.ts' -Content $content

$content = @'
export enum SupportAuthorType {
  CUSTOMER = 'customer',
  STAFF = 'staff',
  SYSTEM = 'system',
}
'@
Write-CodeFile -RelativePath 'src\modules\support\enums\support-author-type.enum.ts' -Content $content

$content = @'
export enum SupportTicketCategory {
  ORDER_ISSUE = 'order_issue',
  REFUND_REQUEST = 'refund_request',
  PAYMENT_ISSUE = 'payment_issue',
  DELIVERY_ISSUE = 'delivery_issue',
  COMPLAINT = 'complaint',
  GENERAL = 'general',
}
'@
Write-CodeFile -RelativePath 'src\modules\support\enums\support-ticket-category.enum.ts' -Content $content

$content = @'
export enum SupportTicketPriority {
  LOW = 'low',
  NORMAL = 'normal',
  HIGH = 'high',
  URGENT = 'urgent',
}
'@
Write-CodeFile -RelativePath 'src\modules\support\enums\support-ticket-priority.enum.ts' -Content $content

$content = @'
export enum SupportTicketStatus {
  OPEN = 'open',
  IN_PROGRESS = 'in_progress',
  WAITING_CUSTOMER = 'waiting_customer',
  RESOLVED = 'resolved',
  CLOSED = 'closed',
}
'@
Write-CodeFile -RelativePath 'src\modules\support\enums\support-ticket-status.enum.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { SupportTicket } from '../entities/support-ticket.entity';

@Injectable()
export class SupportTicketRepository extends BaseRepository<SupportTicket> {
  constructor(dataSource: DataSource) {
    super(dataSource, SupportTicket);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\support\repositories\support-ticket.repository.ts' -Content $content

$content = @'
import {
  IsEmail,
  IsEnum,
  IsOptional,
  IsPhoneNumber,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { UserStatus } from '../enums/user-status.enum';

export class CreateUserDto {
  @IsOptional()
  @IsEmail()
  @MaxLength(320)
  @Transform(({ value }) => value?.trim().toLowerCase())
  email?: string;

  @IsOptional()
  @IsPhoneNumber()
  phone?: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password: string;

  @IsString()
  @MaxLength(160)
  @Transform(({ value }) => value?.trim())
  fullName: string;

  @IsOptional()
  @IsUUID()
  roleId?: string;

  @IsOptional()
  @IsEnum(UserStatus)
  status?: UserStatus;
}
'@
Write-CodeFile -RelativePath 'src\modules\users\dto\create-user.dto.ts' -Content $content

$content = @'
import { PartialType } from '@nestjs/mapped-types';
import { CreateUserDto } from './create-user.dto';

export class UpdateUserDto extends PartialType(CreateUserDto) {}
'@
Write-CodeFile -RelativePath 'src\modules\users\dto\update-user.dto.ts' -Content $content

$content = @'
import { Column, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { User } from './user.entity';
import { Permission } from '../../permissions/entities/permission.entity';

@Entity('user_permissions')
export class UserPermission {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ManyToOne(() => User, (user) => user.userPermissions, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'permission_id', type: 'uuid' })
  permissionId: string;

  @ManyToOne(() => Permission, (permission) => permission.userPermissions, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'permission_id' })
  permission: Permission;

  @Column({ name: 'created_at', type: 'timestamptz', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;
}
'@
Write-CodeFile -RelativePath 'src\modules\users\entities\user-permission.entity.ts' -Content $content

$content = @'
import {
  Column,
  Entity,
  JoinColumn,
  JoinTable,
  ManyToMany,
  ManyToOne,
  OneToMany,
  OneToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Role } from '../../roles/entities/role.entity';
import { Permission } from '../../permissions/entities/permission.entity';
import { UserPermission } from './user-permission.entity';
import { RefreshToken } from '../../auth/entities/refresh-token.entity';
import { SocialAccount } from '../../auth/entities/social-account.entity';
import { CustomerProfile } from '../../customers/entities/customer-profile.entity';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 320, nullable: true })
  email?: string;

  @Column({ type: 'varchar', length: 32, nullable: true })
  phone?: string;

  @Column({ type: 'varchar', length: 255, nullable: true, select: false })
  password?: string;

  @Column({ name: 'full_name', type: 'varchar', length: 160 })
  fullName: string;

  @Column({ name: 'role_id', type: 'uuid' })
  roleId: string;

  @ManyToOne(() => Role, (role) => role.users, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'role_id' })
  role: Role;

  @Column({ type: 'varchar', length: 30, default: 'active' })
  status: string;

  @Column({ name: 'email_verified_at', type: 'timestamptz', nullable: true })
  emailVerifiedAt?: Date;

  @Column({ name: 'phone_verified_at', type: 'timestamptz', nullable: true })
  phoneVerifiedAt?: Date;

  @Column({ name: 'last_login_at', type: 'timestamptz', nullable: true })
  lastLoginAt?: Date;

  @Column({ name: 'archived_at', type: 'timestamptz', nullable: true })
  archivedAt?: Date;

  @OneToMany(() => UserPermission, (userPermission) => userPermission.user)
  userPermissions: UserPermission[];

  @ManyToMany(() => Permission, (permission) => permission.users)
  @JoinTable({
    name: 'user_permissions',
    joinColumn: { name: 'user_id', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'permission_id', referencedColumnName: 'id' },
  })
  permissions: Permission[];

  @OneToMany(() => RefreshToken, (token) => token.user)
  refreshTokens: RefreshToken[];

  @OneToMany(() => SocialAccount, (account) => account.user)
  socialAccounts: SocialAccount[];

  @OneToOne(() => CustomerProfile, (profile) => profile.user)
  customerProfile?: CustomerProfile;

  @Column({ name: 'created_at', type: 'timestamptz', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz', default: () => 'CURRENT_TIMESTAMP' })
  updatedAt: Date;
}
'@
Write-CodeFile -RelativePath 'src\modules\users\entities\user.entity.ts' -Content $content

$content = @'
export enum UserStatus {
  PENDING_VERIFICATION = 'pending_verification',
  ACTIVE = 'active',
  SUSPENDED = 'suspended',
  DISABLED = 'disabled',
  DELETED = 'deleted',
}
'@
Write-CodeFile -RelativePath 'src\modules\users\enums\user-status.enum.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { User } from '../entities/user.entity';

@Injectable()
export class UserRepository extends BaseRepository<User> {
  constructor(dataSource: DataSource) {
    super(dataSource, User);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\users\repositories\user.repository.ts' -Content $content


Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "Generation complete."
Write-Host "Files written: 189"
Write-Host "Migration files were not changed."
Write-Host ""
Write-Host "Recommended checks:"
Write-Host "  npm run format"
Write-Host "  npm run lint:check"
Write-Host "  npm run build"
Write-Host "------------------------------------------------------------"
