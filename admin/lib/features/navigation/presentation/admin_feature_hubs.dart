import 'package:flutter/material.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';
import 'package:la_favola_admin/features/catalogue/presentation/catalogue_inventory_page.dart';
import 'package:la_favola_admin/features/deliveries/presentation/delivery_dispatch_page.dart';
import 'package:la_favola_admin/features/orders/presentation/order_fulfilment_page.dart';
import 'package:la_favola_admin/features/offers/presentation/offers_management_page.dart';
import 'package:la_favola_admin/features/notifications/presentation/notifications_center_page.dart';
import 'package:la_favola_admin/features/restaurant/presentation/restaurant_settings_page.dart';
import 'package:la_favola_admin/features/access/presentation/role_permissions_page.dart';
import 'package:la_favola_admin/features/support/presentation/support_desk_page.dart';
import 'package:la_favola_admin/features/access/presentation/staff_management_page.dart';
import 'package:la_favola_admin/features/access/presentation/user_management_page.dart';
import 'package:la_favola_admin/features/catalogue/presentation/option_groups_page.dart';
import 'package:la_favola_admin/features/catalogue/presentation/pizza_builder_rules_page.dart';
import 'package:la_favola_admin/features/media/presentation/media_library_page.dart';
import 'package:la_favola_admin/shared/presentation/typed_resource_page.dart';

/// Authenticated feature entry points for the restaurant tablet.
///
/// All routes below are explicitly present in [AdminApiRoutes]. A feature never
/// falls back to a customer endpoint, and an unavailable server capability is
/// labelled as such instead of being represented by an inoperative control.
class OrdersWorkspacePage extends StatelessWidget {
  const OrdersWorkspacePage({super.key, required this.api});

  final AdminApiClient api;

  @override
  Widget build(BuildContext context) => OrderFulfilmentPage(api: api);
}

class DeliveryWorkspacePage extends StatelessWidget {
  const DeliveryWorkspacePage({super.key, required this.api});

  final AdminApiClient api;

  @override
  Widget build(BuildContext context) => DeliveryDispatchPage(api: api);
}

class SupportWorkspacePage extends StatelessWidget {
  const SupportWorkspacePage({super.key, required this.api});

  final AdminApiClient api;

  @override
  Widget build(BuildContext context) => SupportDeskPage(api: api);
}

class CatalogueWorkspacePage extends StatelessWidget {
  const CatalogueWorkspacePage({super.key, required this.api});

  final AdminApiClient api;

  @override
  Widget build(BuildContext context) => _FeatureLanding(
    title: 'Catalogo',
    subtitle: 'Gestisci menu, categorie, ingredienti, opzioni e FAQ.',
    cards: [
      _FeatureCard(
        title: 'Voci del menu',
        description: 'Crea, modifica o archivia i prodotti del ristorante.',
        icon: Icons.local_pizza_outlined,
        onOpen:
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CatalogueInventoryPage(api: api),
              ),
            ),
      ),
      _FeatureCard(
        title: 'Categorie',
        description: 'Organizza il menu e la relativa visibilità.',
        icon: Icons.category_outlined,
        onOpen:
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CatalogueInventoryPage(api: api),
              ),
            ),
      ),
      _FeatureCard(
        title: 'Ingredienti',
        description: 'Aggiorna disponibilità, allergeni e prezzi extra.',
        icon: Icons.eco_outlined,
        onOpen: () => _openCrud(context, api, _ingredientsResource),
      ),
      _FeatureCard(
        title: 'Gruppi di opzioni',
        description: 'Configura varianti, aggiunte e scelte del prodotto.',
        icon: Icons.tune_rounded,
        onOpen:
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder:
                    (_) => OptionGroupsPage(
                      api: api,
                      groupConfig: _optionGroupsResource,
                    ),
              ),
            ),
      ),
      _FeatureCard(
        title: 'FAQ pubbliche',
        description: 'Aggiorna le risposte pubblicate sul sito.',
        icon: Icons.quiz_outlined,
        onOpen: () => _openCrud(context, api, _faqResource),
      ),
      _FeatureCard(
        title: 'Compositore pizza',
        description: 'Configura impasto, salsa, formaggio e condimenti.',
        icon: Icons.design_services_outlined,
        onOpen:
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PizzaBuilderRulesPage(api: api),
              ),
            ),
      ),
      _FeatureCard(
        title: 'Media del catalogo',
        description: 'Carica e finalizza una risorsa tramite il ciclo media.',
        icon: Icons.image_outlined,
        onOpen:
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MediaLibraryPage()),
            ),
      ),
    ],
    footer: const _CapabilityNotice(
      icon: Icons.info_outline_rounded,
      message:
          'La libreria media mostra soltanto le risorse del ristorante attivo. '
          'Le credenziali S3 restano sul backend e non vengono mai incluse nel tablet.',
    ),
  );
}

