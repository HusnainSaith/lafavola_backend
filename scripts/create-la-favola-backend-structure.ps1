param(
    [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Ensure-Directory {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "[DIR ] $Path"
    }
    else {
        Write-Host "[SKIP] $Path"
    }
}

function Ensure-File {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$Content = "export {};`r`n"
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        Ensure-Directory $parent
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
        Write-Host "[FILE] $Path"
    }
    else {
        Write-Host "[KEEP] $Path"
    }
}

$Root = (Resolve-Path -LiteralPath $Root).Path

if (-not (Test-Path -LiteralPath (Join-Path $Root "package.json"))) {
    throw "package.json was not found in '$Root'. Run this script from the NestJS backend root or pass -Root."
}

if (-not (Test-Path -LiteralPath (Join-Path $Root "src"))) {
    throw "src folder was not found in '$Root'."
}

Write-Host ""
Write-Host "La Favola backend scaffold"
Write-Host "Root: $Root"
Write-Host "Existing files will NOT be overwritten."
Write-Host ""

# ---------------------------------------------------------------------------
# ROOT-LEVEL FOLDERS
# ---------------------------------------------------------------------------

$rootDirectories = @(
    "docs",
    "scripts",
    "seeds",
    "test\unit",
    "test\integration",
    "test\e2e",
    "test\fixtures",
    "test\mocks",
    "test\utils"
)

foreach ($dir in $rootDirectories) {
    Ensure-Directory (Join-Path $Root $dir)
}

# ---------------------------------------------------------------------------
# COMMON / CROSS-CUTTING INFRASTRUCTURE
# ---------------------------------------------------------------------------

$commonDirectories = @(
    "src\common\constants",
    "src\common\controllers",
    "src\common\decorators",
    "src\common\enums",
    "src\common\exceptions",
    "src\common\filters",
    "src\common\guards",
    "src\common\interceptor",
    "src\common\interfaces",
    "src\common\middleware",
    "src\common\modules",
    "src\common\pipes",
    "src\common\services",
    "src\common\types",
    "src\common\utils",
    "src\common\validators"
)

foreach ($dir in $commonDirectories) {
    Ensure-Directory (Join-Path $Root $dir)
}

$commonFiles = @{
    "src\common\constants\application.constants.ts" = "export const APPLICATION_NAME = 'La Favola';`r`n"
    "src\common\constants\pagination.constants.ts" = "export const DEFAULT_PAGE = 1;`r`nexport const DEFAULT_PAGE_SIZE = 20;`r`nexport const MAX_PAGE_SIZE = 100;`r`n"
    "src\common\enums\currency.enum.ts" = "export enum Currency {`r`n  EUR = 'EUR',`r`n}`r`n"
    "src\common\interfaces\pagination.interface.ts" = @"
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
"@
    "src\common\interfaces\request-context.interface.ts" = @"
export interface RequestContext {
  correlationId?: string;
  userId?: string;
  role?: string;
}
"@
    "src\common\utils\money.util.ts" = @"
export function eurosToMinorUnits(value: number): number {
  return Math.round(value * 100);
}

export function minorUnitsToEuros(value: number): number {
  return value / 100;
}
"@
}

foreach ($item in $commonFiles.GetEnumerator()) {
    Ensure-File (Join-Path $Root $item.Key) $item.Value
}

# ---------------------------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------------------------

$configFiles = @(
    "src\config\app.config.ts",
    "src\config\aws.config.ts",
    "src\config\stripe.config.ts",
    "src\config\firebase.config.ts",
    "src\config\mail.config.ts",
    "src\config\storage.config.ts"
)

foreach ($file in $configFiles) {
    Ensure-File (Join-Path $Root $file)
}

# ---------------------------------------------------------------------------
# DATABASE
# ---------------------------------------------------------------------------

$databaseDirectories = @(
    "src\database",
    "src\database\migrations",
    "src\database\subscribers",
    "src\database\factories",
    "src\database\repositories"
)

foreach ($dir in $databaseDirectories) {
    Ensure-Directory (Join-Path $Root $dir)
}

Ensure-File (Join-Path $Root "src\database\database.module.ts")
Ensure-File (Join-Path $Root "src\database\transaction.service.ts")

# ---------------------------------------------------------------------------
# EXTERNAL INTEGRATIONS
# ---------------------------------------------------------------------------

