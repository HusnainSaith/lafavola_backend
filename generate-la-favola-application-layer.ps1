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
    throw "package.json not found in '$Root'. Run this from the backend root or pass -Root."
}
if (-not (Test-Path -LiteralPath (Join-Path $Root "src"))) {
    throw "src folder not found in '$Root'."
}

$requiredMigration = Join-Path $Root "src\database\migrations\1700000000008-CreateOrdersAndOrderHistory.ts"
if (-not (Test-Path -LiteralPath $requiredMigration)) {
    Write-Warning "Expected La Favola migration files were not found under src\database\migrations."
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = Join-Path $Root ".codegen-backup\application-layer-$timestamp"

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
Write-Host "La Favola application-layer generator"
Write-Host "Backend: $Root"
Write-Host "Generates controllers, services, modules and required application helpers."
Write-Host "Migrations, DTOs, entities, enums, interfaces and repositories are not modified."
if (-not $NoBackup) {
  Write-Host "Existing target files will be backed up under $backupRoot"
}
Write-Host ""
$content = @'
export interface AuthenticatedUser {
  id: string;
  email?: string;
  fullName?: string;
  role?: { name?: string } | string;
  permissions?: unknown[];
}
'@
Write-CodeFile -RelativePath 'src\common\interfaces\authenticated-user.interface.ts' -Content $content

$content = @'
import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';

export function requireEntity<T>(
  entity: T | null | undefined,
  message: string,
): T {
  if (!entity) {
    throw new NotFoundException(message);
  }
  return entity;
}

export function assertCondition(
  condition: unknown,
  message: string,
): asserts condition {
  if (!condition) {
    throw new BadRequestException(message);
  }
}

export function assertUnique(
  condition: unknown,
  message: string,
): asserts condition {
  if (!condition) {
    throw new ConflictException(message);
  }
}
'@
Write-CodeFile -RelativePath 'src\common\utils\service-errors.util.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { RestaurantRepository } from './repositories/restaurant.repository';
import { Restaurant } from './entities/restaurant.entity';
import { CreateRestaurantDto } from './dto/create-restaurant.dto';
import { UpdateRestaurantDto } from './dto/update-restaurant.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class RestaurantsService {
  constructor(private readonly restaurants: RestaurantRepository) {}

  findAll(): Promise<Restaurant[]> {
    return this.restaurants.findMany({ order: { createdAt: 'DESC' } });
  }

  async findById(id: string): Promise<Restaurant> {
    return requireEntity(
      await this.restaurants.findById(id),
      'Restaurant not found',
    );
  }

  async create(dto: CreateRestaurantDto): Promise<Restaurant> {
    const existing = await this.restaurants.findOne({
      where: { slug: dto.slug },
    });
    if (existing) {
      throw new Error('Restaurant slug already exists');
    }
    return this.restaurants.save(
      this.restaurants.create({
        ...dto,
        currency: dto.currency ?? 'EUR',
        timezone: dto.timezone ?? 'Europe/Rome',
        defaultDeliveryMinutes: dto.defaultDeliveryMinutes ?? 30,
        deliveryFeeMinor: dto.deliveryFeeMinor ?? 0,
        minimumOrderMinor: dto.minimumOrderMinor ?? 0,
        taxRateBasisPoints: dto.taxRateBasisPoints ?? 0,
        isActive: dto.isActive ?? true,
      }),
    );
  }

  async update(id: string, dto: UpdateRestaurantDto): Promise<Restaurant> {
    const entity = await this.findById(id);
    Object.assign(entity, dto);
    return this.restaurants.save(entity);
  }

  async remove(id: string): Promise<void> {
    const entity = await this.findById(id);
    entity.isActive = false;
    await this.restaurants.save(entity);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\restaurants\restaurants.service.ts' -Content $content

$content = @'
import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { RestaurantsService } from './restaurants.service';
import { CreateRestaurantDto } from './dto/create-restaurant.dto';
import { UpdateRestaurantDto } from './dto/update-restaurant.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('restaurants')
export class RestaurantsController {
  constructor(private readonly service: RestaurantsService) {}

  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findById(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  create(@Body() dto: CreateRestaurantDto) {
    return this.service.create(dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdateRestaurantDto) {
    return this.service.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  async remove(@Param('id') id: string) {
    await this.service.remove(id);
    return { success: true };
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\restaurants\restaurants.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { RestaurantsController } from './restaurants.controller';
import { RestaurantsService } from './restaurants.service';
import { RestaurantRepository } from './repositories/restaurant.repository';

@Module({
  controllers: [RestaurantsController],
  providers: [RestaurantsService, RestaurantRepository],
  exports: [RestaurantsService, RestaurantRepository],
})
export class RestaurantsModule {}
'@
Write-CodeFile -RelativePath 'src\modules\restaurants\restaurants.module.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { MenuCategoryRepository } from './repositories/menu-category.repository';
import { MenuCategory } from './entities/menu-category.entity';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class CategoriesService {
  constructor(private readonly repository: MenuCategoryRepository) {}

  findAll(): Promise<MenuCategory[]> {
    return this.repository.findMany({ order: { createdAt: 'DESC' } });
  }

  async findById(id: string): Promise<MenuCategory> {
    return requireEntity(
      await this.repository.findById(id),
      'Categories record not found',
    );
  }

  create(dto: CreateCategoryDto): Promise<MenuCategory> {
    return this.repository.save(this.repository.create(dto as Partial<MenuCategory>));
  }

  async update(id: string, dto: UpdateCategoryDto): Promise<MenuCategory> {
    const entity = await this.findById(id);
    Object.assign(entity, dto);
    return this.repository.save(entity);
  }

  async remove(id: string): Promise<void> {
    const entity = await this.findById(id);
    (entity as any).isActive = false;
    await this.repository.save(entity);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\categories\categories.service.ts' -Content $content

$content = @'
import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('categories')
export class CategoriesController {
  constructor(private readonly service: CategoriesService) {}

  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findById(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  create(@Body() dto: CreateCategoryDto) {
    return this.service.create(dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdateCategoryDto) {
    return this.service.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  async remove(@Param('id') id: string) {
    await this.service.remove(id);
    return { success: true };
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\categories\categories.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { CategoriesController } from './categories.controller';
import { CategoriesService } from './categories.service';
import { MenuCategoryRepository } from './repositories/menu-category.repository';

@Module({
  controllers: [CategoriesController],
  providers: [CategoriesService, MenuCategoryRepository],
  exports: [CategoriesService, MenuCategoryRepository],
})
export class CategoriesModule {}
'@
Write-CodeFile -RelativePath 'src\modules\categories\categories.module.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { IngredientRepository } from './repositories/ingredient.repository';
import { Ingredient } from './entities/ingredient.entity';
import { CreateIngredientDto } from './dto/create-ingredient.dto';
import { UpdateIngredientDto } from './dto/update-ingredient.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class IngredientsService {
  constructor(private readonly repository: IngredientRepository) {}

  findAll(): Promise<Ingredient[]> {
    return this.repository.findMany({ order: { createdAt: 'DESC' } });
  }

  async findById(id: string): Promise<Ingredient> {
    return requireEntity(
      await this.repository.findById(id),
      'Ingredients record not found',
    );
  }

  create(dto: CreateIngredientDto): Promise<Ingredient> {
    return this.repository.save(this.repository.create(dto as Partial<Ingredient>));
  }

  async update(id: string, dto: UpdateIngredientDto): Promise<Ingredient> {
    const entity = await this.findById(id);
    Object.assign(entity, dto);
    return this.repository.save(entity);
  }

  async remove(id: string): Promise<void> {
    const entity = await this.findById(id);
    (entity as any).isActive = false;
    await this.repository.save(entity);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\ingredients\ingredients.service.ts' -Content $content

$content = @'
import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { IngredientsService } from './ingredients.service';
import { CreateIngredientDto } from './dto/create-ingredient.dto';
import { UpdateIngredientDto } from './dto/update-ingredient.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('ingredients')
export class IngredientsController {
  constructor(private readonly service: IngredientsService) {}

  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findById(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  create(@Body() dto: CreateIngredientDto) {
    return this.service.create(dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdateIngredientDto) {
    return this.service.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  async remove(@Param('id') id: string) {
    await this.service.remove(id);
    return { success: true };
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\ingredients\ingredients.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { IngredientsController } from './ingredients.controller';
import { IngredientsService } from './ingredients.service';
import { IngredientRepository } from './repositories/ingredient.repository';

@Module({
  controllers: [IngredientsController],
  providers: [IngredientsService, IngredientRepository],
  exports: [IngredientsService, IngredientRepository],
})
export class IngredientsModule {}
'@
Write-CodeFile -RelativePath 'src\modules\ingredients\ingredients.module.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { PromotionRepository } from './repositories/promotion.repository';
import { Promotion } from './entities/promotion.entity';
import { CreatePromotionDto } from './dto/create-promotion.dto';
import { UpdatePromotionDto } from './dto/update-promotion.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class PromotionsService {
  constructor(private readonly repository: PromotionRepository) {}

  findAll(): Promise<Promotion[]> {
    return this.repository.findMany({ order: { createdAt: 'DESC' } });
  }

  async findById(id: string): Promise<Promotion> {
    return requireEntity(
      await this.repository.findById(id),
      'Promotions record not found',
    );
  }

  create(dto: CreatePromotionDto): Promise<Promotion> {
    return this.repository.save(this.repository.create(dto as Partial<Promotion>));
  }

  async update(id: string, dto: UpdatePromotionDto): Promise<Promotion> {
    const entity = await this.findById(id);
    Object.assign(entity, dto);
    return this.repository.save(entity);
  }

  async remove(id: string): Promise<void> {
    const entity = await this.findById(id);
    (entity as any).isActive = false;
    await this.repository.save(entity);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\promotions\promotions.service.ts' -Content $content

$content = @'
import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { PromotionsService } from './promotions.service';
import { CreatePromotionDto } from './dto/create-promotion.dto';
import { UpdatePromotionDto } from './dto/update-promotion.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('promotions')
export class PromotionsController {
  constructor(private readonly service: PromotionsService) {}

  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findById(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  create(@Body() dto: CreatePromotionDto) {
    return this.service.create(dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdatePromotionDto) {
    return this.service.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  async remove(@Param('id') id: string) {
    await this.service.remove(id);
    return { success: true };
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\promotions\promotions.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { PromotionsController } from './promotions.controller';
import { PromotionsService } from './promotions.service';
import { PromotionRepository } from './repositories/promotion.repository';

@Module({
  controllers: [PromotionsController],
  providers: [PromotionsService, PromotionRepository],
  exports: [PromotionsService, PromotionRepository],
})
export class PromotionsModule {}
'@
Write-CodeFile -RelativePath 'src\modules\promotions\promotions.module.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { CouponRepository } from './repositories/coupon.repository';
import { Coupon } from './entities/coupon.entity';
import { CreateCouponDto } from './dto/create-coupon.dto';
import { UpdateCouponDto } from './dto/update-coupon.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class CouponsService {
  constructor(private readonly repository: CouponRepository) {}

  findAll(): Promise<Coupon[]> {
    return this.repository.findMany({ order: { createdAt: 'DESC' } });
  }

  async findById(id: string): Promise<Coupon> {
    return requireEntity(
      await this.repository.findById(id),
      'Coupons record not found',
    );
  }

  create(dto: CreateCouponDto): Promise<Coupon> {
    return this.repository.save(this.repository.create(dto as Partial<Coupon>));
  }

  async update(id: string, dto: UpdateCouponDto): Promise<Coupon> {
    const entity = await this.findById(id);
    Object.assign(entity, dto);
    return this.repository.save(entity);
  }

  async remove(id: string): Promise<void> {
    const entity = await this.findById(id);
    (entity as any).isActive = false;
    await this.repository.save(entity);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\coupons\coupons.service.ts' -Content $content

$content = @'
import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { CouponsService } from './coupons.service';
import { CreateCouponDto } from './dto/create-coupon.dto';
import { UpdateCouponDto } from './dto/update-coupon.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('coupons')
export class CouponsController {
  constructor(private readonly service: CouponsService) {}

  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findById(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  create(@Body() dto: CreateCouponDto) {
    return this.service.create(dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdateCouponDto) {
    return this.service.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  async remove(@Param('id') id: string) {
    await this.service.remove(id);
    return { success: true };
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\coupons\coupons.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { CouponsController } from './coupons.controller';
import { CouponsService } from './coupons.service';
import { CouponRepository } from './repositories/coupon.repository';

@Module({
  controllers: [CouponsController],
  providers: [CouponsService, CouponRepository],
  exports: [CouponsService, CouponRepository],
})
export class CouponsModule {}
'@
Write-CodeFile -RelativePath 'src\modules\coupons\coupons.module.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { FaqArticleRepository } from './repositories/faq-article.repository';
import { FaqArticle } from './entities/faq-article.entity';
import { CreateFaqDto } from './dto/create-faq.dto';
import { UpdateFaqDto } from './dto/update-faq.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class FaqService {
  constructor(private readonly repository: FaqArticleRepository) {}

  findAll(): Promise<FaqArticle[]> {
    return this.repository.findMany({ order: { createdAt: 'DESC' } });
  }

  async findById(id: string): Promise<FaqArticle> {
    return requireEntity(
      await this.repository.findById(id),
      'Faq record not found',
    );
  }

  create(dto: CreateFaqDto): Promise<FaqArticle> {
    return this.repository.save(this.repository.create(dto as Partial<FaqArticle>));
  }

  async update(id: string, dto: UpdateFaqDto): Promise<FaqArticle> {
    const entity = await this.findById(id);
    Object.assign(entity, dto);
    return this.repository.save(entity);
  }

  async remove(id: string): Promise<void> {
    const entity = await this.findById(id);
    (entity as any).isActive = false;
    await this.repository.save(entity);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\faq\faq.service.ts' -Content $content

$content = @'
import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { FaqService } from './faq.service';
import { CreateFaqDto } from './dto/create-faq.dto';
import { UpdateFaqDto } from './dto/update-faq.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('faq')
export class FaqController {
  constructor(private readonly service: FaqService) {}

  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findById(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  create(@Body() dto: CreateFaqDto) {
    return this.service.create(dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdateFaqDto) {
    return this.service.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  async remove(@Param('id') id: string) {
    await this.service.remove(id);
    return { success: true };
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\faq\faq.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { FaqController } from './faq.controller';
import { FaqService } from './faq.service';
import { FaqArticleRepository } from './repositories/faq-article.repository';

@Module({
  controllers: [FaqController],
  providers: [FaqService, FaqArticleRepository],
  exports: [FaqService, FaqArticleRepository],
})
export class FaqModule {}
'@
Write-CodeFile -RelativePath 'src\modules\faq\faq.module.ts' -Content $content

$content = @'
import { Injectable, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { MenuItemRepository } from './repositories/menu-item.repository';
import { MenuItem } from './entities/menu-item.entity';
import { MenuItemSize } from './entities/menu-item-size.entity';
import { CreateMenuItemDto } from './dto/create-menu-item.dto';
import { UpdateMenuItemDto } from './dto/update-menu-item.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class MenuService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly items: MenuItemRepository,
  ) {}

  list(restaurantId?: string): Promise<MenuItem[]> {
    return this.items.findMany({
      where: restaurantId ? { restaurantId, isActive: true } : { isActive: true },
      relations: { category: true, imageAsset: true },
      order: { popularityScore: 'DESC', createdAt: 'DESC' },
    });
  }

  search(restaurantId: string, query: string): Promise<MenuItem[]> {
    return this.items.searchActive(restaurantId, query.trim());
  }

  async detail(id: string): Promise<MenuItem> {
    const item = await this.items.findOne({
      where: { id, isActive: true },
      relations: {
        category: true,
        imageAsset: true,
      },
    });
    return requireEntity(item, 'Menu item not found');
  }

  async create(dto: CreateMenuItemDto): Promise<MenuItem> {
    return this.dataSource.transaction(async (manager) => {
      const itemRepo = manager.getRepository(MenuItem);
      const sizeRepo = manager.getRepository(MenuItemSize);

      const item = await itemRepo.save(
        itemRepo.create({
          restaurantId: dto.restaurantId,
          categoryId: dto.categoryId,
          name: dto.name,
          slug: dto.slug,
          description: dto.description,
          imageAssetId: dto.imageAssetId,
          itemType: dto.itemType,
          calories: dto.calories,
          preparationMinutes: dto.preparationMinutes ?? 15,
          isVegetarian: dto.isVegetarian ?? false,
          isVegan: dto.isVegan ?? false,
          isGlutenFree: dto.isGlutenFree ?? false,
          isSpicy: dto.isSpicy ?? false,
          isPopular: dto.isPopular ?? false,
          popularityScore: '0',
          isActive: dto.isActive ?? true,
        }),
      );

      if (dto.sizes?.length) {
        await sizeRepo.save(
          dto.sizes.map((size) =>
            sizeRepo.create({
              menuItemId: item.id,
              sizeCode: size.sizeCode,
              displayName: size.displayName,
              basePriceMinor: size.basePriceMinor,
              calories: size.calories,
              displayOrder: size.displayOrder ?? 0,
              isActive: size.isActive ?? true,
            }),
          ),
        );
      }

      return itemRepo.findOneOrFail({ where: { id: item.id } });
    });
  }

  async update(id: string, dto: UpdateMenuItemDto): Promise<MenuItem> {
    const item = await this.items.findById(id);
    if (!item) throw new NotFoundException('Menu item not found');
    Object.assign(item, dto);
    return this.items.save(item);
  }

  async archive(id: string): Promise<void> {
    const item = await this.detail(id);
    item.isActive = false;
    item.archivedAt = new Date();
    await this.items.save(item);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\menu\menu.service.ts' -Content $content

$content = @'
import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { MenuService } from './menu.service';
import { CreateMenuItemDto } from './dto/create-menu-item.dto';
import { UpdateMenuItemDto } from './dto/update-menu-item.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('menu')
export class MenuController {
  constructor(private readonly service: MenuService) {}

  @Get()
  list(@Query('restaurantId') restaurantId?: string) {
    return this.service.list(restaurantId);
  }

  @Get('search')
  search(
    @Query('restaurantId') restaurantId: string,
    @Query('q') q: string,
  ) {
    return this.service.search(restaurantId, q ?? '');
  }

  @Get(':id')
  detail(@Param('id') id: string) {
    return this.service.detail(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  create(@Body() dto: CreateMenuItemDto) {
    return this.service.create(dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdateMenuItemDto) {
    return this.service.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  async archive(@Param('id') id: string) {
    await this.service.archive(id);
    return { success: true };
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\menu\menu.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { MenuController } from './menu.controller';
import { MenuService } from './menu.service';
import { MenuItemRepository } from './repositories/menu-item.repository';

@Module({
  controllers: [MenuController],
  providers: [MenuService, MenuItemRepository],
  exports: [MenuService, MenuItemRepository],
})
export class MenuModule {}
'@
Write-CodeFile -RelativePath 'src\modules\menu\menu.module.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { OptionGroupRepository } from './repositories/option-group.repository';
import { OptionGroup } from './entities/option-group.entity';
import { OptionChoice } from './entities/option-choice.entity';
import { CreateOptionGroupDto } from './dto/create-option-group.dto';
import { UpdateOptionGroupDto } from './dto/update-option-group.dto';
import { CreateOptionChoiceDto } from './dto/create-option-choice.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class OptionGroupsService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly groups: OptionGroupRepository,
  ) {}

  list(restaurantId?: string) {
    return this.groups.findMany({
      where: restaurantId ? { restaurantId, isActive: true } : { isActive: true },
      order: { displayOrder: 'ASC', createdAt: 'ASC' },
    });
  }

  async detail(id: string) {
    return requireEntity(await this.groups.findById(id), 'Option group not found');
  }

  create(dto: CreateOptionGroupDto) {
    return this.groups.save(this.groups.create({
      ...dto,
      minSelect: dto.minSelect ?? 0,
      isRequired: dto.isRequired ?? false,
      allowQuantity: dto.allowQuantity ?? false,
      displayOrder: dto.displayOrder ?? 0,
      isActive: dto.isActive ?? true,
    }));
  }

  async update(id: string, dto: UpdateOptionGroupDto) {
    const group = await this.detail(id);
    Object.assign(group, dto);
    return this.groups.save(group);
  }

  async addChoice(groupId: string, dto: CreateOptionChoiceDto) {
    await this.detail(groupId);
    return this.dataSource.getRepository(OptionChoice).save(
      this.dataSource.getRepository(OptionChoice).create({
        ...dto,
        optionGroupId: groupId,
        priceAdjustmentMinor: dto.priceAdjustmentMinor ?? 0,
        caloriesAdjustment: dto.caloriesAdjustment ?? 0,
        isDefault: dto.isDefault ?? false,
        displayOrder: dto.displayOrder ?? 0,
        isActive: dto.isActive ?? true,
      }),
    );
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\option-groups\option-groups.service.ts' -Content $content

$content = @'
import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { OptionGroupsService } from './option-groups.service';
import { CreateOptionGroupDto } from './dto/create-option-group.dto';
import { UpdateOptionGroupDto } from './dto/update-option-group.dto';
import { CreateOptionChoiceDto } from './dto/create-option-choice.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('option-groups')
export class OptionGroupsController {
  constructor(private readonly service: OptionGroupsService) {}

  @Get()
  list(@Query('restaurantId') restaurantId?: string) {
    return this.service.list(restaurantId);
  }

  @Get(':id')
  detail(@Param('id') id: string) {
    return this.service.detail(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  create(@Body() dto: CreateOptionGroupDto) {
    return this.service.create(dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdateOptionGroupDto) {
    return this.service.update(id, dto);
  }

  @Post(':id/choices')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  addChoice(@Param('id') id: string, @Body() dto: CreateOptionChoiceDto) {
    return this.service.addChoice(id, dto);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\option-groups\option-groups.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { OptionGroupsController } from './option-groups.controller';
import { OptionGroupsService } from './option-groups.service';
import { OptionGroupRepository } from './repositories/option-group.repository';

@Module({
  controllers: [OptionGroupsController],
  providers: [OptionGroupsService, OptionGroupRepository],
  exports: [OptionGroupsService, OptionGroupRepository],
})
export class OptionGroupsModule {}
'@
Write-CodeFile -RelativePath 'src\modules\option-groups\option-groups.module.ts' -Content $content

$content = @'
import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { MenuItem } from '../menu/entities/menu-item.entity';
import { MenuItemSize } from '../menu/entities/menu-item-size.entity';
import { OptionChoice } from '../option-groups/entities/option-choice.entity';
import { OptionIncompatibility } from '../option-groups/entities/option-incompatibility.entity';
import { PriceBreakdown } from './interfaces/price-breakdown.interface';

export interface PriceSelection {
  menuItemId: string;
  sizeId?: string;
  optionChoiceIds?: string[];
  quantity?: number;
}

@Injectable()
export class PricingService {
  constructor(private readonly dataSource: DataSource) {}

  async calculate(selection: PriceSelection): Promise<PriceBreakdown> {
    const quantity = Math.max(1, selection.quantity ?? 1);
    const item = await this.dataSource.getRepository(MenuItem).findOne({
      where: { id: selection.menuItemId, isActive: true },
    });
    if (!item) throw new NotFoundException('Menu item not found');

    let basePriceMinor = 0;
    if (selection.sizeId) {
      const size = await this.dataSource.getRepository(MenuItemSize).findOne({
        where: { id: selection.sizeId, menuItemId: item.id, isActive: true },
      });
      if (!size) throw new BadRequestException('Invalid menu item size');
      basePriceMinor = size.basePriceMinor;
    }

    const choiceIds = [...new Set(selection.optionChoiceIds ?? [])];
    const choices = choiceIds.length
      ? await this.dataSource.getRepository(OptionChoice)
          .createQueryBuilder('choice')
          .where('choice.id IN (:...ids)', { ids: choiceIds })
          .andWhere('choice.is_active = true')
          .getMany()
      : [];

    if (choices.length !== choiceIds.length) {
      throw new BadRequestException('One or more selected options are unavailable');
    }

    if (choiceIds.length > 1) {
      const conflict = await this.dataSource
        .getRepository(OptionIncompatibility)
        .createQueryBuilder('conflict')
        .where(
          '(conflict.first_choice_id IN (:...ids) AND conflict.second_choice_id IN (:...ids))',
          { ids: choiceIds },
        )
        .getOne();
      if (conflict) {
        throw new BadRequestException(
          conflict.reason ?? 'Selected options are incompatible',
        );
      }
    }

    const optionsMinor = choices.reduce(
      (sum, choice) => sum + Number(choice.priceAdjustmentMinor ?? 0),
      0,
    );
    const unitPriceMinor = Math.max(0, basePriceMinor + optionsMinor);
    const lineTotalMinor = unitPriceMinor * quantity;

    return {
      basePriceMinor,
      optionAdjustmentsMinor: optionsMinor,
      unitPriceMinor,
      quantity,
      lineTotalMinor,
    } as PriceBreakdown;
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\pricing\pricing.service.ts' -Content $content

$content = @'
import { Body, Controller, Post } from '@nestjs/common';
import { PricingService, PriceSelection } from './pricing.service';

@Controller('pricing')
export class PricingController {
  constructor(private readonly service: PricingService) {}

  @Post('calculate')
  calculate(@Body() body: PriceSelection) {
    return this.service.calculate(body);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\pricing\pricing.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { PricingController } from './pricing.controller';
import { PricingService } from './pricing.service';

@Module({
  controllers: [PricingController],
  providers: [PricingService],
  exports: [PricingService],
})
export class PricingModule {}
'@
Write-CodeFile -RelativePath 'src\modules\pricing\pricing.module.ts' -Content $content

$content = @'
import { Injectable, NotFoundException } from '@nestjs/common';
import { PizzaBuilderRuleRepository } from './repositories/pizza-builder-rule.repository';
import { BuildPizzaDto } from './dto/build-pizza.dto';
import { PricingService } from '../pricing/pricing.service';

@Injectable()
export class PizzaBuilderService {
  constructor(
    private readonly rules: PizzaBuilderRuleRepository,
    private readonly pricing: PricingService,
  ) {}

  async getRule(menuItemId: string) {
    const rule = await this.rules.findOne({
      where: { menuItemId, isActive: true },
    });
    if (!rule) throw new NotFoundException('Pizza builder configuration not found');
    return rule;
  }

  async build(dto: BuildPizzaDto) {
    const rule = await this.getRule(dto.menuItemId);
    const price = await this.pricing.calculate({
      menuItemId: dto.menuItemId,
      sizeId: dto.sizeId,
      optionChoiceIds: dto.optionChoiceIds,
      quantity: dto.quantity ?? 1,
    });

    return {
      menuItemId: dto.menuItemId,
      ruleId: rule.id,
      configuration: {
        sizeId: dto.sizeId,
        optionChoiceIds: dto.optionChoiceIds ?? [],
      },
      price,
    };
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\pizza-builder\pizza-builder.service.ts' -Content $content

$content = @'
import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { PizzaBuilderService } from './pizza-builder.service';
import { BuildPizzaDto } from './dto/build-pizza.dto';

@Controller('pizza-builder')
export class PizzaBuilderController {
  constructor(private readonly service: PizzaBuilderService) {}

  @Get(':menuItemId')
  configuration(@Param('menuItemId') menuItemId: string) {
    return this.service.getRule(menuItemId);
  }

  @Post('build')
  build(@Body() dto: BuildPizzaDto) {
    return this.service.build(dto);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\pizza-builder\pizza-builder.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { PizzaBuilderController } from './pizza-builder.controller';
import { PizzaBuilderService } from './pizza-builder.service';
import { PizzaBuilderRuleRepository } from './repositories/pizza-builder-rule.repository';
import { PricingModule } from '../pricing/pricing.module';

@Module({
  imports: [PricingModule],
  controllers: [PizzaBuilderController],
  providers: [PizzaBuilderService, PizzaBuilderRuleRepository],
  exports: [PizzaBuilderService],
})
export class PizzaBuilderModule {}
'@
Write-CodeFile -RelativePath 'src\modules\pizza-builder\pizza-builder.module.ts' -Content $content

$content = @'
import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { CartRepository } from './repositories/cart.repository';
import { Cart } from './entities/cart.entity';
import { CartItem } from './entities/cart-item.entity';
import { CartItemOption } from './entities/cart-item-option.entity';
import { AddCartItemDto } from './dto/add-cart-item.dto';
import { UpdateCartItemDto } from './dto/update-cart-item.dto';
import { PricingService } from '../pricing/pricing.service';

@Injectable()
export class CartsService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly carts: CartRepository,
    private readonly pricing: PricingService,
  ) {}

  async getActive(customerId: string, restaurantId: string): Promise<Cart> {
    let cart = await this.carts.findOne({
      where: { customerId, restaurantId, status: 'active' },
    });
    if (!cart) {
      cart = await this.carts.save(
        this.carts.create({
          customerId,
          restaurantId,
          status: 'active',
          currency: 'EUR',
          expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 7),
        }),
      );
    }
    return cart;
  }

  async detail(customerId: string, restaurantId: string) {
    const cart = await this.getActive(customerId, restaurantId);
    const items = await this.dataSource.getRepository(CartItem).find({
      where: { cartId: cart.id },
      order: { createdAt: 'ASC' },
    });
    const options = items.length
      ? await this.dataSource.getRepository(CartItemOption)
          .createQueryBuilder('option')
          .where('option.cart_item_id IN (:...ids)', { ids: items.map((i) => i.id) })
          .getMany()
      : [];

    const subtotalMinor = items.reduce((sum, item) => sum + Number(item.lineTotalMinor), 0);
    return { cart, items, options, subtotalMinor };
  }

  async addItem(customerId: string, restaurantId: string, dto: AddCartItemDto) {
    const cart = await this.getActive(customerId, restaurantId);
    const price = await this.pricing.calculate({
      menuItemId: dto.menuItemId,
      sizeId: dto.menuItemSizeId,
      optionChoiceIds: dto.optionChoiceIds,
      quantity: dto.quantity,
    });

    return this.dataSource.transaction(async (manager) => {
      const itemRepo = manager.getRepository(CartItem);
      const optionRepo = manager.getRepository(CartItemOption);
      const item = await itemRepo.save(
        itemRepo.create({
          cartId: cart.id,
          menuItemId: dto.menuItemId,
          menuItemSizeId: dto.menuItemSizeId,
          quantity: dto.quantity,
          itemNameSnapshot: dto.itemNameSnapshot,
          sizeNameSnapshot: dto.sizeNameSnapshot,
          baseUnitPriceMinor: price.basePriceMinor,
          optionsUnitPriceMinor: price.optionAdjustmentsMinor,
          unitPriceMinor: price.unitPriceMinor,
          lineTotalMinor: price.lineTotalMinor,
          specialInstructions: dto.specialInstructions,
          configurationHash: dto.configurationHash,
        }),
      );

      if (dto.options?.length) {
        await optionRepo.save(
          dto.options.map((option) =>
            optionRepo.create({
              cartItemId: item.id,
              optionGroupId: option.optionGroupId,
              optionChoiceId: option.optionChoiceId,
              ingredientId: option.ingredientId,
              action: option.action ?? 'add',
              optionNameSnapshot: option.optionNameSnapshot,
              quantity: option.quantity ?? 1,
              unitPriceAdjustmentMinor: option.unitPriceAdjustmentMinor ?? 0,
              totalPriceAdjustmentMinor: option.totalPriceAdjustmentMinor ?? 0,
            }),
          ),
        );
      }

      return item;
    });
  }

  async updateItem(customerId: string, itemId: string, dto: UpdateCartItemDto) {
    const repo = this.dataSource.getRepository(CartItem);
    const item = await repo.findOne({
      where: { id: itemId },
      relations: { cart: true },
    });
    if (!item || item.cart.customerId !== customerId) {
      throw new NotFoundException('Cart item not found');
    }
    if (dto.quantity !== undefined) {
      if (dto.quantity < 1) throw new BadRequestException('Quantity must be at least 1');
      item.quantity = dto.quantity;
      item.lineTotalMinor = Number(item.unitPriceMinor) * dto.quantity;
    }
    if (dto.specialInstructions !== undefined) {
      item.specialInstructions = dto.specialInstructions;
    }
    return repo.save(item);
  }

  async removeItem(customerId: string, itemId: string): Promise<void> {
    const repo = this.dataSource.getRepository(CartItem);
    const item = await repo.findOne({ where: { id: itemId }, relations: { cart: true } });
    if (!item || item.cart.customerId !== customerId) {
      throw new NotFoundException('Cart item not found');
    }
    await repo.delete(item.id);
  }

  async clear(cartId: string): Promise<void> {
    await this.dataSource.getRepository(CartItem).delete({ cartId });
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\carts\carts.service.ts' -Content $content

$content = @'
import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { CartsService } from './carts.service';
import { AddCartItemDto } from './dto/add-cart-item.dto';
import { UpdateCartItemDto } from './dto/update-cart-item.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';

@Controller('cart')
@UseGuards(JwtAuthGuard)
export class CartsController {
  constructor(private readonly service: CartsService) {}

  @Get()
  detail(
    @CurrentUser() user: AuthenticatedUser,
    @Query('restaurantId') restaurantId: string,
  ) {
    return this.service.detail(user.id, restaurantId);
  }

  @Post('items')
  add(
    @CurrentUser() user: AuthenticatedUser,
    @Query('restaurantId') restaurantId: string,
    @Body() dto: AddCartItemDto,
  ) {
    return this.service.addItem(user.id, restaurantId, dto);
  }

  @Patch('items/:id')
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateCartItemDto,
  ) {
    return this.service.updateItem(user.id, id, dto);
  }

  @Delete('items/:id')
  async remove(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.service.removeItem(user.id, id);
    return { success: true };
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\carts\carts.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { CartsController } from './carts.controller';
import { CartsService } from './carts.service';
import { CartRepository } from './repositories/cart.repository';
import { PricingModule } from '../pricing/pricing.module';

@Module({
  imports: [PricingModule],
  controllers: [CartsController],
  providers: [CartsService, CartRepository],
  exports: [CartsService],
})
export class CartsModule {}
'@
Write-CodeFile -RelativePath 'src\modules\carts\carts.module.ts' -Content $content

$content = @'
import { BadRequestException, Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { OrderRepository } from './repositories/order.repository';
import { Order } from './entities/order.entity';
import { OrderStatusHistory } from './entities/order-status-history.entity';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { OrderStatus } from './enums/order-status.enum';
import { requireEntity } from '../../common/utils/service-errors.util';

const TRANSITIONS: Record<string, string[]> = {
  pending_payment: ['placed', 'cancelled'],
  placed: ['accepted', 'rejected', 'cancelled'],
  accepted: ['preparing', 'cancelled'],
  preparing: ['baking', 'cancelled'],
  baking: ['packing'],
  packing: ['ready'],
  ready: ['driver_assigned', 'out_for_delivery'],
  driver_assigned: ['out_for_delivery'],
  out_for_delivery: ['delivered'],
  delivered: ['closed'],
  closed: [],
  cancelled: [],
  rejected: [],
};

@Injectable()
export class OrdersService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly orders: OrderRepository,
  ) {}

  async customerHistory(customerId: string): Promise<Order[]> {
    return this.orders.findCustomerHistory(customerId);
  }

  async customerDetail(customerId: string, orderId: string): Promise<Order> {
    return requireEntity(
      await this.orders.findOne({
        where: { id: orderId, customerId },
      }),
      'Order not found',
    );
  }

  listAdmin(restaurantId?: string, status?: string) {
    return this.orders.findMany({
      where: {
        ...(restaurantId ? { restaurantId } : {}),
        ...(status ? { status } : {}),
      } as any,
      order: { createdAt: 'DESC' },
    });
  }

  async updateStatus(
    orderId: string,
    dto: UpdateOrderStatusDto,
    actorUserId?: string,
  ): Promise<Order> {
    const order = requireEntity(await this.orders.findById(orderId), 'Order not found');
    const current = String(order.status);
    const next = String(dto.status);
    if (!(TRANSITIONS[current] ?? []).includes(next)) {
      throw new BadRequestException(`Invalid order transition: ${current} -> ${next}`);
    }

    return this.dataSource.transaction(async (manager) => {
      const orderRepo = manager.getRepository(Order);
      const historyRepo = manager.getRepository(OrderStatusHistory);
      const previous = order.status;
      order.status = dto.status as any;
      order.version = Number(order.version) + 1;
      if (next === 'placed') order.placedAt = order.placedAt ?? new Date();
      if (next === 'accepted') order.acceptedAt = new Date();
      if (next === 'delivered') order.deliveredAt = new Date();
      if (next === 'cancelled') {
        order.cancelledAt = new Date();
        order.cancellationReason = dto.note;
      }
      const saved = await orderRepo.save(order);
      await historyRepo.save(
        historyRepo.create({
          orderId: saved.id,
          previousStatus: String(previous),
          newStatus: next,
          changedByUserId: actorUserId,
          note: dto.note,
        }),
      );
      return saved;
    });
  }

  async cancelByCustomer(customerId: string, orderId: string, reason?: string) {
    const order = await this.customerDetail(customerId, orderId);
    if (!['pending_payment', 'placed', 'accepted'].includes(String(order.status))) {
      throw new BadRequestException('Order can no longer be cancelled');
    }
    return this.updateStatus(
      order.id,
      { status: OrderStatus.CANCELLED, note: reason } as UpdateOrderStatusDto,
      customerId,
    );
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\orders\orders.service.ts' -Content $content

$content = @'
import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('orders')
@UseGuards(JwtAuthGuard)
export class OrdersController {
  constructor(private readonly service: OrdersService) {}

  @Get('me')
  history(@CurrentUser() user: AuthenticatedUser) {
    return this.service.customerHistory(user.id);
  }

  @Get('me/:id')
  detail(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.customerDetail(user.id, id);
  }

  @Post('me/:id/cancel')
  cancel(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body('reason') reason?: string,
  ) {
    return this.service.cancelByCustomer(user.id, id, reason);
  }

  @Get('admin/list')
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  adminList(
    @Query('restaurantId') restaurantId?: string,
    @Query('status') status?: string,
  ) {
    return this.service.listAdmin(restaurantId, status);
  }

  @Patch('admin/:id/status')
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  updateStatus(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    return this.service.updateStatus(id, dto, user.id);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\orders\orders.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { OrderRepository } from './repositories/order.repository';

@Module({
  controllers: [OrdersController],
  providers: [OrdersService, OrderRepository],
  exports: [OrdersService, OrderRepository],
})
export class OrdersModule {}
'@
Write-CodeFile -RelativePath 'src\modules\orders\orders.module.ts' -Content $content

$content = @'
import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { CheckoutDto } from './dto/checkout.dto';
import { CartsService } from '../carts/carts.service';
import { Cart } from '../carts/entities/cart.entity';
import { CartItem } from '../carts/entities/cart-item.entity';
import { CartItemOption } from '../carts/entities/cart-item-option.entity';
import { Order } from '../orders/entities/order.entity';
import { OrderItem } from '../orders/entities/order-item.entity';
import { OrderItemOption } from '../orders/entities/order-item-option.entity';
import { OrderStatusHistory } from '../orders/entities/order-status-history.entity';
import { Restaurant } from '../restaurants/entities/restaurant.entity';
import { Coupon } from '../coupons/entities/coupon.entity';
import { CouponRedemption } from '../coupons/entities/coupon-redemption.entity';

@Injectable()
export class CheckoutService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly carts: CartsService,
  ) {}

  private computeCouponDiscount(coupon: Coupon, subtotalMinor: number): number {
    if (subtotalMinor < Number(coupon.minOrderMinor ?? 0)) return 0;
    if (coupon.discountType === 'percentage') {
      const raw = Math.floor(subtotalMinor * Number(coupon.discountValue) / 100);
      return coupon.maxDiscountMinor
        ? Math.min(raw, Number(coupon.maxDiscountMinor))
        : raw;
    }
    if (coupon.discountType === 'fixed_amount') {
      return Math.min(Number(coupon.discountValue), subtotalMinor);
    }
    return 0;
  }

  async checkout(customerId: string, dto: CheckoutDto) {
    const cartSummary = await this.carts.detail(customerId, dto.restaurantId);
    const { cart, items } = cartSummary;
    if (!items.length) throw new BadRequestException('Cart is empty');

    const restaurant = await this.dataSource.getRepository(Restaurant).findOne({
      where: { id: dto.restaurantId, isActive: true },
    });
    if (!restaurant) throw new NotFoundException('Restaurant not found');

    return this.dataSource.transaction(async (manager) => {
      const cartRepo = manager.getRepository(Cart);
      const cartItemRepo = manager.getRepository(CartItem);
      const cartOptionRepo = manager.getRepository(CartItemOption);
      const orderRepo = manager.getRepository(Order);
      const orderItemRepo = manager.getRepository(OrderItem);
      const orderOptionRepo = manager.getRepository(OrderItemOption);
      const historyRepo = manager.getRepository(OrderStatusHistory);

      const lockedCart = await cartRepo
        .createQueryBuilder('cart')
        .setLock('pessimistic_write')
        .where('cart.id = :id', { id: cart.id })
        .andWhere('cart.status = :status', { status: 'active' })
        .getOne();
      if (!lockedCart) throw new BadRequestException('Cart is no longer active');

      const lockedItems = await cartItemRepo.find({
        where: { cartId: cart.id },
        order: { createdAt: 'ASC' },
      });
      if (!lockedItems.length) throw new BadRequestException('Cart is empty');

      const subtotalMinor = lockedItems.reduce(
        (sum, item) => sum + Number(item.lineTotalMinor),
        0,
      );

      let coupon: Coupon | null = null;
      let discountMinor = 0;
      if (dto.couponCode) {
        coupon = await manager.getRepository(Coupon)
          .createQueryBuilder('coupon')
          .where('coupon.restaurant_id = :restaurantId', { restaurantId: dto.restaurantId })
          .andWhere('LOWER(coupon.code) = LOWER(:code)', { code: dto.couponCode })
          .andWhere('coupon.is_active = true')
          .andWhere('(coupon.starts_at IS NULL OR coupon.starts_at <= NOW())')
          .andWhere('(coupon.expires_at IS NULL OR coupon.expires_at > NOW())')
          .getOne();
        if (!coupon) throw new BadRequestException('Coupon is invalid or expired');
        discountMinor = this.computeCouponDiscount(coupon, subtotalMinor);
      }

      const deliveryFeeMinor =
        dto.orderType === 'delivery' ? Number(restaurant.deliveryFeeMinor ?? 0) : 0;
      if (coupon?.discountType === 'free_delivery') {
        discountMinor += deliveryFeeMinor;
      }

      const taxableMinor = Math.max(0, subtotalMinor + deliveryFeeMinor - discountMinor);
      const taxMinor =
        restaurant.taxBehavior === 'excluded'
          ? Math.round(taxableMinor * Number(restaurant.taxRateBasisPoints ?? 0) / 10000)
          : 0;
      const grandTotalMinor = Math.max(
        0,
        subtotalMinor + deliveryFeeMinor + taxMinor - discountMinor,
      );

      const now = new Date();
      const estimated = new Date(
        now.getTime() + Number(restaurant.defaultDeliveryMinutes ?? 30) * 60_000,
      );

      const order = await orderRepo.save(
        orderRepo.create({
          restaurantId: restaurant.id,
          customerId,
          cartId: cart.id,
          orderType: dto.orderType ?? 'delivery',
          status: dto.paymentMethod === 'cash' || dto.paymentMethod === 'card_on_delivery'
            ? 'placed'
            : 'pending_payment',
          paymentStatus:
            dto.paymentMethod === 'cash' || dto.paymentMethod === 'card_on_delivery'
              ? 'collection_pending'
              : 'pending',
          paymentMethod: dto.paymentMethod,
          currency: 'EUR',
          subtotalMinor,
          optionChargesMinor: 0,
          discountMinor,
          loyaltyDiscountMinor: 0,
          deliveryFeeMinor,
          taxMinor,
          grandTotalMinor,
          deliveryAddressSnapshot: dto.deliveryAddress,
          deliveryInstructions: dto.deliveryInstructions,
          customerNote: dto.customerNote,
          estimatedDeliveryAt: estimated,
          scheduledFor: dto.scheduledFor ? new Date(dto.scheduledFor) : undefined,
          placedAt:
            dto.paymentMethod === 'cash' || dto.paymentMethod === 'card_on_delivery'
              ? now
              : undefined,
          pricingSnapshot: {
            restaurantId: restaurant.id,
            taxBehavior: restaurant.taxBehavior,
            taxRateBasisPoints: restaurant.taxRateBasisPoints,
            couponCode: coupon?.code ?? null,
          },
          version: 1,
        }),
      );

      const cartOptions = lockedItems.length
        ? await cartOptionRepo
            .createQueryBuilder('option')
            .where('option.cart_item_id IN (:...ids)', { ids: lockedItems.map((i) => i.id) })
            .getMany()
        : [];

      for (const cartItem of lockedItems) {
        const orderItem = await orderItemRepo.save(
          orderItemRepo.create({
            orderId: order.id,
            menuItemId: cartItem.menuItemId,
            menuItemSizeId: cartItem.menuItemSizeId,
            itemNameSnapshot: cartItem.itemNameSnapshot,
            sizeNameSnapshot: cartItem.sizeNameSnapshot,
            quantity: cartItem.quantity,
            baseUnitPriceMinor: cartItem.baseUnitPriceMinor,
            optionsUnitPriceMinor: cartItem.optionsUnitPriceMinor,
            unitPriceMinor: cartItem.unitPriceMinor,
            lineTotalMinor: cartItem.lineTotalMinor,
            specialInstructions: cartItem.specialInstructions,
            configurationSnapshot: {
              configurationHash: cartItem.configurationHash,
            },
          }),
        );

        const options = cartOptions.filter((o) => o.cartItemId === cartItem.id);
        if (options.length) {
          await orderOptionRepo.save(
            options.map((option) =>
              orderOptionRepo.create({
                orderItemId: orderItem.id,
                optionGroupId: option.optionGroupId,
                optionChoiceId: option.optionChoiceId,
                ingredientId: option.ingredientId,
                action: option.action,
                optionNameSnapshot: option.optionNameSnapshot,
                quantity: option.quantity,
                unitPriceAdjustmentMinor: option.unitPriceAdjustmentMinor,
                totalPriceAdjustmentMinor: option.totalPriceAdjustmentMinor,
              }),
            ),
          );
        }
      }

      await historyRepo.save(
        historyRepo.create({
          orderId: order.id,
          previousStatus: undefined,
          newStatus: String(order.status),
          changedByUserId: customerId,
          note: 'Order created',
        }),
      );

      if (coupon) {
        await manager.getRepository(CouponRedemption).save(
          manager.getRepository(CouponRedemption).create({
            couponId: coupon.id,
            customerId,
            orderId: order.id,
            discountMinor,
          }),
        );
      }

      lockedCart.status = 'converted';
      await cartRepo.save(lockedCart);

      return {
        orderId: order.id,
        orderNumber: order.orderNumber,
        status: order.status,
        paymentStatus: order.paymentStatus,
        amountMinor: grandTotalMinor,
        currency: 'EUR',
        estimatedDeliveryAt: order.estimatedDeliveryAt,
      };
    });
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\checkout\checkout.service.ts' -Content $content

$content = @'
import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { CheckoutService } from './checkout.service';
import { CheckoutDto } from './dto/checkout.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';

@Controller('checkout')
@UseGuards(JwtAuthGuard)
export class CheckoutController {
  constructor(private readonly service: CheckoutService) {}

  @Post()
  checkout(@CurrentUser() user: AuthenticatedUser, @Body() dto: CheckoutDto) {
    return this.service.checkout(user.id, dto);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\checkout\checkout.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { CheckoutController } from './checkout.controller';
import { CheckoutService } from './checkout.service';
import { CartsModule } from '../carts/carts.module';

@Module({
  imports: [CartsModule],
  controllers: [CheckoutController],
  providers: [CheckoutService],
  exports: [CheckoutService],
})
export class CheckoutModule {}
'@
Write-CodeFile -RelativePath 'src\modules\checkout\checkout.module.ts' -Content $content

$content = @'
import { BadRequestException, Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { PaymentTransactionRepository } from './repositories/payment-transaction.repository';
import { PaymentTransaction } from './entities/payment-transaction.entity';
import { CustomerPaymentMethod } from './entities/customer-payment-method.entity';
import { PaymentWebhookEvent } from './entities/payment-webhook-event.entity';
import { PaymentReceipt } from './entities/payment-receipt.entity';
import { Order } from '../orders/entities/order.entity';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { SavePaymentMethodDto } from './dto/save-payment-method.dto';
import { CollectPaymentDto } from './dto/collect-payment.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class PaymentsService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly transactions: PaymentTransactionRepository,
  ) {}

  listMethods(customerId: string) {
    return this.dataSource.getRepository(CustomerPaymentMethod).find({
      where: { customerId, archivedAt: null as any },
      order: { isDefault: 'DESC', createdAt: 'DESC' },
    });
  }

  async saveMethod(customerId: string, dto: SavePaymentMethodDto) {
    const repo = this.dataSource.getRepository(CustomerPaymentMethod);
    if (dto.isDefault) {
      await repo.update({ customerId, isDefault: true }, { isDefault: false });
    }
    return repo.save(
      repo.create({
        ...dto,
        customerId,
        provider: dto.provider ?? 'stripe',
      }),
    );
  }

  async createIntent(customerId: string, dto: CreatePaymentIntentDto) {
    const order = requireEntity(
      await this.dataSource.getRepository(Order).findOne({
        where: { id: dto.orderId, customerId },
      }),
      'Order not found',
    );
    if (String(order.paymentStatus) === 'paid') {
      throw new BadRequestException('Order is already paid');
    }

    const existing = dto.idempotencyKey
      ? await this.transactions.findOne({
          where: { orderId: order.id, idempotencyKey: dto.idempotencyKey },
        })
      : null;
    if (existing) return existing;

    return this.transactions.save(
      this.transactions.create({
        orderId: order.id,
        customerId,
        paymentMethodId: dto.paymentMethodId,
        provider: 'stripe',
        paymentMethodType: dto.paymentMethodType,
        amountMinor: Number(order.grandTotalMinor),
        currency: 'EUR',
        status: 'pending',
        idempotencyKey: dto.idempotencyKey,
        metadata: {
          orderNumber: order.orderNumber,
          requiresProviderConfirmation: true,
        },
      }),
    );
  }

  async collectOnDelivery(
    orderId: string,
    collectorUserId: string,
    dto: CollectPaymentDto,
  ) {
    const order = requireEntity(
      await this.dataSource.getRepository(Order).findOne({ where: { id: orderId } }),
      'Order not found',
    );
    if (!['cash', 'card_on_delivery'].includes(String(order.paymentMethod))) {
      throw new BadRequestException('Order is not configured for pay-on-delivery');
    }
    return this.dataSource.transaction(async (manager) => {
      const txRepo = manager.getRepository(PaymentTransaction);
      const orderRepo = manager.getRepository(Order);
      const receiptRepo = manager.getRepository(PaymentReceipt);

      const transaction = await txRepo.save(
        txRepo.create({
          orderId: order.id,
          customerId: order.customerId,
          provider: dto.paymentMethodType === 'cash' ? 'cash' : 'external_terminal',
          paymentMethodType: dto.paymentMethodType,
          amountMinor: Number(order.grandTotalMinor),
          currency: 'EUR',
          status: 'captured',
          capturedAt: new Date(),
          metadata: { collectorUserId },
        }),
      );
      order.paymentStatus = 'paid' as any;
      await orderRepo.save(order);

      await receiptRepo.save(
        receiptRepo.create({
          orderId: order.id,
          paymentTransactionId: transaction.id,
          receiptNumber: `LF-R-${Date.now()}-${order.orderNumber}`,
          amountMinor: Number(order.grandTotalMinor),
          taxMinor: Number(order.taxMinor),
          currency: 'EUR',
          receiptData: { paymentMethod: dto.paymentMethodType },
        }),
      );
      return transaction;
    });
  }

  async recordWebhook(providerEventId: string, eventType: string, payload: unknown) {
    const repo = this.dataSource.getRepository(PaymentWebhookEvent);
    const existing = await repo.findOne({ where: { provider: 'stripe', providerEventId } });
    if (existing) return existing;
    return repo.save(
      repo.create({
        provider: 'stripe',
        providerEventId,
        eventType,
        payload: payload as any,
        processingStatus: 'pending',
        attempts: 0,
      }),
    );
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\payments\payments.service.ts' -Content $content

$content = @'
import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { SavePaymentMethodDto } from './dto/save-payment-method.dto';
import { CollectPaymentDto } from './dto/collect-payment.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('payments')
@UseGuards(JwtAuthGuard)
export class PaymentsController {
  constructor(private readonly service: PaymentsService) {}

  @Get('methods')
  methods(@CurrentUser() user: AuthenticatedUser) {
    return this.service.listMethods(user.id);
  }

  @Post('methods')
  saveMethod(@CurrentUser() user: AuthenticatedUser, @Body() dto: SavePaymentMethodDto) {
    return this.service.saveMethod(user.id, dto);
  }

  @Post('intent')
  createIntent(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreatePaymentIntentDto,
  ) {
    return this.service.createIntent(user.id, dto);
  }

  @Post('orders/:id/collect')
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  collect(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: CollectPaymentDto,
  ) {
    return this.service.collectOnDelivery(id, user.id, dto);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\payments\payments.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { PaymentTransactionRepository } from './repositories/payment-transaction.repository';

@Module({
  controllers: [PaymentsController],
  providers: [PaymentsService, PaymentTransactionRepository],
  exports: [PaymentsService],
})
export class PaymentsModule {}
'@
Write-CodeFile -RelativePath 'src\modules\payments\payments.module.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { DeliveryTrackingRepository } from './repositories/delivery-tracking.repository';
import { DeliveryAssignment } from './entities/delivery-assignment.entity';
import { DeliveryTracking } from './entities/delivery-tracking.entity';
import { DeliveryTrackingEvent } from './entities/delivery-tracking-event.entity';
import { AssignDriverDto } from './dto/assign-driver.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class DeliveriesService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly tracking: DeliveryTrackingRepository,
  ) {}

  async getTracking(orderId: string) {
    return requireEntity(
      await this.tracking.findByOrderId(orderId),
      'Delivery tracking not found',
    );
  }

  async assign(orderId: string, assignedByUserId: string, dto: AssignDriverDto) {
    return this.dataSource.transaction(async (manager) => {
      const assignmentRepo = manager.getRepository(DeliveryAssignment);
      const trackingRepo = manager.getRepository(DeliveryTracking);

      let assignment = await assignmentRepo.findOne({ where: { orderId } });
      if (!assignment) {
        assignment = assignmentRepo.create({
          orderId,
          driverUserId: dto.driverUserId,
          assignedByUserId,
          status: 'assigned',
        });
      } else {
        assignment.driverUserId = dto.driverUserId;
        assignment.assignedByUserId = assignedByUserId;
        assignment.status = 'assigned' as any;
        assignment.assignedAt = new Date();
      }
      assignment = await assignmentRepo.save(assignment);

      let tracking = await trackingRepo.findOne({ where: { orderId } });
      if (!tracking) {
        tracking = trackingRepo.create({
          orderId,
          assignmentId: assignment.id,
          status: 'driver_assigned',
        });
      } else {
        tracking.assignmentId = assignment.id;
        tracking.status = 'driver_assigned' as any;
      }
      await trackingRepo.save(tracking);
      return assignment;
    });
  }

  async updateLocation(orderId: string, dto: UpdateLocationDto) {
    return this.dataSource.transaction(async (manager) => {
      const trackingRepo = manager.getRepository(DeliveryTracking);
      const eventRepo = manager.getRepository(DeliveryTrackingEvent);
      const tracking = await trackingRepo.findOne({ where: { orderId } });
      if (!tracking) throw new Error('Delivery tracking not found');

      tracking.currentLatitude = dto.latitude;
      tracking.currentLongitude = dto.longitude;
      tracking.headingDegrees = dto.headingDegrees;
      tracking.speedKph = dto.speedKph;
      tracking.remainingMinutes = dto.remainingMinutes;
      tracking.estimatedArrivalAt = dto.estimatedArrivalAt
        ? new Date(dto.estimatedArrivalAt)
        : tracking.estimatedArrivalAt;
      tracking.lastPingedAt = new Date();
      if (dto.status) tracking.status = dto.status as any;
      const saved = await trackingRepo.save(tracking);

      await eventRepo.save(
        eventRepo.create({
          trackingId: saved.id,
          status: dto.status,
          latitude: dto.latitude,
          longitude: dto.longitude,
          remainingMinutes: dto.remainingMinutes,
          source: 'driver',
        }),
      );

      return saved;
    });
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\deliveries\deliveries.service.ts' -Content $content

$content = @'
import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { DeliveriesService } from './deliveries.service';
import { AssignDriverDto } from './dto/assign-driver.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('deliveries')
export class DeliveriesController {
  constructor(private readonly service: DeliveriesService) {}

  @Get('orders/:orderId/tracking')
  @UseGuards(JwtAuthGuard)
  tracking(@Param('orderId') orderId: string) {
    return this.service.getTracking(orderId);
  }

  @Post('orders/:orderId/assign')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  assign(
    @CurrentUser() user: AuthenticatedUser,
    @Param('orderId') orderId: string,
    @Body() dto: AssignDriverDto,
  ) {
    return this.service.assign(orderId, user.id, dto);
  }

  @Patch('orders/:orderId/location')
  @UseGuards(JwtAuthGuard)
  updateLocation(@Param('orderId') orderId: string, @Body() dto: UpdateLocationDto) {
    return this.service.updateLocation(orderId, dto);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\deliveries\deliveries.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { DeliveriesController } from './deliveries.controller';
import { DeliveriesService } from './deliveries.service';
import { DeliveryTrackingRepository } from './repositories/delivery-tracking.repository';

@Module({
  controllers: [DeliveriesController],
  providers: [DeliveriesService, DeliveryTrackingRepository],
  exports: [DeliveriesService],
})
export class DeliveriesModule {}
'@
Write-CodeFile -RelativePath 'src\modules\deliveries\deliveries.module.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { NotificationRepository } from './repositories/notification.repository';
import { Notification } from './entities/notification.entity';
import { DeviceToken } from './entities/device-token.entity';
import { NotificationPreference } from './entities/notification-preference.entity';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { UpdateNotificationPreferencesDto } from './dto/update-notification-preferences.dto';

@Injectable()
export class NotificationsService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly notifications: NotificationRepository,
  ) {}

  list(userId: string) {
    return this.notifications.findMany({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: 100,
    });
  }

  async unreadCount(userId: string): Promise<number> {
    return this.dataSource.getRepository(Notification)
      .createQueryBuilder('notification')
      .where('notification.user_id = :userId', { userId })
      .andWhere('notification.read_at IS NULL')
      .getCount();
  }

  async markRead(userId: string, id: string) {
    const notification = await this.notifications.findOne({ where: { id, userId } });
    if (!notification) return null;
    notification.readAt = new Date();
    return this.notifications.save(notification);
  }

  async registerDevice(userId: string, dto: RegisterDeviceTokenDto) {
    const repo = this.dataSource.getRepository(DeviceToken);
    let token = await repo.findOne({ where: { token: dto.token } });
    if (!token) {
      token = repo.create({
        userId,
        platform: dto.platform,
        provider: 'fcm',
        token: dto.token,
        isActive: true,
        lastSeenAt: new Date(),
      });
    } else {
      token.userId = userId;
      token.platform = dto.platform;
      token.isActive = true;
      token.lastSeenAt = new Date();
    }
    return repo.save(token);
  }

  async preferences(userId: string) {
    const repo = this.dataSource.getRepository(NotificationPreference);
    let preferences = await repo.findOne({ where: { userId } });
    if (!preferences) {
      preferences = await repo.save(repo.create({ userId }));
    }
    return preferences;
  }

  async updatePreferences(userId: string, dto: UpdateNotificationPreferencesDto) {
    const repo = this.dataSource.getRepository(NotificationPreference);
    let preferences = await this.preferences(userId);
    Object.assign(preferences, dto);
    return repo.save(preferences);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\notifications\notifications.service.ts' -Content $content

$content = @'
import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { UpdateNotificationPreferencesDto } from './dto/update-notification-preferences.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly service: NotificationsService) {}

  @Get()
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.service.list(user.id);
  }

  @Get('unread-count')
  async unread(@CurrentUser() user: AuthenticatedUser) {
    return { count: await this.service.unreadCount(user.id) };
  }

  @Patch(':id/read')
  markRead(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.markRead(user.id, id);
  }

  @Post('devices')
  registerDevice(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RegisterDeviceTokenDto,
  ) {
    return this.service.registerDevice(user.id, dto);
  }

  @Get('preferences/me')
  preferences(@CurrentUser() user: AuthenticatedUser) {
    return this.service.preferences(user.id);
  }

  @Patch('preferences/me')
  updatePreferences(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateNotificationPreferencesDto,
  ) {
    return this.service.updatePreferences(user.id, dto);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\notifications\notifications.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { NotificationRepository } from './repositories/notification.repository';

@Module({
  controllers: [NotificationsController],
  providers: [NotificationsService, NotificationRepository],
  exports: [NotificationsService],
})
export class NotificationsModule {}
'@
Write-CodeFile -RelativePath 'src\modules\notifications\notifications.module.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { FavoriteRepository } from './repositories/favorite.repository';
import { CreateFavoriteDto } from './dto/create-favorite.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class FavoritesService {
  constructor(private readonly favorites: FavoriteRepository) {}

  list(customerId: string) {
    return this.favorites.findMany({
      where: { customerId },
      order: { createdAt: 'DESC' },
    });
  }

  create(customerId: string, dto: CreateFavoriteDto) {
    return this.favorites.save(
      this.favorites.create({
        ...dto,
        customerId,
        configurationSnapshot: dto.configurationSnapshot ?? {},
      }),
    );
  }

  async remove(customerId: string, id: string): Promise<void> {
    const favorite = requireEntity(
      await this.favorites.findOne({ where: { id, customerId } }),
      'Favorite not found',
    );
    await this.favorites.deleteById(favorite.id);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\favorites\favorites.service.ts' -Content $content

$content = @'
import { Body, Controller, Delete, Get, Param, Post, UseGuards } from '@nestjs/common';
import { FavoritesService } from './favorites.service';
import { CreateFavoriteDto } from './dto/create-favorite.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';

@Controller('favorites')
@UseGuards(JwtAuthGuard)
export class FavoritesController {
  constructor(private readonly service: FavoritesService) {}

  @Get()
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.service.list(user.id);
  }

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateFavoriteDto) {
    return this.service.create(user.id, dto);
  }

  @Delete(':id')
  async remove(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.service.remove(user.id, id);
    return { success: true };
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\favorites\favorites.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { FavoritesController } from './favorites.controller';
import { FavoritesService } from './favorites.service';
import { FavoriteRepository } from './repositories/favorite.repository';

@Module({
  controllers: [FavoritesController],
  providers: [FavoritesService, FavoriteRepository],
  exports: [FavoritesService],
})
export class FavoritesModule {}
'@
Write-CodeFile -RelativePath 'src\modules\favorites\favorites.module.ts' -Content $content

$content = @'
import { BadRequestException, Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { LoyaltyAccountRepository } from './repositories/loyalty-account.repository';
import { LoyaltyAccount } from './entities/loyalty-account.entity';
import { LoyaltyTransaction } from './entities/loyalty-transaction.entity';
import { RedeemLoyaltyPointsDto } from './dto/redeem-loyalty-points.dto';

@Injectable()
export class LoyaltyService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly accounts: LoyaltyAccountRepository,
  ) {}

  async getOrCreate(customerId: string): Promise<LoyaltyAccount> {
    let account = await this.accounts.findByCustomerId(customerId);
    if (!account) {
      account = await this.accounts.save(
        this.accounts.create({
          customerId,
          pointsBalance: 0,
          lifetimePointsEarned: 0,
          tier: 'standard',
        }),
      );
    }
    return account;
  }

  async balance(customerId: string) {
    const account = await this.getOrCreate(customerId);
    return { points: account.pointsBalance, tier: account.tier };
  }

  history(customerId: string) {
    return this.dataSource.getRepository(LoyaltyTransaction)
      .createQueryBuilder('tx')
      .innerJoin(LoyaltyAccount, 'account', 'account.id = tx.loyalty_account_id')
      .where('account.customer_id = :customerId', { customerId })
      .orderBy('tx.created_at', 'DESC')
      .getMany();
  }

  async redeem(customerId: string, dto: RedeemLoyaltyPointsDto) {
    return this.dataSource.transaction(async (manager) => {
      const accountRepo = manager.getRepository(LoyaltyAccount);
      const txRepo = manager.getRepository(LoyaltyTransaction);

      const account = await accountRepo
        .createQueryBuilder('account')
        .setLock('pessimistic_write')
        .where('account.customer_id = :customerId', { customerId })
        .getOne();
      if (!account) throw new BadRequestException('Loyalty account not found');
      if (Number(account.pointsBalance) < dto.points) {
        throw new BadRequestException('Insufficient loyalty points');
      }

      account.pointsBalance = Number(account.pointsBalance) - dto.points;
      await accountRepo.save(account);
      return txRepo.save(
        txRepo.create({
          loyaltyAccountId: account.id,
          orderId: dto.orderId,
          type: 'redeemed',
          pointsDelta: -dto.points,
          balanceAfter: account.pointsBalance,
          description: 'Loyalty points redeemed',
        }),
      );
    });
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\loyalty\loyalty.service.ts' -Content $content

$content = @'
import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { LoyaltyService } from './loyalty.service';
import { RedeemLoyaltyPointsDto } from './dto/redeem-loyalty-points.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';

@Controller('loyalty')
@UseGuards(JwtAuthGuard)
export class LoyaltyController {
  constructor(private readonly service: LoyaltyService) {}

  @Get('balance')
  balance(@CurrentUser() user: AuthenticatedUser) {
    return this.service.balance(user.id);
  }

  @Get('history')
  history(@CurrentUser() user: AuthenticatedUser) {
    return this.service.history(user.id);
  }

  @Post('redeem')
  redeem(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RedeemLoyaltyPointsDto,
  ) {
    return this.service.redeem(user.id, dto);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\loyalty\loyalty.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { LoyaltyController } from './loyalty.controller';
import { LoyaltyService } from './loyalty.service';
import { LoyaltyAccountRepository } from './repositories/loyalty-account.repository';

@Module({
  controllers: [LoyaltyController],
  providers: [LoyaltyService, LoyaltyAccountRepository],
  exports: [LoyaltyService],
})
export class LoyaltyModule {}
'@
Write-CodeFile -RelativePath 'src\modules\loyalty\loyalty.module.ts' -Content $content

$content = @'
import { Injectable, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { SupportTicketRepository } from './repositories/support-ticket.repository';
import { SupportMessage } from './entities/support-message.entity';
import { CreateSupportTicketDto } from './dto/create-support-ticket.dto';
import { CreateSupportMessageDto } from './dto/create-support-message.dto';
import { UpdateSupportTicketDto } from './dto/update-support-ticket.dto';

@Injectable()
export class SupportService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly tickets: SupportTicketRepository,
  ) {}

  listCustomer(customerId: string) {
    return this.tickets.findMany({
      where: { customerId },
      order: { createdAt: 'DESC' },
    });
  }

  create(customerId: string, dto: CreateSupportTicketDto) {
    return this.tickets.save(
      this.tickets.create({
        ...dto,
        customerId,
        status: 'open',
        priority: dto.priority ?? 'normal',
      }),
    );
  }

  async detail(customerId: string, id: string) {
    const ticket = await this.tickets.findOne({ where: { id, customerId } });
    if (!ticket) throw new NotFoundException('Support ticket not found');
    const messages = await this.dataSource.getRepository(SupportMessage).find({
      where: { ticketId: ticket.id },
      order: { createdAt: 'ASC' },
    });
    return { ticket, messages };
  }

  async addCustomerMessage(
    customerId: string,
    ticketId: string,
    dto: CreateSupportMessageDto,
  ) {
    await this.detail(customerId, ticketId);
    return this.dataSource.getRepository(SupportMessage).save(
      this.dataSource.getRepository(SupportMessage).create({
        ticketId,
        authorUserId: customerId,
        authorType: 'customer',
        body: dto.body,
      }),
    );
  }

  listAdmin() {
    return this.tickets.findMany({ order: { createdAt: 'DESC' } });
  }

  async updateAdmin(id: string, dto: UpdateSupportTicketDto) {
    const ticket = await this.tickets.findById(id);
    if (!ticket) throw new NotFoundException('Support ticket not found');
    Object.assign(ticket, dto);
    if (dto.status === 'resolved') ticket.resolvedAt = new Date();
    if (dto.status === 'closed') ticket.closedAt = new Date();
    return this.tickets.save(ticket);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\support\support.service.ts' -Content $content

$content = @'
import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { SupportService } from './support.service';
import { CreateSupportTicketDto } from './dto/create-support-ticket.dto';
import { CreateSupportMessageDto } from './dto/create-support-message.dto';
import { UpdateSupportTicketDto } from './dto/update-support-ticket.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('support')
@UseGuards(JwtAuthGuard)
export class SupportController {
  constructor(private readonly service: SupportService) {}

  @Get('tickets')
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.service.listCustomer(user.id);
  }

  @Post('tickets')
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateSupportTicketDto) {
    return this.service.create(user.id, dto);
  }

  @Get('tickets/:id')
  detail(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.detail(user.id, id);
  }

  @Post('tickets/:id/messages')
  message(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: CreateSupportMessageDto,
  ) {
    return this.service.addCustomerMessage(user.id, id, dto);
  }

  @Get('admin/tickets')
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  adminList() {
    return this.service.listAdmin();
  }

  @Patch('admin/tickets/:id')
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  adminUpdate(@Param('id') id: string, @Body() dto: UpdateSupportTicketDto) {
    return this.service.updateAdmin(id, dto);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\support\support.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { SupportController } from './support.controller';
import { SupportService } from './support.service';
import { SupportTicketRepository } from './repositories/support-ticket.repository';

@Module({
  controllers: [SupportController],
  providers: [SupportService, SupportTicketRepository],
  exports: [SupportService],
})
export class SupportModule {}
'@
Write-CodeFile -RelativePath 'src\modules\support\support.module.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { SalesReportQueryDto } from './dto/sales-report-query.dto';
import { Order } from '../orders/entities/order.entity';
import { OrderItem } from '../orders/entities/order-item.entity';

@Injectable()
export class ReportsService {
  constructor(private readonly dataSource: DataSource) {}

  async sales(query: SalesReportQueryDto) {
    const qb = this.dataSource.getRepository(Order)
      .createQueryBuilder('o')
      .select('COUNT(o.id)', 'totalOrders')
      .addSelect("COALESCE(SUM(CASE WHEN o.status IN ('delivered','closed') THEN o.grand_total_minor ELSE 0 END),0)", 'revenueMinor')
      .addSelect('COALESCE(SUM(o.discount_minor),0)', 'discountMinor')
      .addSelect('COALESCE(SUM(o.tax_minor),0)', 'taxMinor')
      .where('o.restaurant_id = :restaurantId', { restaurantId: query.restaurantId });

    if (query.from) qb.andWhere('o.created_at >= :from', { from: query.from });
    if (query.to) qb.andWhere('o.created_at < (:to::date + INTERVAL \'1 day\')', { to: query.to });

    return qb.getRawOne();
  }

  async popularItems(query: SalesReportQueryDto) {
    const qb = this.dataSource.getRepository(OrderItem)
      .createQueryBuilder('i')
      .innerJoin(Order, 'o', 'o.id = i.order_id')
      .select('i.menu_item_id', 'menuItemId')
      .addSelect('MAX(i.item_name_snapshot)', 'name')
      .addSelect('SUM(i.quantity)', 'quantity')
      .addSelect('SUM(i.line_total_minor)', 'revenueMinor')
      .where('o.restaurant_id = :restaurantId', { restaurantId: query.restaurantId })
      .andWhere("o.status IN ('delivered','closed')");

    if (query.from) qb.andWhere('o.created_at >= :from', { from: query.from });
    if (query.to) qb.andWhere('o.created_at < (:to::date + INTERVAL \'1 day\')', { to: query.to });

    return qb
      .groupBy('i.menu_item_id')
      .orderBy('SUM(i.quantity)', 'DESC')
      .limit(20)
      .getRawMany();
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\reports\reports.service.ts' -Content $content

$content = @'
import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { SalesReportQueryDto } from './dto/sales-report-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('reports')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(RoleEnum.ADMIN)
export class ReportsController {
  constructor(private readonly service: ReportsService) {}

  @Get('sales')
  sales(@Query() query: SalesReportQueryDto) {
    return this.service.sales(query);
  }

  @Get('popular-items')
  popular(@Query() query: SalesReportQueryDto) {
    return this.service.popularItems(query);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\reports\reports.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { ReportsController } from './reports.controller';
import { ReportsService } from './reports.service';

@Module({
  controllers: [ReportsController],
  providers: [ReportsService],
  exports: [ReportsService],
})
export class ReportsModule {}
'@
Write-CodeFile -RelativePath 'src\modules\reports\reports.module.ts' -Content $content

$content = @'
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
'@
Write-CodeFile -RelativePath 'src\modules\customers\customers.service.ts' -Content $content

$content = @'
import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { CustomersService } from './customers.service';
import { UpdateCustomerProfileDto } from './dto/update-customer-profile.dto';
import { UpdateCustomerPreferencesDto } from './dto/update-customer-preferences.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';

@Controller('customers/me')
@UseGuards(JwtAuthGuard)
export class CustomersController {
  constructor(private readonly service: CustomersService) {}

  @Get('profile')
  profile(@CurrentUser() user: AuthenticatedUser) {
    return this.service.profile(user.id);
  }

  @Patch('profile')
  updateProfile(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateCustomerProfileDto,
  ) {
    return this.service.updateProfile(user.id, dto);
  }

  @Get('preferences')
  preferences(@CurrentUser() user: AuthenticatedUser) {
    return this.service.preferences(user.id);
  }

  @Patch('preferences')
  updatePreferences(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateCustomerPreferencesDto,
  ) {
    return this.service.updatePreferences(user.id, dto);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\customers\customers.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { CustomersController } from './customers.controller';
import { CustomersService } from './customers.service';
import { CustomerProfileRepository } from './repositories/customer-profile.repository';

@Module({
  controllers: [CustomersController],
  providers: [CustomersService, CustomerProfileRepository],
  exports: [CustomersService],
})
export class CustomersModule {}
'@
Write-CodeFile -RelativePath 'src\modules\customers\customers.module.ts' -Content $content

$content = @'
import { Injectable, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { CustomerAddressRepository } from './repositories/customer-address.repository';
import { CustomerAddress } from './entities/customer-address.entity';
import { CreateAddressDto } from './dto/create-address.dto';
import { UpdateAddressDto } from './dto/update-address.dto';

@Injectable()
export class AddressesService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly addresses: CustomerAddressRepository,
  ) {}

  list(customerId: string) {
    return this.addresses.findActiveForCustomer(customerId);
  }

  async create(customerId: string, dto: CreateAddressDto) {
    return this.dataSource.transaction(async (manager) => {
      const repo = manager.getRepository(CustomerAddress);
      if (dto.isDefault) {
        await repo.update({ customerId, isDefault: true }, { isDefault: false });
      }
      return repo.save(
        repo.create({
          ...dto,
          customerId,
          countryCode: dto.countryCode ?? 'IT',
          isActive: true,
          isDefault: dto.isDefault ?? false,
        }),
      );
    });
  }

  async update(customerId: string, id: string, dto: UpdateAddressDto) {
    return this.dataSource.transaction(async (manager) => {
      const repo = manager.getRepository(CustomerAddress);
      const address = await repo.findOne({ where: { id, customerId, isActive: true } });
      if (!address) throw new NotFoundException('Address not found');
      if (dto.isDefault) {
        await repo.update({ customerId, isDefault: true }, { isDefault: false });
      }
      Object.assign(address, dto);
      return repo.save(address);
    });
  }

  async remove(customerId: string, id: string) {
    const address = await this.addresses.findOne({
      where: { id, customerId, isActive: true },
    });
    if (!address) throw new NotFoundException('Address not found');
    address.isActive = false;
    address.isDefault = false;
    await this.addresses.save(address);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\addresses\addresses.service.ts' -Content $content

$content = @'
import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { AddressesService } from './addresses.service';
import { CreateAddressDto } from './dto/create-address.dto';
import { UpdateAddressDto } from './dto/update-address.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';

@Controller('customers/me/addresses')
@UseGuards(JwtAuthGuard)
export class AddressesController {
  constructor(private readonly service: AddressesService) {}

  @Get()
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.service.list(user.id);
  }

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateAddressDto) {
    return this.service.create(user.id, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateAddressDto,
  ) {
    return this.service.update(user.id, id, dto);
  }

  @Delete(':id')
  async remove(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.service.remove(user.id, id);
    return { success: true };
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\addresses\addresses.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { AddressesController } from './addresses.controller';
import { AddressesService } from './addresses.service';
import { CustomerAddressRepository } from './repositories/customer-address.repository';

@Module({
  controllers: [AddressesController],
  providers: [AddressesService, CustomerAddressRepository],
  exports: [AddressesService],
})
export class AddressesModule {}
'@
Write-CodeFile -RelativePath 'src\modules\addresses\addresses.module.ts' -Content $content

$content = @'
import { Injectable, NotFoundException } from '@nestjs/common';
import { RefundRepository } from './repositories/refund.repository';
import { CreateRefundDto } from './dto/create-refund.dto';

@Injectable()
export class RefundsService {
  constructor(private readonly refunds: RefundRepository) {}

  create(customerId: string, dto: CreateRefundDto) {
    return this.refunds.save(
      this.refunds.create({
        ...dto,
        requestedByUserId: customerId,
        status: 'requested',
      }),
    );
  }

  listForOrder(orderId: string) {
    return this.refunds.findMany({
      where: { orderId },
      order: { createdAt: 'DESC' },
    });
  }

  async approve(id: string, staffNote?: string) {
    const refund = await this.refunds.findById(id);
    if (!refund) throw new NotFoundException('Refund not found');
    refund.status = 'approved' as any;
    refund.staffNote = staffNote;
    return this.refunds.save(refund);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\refunds\refunds.service.ts' -Content $content

$content = @'
import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { RefundsService } from './refunds.service';
import { CreateRefundDto } from './dto/create-refund.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('refunds')
@UseGuards(JwtAuthGuard)
export class RefundsController {
  constructor(private readonly service: RefundsService) {}

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateRefundDto) {
    return this.service.create(user.id, dto);
  }

  @Get('orders/:orderId')
  list(@Param('orderId') orderId: string) {
    return this.service.listForOrder(orderId);
  }

  @Patch(':id/approve')
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  approve(@Param('id') id: string, @Body('staffNote') staffNote?: string) {
    return this.service.approve(id, staffNote);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\refunds\refunds.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { RefundsController } from './refunds.controller';
import { RefundsService } from './refunds.service';
import { RefundRepository } from './repositories/refund.repository';

@Module({
  controllers: [RefundsController],
  providers: [RefundsService, RefundRepository],
  exports: [RefundsService],
})
export class RefundsModule {}
'@
Write-CodeFile -RelativePath 'src\modules\refunds\refunds.module.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { MediaAssetRepository } from './repositories/media-asset.repository';
import { CreateUploadUrlDto } from './dto/create-upload-url.dto';

@Injectable()
export class MediaService {
  constructor(private readonly assets: MediaAssetRepository) {}

  async registerPendingUpload(userId: string, dto: CreateUploadUrlDto) {
    const key = `restaurants/${dto.restaurantId ?? 'shared'}/${Date.now()}-${Math.random()
      .toString(36)
      .slice(2)}-${dto.fileName.replace(/[^a-zA-Z0-9._-]/g, '_')}`;

    const asset = await this.assets.save(
      this.assets.create({
        restaurantId: dto.restaurantId,
        uploadedByUserId: userId,
        storageProvider: 'aws_s3',
        bucket: process.env.AWS_S3_BUCKET ?? '',
        objectKey: key,
        mimeType: dto.mimeType,
        sizeBytes: dto.sizeBytes,
        altText: dto.altText,
        status: 'pending',
      }),
    );

    return {
      asset,
      objectKey: key,
      uploadStrategy: 'presigned-url',
      note: 'Use the AWS S3 integration service to generate the presigned PUT URL.',
    };
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\media\media.service.ts' -Content $content

$content = @'
import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { MediaService } from './media.service';
import { CreateUploadUrlDto } from './dto/create-upload-url.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';

@Controller('media')
@UseGuards(JwtAuthGuard)
export class MediaController {
  constructor(private readonly service: MediaService) {}

  @Post('uploads')
  register(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateUploadUrlDto) {
    return this.service.registerPendingUpload(user.id, dto);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\media\media.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { MediaController } from './media.controller';
import { MediaService } from './media.service';
import { MediaAssetRepository } from './repositories/media-asset.repository';

@Module({
  controllers: [MediaController],
  providers: [MediaService, MediaAssetRepository],
  exports: [MediaService],
})
export class MediaModule {}
'@
Write-CodeFile -RelativePath 'src\modules\media\media.module.ts' -Content $content

$content = @'
import { Injectable, NotFoundException } from '@nestjs/common';
import { StaffMemberRepository } from './repositories/staff-member.repository';
import { CreateStaffMemberDto } from './dto/create-staff-member.dto';

@Injectable()
export class StaffService {
  constructor(private readonly staff: StaffMemberRepository) {}

  list(restaurantId?: string) {
    return this.staff.findMany({
      where: restaurantId ? { restaurantId, isActive: true } : { isActive: true },
      order: { createdAt: 'DESC' },
    });
  }

  create(dto: CreateStaffMemberDto) {
    return this.staff.save(this.staff.create({ ...dto, isActive: true }));
  }

  async deactivate(id: string) {
    const staff = await this.staff.findById(id);
    if (!staff) throw new NotFoundException('Staff member not found');
    staff.isActive = false;
    return this.staff.save(staff);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\staff\staff.service.ts' -Content $content

$content = @'
import { Body, Controller, Delete, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { StaffService } from './staff.service';
import { CreateStaffMemberDto } from './dto/create-staff-member.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('staff')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(RoleEnum.ADMIN)
export class StaffController {
  constructor(private readonly service: StaffService) {}

  @Get()
  list(@Query('restaurantId') restaurantId?: string) {
    return this.service.list(restaurantId);
  }

  @Post()
  create(@Body() dto: CreateStaffMemberDto) {
    return this.service.create(dto);
  }

  @Delete(':id')
  deactivate(@Param('id') id: string) {
    return this.service.deactivate(id);
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\staff\staff.controller.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { StaffController } from './staff.controller';
import { StaffService } from './staff.service';
import { StaffMemberRepository } from './repositories/staff-member.repository';

@Module({
  controllers: [StaffController],
  providers: [StaffService, StaffMemberRepository],
  exports: [StaffService],
})
export class StaffModule {}
'@
Write-CodeFile -RelativePath 'src\modules\staff\staff.module.ts' -Content $content

$content = @'
import { Injectable } from '@nestjs/common';
import { AuditLogRepository } from './repositories/audit-log.repository';
import { AuditContext } from './interfaces/audit-context.interface';

@Injectable()
export class AuditService {
  constructor(private readonly logs: AuditLogRepository) {}

  record(
    action: string,
    resourceType: string,
    resourceId: string | undefined,
    context: AuditContext,
    beforeData?: unknown,
    afterData?: unknown,
  ) {
    return this.logs.save(
      this.logs.create({
        actorUserId: context.actorUserId,
        action,
        resourceType,
        resourceId,
        restaurantId: context.restaurantId,
        correlationId: context.correlationId,
        ipAddress: context.ipAddress,
        userAgent: context.userAgent,
        beforeData: beforeData as any,
        afterData: afterData as any,
        metadata: context.metadata ?? {},
      }),
    );
  }
}
'@
Write-CodeFile -RelativePath 'src\modules\audit\audit.service.ts' -Content $content

$content = @'
import { Global, Module } from '@nestjs/common';
import { AuditService } from './audit.service';
import { AuditLogRepository } from './repositories/audit-log.repository';

@Global()
@Module({
  providers: [AuditService, AuditLogRepository],
  exports: [AuditService],
})
export class AuditModule {}
'@
Write-CodeFile -RelativePath 'src\modules\audit\audit.module.ts' -Content $content

$content = @'
import { Module } from '@nestjs/common';
import { RestaurantsModule } from './restaurants/restaurants.module';
import { CustomersModule } from './customers/customers.module';
import { AddressesModule } from './addresses/addresses.module';
import { StaffModule } from './staff/staff.module';
import { MediaModule } from './media/media.module';
import { CategoriesModule } from './categories/categories.module';
import { IngredientsModule } from './ingredients/ingredients.module';
import { MenuModule } from './menu/menu.module';
import { OptionGroupsModule } from './option-groups/option-groups.module';
import { PricingModule } from './pricing/pricing.module';
import { PizzaBuilderModule } from './pizza-builder/pizza-builder.module';
import { CartsModule } from './carts/carts.module';
import { PromotionsModule } from './promotions/promotions.module';
import { CouponsModule } from './coupons/coupons.module';
import { CheckoutModule } from './checkout/checkout.module';
import { OrdersModule } from './orders/orders.module';
import { PaymentsModule } from './payments/payments.module';
import { RefundsModule } from './refunds/refunds.module';
import { DeliveriesModule } from './deliveries/deliveries.module';
import { NotificationsModule } from './notifications/notifications.module';
import { FavoritesModule } from './favorites/favorites.module';
import { LoyaltyModule } from './loyalty/loyalty.module';
import { SupportModule } from './support/support.module';
import { FaqModule } from './faq/faq.module';
import { ReportsModule } from './reports/reports.module';
import { AuditModule } from './audit/audit.module';

@Module({
  imports: [
    AuditModule,
    RestaurantsModule,
    CustomersModule,
    AddressesModule,
    StaffModule,
    MediaModule,
    CategoriesModule,
    IngredientsModule,
    MenuModule,
    OptionGroupsModule,
    PricingModule,
    PizzaBuilderModule,
    CartsModule,
    PromotionsModule,
    CouponsModule,
    CheckoutModule,
    OrdersModule,
    PaymentsModule,
    RefundsModule,
    DeliveriesModule,
    NotificationsModule,
    FavoritesModule,
    LoyaltyModule,
    SupportModule,
    FaqModule,
    ReportsModule,
  ],
  exports: [
    RestaurantsModule,
    CustomersModule,
    AddressesModule,
    StaffModule,
    MediaModule,
    CategoriesModule,
    IngredientsModule,
    MenuModule,
    OptionGroupsModule,
    PricingModule,
    PizzaBuilderModule,
    CartsModule,
    PromotionsModule,
    CouponsModule,
    CheckoutModule,
    OrdersModule,
    PaymentsModule,
    RefundsModule,
    DeliveriesModule,
    NotificationsModule,
    FavoritesModule,
    LoyaltyModule,
    SupportModule,
    FaqModule,
    ReportsModule,
  ],
})
export class BusinessModule {}
'@
Write-CodeFile -RelativePath 'src\modules\business.module.ts' -Content $content

$content = @'
# La Favola Application Layer Generator

This generated layer implements the NestJS controllers, services, and modules for the restaurant business flow.

## Included

- Restaurant/admin management
- Customer profile/preferences
- Delivery addresses
- Staff
- Menu/categories/ingredients/options
- Pizza builder and server-side pricing
- Cart
- Promotions/coupons
- Checkout transaction and immutable order snapshots
- Order history/status workflow
- Payment transaction persistence
- Pay-on-delivery collection
- Refund request/approval persistence
- Delivery assignment and location history
- Notifications/device tokens/preferences
- Favorites
- Loyalty balance/history/redemption
- Support tickets/messages
- FAQ
- Reports
- Audit service
- A single `BusinessModule` for easy root-module wiring

## Important third-party boundary

The generated application layer intentionally does not fake external provider behavior.

The following integrations still need their real provider adapters:
- Stripe PaymentIntent creation/confirmation and signature-verified webhooks
- AWS S3 presigned URL generation
- AWS SMS / End User Messaging
- Amazon SES or configured email provider
- Firebase Cloud Messaging delivery
- Google identity-token verification
- Apple identity-token verification

The services persist the required state and expose the correct business boundaries, but external provider calls must be implemented with real SDKs and credentials.

## Root module

After generation, import `BusinessModule` into `src/app.module.ts`.

```ts
import { BusinessModule } from './modules/business.module';

@Module({
  imports: [
    // existing ConfigModule, TypeOrmModule, AuthModule, RBAC modules...
    BusinessModule,
  ],
})
export class AppModule {}
```

## Run checks

```powershell
npm run format
npm run lint:check
npm run build
```

Then fix any mismatch caused by changes made to DTO/entity names after the domain generator was produced.
'@
Write-CodeFile -RelativePath 'APPLICATION_LAYER_GENERATION_NOTES.md' -Content $content


Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "Generation complete."
Write-Host "Files written: 81"
Write-Host ""
Write-Host "NEXT:"
Write-Host "1. Import BusinessModule in src/app.module.ts"
Write-Host "2. npm run format"
Write-Host "3. npm run lint:check"
Write-Host "4. npm run build"
Write-Host ""
Write-Host "Do not connect real Stripe/AWS/Firebase flows until their adapters are implemented."
Write-Host "------------------------------------------------------------"
