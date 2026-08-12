import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:la_favola/core/session/customer_session_controller.dart';
import 'package:la_favola/design_system/la_favola_theme.dart';
import 'package:la_favola/features/menu/customer_menu_experience.dart';
import 'package:la_favola/features/modernization/data/customer_feature_repositories.dart';
import 'package:la_favola/features/modernization/presentation/customer_feature_pages.dart';
import 'package:la_favola/l10n/generated/app_localizations.dart';
import 'package:la_favola/l10n/locale_scope.dart';
import 'package:la_favola/week2/week2_account_screens.dart';
import 'package:la_favola/week2/week2_auth_screens.dart';
import 'package:la_favola/week2/week2_models.dart';
import 'package:la_favola/week2/week2_splash_screen.dart';

final customerLocaleProvider = StateProvider<Locale>(
  (ref) => const Locale('it', 'IT'),
);

const _publicPaths = <String>{
  '/',
  '/signin',
  '/register',
  '/verify',
  '/recovery',
  '/menu',
  '/faq',
};

bool isPublicCustomerPath(String path) =>
    _publicPaths.contains(path) ||
    path.startsWith('/menu/item/') ||
    path.startsWith('/provider/');

String? customerGuardRedirect({
  required CustomerSessionState session,
  required Uri location,
}) {
  final path = location.path;
  if (session.phase == SessionPhase.restoring) return path == '/' ? null : '/';
  if (!session.isAuthenticated && !isPublicCustomerPath(path)) {
    return Uri(
      path: '/signin',
      queryParameters: {'from': location.toString()},
    ).toString();
  }
  if (session.isAuthenticated && (path == '/' || path == '/signin')) {
    return _safeTarget(location.queryParameters['from']) ?? '/home';
  }
  if (!session.isAuthenticated && path == '/') return '/signin';
  return null;
}

final customerRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(customerSessionProvider);
  final gateway = ref.watch(customerGatewayProvider);
  return GoRouter(
    initialLocation: '/',
    redirect:
        (context, state) =>
            customerGuardRedirect(session: session, location: state.uri),
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Week2SplashScreen(onNext: _noop),
      ),
      GoRoute(
        path: '/signin',
        builder:
            (context, state) => SignInScreen(
              gateway: gateway,
              sessionNotice: session.notice,
              onSignedIn: (value) async {
                await ref
                    .read(customerSessionProvider.notifier)
                    .establish(value);
                if (context.mounted) {
                  context.go(
                    _safeTarget(state.uri.queryParameters['from']) ?? '/home',
                  );
                }
              },
              onOpenRegistration: () => context.push('/register'),
              onOpenVerification: () => context.push('/verify'),
              onOpenRecovery: () => context.push('/recovery'),
              onOpenProvider:
                  (provider) => context.push(
                    Uri(
                      path: '/provider/$provider',
                      queryParameters: {
                        if (state.uri.queryParameters['from'] != null)
                          'from': state.uri.queryParameters['from'],
                      },
                    ).toString(),
                  ),
              onOpenPublicMenu: () => context.push('/menu'),
            ),
      ),
      GoRoute(
        path: '/register',
        builder:
            (context, _) => RegistrationScreen(
              gateway: gateway,
              onRegistrationCompleted: () => context.go('/signin'),
            ),
      ),
      GoRoute(
        path: '/verify',
        builder: (_, __) => VerificationScreen(gateway: gateway),
      ),
      GoRoute(
        path: '/recovery',
        builder: (_, __) => RecoveryScreen(gateway: gateway),
      ),
      GoRoute(
        path: '/provider/:provider',
        builder:
            (context, state) => ProviderReturnScreen(
              gateway: gateway,
              provider: state.pathParameters['provider']!,
              onSignedIn: (value) async {
                await ref
                    .read(customerSessionProvider.notifier)
                    .establish(value);
                if (context.mounted) {
                  context.go(
                    _safeTarget(state.uri.queryParameters['from']) ?? '/home',
                  );
                }
              },
            ),
      ),
      GoRoute(path: '/home', builder: (_, __) => const CustomerHomePage()),
      GoRoute(
        path: '/menu',
        builder:
            (context, _) => Scaffold(
              appBar: AppBar(
                title: Text(AppLocalizations.of(context).publicMenu),
                actions: [
                  IconButton(
                    tooltip:
                        Localizations.localeOf(context).languageCode == 'it'
                            ? 'Carrello'
                            : 'Cart',
                    onPressed: () => context.push('/cart'),
                    icon: const Icon(Icons.shopping_bag_outlined),
                  ),
                ],
              ),
              body: CustomerMenuScreen(
                gateway: gateway,
                onOpenItem: (id) => context.push('/menu/item/$id'),
                onOpenBuilder:
                    (id) => context.push('/menu/item/$id?builder=true'),
              ),
            ),
      ),
      GoRoute(
        path: '/menu/item/:id',
        builder:
            (context, state) => CustomerMenuDetailScreen(
              gateway: gateway,
              itemId: state.pathParameters['id']!,
              openBuilder: state.uri.queryParameters['builder'] == 'true',
              onSaveFavorite: (item) async {
                if (!ref.read(customerSessionProvider).isAuthenticated) {
                  await context.push(
                    Uri(
                      path: '/signin',
                      queryParameters: {
                        'from': '/menu/item/${state.pathParameters['id']!}',
                      },
                    ).toString(),
                  );
                  return false;
                }
                await ref
                    .read(favoritesRepositoryProvider)
                    .saveFavorite(menuItemId: item.id, label: item.name);
                ref.invalidate(favoritesProvider);
                return true;
              },
            ),
      ),
      GoRoute(path: '/cart', builder: (_, __) => const CartPage()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutRoutePage()),
      GoRoute(
        path: '/orders',
        builder: (context, _) => _OrdersRoutePage(gateway: gateway),
      ),
      GoRoute(
        path: '/orders/:id',
        builder:
            (_, state) =>
                OrderDetailRoutePage(orderId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/favorites', builder: (_, __) => const FavoritesPage()),
      GoRoute(path: '/rewards', builder: (_, __) => const RewardsPage()),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(path: '/support', builder: (_, __) => const SupportPage()),
      GoRoute(
        path: '/support/:id',
        builder:
            (_, state) => SupportConversationPage(
              ticketId: state.pathParameters['id']!,
              subject:
                  state.extra is String ? state.extra! as String : 'Support',
            ),
      ),
      GoRoute(path: '/faq', builder: (_, __) => const FaqPage()),
      GoRoute(path: '/account', builder: (_, __) => const AccountHubPage()),
      GoRoute(
        path: '/account/profile',
        builder: (_, __) => ProfileScreen(gateway: gateway),
      ),
      GoRoute(
        path: '/account/addresses',
        builder: (_, __) => AddressesScreen(gateway: gateway),
      ),
      GoRoute(
        path: '/account/preferences',
        builder:
            (_, __) => PreferencesSecurityScreen(
              gateway: gateway,
              session: session.session,
            ),
      ),
      GoRoute(
        path: '/account/privacy',
        builder: (_, __) => PrivacyScreen(gateway: gateway),
      ),
      GoRoute(
        path: '/payment-methods',
        builder: (_, __) => const PaymentMethodsPage(),
      ),
    ],
    errorBuilder: (context, _) {
      final copy = CustomerCopy.of(context);
      return CustomerRouteFrame(
        title: copy.text('Pagina non trovata', 'Page not found'),
        child: Center(
          child: FilledButton(
            onPressed: () => context.go('/home'),
            child: Text(copy.text('Torna alla home', 'Back home')),
          ),
        ),
      );
    },
  );
});

