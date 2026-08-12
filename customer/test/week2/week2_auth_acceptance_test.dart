import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_favola/week2/week2_account_screens.dart';
import 'package:la_favola/week2/week2_app.dart';
import 'package:la_favola/week2/week2_auth_screens.dart';
import 'support/deterministic_week2_gateway.dart';
import 'package:la_favola/week2/week2_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('registration reaches sign-in-ready success', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      Week2App(gateway: DeterministicWeek2Gateway(latency: Duration.zero)),
    );
    await tester.pumpAndSettle();
    final createAccountLink = find.text('Crea un account');
    await tester.tap(createAccountLink);
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Cliente Test');
    await tester.enterText(fields.at(1), 'cliente.test@example.invalid');
    await tester.enterText(fields.at(2), 'password-demo');
    await tester.enterText(fields.at(3), 'password-demo');
    await tester.tap(find.text('Crea un account').last);
    await tester.pumpAndSettle();

    expect(find.text('Registrazione completata'), findsOneWidget);
    expect(find.text("Vai all'accesso"), findsOneWidget);

    await tester.tap(find.text("Vai all'accesso"));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sign-in-email')), findsOneWidget);
  });

  testWidgets('login opens the redesigned horizontal menu and item detail', (
    tester,
  ) async {
    await _signIn(tester);

    expect(find.byKey(const Key('customer-menu-category-row')), findsOneWidget);
    expect(find.byKey(const Key('open-custom-pizza')), findsOneWidget);
    expect(find.textContaining('[CATEGORIA SINTETICA]'), findsOneWidget);
    expect(find.textContaining('[VOCE MENU SINTETICA]'), findsOneWidget);

    final item = find.textContaining('[VOCE MENU SINTETICA]').last;
    await tester.drag(
      find.byKey(const Key('customer-menu-scroll')),
      const Offset(0, -560),
    );
    await tester.pumpAndSettle();
    await tester.tap(item);
    await tester.pumpAndSettle();

    expect(find.text('Preparato con cura'), findsOneWidget);
    expect(find.text('Informazioni alimentari e allergeni'), findsOneWidget);
    expect(find.byKey(const Key('open-live-checkout')), findsOneWidget);
  });

  testWidgets('profile screen loads owned verified identity', (tester) async {
    await _signIn(tester);
    await tester.tap(find.text('Profilo').last);
    await tester.pumpAndSettle();

    expect(find.text('Dati del profilo'), findsOneWidget);
    expect(find.text('Email verificata'), findsOneWidget);
    expect(find.text('Indirizzi salvati'), findsOneWidget);
  });

  testWidgets('dependency failure is durable and retry succeeds', (
    tester,
  ) async {
    final gateway = DeterministicWeek2Gateway(
      latency: Duration.zero,
      faults: {Week2Operation.login: Week2FailureKind.dependencyUnavailable},
    );
    await tester.pumpWidget(Week2App(gateway: gateway));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('sign-in-email')),
      'cliente.test@example.invalid',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('sign-in-password')),
        matching: find.byType(TextField),
      ),
      'password-demo',
    );
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Impossibile completare l’operazione'), findsOneWidget);
    expect(find.text('Riprova'), findsOneWidget);

    gateway.setFault(Week2Operation.login, null);
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();
    expect(find.text('Menu'), findsWidgets);
  });

  testWidgets('verification and recovery/reset expose durable results', (
    tester,
  ) async {
    final gateway = DeterministicWeek2Gateway(latency: Duration.zero);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: VerificationScreen(gateway: gateway))),
    );
    await tester.enterText(
      find.byType(TextField).first,
      'verify-demo-token-0001',
    );
    await tester.tap(find.text('Verifica'));
    await tester.pumpAndSettle();
    expect(find.text('Email verificata. Ora puoi accedere.'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: RecoveryScreen(gateway: gateway)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'cliente.test@example.invalid',
    );
    await tester.tap(find.text('Richiedi recupero'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Il risultato resta neutrale'), findsWidgets);
  });

  testWidgets('configured provider intent waits for verified return', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: ProviderReturnScreen(
          gateway: DeterministicWeek2Gateway(latency: Duration.zero),
          provider: 'google',
          onSignedIn: (_) {},
        ),
      ),
    );
    await tester.tap(find.text('Continua'));
    await tester.pumpAndSettle();

    expect(find.text('In attesa del provider'), findsOneWidget);
  });

  testWidgets('addresses, security and privacy define empty/current states', (
    tester,
  ) async {
    final gateway = DeterministicWeek2Gateway(
      latency: Duration.zero,
      emptyAddresses: true,
    );
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AddressesScreen(gateway: gateway))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nessun indirizzo salvato'), findsOneWidget);
    expect(find.text('Aggiungi il primo indirizzo'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PreferencesSecurityScreen(gateway: gateway)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sessioni attive'), findsOneWidget);
    expect(find.text('Avvisi di sicurezza essenziali'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: PrivacyScreen(gateway: gateway))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nessuna richiesta'), findsOneWidget);
    expect(find.text('Avvia richiesta cancellazione'), findsOneWidget);
  });

  testWidgets('direct protected route is centrally denied without a session', (
    tester,
  ) async {
    await tester.pumpWidget(
      Week2App(gateway: DeterministicWeek2Gateway(latency: Duration.zero)),
    );
    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.byType(SignInScreen)),
    ).pushNamed(Week2Routes.addresses);
    await tester.pumpAndSettle();
    expect(find.text('Accedi'), findsWidgets);
    expect(
      find.text('Accedi per aprire questa destinazione protetta.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'protected session failure clears root state and returns to sign-in',
    (tester) async {
      final gateway = DeterministicWeek2Gateway(latency: Duration.zero);
      await tester.pumpWidget(Week2App(gateway: gateway));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('sign-in-email')),
        'cliente.test@example.invalid',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('sign-in-password')),
          matching: find.byType(TextField),
        ),
        'password-demo',
      );
      gateway.setFault(Week2Operation.getMenu, Week2FailureKind.sessionExpired);
      await tester.tap(find.byKey(const Key('sign-in-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Accedi'), findsWidgets);
      expect(find.text('Sessione scaduta. Accedi di nuovo.'), findsOneWidget);
    },
  );

  testWidgets('app exposes the approved it-IT locale', (tester) async {
    await tester.pumpWidget(
      Week2App(gateway: DeterministicWeek2Gateway(latency: Duration.zero)),
    );
    await tester.pumpAndSettle();
    expect(
      Localizations.localeOf(tester.element(find.byType(SignInScreen))),
      const Locale('it', 'IT'),
    );
  });

  testWidgets('English covers auth and every protected customer destination', (
    tester,
  ) async {
    await tester.pumpWidget(
      Week2App(gateway: DeterministicWeek2Gateway(latency: Duration.zero)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.language_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inglese'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('sign-in-email')),
      'cliente@example.test',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('sign-in-password')),
        matching: find.byType(TextField),
      ),
      'password-demo',
    );
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Profile details'), findsOneWidget);
    expect(find.text('Saved addresses'), findsOneWidget);
    await tester.tap(find.text('Saved addresses'));
    await tester.pumpAndSettle();
    expect(find.text('Add address'), findsWidgets);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Preferences').last);
    await tester.pumpAndSettle();
    expect(find.text('Security and preferences'), findsOneWidget);
    expect(find.text('Active sessions'), findsOneWidget);

    await tester.tap(find.text('Privacy').last);
    await tester.pumpAndSettle();
    expect(find.text('Reauthentication required'), findsOneWidget);
    expect(find.text('Request export'), findsOneWidget);
  });

  testWidgets(
    'registration focuses the first invalid field and annotates each field',
    (tester) async {
      final gateway = DeterministicWeek2Gateway(latency: Duration.zero);
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(
            gateway: gateway,
            onRegistrationCompleted: () {},
          ),
        ),
      );
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '');
      await tester.enterText(fields.at(1), 'non-valida');
      final submit = find.widgetWithText(ElevatedButton, 'Crea un account');
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pump();
      expect(
        find.text(
          'Il nome è obbligatorio, deve contenere al massimo 100 caratteri e non può includere caratteri di controllo.',
        ),
        findsWidgets,
      );
      expect(find.text('Inserisci un indirizzo email valido.'), findsWidgets);
      expect(
        tester.widget<TextField>(fields.at(0)).focusNode!.hasFocus,
        isTrue,
      );
    },
  );
}

Future<void> _signIn(WidgetTester tester) async {
  await tester.pumpWidget(
    Week2App(gateway: DeterministicWeek2Gateway(latency: Duration.zero)),
  );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('sign-in-email')),
    'cliente.test@example.invalid',
  );
  final passwordField = find.descendant(
    of: find.byKey(const Key('sign-in-password')),
    matching: find.byType(TextField),
  );
  await tester.enterText(passwordField, 'password-demo');
  await tester.tap(find.byKey(const Key('sign-in-submit')));
  await tester.pumpAndSettle();
}
