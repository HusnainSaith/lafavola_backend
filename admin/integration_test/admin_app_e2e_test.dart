import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:la_favola_admin/app/admin_shell.dart';
import 'package:la_favola_admin/app/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = String.fromEnvironment('E2E_ADMIN_EMAIL');
  const password = String.fromEnvironment('E2E_ADMIN_PASSWORD');
  const posProductName = String.fromEnvironment('E2E_POS_PRODUCT_NAME');

  testWidgets('administrator signs in and opens every workspace', (
    tester,
  ) async {
    expect(email, isNotEmpty, reason: 'E2E_ADMIN_EMAIL is required');
    expect(password, isNotEmpty, reason: 'E2E_ADMIN_PASSWORD is required');

    await tester.pumpWidget(const ProviderScope(child: LaFavolaAdminApp()));
    await _waitFor(tester, find.byKey(const Key('admin-email-field')));

    await tester.enterText(find.byKey(const Key('admin-email-field')), email);
    await tester.enterText(
      find.byKey(const Key('admin-password-field')),
      password,
    );
    await tester.tap(find.byKey(const Key('admin-sign-in-button')));
    await _waitFor(tester, find.text('Operazioni di oggi'));

    for (final destination in adminDestinations) {
      GoRouter.of(tester.element(find.byType(AdminShell))).go(destination.path);
      await _pumpFor(tester);
      await _waitFor(tester, find.text(destination.label));
    }

    if (posProductName.isNotEmpty) {
      GoRouter.of(tester.element(find.byType(AdminShell))).go('/pos');
      await _pumpFor(tester);
      await _waitFor(tester, find.text('Nuovo ordine'));
      await _waitFor(tester, find.text(posProductName));

      await tester.tap(find.text(posProductName).first);
      await _waitFor(tester, find.text('Aggiungi al carrello'));
      await tester.tap(find.text('Aggiungi al carrello'));
      await _pumpFor(tester);

      final checkout = find.byKey(const Key('pos-checkout'));
      await tester.dragUntilVisible(
        checkout,
        find.byKey(const Key('pos-cart-list')),
        const Offset(0, -280),
      );
      await tester.tap(checkout);
      await _waitFor(
        tester,
        find.text('Ricevuta pronta'),
        timeout: const Duration(seconds: 30),
      );
      expect(find.text('COPIA DI CORTESIA - NON FISCALE'), findsOneWidget);
      await tester.tap(find.text('Chiudi'));
      await _pumpFor(tester);
    }
  });
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(finder, findsWidgets);
  await _pumpFor(tester);
}

Future<void> _pumpFor(
  WidgetTester tester, {
  Duration duration = const Duration(milliseconds: 600),
}) async {
  final deadline = DateTime.now().add(duration);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
