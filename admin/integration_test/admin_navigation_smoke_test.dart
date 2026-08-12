import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:la_favola_admin/app/admin_shell.dart';
import 'package:la_favola_admin/app/app.dart';
import 'package:la_favola_admin/app/providers.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';
import 'package:la_favola_admin/core/session/secure_session_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every admin workspace mounts on an Android tablet', (
    tester,
  ) async {
    final session = SessionController(
      AdminApiClient(baseUrl: 'http://127.0.0.1:9/api/v1/'),
      _MemorySessionStore(),
      restoreOnCreate: false,
      initialState: const SessionState(
        status: SessionStatus.authenticated,
        session: AdminSession(
          accessToken: 'navigation-smoke-access',
          refreshToken: 'navigation-smoke-refresh',
          roleName: 'admin',
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith((_) => session),
          connectivityProvider.overrideWith((_) => Stream.value(true)),
        ],
        child: const LaFavolaAdminApp(),
      ),
    );
    await _pumpFor(tester);

    for (final destination in adminDestinations) {
      final shell = find.byType(AdminShell);
      expect(shell, findsOneWidget, reason: destination.path);
      GoRouter.of(tester.element(shell)).go(destination.path);
      await _pumpFor(tester);
      expect(
        find.text(destination.label),
        findsWidgets,
        reason: destination.path,
      );
      expect(tester.takeException(), isNull, reason: destination.path);
    }
  });
}

Future<void> _pumpFor(WidgetTester tester) async {
  for (var index = 0; index < 6; index += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _MemorySessionStore extends SecureSessionStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readRefreshToken() async => 'navigation-smoke-refresh';

  @override
  Future<void> saveRefreshToken(String refreshToken) async {}
}