class OffersWorkspacePage extends StatelessWidget {
  const OffersWorkspacePage({super.key, required this.api});

  final AdminApiClient api;

  @override
  Widget build(BuildContext context) => OffersManagementPage(api: api);
}

class TeamAccessWorkspacePage extends StatelessWidget {
  const TeamAccessWorkspacePage({super.key, required this.api});

  final AdminApiClient api;

  @override
  Widget build(BuildContext context) => _FeatureLanding(
    title: 'Team e accessi',
    subtitle:
        'Gestisci staff, account, ruoli e permessi con minimo privilegio.',
    cards: [
      _FeatureCard(
        title: 'Staff',
        description: 'Associa utenti al ristorante e aggiorna lo stato staff.',
        icon: Icons.badge_outlined,
        onOpen:
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => StaffManagementPage(api: api),
              ),
            ),
      ),
      _FeatureCard(
        title: 'Utenti',
        description: 'Crea, modifica e disattiva gli account autorizzati.',
        icon: Icons.people_outline_rounded,
        onOpen:
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => UserManagementPage(api: api),
              ),
            ),
      ),
      _FeatureCard(
        title: 'Ruoli',
        description: 'Definisci i ruoli disponibili per l’operatività.',
        icon: Icons.admin_panel_settings_outlined,
        onOpen: () => _openCrud(context, api, _rolesResource),
      ),
      _FeatureCard(
        title: 'Permessi',
        description: 'Configura permessi ed evita di rimuovere il tuo accesso.',
        icon: Icons.key_outlined,
        onOpen: () => _openCrud(context, api, _permissionsResource),
      ),
      _FeatureCard(
        title: 'Assegnazioni ruolo',
        description: 'Rivedi o modifica i permessi assegnati a un ruolo.',
        icon: Icons.rule_outlined,
        onOpen:
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RolePermissionsPage(api: api),
              ),
            ),
      ),
    ],
    footer: const _CapabilityNotice(
      icon: Icons.warning_amber_rounded,
      message:
          'Non rimuovere l’ultimo ruolo amministratore attivo. L’API resta la '
          'fonte autorevole e rifiuta operazioni non consentite.',
    ),
  );
}

class SettingsWorkspacePage extends StatelessWidget {
  const SettingsWorkspacePage({super.key, required this.api});

  final AdminApiClient api;

  @override
  Widget build(BuildContext context) => _FeatureLanding(
    title: 'Impostazioni',
    subtitle: 'Profilo del ristorante, orari e preferenze operative.',
    cards: [
      _FeatureCard(
        title: 'Profilo ristorante',
        description: 'Aggiorna recapiti, indirizzo, fiscalità e consegna.',
        icon: Icons.storefront_outlined,
        onOpen: () => _openRestaurantSettings(context, api),
      ),
      _FeatureCard(
        title: 'Orari di apertura',
        description: 'Imposta apertura, chiusura e giornate di chiusura.',
        icon: Icons.schedule_outlined,
        onOpen: () => _openRestaurantSettings(context, api),
      ),
      _FeatureCard(
        title: 'Preferenze notifiche',
        description: 'Leggi e aggiorna le preferenze dell’account corrente.',
        icon: Icons.notifications_active_outlined,
        onOpen:
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NotificationsCenterPage(api: api),
              ),
            ),
      ),
    ],
  );
}

class NotificationsWorkspacePage extends StatelessWidget {
  const NotificationsWorkspacePage({super.key, required this.api});

  final AdminApiClient api;

  @override
  Widget build(BuildContext context) => NotificationsCenterPage(api: api);
}

void _openCrud(
  BuildContext context,
  AdminApiClient api,
  TypedResourceConfig resource,
) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => TypedResourcePage(api: api, config: resource),
  ),
);

void _openRestaurantSettings(BuildContext context, AdminApiClient api) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => RestaurantSettingsPage(api: api)),
    );

class _FeatureLanding extends StatelessWidget {
  const _FeatureLanding({
    required this.title,
    required this.subtitle,
    required this.cards,
    this.footer,
  });

