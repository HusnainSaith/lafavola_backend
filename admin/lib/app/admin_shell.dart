import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:la_favola_admin/app/providers.dart';
import 'package:la_favola_admin/core/theme/app_theme.dart';

typedef AdminDestination =
    ({String path, String label, IconData icon, String section});

const adminDestinations = <AdminDestination>[
  (
    path: '/dashboard',
    label: 'Panoramica',
    icon: Icons.dashboard_outlined,
    section: 'Oggi',
  ),
  (
    path: '/pos',
    label: 'Cassa e tavoli',
    icon: Icons.point_of_sale_outlined,
    section: 'Oggi',
  ),
  (
    path: '/orders',
    label: 'Ordini',
    icon: Icons.receipt_long_outlined,
    section: 'Oggi',
  ),
  (
    path: '/deliveries',
    label: 'Consegne',
    icon: Icons.route_outlined,
    section: 'Vendite',
  ),
  (
    path: '/drivers',
    label: 'Driver',
    icon: Icons.delivery_dining_outlined,
    section: 'Vendite',
  ),
  (
    path: '/refunds',
    label: 'Rimborsi',
    icon: Icons.currency_exchange_outlined,
    section: 'Vendite',
  ),
  (
    path: '/customers',
    label: 'Clienti',
    icon: Icons.groups_outlined,
    section: 'Vendite',
  ),
  (
    path: '/catalogue/menu',
    label: 'Prodotti',
    icon: Icons.local_pizza_outlined,
    section: 'Catalogo',
  ),
  (
    path: '/catalogue/categories',
    label: 'Categorie',
    icon: Icons.category_outlined,
    section: 'Catalogo',
  ),
  (
    path: '/catalogue/ingredients',
    label: 'Ingredienti',
    icon: Icons.eco_outlined,
    section: 'Catalogo',
  ),
  (
    path: '/catalogue/options',
    label: 'Opzioni',
    icon: Icons.tune_outlined,
    section: 'Catalogo',
  ),
  (
    path: '/catalogue/pizza-builder',
    label: 'Compositore pizza',
    icon: Icons.design_services_outlined,
    section: 'Catalogo',
  ),
  (
    path: '/media',
    label: 'Media',
    icon: Icons.perm_media_outlined,
    section: 'Catalogo',
  ),
  (
    path: '/offers',
    label: 'Promozioni e coupon',
    icon: Icons.local_offer_outlined,
    section: 'Marketing',
  ),
  (path: '/faq', label: 'FAQ', icon: Icons.quiz_outlined, section: 'Marketing'),
  (
    path: '/notifications',
    label: 'Notifiche',
    icon: Icons.notifications_outlined,
    section: 'Marketing',
  ),
  (
    path: '/support',
    label: 'Supporto',
    icon: Icons.forum_outlined,
    section: 'Persone',
  ),
  (
    path: '/staff',
    label: 'Staff',
    icon: Icons.badge_outlined,
    section: 'Persone',
  ),
  (
    path: '/users',
    label: 'Utenti',
    icon: Icons.manage_accounts_outlined,
    section: 'Persone',
  ),
  (
    path: '/access/roles',
    label: 'Ruoli',
    icon: Icons.admin_panel_settings_outlined,
    section: 'Persone',
  ),
  (
    path: '/access/permissions',
    label: 'Permessi',
    icon: Icons.key_outlined,
    section: 'Persone',
  ),
  (
    path: '/access/assignments',
    label: 'Matrice accessi',
    icon: Icons.rule_outlined,
    section: 'Persone',
  ),
  (
    path: '/restaurant',
    label: 'Ristorante e orari',
    icon: Icons.storefront_outlined,
    section: 'Controllo',
  ),
  (
    path: '/reports',
    label: 'Report',
    icon: Icons.analytics_outlined,
    section: 'Controllo',
  ),
  (
    path: '/audit',
    label: 'Attività',
    icon: Icons.history_outlined,
    section: 'Controllo',
  ),
];

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final index = adminDestinations.indexWhere(
      (item) => path == item.path || path.startsWith('${item.path}/'),
    );
    final selected = index < 0 ? 0 : index;
    final compact = MediaQuery.sizeOf(context).width < 1100;
    final navigation = _AdminNavigation(
      selected: selected,
      onSelect: (value) {
        if (compact) Navigator.of(context).maybePop();
        context.go(adminDestinations[value].path);
      },
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(adminDestinations[selected].label),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ref
                .watch(connectivityProvider)
                .when(
                  data:
                      (online) => Chip(
                        backgroundColor: BrandColors.paper,
                        avatar: Icon(
                          online
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_off_outlined,
                          size: 18,
                          color:
                              online
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                        ),
                        label: Text(
                          online ? 'API v1' : 'Offline',
                          style: const TextStyle(color: BrandColors.ink),
                        ),
                      ),
                  loading: () => const Chip(label: Text('Rete')),
                  error:
                      (_, __) =>
                          const Chip(label: Text('Rete non disponibile')),
                ),
          ),
          IconButton(
            tooltip: 'Esci',
            onPressed:
                () => ref.read(sessionControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: compact ? Drawer(child: SafeArea(child: navigation)) : null,
      body: Row(
        children: [
          if (!compact)
            SizedBox(width: 286, child: SafeArea(child: navigation)),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AdminNavigation extends StatelessWidget {
  const _AdminNavigation({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: BrandColors.espresso,
    child: ListView(
      key: const Key('admin-navigation-list'),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 0, 8, 18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: BrandColors.paper,
                child: Icon(
                  Icons.local_pizza_rounded,
                  color: BrandColors.terracotta,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'La Favola Admin',
                  style: TextStyle(
                    color: BrandColors.paper,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (var index = 0; index < adminDestinations.length; index++) ...[
          if (index == 0 ||
              adminDestinations[index - 1].section !=
                  adminDestinations[index].section)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
              child: Text(
                adminDestinations[index].section.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFFFE0CC),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ListTile(
            key: Key('admin-destination-${adminDestinations[index].label}'),
            minTileHeight: 48,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            selected: index == selected,
            selectedTileColor: BrandColors.paper,
            selectedColor: BrandColors.espresso,
            textColor: BrandColors.paper,
            iconColor: BrandColors.paper,
            leading: Icon(adminDestinations[index].icon),
            title: Text(
              adminDestinations[index].label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () => onSelect(index),
          ),
        ],
      ],
    ),
  );
}