String? _safeTarget(String? target) {
  if (target == null ||
      !target.startsWith('/') ||
      target.startsWith('//') ||
      target.startsWith('/signin')) {
    return null;
  }
  return target;
}

void _noop() {}

final class CustomerApp extends ConsumerWidget {
  const CustomerApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(customerRouterProvider);
    final locale = ref.watch(customerLocaleProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: buildLaFavolaTheme(),
      builder:
          (context, child) => LocaleScope(
            locale: locale,
            onChanged:
                (value) =>
                    ref.read(customerLocaleProvider.notifier).state = value,
            child: FocusTraversalGroup(
              policy: ReadingOrderTraversalPolicy(),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
    );
  }
}

final class _OrdersRoutePage extends StatefulWidget {
  const _OrdersRoutePage({required this.gateway});
  final Week2Gateway gateway;
  @override
  State<_OrdersRoutePage> createState() => _OrdersRoutePageState();
}

final class _OrdersRoutePageState extends State<_OrdersRoutePage> {
  late Future<List<OrderReceipt>> orders;
  @override
  void initState() {
    super.initState();
    orders = widget.gateway.getOrders();
  }

  @override
  Widget build(BuildContext context) {
    final copy = CustomerCopy.of(context);
    return CustomerRouteFrame(
      title: copy.text('I tuoi ordini', 'Your orders'),
      child: FutureBuilder<List<OrderReceipt>>(
        future: orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed:
                    () => setState(() => orders = widget.gateway.getOrders()),
                icon: const Icon(Icons.refresh),
                label: Text(copy.text('Riprova', 'Retry')),
              ),
            );
          }
          final values = snapshot.data ?? const [];
          if (values.isEmpty) {
            return Center(
              child: Text(copy.text('Nessun ordine.', 'No orders yet.')),
            );
          }
          return RefreshIndicator(
            onRefresh:
                () async => setState(() => orders = widget.gateway.getOrders()),
            child: ListView.builder(
              itemCount: values.length,
              itemBuilder: (_, index) {
                final order = values[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(order.reference),
                    subtitle: Text(order.status),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/orders/${order.orderId}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