  final String title;
  final String subtitle;
  final List<_FeatureCard> cards;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns =
        width >= 1240
            ? 3
            : width >= 760
            ? 2
            : 1;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _PageHeading(title: title, subtitle: subtitle),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: columns,
            childAspectRatio: width >= 760 ? 1.85 : 1.55,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cards,
          ),
          if (footer != null) ...[const SizedBox(height: 20), footer!],
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onOpen,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF774E32), size: 30),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Icon(Icons.arrow_forward_rounded, semanticLabel: 'Apri'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
          fontFamily: 'Lora',
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      Text(subtitle),
    ],
  );
}

class _CapabilityNotice extends StatelessWidget {
  const _CapabilityNotice({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6F4E37)),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

const _ingredientsResource = TypedResourceConfig(
  title: 'Ingredienti',
  subtitle: 'Gestisci disponibilità, allergeni e sovrapprezzi del catalogo.',
  endpoint: AdminApiRoutes.ingredients,
  itemPath: AdminApiRoutes.ingredient,
  primaryField: 'name',
  restaurantScoped: true,
  fields: [
    AdminField('name', 'Nome', required: true),
    AdminField('slug', 'Slug', required: true),
    AdminField('description', 'Descrizione', type: AdminFieldType.multiline),
    AdminField(
      'extraPriceMinor',
      'Sovrapprezzo in centesimi',
      type: AdminFieldType.integer,
    ),
    AdminField('calories', 'Calorie', type: AdminFieldType.integer),
    AdminField(
      'containsAllergens',
      'Allergeni',
      type: AdminFieldType.stringList,
    ),
    AdminField('isVegetarian', 'Vegetariano', type: AdminFieldType.boolean),
    AdminField('isVegan', 'Vegano', type: AdminFieldType.boolean),
    AdminField('isGlutenFree', 'Senza glutine', type: AdminFieldType.boolean),
    AdminField('isSpicy', 'Piccante', type: AdminFieldType.boolean),
    AdminField(
      'isActive',
      'Disponibile',
      type: AdminFieldType.boolean,
      booleanDefault: true,
    ),
  ],
);

const _optionGroupsResource = TypedResourceConfig(
  title: 'Gruppi di opzioni',
  subtitle: 'Configura varianti e limiti di selezione per i prodotti.',
  endpoint: AdminApiRoutes.optionGroups,
  itemPath: AdminApiRoutes.optionGroup,
  primaryField: 'name',
  restaurantScoped: true,
  fields: [
    AdminField('name', 'Nome', required: true),
    AdminField('code', 'Codice', required: true),
    AdminField('optionType', 'Tipo opzione', required: true),
    AdminField('minSelect', 'Selezioni minime', type: AdminFieldType.integer),
    AdminField('maxSelect', 'Selezioni massime', type: AdminFieldType.integer),
    AdminField(
      'isActive',
      'Attivo',
      type: AdminFieldType.boolean,
      booleanDefault: true,
    ),
  ],
);

const _faqResource = TypedResourceConfig(
  title: 'FAQ',
  subtitle: 'Pubblica e ordina le domande frequenti mostrate ai clienti.',
  endpoint: AdminApiRoutes.faqs,
  itemPath: AdminApiRoutes.faq,
  primaryField: 'question',
  fields: [
    AdminField('question', 'Domanda', required: true),
    AdminField(
      'answer',
      'Risposta',
      type: AdminFieldType.multiline,
      required: true,
    ),
    AdminField('displayOrder', 'Ordine', type: AdminFieldType.integer),
    AdminField(
      'isActive',
      'Pubblicata',
      type: AdminFieldType.boolean,
      booleanDefault: true,
    ),
  ],
);

const _rolesResource = TypedResourceConfig(
  title: 'Ruoli',
  subtitle: 'Definisci ruoli amministrativi prima di assegnarne i permessi.',
  endpoint: AdminApiRoutes.roles,
  itemPath: AdminApiRoutes.role,
  primaryField: 'name',
  fields: [
    AdminField('name', 'Nome ruolo', required: true),
    AdminField('description', 'Descrizione', type: AdminFieldType.multiline),
  ],
);

const _permissionsResource = TypedResourceConfig(
  title: 'Permessi',
  subtitle: 'Gestisci le capacità granulari usate dal controllo accessi.',
  endpoint: AdminApiRoutes.permissions,
  itemPath: AdminApiRoutes.permission,
  primaryField: 'resource',
  fields: [
    AdminField('resource', 'Risorsa', required: true),
    AdminField('action', 'Azione', required: true),
    AdminField('description', 'Descrizione', type: AdminFieldType.multiline),
  ],
);