$integrations = @(
    @{ Name = "aws\s3";       Prefix = "s3" },
    @{ Name = "aws\sms";      Prefix = "sms" },
    @{ Name = "aws\ses";      Prefix = "ses" },
    @{ Name = "stripe";       Prefix = "stripe" },
    @{ Name = "firebase";     Prefix = "firebase" },
    @{ Name = "google";       Prefix = "google" },
    @{ Name = "apple";        Prefix = "apple" }
)

foreach ($integration in $integrations) {
    $dir = Join-Path $Root ("src\integrations\" + $integration.Name)
    Ensure-Directory $dir
    Ensure-Directory (Join-Path $dir "interfaces")
    Ensure-Directory (Join-Path $dir "dto")

    $prefix = $integration.Prefix
    Ensure-File (Join-Path $dir "$prefix.module.ts")
    Ensure-File (Join-Path $dir "$prefix.service.ts")
}

# Stripe webhooks deserve an explicit adapter/controller area.
Ensure-Directory (Join-Path $Root "src\integrations\stripe\webhooks")
Ensure-File (Join-Path $Root "src\integrations\stripe\webhooks\stripe-webhook.controller.ts")
Ensure-File (Join-Path $Root "src\integrations\stripe\webhooks\stripe-webhook.service.ts")

# ---------------------------------------------------------------------------
# DOMAIN MODULES
# ---------------------------------------------------------------------------

# Existing modules are included deliberately. The script never overwrites them;
# it only fills in missing conventional folders/files.
$modules = @(
    "auth",
    "users",
    "roles",
    "permissions",
    "role-permissions",
    "customers",
    "addresses",
    "staff",
    "restaurants",
    "media",
    "menu",
    "categories",
    "ingredients",
    "option-groups",
    "pizza-builder",
    "pricing",
    "carts",
    "promotions",
    "coupons",
    "checkout",
    "orders",
    "payments",
    "refunds",
    "deliveries",
    "notifications",
    "favorites",
    "loyalty",
    "support",
    "faq",
    "reports",
    "audit"
)

function Convert-ToPascalCase {
    param([string]$Value)

    $parts = $Value -split "[-_]"
    return (($parts | ForEach-Object {
        if ($_.Length -eq 0) { return "" }
        $_.Substring(0,1).ToUpper() + $_.Substring(1)
    }) -join "")
}

foreach ($module in $modules) {
    $moduleDir = Join-Path $Root "src\modules\$module"

    $subdirs = @(
        "",
        "dto",
        "entities",
        "interfaces",
        "repositories",
        "enums"
    )

    foreach ($subdir in $subdirs) {
        if ($subdir -eq "") {
            Ensure-Directory $moduleDir
        }
        else {
            Ensure-Directory (Join-Path $moduleDir $subdir)
        }
    }

    $className = Convert-ToPascalCase $module

    $moduleTemplate = @"
import { Module } from '@nestjs/common';

@Module({})
export class ${className}Module {}
"@

    $serviceTemplate = @"
import { Injectable } from '@nestjs/common';

@Injectable()
export class ${className}Service {}
"@

    $controllerTemplate = @"
import { Controller } from '@nestjs/common';

@Controller()
export class ${className}Controller {}
"@

    Ensure-File (Join-Path $moduleDir "$module.module.ts") $moduleTemplate
    Ensure-File (Join-Path $moduleDir "$module.service.ts") $serviceTemplate
    Ensure-File (Join-Path $moduleDir "$module.controller.ts") $controllerTemplate
}

# ---------------------------------------------------------------------------
# MODULE-SPECIFIC FILES
# ---------------------------------------------------------------------------

$specificFiles = @(
    # Customers / addresses
    "src\modules\customers\entities\customer-profile.entity.ts",
    "src\modules\customers\dto\update-customer-profile.dto.ts",
    "src\modules\addresses\entities\address.entity.ts",
    "src\modules\addresses\dto\create-address.dto.ts",
    "src\modules\addresses\dto\update-address.dto.ts",

    # Staff / restaurant
    "src\modules\staff\entities\staff-member.entity.ts",
    "src\modules\restaurants\entities\restaurant.entity.ts",
    "src\modules\restaurants\entities\business-hours.entity.ts",
    "src\modules\restaurants\dto\update-restaurant.dto.ts",
    "src\modules\restaurants\dto\update-business-hours.dto.ts",

    # Media
    "src\modules\media\entities\media-asset.entity.ts",
    "src\modules\media\dto\create-upload-url.dto.ts",

    # Menu/catalog
    "src\modules\categories\entities\category.entity.ts",
    "src\modules\categories\dto\create-category.dto.ts",
    "src\modules\categories\dto\update-category.dto.ts",
    "src\modules\menu\entities\menu-item.entity.ts",
    "src\modules\menu\entities\menu-item-size.entity.ts",
    "src\modules\menu\dto\create-menu-item.dto.ts",
    "src\modules\menu\dto\update-menu-item.dto.ts",
    "src\modules\ingredients\entities\ingredient.entity.ts",
    "src\modules\ingredients\entities\ingredient-category.entity.ts",
    "src\modules\ingredients\dto\create-ingredient.dto.ts",
    "src\modules\ingredients\dto\update-ingredient.dto.ts",
    "src\modules\option-groups\entities\option-group.entity.ts",
    "src\modules\option-groups\entities\option-choice.entity.ts",
    "src\modules\option-groups\entities\option-incompatibility.entity.ts",
    "src\modules\option-groups\dto\create-option-group.dto.ts",
    "src\modules\option-groups\dto\update-option-group.dto.ts",

    # Pizza builder / pricing
    "src\modules\pizza-builder\entities\pizza-builder-rule.entity.ts",
    "src\modules\pizza-builder\dto\build-pizza.dto.ts",
    "src\modules\pricing\pricing-engine.service.ts",
    "src\modules\pricing\interfaces\price-breakdown.interface.ts",

    # Cart
    "src\modules\carts\entities\cart.entity.ts",
    "src\modules\carts\entities\cart-item.entity.ts",
    "src\modules\carts\entities\cart-item-option.entity.ts",
    "src\modules\carts\dto\add-cart-item.dto.ts",
    "src\modules\carts\dto\update-cart-item.dto.ts",

    # Promotions / coupons
    "src\modules\promotions\entities\promotion.entity.ts",
    "src\modules\promotions\entities\promotion-rule.entity.ts",
    "src\modules\promotions\dto\create-promotion.dto.ts",
    "src\modules\promotions\dto\update-promotion.dto.ts",
    "src\modules\coupons\entities\coupon.entity.ts",
    "src\modules\coupons\entities\coupon-redemption.entity.ts",
    "src\modules\coupons\dto\apply-coupon.dto.ts",

    # Checkout / orders
    "src\modules\checkout\dto\checkout.dto.ts",
    "src\modules\checkout\interfaces\checkout-result.interface.ts",
    "src\modules\orders\entities\order.entity.ts",
    "src\modules\orders\entities\order-item.entity.ts",
    "src\modules\orders\entities\order-item-option.entity.ts",
    "src\modules\orders\entities\order-status-history.entity.ts",
    "src\modules\orders\enums\order-status.enum.ts",
    "src\modules\orders\dto\create-order.dto.ts",
    "src\modules\orders\dto\update-order-status.dto.ts",

    # Payments / refunds
    "src\modules\payments\entities\payment-method.entity.ts",
    "src\modules\payments\entities\payment-transaction.entity.ts",
    "src\modules\payments\entities\payment-webhook-event.entity.ts",
    "src\modules\payments\enums\payment-status.enum.ts",
    "src\modules\payments\dto\create-payment-intent.dto.ts",
    "src\modules\payments\dto\confirm-payment.dto.ts",
    "src\modules\refunds\entities\refund.entity.ts",
    "src\modules\refunds\dto\create-refund.dto.ts",

    # Delivery
    "src\modules\deliveries\entities\delivery-assignment.entity.ts",
    "src\modules\deliveries\entities\delivery-tracking.entity.ts",
    "src\modules\deliveries\entities\delivery-tracking-event.entity.ts",
    "src\modules\deliveries\enums\delivery-status.enum.ts",
    "src\modules\deliveries\dto\assign-driver.dto.ts",
    "src\modules\deliveries\dto\update-location.dto.ts",

    # Notifications
    "src\modules\notifications\entities\notification.entity.ts",
    "src\modules\notifications\entities\notification-preference.entity.ts",
    "src\modules\notifications\entities\device-token.entity.ts",
    "src\modules\notifications\dto\register-device-token.dto.ts",
    "src\modules\notifications\dto\update-notification-preferences.dto.ts",

    # Favorites
    "src\modules\favorites\entities\favorite.entity.ts",
    "src\modules\favorites\dto\create-favorite.dto.ts",

    # Loyalty
    "src\modules\loyalty\entities\loyalty-account.entity.ts",
    "src\modules\loyalty\entities\loyalty-transaction.entity.ts",
    "src\modules\loyalty\enums\loyalty-transaction-type.enum.ts",

    # Support / FAQ
    "src\modules\support\entities\support-ticket.entity.ts",
    "src\modules\support\entities\support-message.entity.ts",
    "src\modules\support\enums\support-ticket-status.enum.ts",
    "src\modules\support\dto\create-support-ticket.dto.ts",
    "src\modules\support\dto\create-support-message.dto.ts",
    "src\modules\faq\entities\faq-article.entity.ts",
    "src\modules\faq\dto\create-faq.dto.ts",
    "src\modules\faq\dto\update-faq.dto.ts",

    # Reporting / audit
    "src\modules\reports\dto\sales-report-query.dto.ts",
    "src\modules\reports\interfaces\sales-report.interface.ts",
    "src\modules\audit\entities\audit-log.entity.ts",
    "src\modules\audit\interfaces\audit-context.interface.ts"
)

foreach ($file in $specificFiles) {
    Ensure-File (Join-Path $Root $file)
}

# ---------------------------------------------------------------------------
# BACKGROUND PROCESSING / EVENTS
# ---------------------------------------------------------------------------

$backgroundDirs = @(
    "src\jobs",
    "src\events",
    "src\events\handlers",
    "src\queue"
)

foreach ($dir in $backgroundDirs) {
    Ensure-Directory (Join-Path $Root $dir)
}

$backgroundFiles = @(
    "src\jobs\loyalty-expiration.job.ts",
    "src\jobs\promotion-notification.job.ts",
    "src\jobs\report-snapshot.job.ts",
    "src\events\domain-event.interface.ts",
    "src\queue\outbox-event.entity.ts",
    "src\queue\outbox.service.ts",
    "src\queue\outbox.worker.ts"
)

foreach ($file in $backgroundFiles) {
    Ensure-File (Join-Path $Root $file)
}

# ---------------------------------------------------------------------------
# DOCUMENTATION PLACEHOLDERS
# ---------------------------------------------------------------------------

$docs = @{
    "docs\ARCHITECTURE.md" = "# La Favola Backend Architecture`r`n`r`nArchitecture documentation will live here.`r`n"
    "docs\DATABASE.md" = "# Database Design`r`n`r`nCanonical database design and ER relationships will live here.`r`n"
    "docs\API.md" = "# API Contract`r`n`r`nREST API conventions and endpoint catalogue will live here.`r`n"
    "docs\SECURITY.md" = "# Security`r`n`r`nAuthentication, authorization, payment, privacy, and security requirements will live here.`r`n"
}

foreach ($item in $docs.GetEnumerator()) {
    Ensure-File (Join-Path $Root $item.Key) $item.Value
}

# ---------------------------------------------------------------------------
# ENVIRONMENT EXAMPLE
# ---------------------------------------------------------------------------

$envExample = @"
NODE_ENV=development
PORT=3000

# PostgreSQL
DATABASE_HOST=
DATABASE_PORT=5432
DATABASE_NAME=
DATABASE_USER=
DATABASE_PASSWORD=
DATABASE_SSL=false

# JWT
JWT_ACCESS_SECRET=
JWT_REFRESH_SECRET=
JWT_ACCESS_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=30d

# AWS
AWS_REGION=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_S3_BUCKET=
AWS_CLOUDFRONT_URL=
AWS_SMS_ORIGINATION_ID=
AWS_SES_FROM_EMAIL=

# Stripe
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=

# Firebase
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=

# Google OAuth
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# Apple Sign In
APPLE_CLIENT_ID=
APPLE_TEAM_ID=
APPLE_KEY_ID=
APPLE_PRIVATE_KEY=

# Application
APP_BASE_URL=
FRONTEND_BASE_URL=
"@

Ensure-File (Join-Path $Root ".env.example") $envExample

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "Scaffold complete."
Write-Host "Existing project files were preserved."
Write-Host "Next: review the generated tree before importing new modules into app.module.ts."
Write-Host "------------------------------------------------------------"
