import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateMenuCatalogAndPizzaBuilder1700000000005 implements MigrationInterface {
  name = 'CreateMenuCatalogAndPizzaBuilder1700000000005';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
CREATE TABLE menu_categories (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
        name varchar(120) NOT NULL,
        slug varchar(140) NOT NULL,
        description text,
        image_asset_id uuid REFERENCES media_assets(id) ON DELETE SET NULL,
        display_order integer NOT NULL DEFAULT 0,
        is_active boolean NOT NULL DEFAULT true,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_menu_category_slug UNIQUE (restaurant_id, slug)
      );

      CREATE TABLE ingredient_categories (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
        name varchar(120) NOT NULL,
        slug varchar(140) NOT NULL,
        display_order integer NOT NULL DEFAULT 0,
        is_active boolean NOT NULL DEFAULT true,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_ingredient_category_slug UNIQUE (restaurant_id, slug)
      );

      CREATE TABLE ingredients (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
        category_id uuid REFERENCES ingredient_categories(id) ON DELETE SET NULL,
        name varchar(140) NOT NULL,
        slug varchar(160) NOT NULL,
        description text,
        image_asset_id uuid REFERENCES media_assets(id) ON DELETE SET NULL,
        extra_price_minor integer NOT NULL DEFAULT 0 CHECK (extra_price_minor >= 0),
        calories integer CHECK (calories IS NULL OR calories >= 0),
        is_vegetarian boolean NOT NULL DEFAULT false,
        is_vegan boolean NOT NULL DEFAULT false,
        is_gluten_free boolean NOT NULL DEFAULT false,
        is_spicy boolean NOT NULL DEFAULT false,
        contains_allergens text[] NOT NULL DEFAULT ARRAY[]::text[],
        is_active boolean NOT NULL DEFAULT true,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_ingredient_slug UNIQUE (restaurant_id, slug)
      );

      CREATE TABLE menu_items (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
        category_id uuid REFERENCES menu_categories(id) ON DELETE SET NULL,
        name varchar(180) NOT NULL,
        slug varchar(200) NOT NULL,
        description text,
        image_asset_id uuid REFERENCES media_assets(id) ON DELETE SET NULL,
        item_type varchar(30) NOT NULL DEFAULT 'standard'
          CHECK (item_type IN ('standard','modifiable','build_your_own','side','drink','other')),
        calories integer CHECK (calories IS NULL OR calories >= 0),
        preparation_minutes integer NOT NULL DEFAULT 15 CHECK (preparation_minutes >= 0),
        is_vegetarian boolean NOT NULL DEFAULT false,
        is_vegan boolean NOT NULL DEFAULT false,
        is_gluten_free boolean NOT NULL DEFAULT false,
        is_spicy boolean NOT NULL DEFAULT false,
        is_popular boolean NOT NULL DEFAULT false,
        popularity_score numeric(12,4) NOT NULL DEFAULT 0,
        is_active boolean NOT NULL DEFAULT true,
        available_from timestamptz,
        available_until timestamptz,
        archived_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_menu_item_slug UNIQUE (restaurant_id, slug)
      );

      CREATE TABLE menu_item_sizes (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        menu_item_id uuid NOT NULL REFERENCES menu_items(id) ON DELETE CASCADE,
        size_code varchar(30) NOT NULL CHECK (size_code IN ('small','medium','large','single')),
        display_name varchar(80) NOT NULL,
        base_price_minor integer NOT NULL CHECK (base_price_minor >= 0),
        calories integer CHECK (calories IS NULL OR calories >= 0),
        display_order integer NOT NULL DEFAULT 0,
        is_active boolean NOT NULL DEFAULT true,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_menu_item_size UNIQUE (menu_item_id, size_code)
      );

      CREATE TABLE menu_item_ingredients (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        menu_item_id uuid NOT NULL REFERENCES menu_items(id) ON DELETE CASCADE,
        ingredient_id uuid NOT NULL REFERENCES ingredients(id) ON DELETE RESTRICT,
        is_default boolean NOT NULL DEFAULT true,
        is_removable boolean NOT NULL DEFAULT true,
        default_quantity numeric(8,2) NOT NULL DEFAULT 1 CHECK (default_quantity > 0),
        display_order integer NOT NULL DEFAULT 0,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_menu_item_ingredient UNIQUE (menu_item_id, ingredient_id)
      );

      CREATE TABLE option_groups (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
        name varchar(140) NOT NULL,
        code varchar(100) NOT NULL,
        option_type varchar(30) NOT NULL
          CHECK (option_type IN ('dough','sauce','cheese','topping','extra','removal','generic')),
        min_select integer NOT NULL DEFAULT 0 CHECK (min_select >= 0),
        max_select integer CHECK (max_select IS NULL OR max_select >= min_select),
        is_required boolean NOT NULL DEFAULT false,
        allow_quantity boolean NOT NULL DEFAULT false,
        display_order integer NOT NULL DEFAULT 0,
        is_active boolean NOT NULL DEFAULT true,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_option_group_code UNIQUE (restaurant_id, code)
      );

      CREATE TABLE option_choices (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        option_group_id uuid NOT NULL REFERENCES option_groups(id) ON DELETE CASCADE,
        ingredient_id uuid REFERENCES ingredients(id) ON DELETE SET NULL,
        name varchar(140) NOT NULL,
        code varchar(120) NOT NULL,
        price_adjustment_minor integer NOT NULL DEFAULT 0,
        calories_adjustment integer NOT NULL DEFAULT 0,
        is_default boolean NOT NULL DEFAULT false,
        display_order integer NOT NULL DEFAULT 0,
        is_active boolean NOT NULL DEFAULT true,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_option_choice_code UNIQUE (option_group_id, code)
      );

      CREATE TABLE menu_item_option_groups (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        menu_item_id uuid NOT NULL REFERENCES menu_items(id) ON DELETE CASCADE,
        option_group_id uuid NOT NULL REFERENCES option_groups(id) ON DELETE CASCADE,
        min_select_override integer CHECK (min_select_override IS NULL OR min_select_override >= 0),
        max_select_override integer CHECK (max_select_override IS NULL OR max_select_override >= 0),
        display_order integer NOT NULL DEFAULT 0,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_menu_item_option_group UNIQUE (menu_item_id, option_group_id)
      );

      CREATE TABLE option_incompatibilities (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        first_choice_id uuid NOT NULL REFERENCES option_choices(id) ON DELETE CASCADE,
        second_choice_id uuid NOT NULL REFERENCES option_choices(id) ON DELETE CASCADE,
        reason varchar(255),
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT chk_distinct_incompatible_choices CHECK (first_choice_id <> second_choice_id),
        CONSTRAINT uq_option_incompatibility UNIQUE (first_choice_id, second_choice_id)
      );

      CREATE TABLE pizza_builder_rules (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        restaurant_id uuid NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
        menu_item_id uuid REFERENCES menu_items(id) ON DELETE CASCADE,
        name varchar(160) NOT NULL,
        size_group_id uuid REFERENCES option_groups(id) ON DELETE SET NULL,
        dough_group_id uuid REFERENCES option_groups(id) ON DELETE SET NULL,
        sauce_group_id uuid REFERENCES option_groups(id) ON DELETE SET NULL,
        cheese_group_id uuid REFERENCES option_groups(id) ON DELETE SET NULL,
        toppings_group_id uuid REFERENCES option_groups(id) ON DELETE SET NULL,
        max_total_toppings integer CHECK (max_total_toppings IS NULL OR max_total_toppings >= 0),
        free_topping_count integer NOT NULL DEFAULT 0 CHECK (free_topping_count >= 0),
        rule_config jsonb NOT NULL DEFAULT '{}'::jsonb,
        is_active boolean NOT NULL DEFAULT true,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX idx_menu_items_search_name
        ON menu_items USING gin (name gin_trgm_ops);

      CREATE INDEX idx_menu_items_filters
        ON menu_items (restaurant_id, category_id, is_active, is_vegetarian, is_vegan, is_gluten_free, is_spicy);

      CREATE INDEX idx_ingredients_search_name
        ON ingredients USING gin (name gin_trgm_ops);

      CREATE TRIGGER trg_menu_categories_updated_at
      BEFORE UPDATE ON menu_categories FOR EACH ROW EXECUTE FUNCTION set_updated_at();
      CREATE TRIGGER trg_ingredient_categories_updated_at
      BEFORE UPDATE ON ingredient_categories FOR EACH ROW EXECUTE FUNCTION set_updated_at();
      CREATE TRIGGER trg_ingredients_updated_at
      BEFORE UPDATE ON ingredients FOR EACH ROW EXECUTE FUNCTION set_updated_at();
      CREATE TRIGGER trg_menu_items_updated_at
      BEFORE UPDATE ON menu_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();
      CREATE TRIGGER trg_menu_item_sizes_updated_at
      BEFORE UPDATE ON menu_item_sizes FOR EACH ROW EXECUTE FUNCTION set_updated_at();
      CREATE TRIGGER trg_option_groups_updated_at
      BEFORE UPDATE ON option_groups FOR EACH ROW EXECUTE FUNCTION set_updated_at();
      CREATE TRIGGER trg_option_choices_updated_at
      BEFORE UPDATE ON option_choices FOR EACH ROW EXECUTE FUNCTION set_updated_at();
      CREATE TRIGGER trg_pizza_builder_rules_updated_at
      BEFORE UPDATE ON pizza_builder_rules FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
DROP TABLE IF EXISTS pizza_builder_rules;
      DROP TABLE IF EXISTS option_incompatibilities;
      DROP TABLE IF EXISTS menu_item_option_groups;
      DROP TABLE IF EXISTS option_choices;
      DROP TABLE IF EXISTS option_groups;
      DROP TABLE IF EXISTS menu_item_ingredients;
      DROP TABLE IF EXISTS menu_item_sizes;
      DROP TABLE IF EXISTS menu_items;
      DROP TABLE IF EXISTS ingredients;
      DROP TABLE IF EXISTS ingredient_categories;
      DROP TABLE IF EXISTS menu_categories;
    `);
  }
}
