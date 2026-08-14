import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:la_favola/design_system/la_favola_theme.dart';
import 'package:la_favola/design_system/tokens.dart';
import 'package:la_favola/features/menu/customer_menu_experience.dart';
import 'package:la_favola/l10n/app_strings.dart';
import 'package:la_favola/week2/week2_account_screens.dart';
import 'package:la_favola/week2/week2_auth_screens.dart';
import 'package:la_favola/week2/week2_http_gateway.dart';
import 'package:la_favola/week2/week2_models.dart';
import 'package:la_favola/week2/week2_widgets.dart';
import 'package:la_favola/week2/week2_splash_screen.dart';
import 'package:la_favola_generated_api/la_favola_api.dart';
import 'package:la_favola/l10n/generated/app_localizations.dart';
import 'package:la_favola/l10n/locale_scope.dart';

abstract final class Week2Routes {
  static const splash = '/';
  static const signIn = '/signin';
  static const publicMenu = '/menu';
  static const register = '/register';
  static const verify = '/verify';
  static const recovery = '/recovery';
  static const provider = '/provider';
  static const home = '/home';
  static const item = '/menu/item';
  static const addresses = '/profile/addresses';
}

final class CustomerItemRoute {
  const CustomerItemRoute(this.itemId, {this.openBuilder = false});

  final String itemId;
  final bool openBuilder;
}

final class _SessionAwareGateway implements Week2Gateway {
  _SessionAwareGateway({
    required this.delegate,
    required this.onInvalidated,
    required this.onRotated,
  });

  final Week2Gateway delegate;
  final ValueChanged<Week2Failure> onInvalidated;
  final ValueChanged<CustomerSession> onRotated;

  @override
  Set<String> get configuredFederatedProviders =>
      delegate.configuredFederatedProviders;

  @override
  bool get supportsCustomerReauthentication =>
      delegate.supportsCustomerReauthentication;

