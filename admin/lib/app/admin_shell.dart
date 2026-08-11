import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:la_favola_admin/app/providers.dart';
import 'package:la_favola_admin/core/theme/app_theme.dart';

const adminDestinations = <({String path, String label, IconData icon})>[
  (path: '/dashboard', label: 'Panoramica', icon: Icons.dashboard_outlined),
  (path: '/pos', label: 'Cassa', icon: Icons.point_of_sale_outlined),
  (path: '/orders', label: 'Ordini', icon: Icons.receipt_long_outlined),
  (
    path: '/deliveries',
    label: 'Consegne',
    icon: Icons.delivery_dining_outlined,
  ),
  (path: '/refunds', label: 'Rimborsi', icon: Icons.currency_exchange_outlined),
  (path: '/support', label: 'Supporto', icon: Icons.forum_outlined),
  (path: '/catalogue', label: 'Catalogo', icon: Icons.restaurant_menu_outlined),
  (path: '/offers', label: 'Offerte', icon: Icons.local_offer_outlined),
  (path: '/media', label: 'Media', icon: Icons.perm_media_outlined),
  (
    path: '/people',
    label: 'Team e accessi',
    icon: Icons.manage_accounts_outlined,
  ),
  (path: '/restaurant', label: 'Ristorante', icon: Icons.storefront_outlined),
  (path: '/reports', label: 'Report', icon: Icons.analytics_outlined),
  (
    path: '/notifications',
    label: 'Notifiche',
    icon: Icons.notifications_outlined,
  ),
  (path: '/audit', label: 'Attività', icon: Icons.history_outlined),
];

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final index = adminDestinations.indexWhere(
      (item) => path.startsWith(item.path),
    );
    final selected = index < 0 ? 0 : index;
    final compact = MediaQuery.sizeOf(context).width < 900;
    final navigation = _Navigation(
      selected: selected,
      compact: compact,
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
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: ref
                .watch(connectivityProvider)
                .when(
                  data:
                      (online) => Chip(
                        avatar: Icon(
                          online
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_off_outlined,
                          size: 18,
                        ),
                        label: Text(online ? 'API v1' : 'Offline'),
                      ),
                  loading:
                      () => const Chip(
                        avatar: SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        label: Text('Rete'),
                      ),
                  error:
                      (_, __) => const Chip(
                        avatar: Icon(Icons.cloud_off_outlined, size: 18),
                        label: Text('Rete non disponibile'),
                      ),
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
            ColoredBox(
              color: BrandColors.espresso,
              child: SafeArea(child: navigation),
            ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Navigation extends StatelessWidget {
  const _Navigation({
    required this.selected,
    required this.compact,
    required this.onSelect,
  });

  final int selected;
  final bool compact;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return ColoredBox(
        color: BrandColors.espresso,
        child: ListView(
          key: const Key('admin-navigation-list'),
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
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
                  Text(
                    'La Favola Admin',
                    style: TextStyle(
                      color: BrandColors.paper,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            for (var index = 0; index < adminDestinations.length; index++)
              ListTile(
                key: Key('admin-destination-${adminDestinations[index].label}'),
                minTileHeight: 48,
                selected: index == selected,
                selectedTileColor: BrandColors.sand,
                selectedColor: BrandColors.espresso,
                textColor: BrandColors.paper,
                iconColor: BrandColors.paper,
                leading: Icon(adminDestinations[index].icon),
                title: Text(adminDestinations[index].label),
                onTap: () => onSelect(index),
              ),
          ],
        ),
      );
    }
    return NavigationRail(
      backgroundColor: BrandColors.espresso,
      indicatorColor: BrandColors.sand,
      selectedIconTheme: const IconThemeData(color: BrandColors.espresso),
      unselectedIconTheme: const IconThemeData(color: BrandColors.paper),
      selectedLabelTextStyle: const TextStyle(color: BrandColors.paper),
      unselectedLabelTextStyle: const TextStyle(color: BrandColors.paper),
      extended: MediaQuery.sizeOf(context).width >= 1180,
      minExtendedWidth: 220,
      labelType:
          MediaQuery.sizeOf(context).width >= 1180
              ? NavigationRailLabelType.none
              : NavigationRailLabelType.all,
      leading: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: CircleAvatar(
          backgroundColor: BrandColors.paper,
          child: Icon(Icons.local_pizza_rounded, color: BrandColors.terracotta),
        ),
      ),
      destinations: [
        for (final item in adminDestinations)
          NavigationRailDestination(
            icon: Icon(item.icon),
            label: Text(item.label),
          ),
      ],
      selectedIndex: selected,
      onDestinationSelected: onSelect,
    );
  }
}
