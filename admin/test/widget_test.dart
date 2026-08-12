import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:la_favola_admin/app/admin_shell.dart';
import 'package:la_favola_admin/app/providers.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';
import 'package:la_favola_admin/core/session/secure_session_store.dart';
import 'package:la_favola_admin/features/auth/presentation/sign_in_page.dart';

void main() {
  testWidgets(
    'admin email and password fields accept emulator keyboard input',
    (tester) async {
      final controller = SessionController(
        AdminApiClient(baseUrl: 'http://test.invalid/api/v1/'),
        _MemorySessionStore(),
        restoreOnCreate: false,
        initialState: const SessionState(status: SessionStatus.signedOut),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith((_) => controller),
          ],
          child: const MaterialApp(home: SignInPage()),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('admin-email-field')),
        'admin@lafavolabrescia.it',
      );
      await tester.enterText(
        find.byKey(const Key('admin-password-field')),
        'valid-password',
      );

      expect(find.text('admin@lafavolabrescia.it'), findsOneWidget);
      final password = tester.widget<TextFormField>(
        find.byKey(const Key('admin-password-field')),
      );
      expect(password.controller?.text, 'valid-password');
    },
  );

  testWidgets('tablet shell exposes every administrative workspace', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        ShellRoute(
          builder: (_, __, child) => AdminShell(child: child),
          routes: [
            GoRoute(path: '/dashboard', builder: (_, __) => const SizedBox()),
          ],
        ),
      ],
    );
    final controller = SessionController(
      AdminApiClient(baseUrl: 'http://test.invalid/api/v1/'),
      _MemorySessionStore(),
      restoreOnCreate: false,
      initialState: const SessionState(
        status: SessionStatus.authenticated,
        session: AdminSession(
          accessToken: 'a',
          refreshToken: 'r',
          roleName: 'admin',
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith((_) => controller),
          connectivityProvider.overrideWith((_) => Stream.value(true)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final selectedTile = tester.widget<ListTile>(
      find.byKey(const Key('admin-destination-Panoramica')),
    );
    expect(selectedTile.selected, isTrue);
    expect(selectedTile.selectedTileColor, isNotNull);
    expect(selectedTile.selectedColor, isNotNull);
    expect(selectedTile.textColor, isNotNull);

    for (final destination in adminDestinations) {
      final tile = find.byKey(Key('admin-destination-${destination.label}'));
      await tester.scrollUntilVisible(
        tile,
        64,
        scrollable:
            find
                .descendant(
                  of: find.byKey(const Key('admin-navigation-list')),
                  matching: find.byType(Scrollable),
                )
                .first,
      );
      expect(tile, findsOneWidget);
    }
  });
}

class _MemorySessionStore extends SecureSessionStore {
  String? token;
  @override
  Future<void> clear() async => token = null;
  @override
  Future<String?> readRefreshToken() async => token;
  @override
  Future<void> saveRefreshToken(String refreshToken) async =>
      token = refreshToken;
}
