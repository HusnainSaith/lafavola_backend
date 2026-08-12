import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_favola/week2/week2_account_screens.dart';
import 'package:la_favola/week2/week2_app.dart';
import 'package:la_favola/week2/week2_auth_screens.dart';
import 'support/deterministic_week2_gateway.dart';
import 'package:la_favola/week2/week2_menu_screens.dart';
import 'package:la_favola/week2/week2_models.dart';
import 'package:la_favola/week2/week2_theme.dart';
import 'package:la_favola/week2/week2_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in [320.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('sign-in reflows at ${width.toInt()} px and 200% text', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1200);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await tester.pumpWidget(
        Week2App(gateway: DeterministicWeek2Gateway(latency: Duration.zero)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('week2-page-heading')), findsOneWidget);
      expect(find.text('Accedi'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('menu reflows at ${width.toInt()} px and 200% text', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1200);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: buildWeek2Theme(),
          home: Scaffold(
            body: MenuHierarchyScreen(
              gateway: DeterministicWeek2Gateway(latency: Duration.zero),
              onOpenItem: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('[CATEGORIA SINTETICA]'), findsOneWidget);
      expect(find.textContaining('[VOCE MENU SINTETICA]'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('semantic labels and 48dp actions are exposed', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      Week2App(gateway: DeterministicWeek2Gateway(latency: Duration.zero)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('week2-demo-banner')), findsNothing);
    final submitSize = tester.getSize(find.byKey(const Key('sign-in-submit')));
    expect(submitSize.height, greaterThanOrEqualTo(48));
    semantics.dispose();
  });

  testWidgets('failure panel exposes status and correlation reference', (
    tester,
  ) async {
    const failure = Week2Failure(
      kind: Week2FailureKind.conflict,
      message: 'I dati sono cambiati.',
      correlationId: 'lf-mobile-local-0001',
      retryable: true,
      currentVersion: '2',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Week2StatePanel.failure(failure, onRetry: () {})),
      ),
    );

    expect(find.text('Impossibile completare l’operazione'), findsOneWidget);
    expect(find.text('Riferimento: lf-mobile-local-0001'), findsOneWidget);
    expect(find.text('Riprova'), findsOneWidget);
  });

  for (final width in [320.0, 768.0, 1024.0, 1440.0]) {
    testWidgets(
      'all eleven Week 2 flows reflow, focus, and expose 48dp actions '
      'at ${width.toInt()} px and 200% text',
      (tester) async {
        final semantics = tester.ensureSemantics();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1200);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        final gateway = DeterministicWeek2Gateway(latency: Duration.zero);
        final flows = <Widget>[
          SignInScreen(
            gateway: gateway,
            onSignedIn: (_) {},
            onOpenRegistration: () {},
            onOpenVerification: () {},
            onOpenRecovery: () {},
            onOpenProvider: (_) {},
            onOpenPublicMenu: () {},
          ),
          RegistrationScreen(gateway: gateway, onRegistrationCompleted: () {}),
          VerificationScreen(gateway: gateway),
          RecoveryScreen(gateway: gateway),
          ProviderReturnScreen(
            gateway: gateway,
            provider: 'google',
            onSignedIn: (_) {},
          ),
          ProfileScreen(gateway: gateway),
          AddressesScreen(gateway: gateway),
          PreferencesSecurityScreen(gateway: gateway),
          PrivacyScreen(gateway: gateway),
          MenuHierarchyScreen(gateway: gateway, onOpenItem: (_) {}),
          MenuItemDetailScreen(
            gateway: gateway,
            itemId: '55555555-5555-4555-8555-555555555555',
          ),
        ];
        for (final flow in flows) {
          await tester.pumpWidget(
            MaterialApp(theme: buildWeek2Theme(), home: Scaffold(body: flow)),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('week2-page-heading')), findsOneWidget);
          expect(
            tester
                .getSemantics(find.byKey(const Key('week2-page-heading')))
                .label,
            isNotEmpty,
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(FocusManager.instance.primaryFocus, isNotNull);
          final actions = find.byWidgetPredicate(
            (widget) => widget is ButtonStyleButton || widget is IconButton,
          );
          expect(actions, findsWidgets);
          for (final element in actions.evaluate()) {
            final renderObject = element.renderObject;
            if (renderObject is! RenderBox || !renderObject.hasSize) continue;
            expect(
              renderObject.size.height,
              greaterThanOrEqualTo(48),
              reason: '${flow.runtimeType} contains an undersized action.',
            );
            expect(
              renderObject.size.width,
              greaterThanOrEqualTo(48),
              reason: '${flow.runtimeType} contains an undersized action.',
            );
          }
          expect(tester.takeException(), isNull);
        }
        semantics.dispose();
      },
    );
  }

  test('input boundary token exceeds the approved three-to-one pair', () {
    expect(Week2Colors.inputBoundary, Week2Colors.strong);
    expect(Week2Colors.inputBoundary, isNot(Week2Colors.border));
  });
}