  Future<T> _protected<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Week2Failure catch (failure) {
      if (failure.kind == Week2FailureKind.sessionExpired ||
          failure.kind == Week2FailureKind.sessionRevoked ||
          failure.kind == Week2FailureKind.sessionReuseDetected ||
          failure.kind == Week2FailureKind.unauthenticated) {
        onInvalidated(failure);
      }
      rethrow;
    }
  }

  @override
  Map<String, JsonOperationContract> get generatedOperations =>
      delegate.generatedOperations;
  @override
  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) => delegate.register(
    displayName: displayName,
    email: email,
    password: password,
  );
  @override
  Future<CustomerSession> login({
    required String email,
    required String password,
  }) => delegate.login(email: email, password: password);
  @override
  Future<void> verifyEmail(String token) => delegate.verifyEmail(token);
  @override
  Future<void> resendVerification(String email) =>
      delegate.resendVerification(email);
  @override
  Future<void> requestPasswordRecovery(String email) =>
      delegate.requestPasswordRecovery(email);
  @override
  Future<void> resetPassword({
    required String code,
    required String password,
  }) => delegate.resetPassword(code: code, password: password);
  @override
  Future<ProviderIntent> startFederated(String provider) =>
      delegate.startFederated(provider);
  @override
  Future<CustomerSession> completeFederated({
    required ProviderIntent intent,
    required String result,
  }) => delegate.completeFederated(intent: intent, result: result);
  @override
  Future<String> reauthenticate(String password) =>
      _protected(() => delegate.reauthenticate(password));
  @override
  Future<CustomerSession> refreshSession(String refreshToken) =>
      _protected(() async {
        final session = await delegate.refreshSession(refreshToken);
        onRotated(session);
        return session;
      });
  @override
  Future<void> logout() => delegate.logout();
  @override
  Future<CustomerProfile> getProfile() => _protected(delegate.getProfile);
  @override
  Future<CustomerProfile> updateProfile({
    required String displayName,
    required String? phone,
    required String expectedVersion,
  }) => _protected(
    () => delegate.updateProfile(
      displayName: displayName,
      phone: phone,
      expectedVersion: expectedVersion,
    ),
  );
  @override
  Future<List<CustomerAddress>> getAddresses() =>
      _protected(delegate.getAddresses);
  @override
  Future<CustomerAddress> createAddress(CustomerAddress input) =>
      _protected(() => delegate.createAddress(input));
  @override
  Future<CustomerAddress> updateAddress(CustomerAddress input) =>
      _protected(() => delegate.updateAddress(input));
  @override
  Future<CustomerAddress> archiveAddress(CustomerAddress input) =>
      _protected(() => delegate.archiveAddress(input));
  @override
  Future<CustomerPreferences> getPreferences() =>
      _protected(delegate.getPreferences);
  @override
  Future<CustomerPreferences> updatePreferences({
    required bool marketingEmailOptIn,
    required String expectedVersion,
  }) => _protected(
    () => delegate.updatePreferences(
      marketingEmailOptIn: marketingEmailOptIn,
      expectedVersion: expectedVersion,
    ),
  );
  @override
  Future<List<SecuritySession>> getSecuritySessions() =>
      _protected(delegate.getSecuritySessions);
  @override
  Future<void> revokeSecuritySession(String id) =>
      _protected(() => delegate.revokeSecuritySession(id));
  @override
  Future<PrivacyRequest> requestPrivacyExport(String reauthenticationProof) =>
      _protected(() => delegate.requestPrivacyExport(reauthenticationProof));
  @override
  Future<PrivacyRequest> requestPrivacyDeletion(String reauthenticationProof) =>
      _protected(() => delegate.requestPrivacyDeletion(reauthenticationProof));
  @override
  Future<PrivacyRequest> getPrivacyRequest(String id) =>
      _protected(() => delegate.getPrivacyRequest(id));
  @override
  Future<MenuSnapshot> getMenu() => _protected(delegate.getMenu);
  @override
  Future<MenuItemSummary> getMenuItem(String id) =>
      _protected(() => delegate.getMenuItem(id));

  @override
  Future<FulfillmentAvailability> getFulfillmentAvailability({
    required FulfillmentType type,
    String? date,
    String? menuItemId,
  }) => delegate.getFulfillmentAvailability(
    type: type,
    date: date,
    menuItemId: menuItemId,
  );

  @override
  Future<Quote> createQuote({
    required String locationId,
    required List<QuoteLineInput> lines,
    required FulfillmentContext fulfillmentContext,
    String? couponCode,
    bool loyaltyIntent = false,
  }) => _protected(
    () => delegate.createQuote(
      locationId: locationId,
      lines: lines,
      fulfillmentContext: fulfillmentContext,
      couponCode: couponCode,
      loyaltyIntent: loyaltyIntent,
    ),
  );

  @override
  Future<Quote> getQuote(String quoteId) =>
      _protected(() => delegate.getQuote(quoteId));

  @override
  Future<Quote> applyPromotion(String quoteId, String code) =>
      _protected(() => delegate.applyPromotion(quoteId, code));
  @override
  Future<OrderReceipt> submitOrder(
    String quoteId,
    PaymentMethod paymentMethod,
  ) => _protected(() => delegate.submitOrder(quoteId, paymentMethod));

  @override
  Future<List<OrderReceipt>> getOrders() => _protected(delegate.getOrders);

  @override
  Future<OrderReceipt> getOrder(String orderId) =>
      _protected(() => delegate.getOrder(orderId));

  @override
  Future<CustomerOrderReceiptDocument> getOrderReceipt(String orderId) =>
      _protected(() => delegate.getOrderReceipt(orderId));

  @override
  Stream<OrderRealtimeEvent> watchOrderEvents(String orderId) =>
      delegate.watchOrderEvents(orderId);

  @override
  Future<OrderReceipt> requestOrderCancellation({
    required String orderId,
    required String expectedVersion,
    required String reason,
  }) => _protected(
    () => delegate.requestOrderCancellation(
      orderId: orderId,
      expectedVersion: expectedVersion,
      reason: reason,
    ),
  );
}

final class Week2App extends StatefulWidget {
  Week2App({super.key, Week2Gateway? gateway})
    : gateway = gateway ?? HttpWeek2Gateway.fromEnvironment();

  final Week2Gateway gateway;

  @override
  State<Week2App> createState() => _Week2AppState();
}

final class _Week2AppState extends State<Week2App> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  CustomerSession? _session;
  Locale _locale = const Locale('it', 'IT');
  String? _sessionNotice;
  late final Week2Gateway _protectedGateway;

  static const _protectedRoutes = {Week2Routes.home, Week2Routes.addresses};

  @override
  void initState() {
    super.initState();
    _protectedGateway = _SessionAwareGateway(
      delegate: widget.gateway,
      onInvalidated: _sessionInvalidated,
      onRotated: _sessionRotated,
    );
  }

  void _sessionRotated(CustomerSession session) {
    if (!mounted) return;
    setState(() => _session = session);
  }

  void _sessionInvalidated(Week2Failure failure) {
    if (!mounted) return;
    setState(() {
      _session = null;
      _sessionNotice = failure.message;
    });
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      Week2Routes.signIn,
      (route) => false,
    );
  }

  Future<void> _signedIn(CustomerSession session) async {
    setState(() {
      _session = session;
      _sessionNotice = null;
    });
    // The native app is deliberately customer-only. Staff access is provided
    // by the protected React operations portal, never by an email heuristic.
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      Week2Routes.home,
      (route) => false,
    );
  }

  Future<void> _signedOut({String? notice}) async {
    try {
      await widget.gateway.logout();
    } on Week2Failure {
      // Logout is idempotent; local protected state is still cleared.
    }
    if (!mounted) return;
    setState(() {
      _session = null;
      _sessionNotice = notice;
    });
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      Week2Routes.signIn,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      // This is the production customer design.  The old prototype is not a
      // release route and no debug-only content is used here.
      theme: buildLaFavolaTheme(),
      builder: (context, child) {
        return LocaleScope(
          locale: _locale,
          onChanged: (locale) => setState(() => _locale = locale),
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      onGenerateRoute: (settings) {
        final guarded =
            _protectedRoutes.contains(settings.name) && _session == null;
        final routeName = guarded ? Week2Routes.signIn : settings.name;
        if (guarded) {
          _sessionNotice = appStrings(context).signInProtectedRoute;
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder:
              (context) => switch (routeName) {
                Week2Routes.register => RegistrationScreen(
                  gateway: widget.gateway,
                  onRegistrationCompleted:
                      () => Navigator.pushReplacementNamed(
                        context,
                        Week2Routes.signIn,
                      ),
                ),
                Week2Routes.verify => VerificationScreen(
                  gateway: widget.gateway,
                ),
                Week2Routes.recovery => RecoveryScreen(gateway: widget.gateway),
                Week2Routes.provider => ProviderReturnScreen(
                  gateway: widget.gateway,
                  provider: (settings.arguments as String?) ?? 'google',
                  onSignedIn: _signedIn,
                ),
                Week2Routes.publicMenu => Scaffold(
                  appBar: AppBar(
                    title: Text(AppLocalizations.of(context).publicMenu),
                    actions: [
                      const LanguageMenuButton(),
                      TextButton.icon(
                        onPressed:
                            () => Navigator.pushNamed(
                              context,
                              Week2Routes.signIn,
                            ),
                        icon: const Icon(Icons.login),
                        label: Text(AppLocalizations.of(context).signIn),
                      ),
                    ],
                  ),
                  body: CustomerMenuScreen(
                    gateway: widget.gateway,
                    onOpenItem:
                        (id) => Navigator.pushNamed(
                          context,
                          Week2Routes.item,
                          arguments: id,
                        ),
                    onOpenBuilder:
                        (itemId) => Navigator.pushNamed(
                          context,
                          Week2Routes.item,
                          arguments: CustomerItemRoute(
                            itemId,
                            openBuilder: true,
                          ),
                        ),
                  ),
                ),
                Week2Routes.home => CustomerWeek2Shell(
                  gateway: _protectedGateway,
                  session: _session,
                  onSignedOut: _signedOut,
                  onOpenItem:
                      (id) => Navigator.pushNamed(
                        context,
                        Week2Routes.item,
                        arguments: id,
                      ),
                  onOpenBuilder:
                      (itemId) => Navigator.pushNamed(
                        context,
                        Week2Routes.item,
                        arguments: CustomerItemRoute(itemId, openBuilder: true),
                      ),
                  onOpenAddresses:
                      () => Navigator.pushNamed(context, Week2Routes.addresses),
                ),
                Week2Routes.item => switch (settings.arguments) {
                  final CustomerItemRoute route => CustomerMenuDetailScreen(
                    gateway: widget.gateway,
                    itemId: route.itemId,
                    openBuilder: route.openBuilder,
                  ),
                  final String itemId => CustomerMenuDetailScreen(
                    gateway: widget.gateway,
                    itemId: itemId,
                  ),
                  _ => Scaffold(
                    body: Week2Page(
                      title: AppLocalizations.of(context).contentNotFound,
                      child: Week2StatePanel(
                        title: AppLocalizations.of(context).contentNotFound,
                        message: AppLocalizations.of(context).invalidMenuItem,
                        kind: Week2FailureKind.notFound,
                      ),
                    ),
                  ),
                },
                Week2Routes.addresses => AddressesScreen(
                  gateway: _protectedGateway,
                ),
                Week2Routes.splash => Week2SplashScreen(
                  onNext:
                      () => Navigator.pushReplacementNamed(
                        context,
                        _session != null
                            ? Week2Routes.home
                            : Week2Routes.signIn,
                      ),
                ),
                Week2Routes.signIn => SignInScreen(
                  gateway: widget.gateway,
                  onSignedIn: _signedIn,
                  onOpenRegistration:
                      () => Navigator.pushNamed(context, Week2Routes.register),
                  onOpenVerification:
                      () => Navigator.pushNamed(context, Week2Routes.verify),
                  onOpenRecovery:
                      () => Navigator.pushNamed(context, Week2Routes.recovery),
                  onOpenProvider:
                      (provider) => Navigator.pushNamed(
                        context,
                        Week2Routes.provider,
                        arguments: provider,
                      ),
                  onOpenPublicMenu:
                      () =>
                          Navigator.pushNamed(context, Week2Routes.publicMenu),
                  sessionNotice: _sessionNotice,
                ),
                _ => SignInScreen(
                  gateway: widget.gateway,
                  onSignedIn: _signedIn,
                  onOpenRegistration:
                      () => Navigator.pushNamed(context, Week2Routes.register),
                  onOpenVerification:
                      () => Navigator.pushNamed(context, Week2Routes.verify),
                  onOpenRecovery:
                      () => Navigator.pushNamed(context, Week2Routes.recovery),
                  onOpenProvider:
                      (provider) => Navigator.pushNamed(
                        context,
                        Week2Routes.provider,
                        arguments: provider,
                      ),
                  onOpenPublicMenu:
                      () =>
                          Navigator.pushNamed(context, Week2Routes.publicMenu),
                  sessionNotice: _sessionNotice,
                ),
              },
        );
      },
    );
  }
}

final class CustomerWeek2Shell extends StatefulWidget {
  const CustomerWeek2Shell({
    required this.gateway,
    required this.session,
    required this.onSignedOut,
    required this.onOpenItem,
    required this.onOpenBuilder,
    required this.onOpenAddresses,
    super.key,
  });

  final Week2Gateway gateway;
  final CustomerSession? session;
  final Future<void> Function({String? notice}) onSignedOut;
  final ValueChanged<String> onOpenItem;
  final ValueChanged<String> onOpenBuilder;
  final VoidCallback onOpenAddresses;

  @override
  State<CustomerWeek2Shell> createState() => _CustomerWeek2ShellState();
}

final class _CustomerWeek2ShellState extends State<CustomerWeek2Shell> {
  int _selected = 0;

  List<Widget> get _pages => [
    CustomerMenuScreen(
      gateway: widget.gateway,
      onOpenItem: widget.onOpenItem,
      onOpenBuilder: widget.onOpenBuilder,
    ),
    CustomerOrdersScreen(gateway: widget.gateway),
    _ProfileDestination(
      gateway: widget.gateway,
      onOpenAddresses: widget.onOpenAddresses,
    ),
    PreferencesSecurityScreen(gateway: widget.gateway, session: widget.session),
    PrivacyScreen(gateway: widget.gateway),
  ];

  List<NavigationDestination> _destinations(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return [
      NavigationDestination(
        icon: Icon(Icons.restaurant_menu_outlined),
        selectedIcon: Icon(Icons.restaurant_menu),
        label: strings.menu,
      ),
      NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: strings.orders,
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: strings.profile,
      ),
      NavigationDestination(
        icon: Icon(Icons.security_outlined),
        selectedIcon: Icon(Icons.security),
        label: strings.preferences,
      ),
      NavigationDestination(
        icon: Icon(Icons.privacy_tip_outlined),
        selectedIcon: Icon(Icons.privacy_tip),
        label: strings.privacy,
      ),
    ];
  }

  List<NavigationRailDestination> _railDestinations(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return [
      NavigationRailDestination(
        icon: Icon(Icons.restaurant_menu_outlined),
        selectedIcon: Icon(Icons.restaurant_menu),
        label: Text(strings.menu),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: Text(strings.orders),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: Text(strings.profile),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.security_outlined),
        selectedIcon: Icon(Icons.security),
        label: Text(strings.preferences),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.privacy_tip_outlined),
        selectedIcon: Icon(Icons.privacy_tip),
        label: Text(strings.privacy),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (widget.session == null) {
      return Scaffold(
        body: Week2Page(
          title: strings.sessionRequired,
          child: Week2StatePanel(
            title: strings.signInToContinue,
            message: strings.protectedRouteNotice,
            kind: Week2FailureKind.sessionExpired,
            onRetry: () => widget.onSignedOut(notice: strings.signInAgain),
          ),
        ),
      );
    }
    final mode = week2LayoutMode(MediaQuery.sizeOf(context).width);
    final page = IndexedStack(index: _selected, children: _pages);
    return Scaffold(
      appBar: AppBar(
        title: const Text('La Favola'),
        actions: [
          const LanguageMenuButton(),
          IconButton(
            tooltip: strings.signOut,
            onPressed: () => widget.onSignedOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body:
          mode == Week2LayoutMode.compact
              ? page
              : Row(
                children: [
                  NavigationRail(
                    extended: mode == Week2LayoutMode.expanded,
                    selectedIndex: _selected,
                    onDestinationSelected:
                        (value) => setState(() => _selected = value),
                    labelType:
                        mode == Week2LayoutMode.medium
                            ? NavigationRailLabelType.all
                            : NavigationRailLabelType.none,
                    destinations: _railDestinations(context),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: page),
                ],
              ),
      bottomNavigationBar:
          mode == Week2LayoutMode.compact
              ? NavigationBar(
                selectedIndex: _selected,
                onDestinationSelected:
                    (value) => setState(() => _selected = value),
                destinations: _destinations(context),
              )
              : null,
    );
  }
}

final class _ProfileDestination extends StatelessWidget {
  const _ProfileDestination({
    required this.gateway,
    required this.onOpenAddresses,
  });

  final Week2Gateway gateway;
  final VoidCallback onOpenAddresses;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      children: [
        Material(
          color: LaFavolaTokens.informationContainer,
          child: InkWell(
            onTap: onOpenAddresses,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined),
                  const SizedBox(width: 12),
                  Expanded(child: Text(strings.savedAddresses)),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: ProfileScreen(gateway: gateway)),
      ],
    );
  }
}
