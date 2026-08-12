import 'package:flutter_test/flutter_test.dart';
import 'support/deterministic_week2_gateway.dart';
import 'package:la_favola/week2/week2_models.dart';

void main() {
  group('DeterministicWeek2Gateway generated-contract parity', () {
    late DeterministicWeek2Gateway gateway;

    setUp(() {
      gateway = DeterministicWeek2Gateway(latency: Duration.zero);
    });

    test('exposes the complete frozen public/customer operation registry', () {
      expect(gateway.generatedOperations, hasLength(35));
      expect(
        gateway.generatedOperations.keys,
        containsAll([
          'customerRegister',
          'customerLogin',
          'customerReauthenticate',
          'customerPatchProfile',
          'publicGetMenuCategories',
          'publicGetMenuItem',
        ]),
      );
    });

    test('registration, verification, login and recovery validate', () async {
      await gateway.register(
        displayName: 'Cliente Demo',
        email: 'cliente.demo@example.invalid',
        password: 'password-demo',
      );
      await gateway.verifyEmail('verify-demo-token');
      await gateway.resendVerification('cliente.demo@example.invalid');
      await gateway.requestPasswordRecovery('cliente.demo@example.invalid');
      await gateway.resetPassword(
        token: 'reset-demo-token',
        password: 'password-demo-2',
      );
      final session = await gateway.login(
        email: 'cliente.demo@example.invalid',
        password: 'password-demo',
      );
      expect(session.sessionId, isNotEmpty);
      final refreshed = await gateway.refreshSession(session.refreshToken);
      expect(refreshed.accessToken, isNotEmpty);
      await gateway.logout();
    });

    test('provider ports stay deterministic and non-live', () async {
      final google = await gateway.startFederated('google');
      final apple = await gateway.startFederated('apple');

      expect(google.live, isFalse);
      expect(apple.live, isFalse);
      expect(google.provider, 'google');
      expect(apple.provider, 'apple');

      final session = await gateway.completeFederated(
        intent: google,
        result: 'success',
      );
      expect(session.refreshToken, isNotEmpty);
    });

    test('profile update is versioned and contract-valid', () async {
      final profile = await gateway.getProfile();
      final updated = await gateway.updateProfile(
        displayName: 'Cliente Demo Aggiornato',
        phone: '+393331234567',
        expectedVersion: profile.version,
      );

      expect(updated.version, '2');
      expect(updated.displayName, 'Cliente Demo Aggiornato');
      expect(updated.email, 'cliente.demo@example.invalid');
    });

    test('address create, update, list and archive validate', () async {
      final emptyGateway = DeterministicWeek2Gateway(
        latency: Duration.zero,
        emptyAddresses: true,
      );
      const input = CustomerAddress(
        id: '99999999-9999-4999-8999-999999999999',
        version: '1',
        label: 'Casa demo',
        recipientName: 'Cliente Demo',
        addressLine: 'Via sintetica 2',
        city: 'Brescia',
        province: 'BS',
        postalCode: '25100',
        countryCode: 'IT',
        deliveryNotes: null,
        isDefault: false,
        archivedAt: null,
      );

      final created = await emptyGateway.createAddress(input);
      expect(await emptyGateway.getAddresses(), hasLength(1));
      final updated = await emptyGateway.updateAddress(
        created.copyWith(label: 'Casa demo aggiornata'),
      );
      expect(updated.version, '2');
      await emptyGateway.archiveAddress(updated);
      expect(await emptyGateway.getAddresses(), isEmpty);
    });

    test('preferences, sessions and privacy states validate', () async {
      final preferences = await gateway.getPreferences();
      final updated = await gateway.updatePreferences(
        marketingEmailOptIn: true,
        expectedVersion: preferences.version,
      );
      expect(updated.marketingEmailOptIn, isTrue);

      final sessions = await gateway.getSecuritySessions();
      expect(sessions, hasLength(2));
      await gateway.revokeSecuritySession(
        sessions.firstWhere((session) => !session.current).id,
      );
      expect(await gateway.getSecuritySessions(), hasLength(1));

      final export = await gateway.requestPrivacyExport('reauth-proof-demo');
      final deletion = await gateway.requestPrivacyDeletion(
        'reauth-proof-demo',
      );
      expect(export.kind, PrivacyRequestKind.export);
      expect(deletion.state, PrivacyRequestState.retentionRequired);
      expect((await gateway.getPrivacyRequest(export.id)).id, export.id);
    });

    test(
      'menu hierarchy and item detail retain display price and attributes',
      () async {
        final menu = await gateway.getMenu();
        final summary = menu.categories
            .expand((category) => category.items)
            .firstWhere((item) => item.name.contains('[VOCE MENU SINTETICA]'));
        final item = await gateway.getMenuItem(summary.id);

        expect(menu.catalogVersion, '1');
        expect(item.name, contains('[VOCE MENU SINTETICA]'));
        expect(item.syntheticMediaReference, isNull);
        expect(item.price, '€7,00');
        expect(
          item.attributes,
          containsAll(['vegetarian', 'gluten', 'lactose']),
        );
      },
    );

    test('typed faults are deterministic and recoverable', () async {
      gateway.setFault(
        Week2Operation.login,
        Week2FailureKind.dependencyUnavailable,
      );

      await expectLater(
        gateway.login(
          email: 'cliente.demo@example.invalid',
          password: 'password-demo',
        ),
        throwsA(
          isA<Week2Failure>()
              .having(
                (failure) => failure.kind,
                'kind',
                Week2FailureKind.dependencyUnavailable,
              )
              .having((failure) => failure.retryable, 'retryable', isTrue),
        ),
      );

      gateway.setFault(Week2Operation.login, null);
      expect(
        await gateway.login(
          email: 'cliente.demo@example.invalid',
          password: 'password-demo',
        ),
        isA<CustomerSession>(),
      );
    });

    test('generated request failures become typed field validation', () async {
      await expectLater(
        gateway.verifyEmail('short'),
        throwsA(
          isA<Week2Failure>()
              .having(
                (failure) => failure.kind,
                'kind',
                Week2FailureKind.validation,
              )
              .having((failure) => failure.field, 'field', 'token'),
        ),
      );
    });

    test('refresh rotates once and refresh-token reuse is rejected', () async {
      final signedIn = await gateway.login(
        email: 'cliente.demo@example.invalid',
        password: 'password-demo',
      );
      final rotated = await gateway.refreshSession(signedIn.refreshToken);
      expect(rotated.refreshToken, isNot(signedIn.refreshToken));
      await expectLater(
        gateway.refreshSession(signedIn.refreshToken),
        throwsA(
          isA<Week2Failure>().having(
            (failure) => failure.kind,
            'kind',
            Week2FailureKind.sessionReuseDetected,
          ),
        ),
      );
    });

    for (final provider in ['google', 'apple']) {
      test('$provider success returns a deterministic session', () async {
        final intent = await gateway.startFederated(provider);
        final session = await gateway.completeFederated(
          intent: intent,
          result: 'success',
        );
        expect(session.refreshToken, isNotEmpty);
      });
      for (final outcome in [
        'cancelled',
        'denied',
        'timeout',
        'malformed',
        'provider_failure',
      ]) {
        test('$provider $outcome has a deterministic typed seam', () async {
          final intent = await gateway.startFederated(provider);
          await expectLater(
            gateway.completeFederated(intent: intent, result: outcome),
            throwsA(isA<Week2Failure>()),
          );
        });
      }
    }

    test('address create is unique and retry-idempotent', () async {
      final empty = DeterministicWeek2Gateway(
        latency: Duration.zero,
        emptyAddresses: true,
      );
      const firstInput = CustomerAddress(
        id: '99999999-9999-4999-8999-999999999999',
        version: '1',
        label: 'Casa A',
        recipientName: 'Cliente Demo',
        addressLine: 'Via A 1',
        city: 'Brescia',
        province: 'BS',
        postalCode: '25100',
        countryCode: 'IT',
        deliveryNotes: null,
        isDefault: false,
        archivedAt: null,
      );
      final first = await empty.createAddress(firstInput);
      final retry = await empty.createAddress(firstInput);
      final second = await empty.createAddress(
        firstInput.copyWith(label: 'Casa B'),
      );
      expect(retry.id, first.id);
      expect(second.id, isNot(first.id));
      expect(await empty.getAddresses(), hasLength(2));
    });

    test(
      'privacy and menu lookups do not substitute another exact id',
      () async {
        await expectLater(
          gateway.getPrivacyRequest('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
          throwsA(
            isA<Week2Failure>().having(
              (failure) => failure.kind,
              'kind',
              Week2FailureKind.notFound,
            ),
          ),
        );
        await expectLater(
          gateway.getMenuItem('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
          throwsA(
            isA<Week2Failure>().having(
              (failure) => failure.kind,
              'kind',
              Week2FailureKind.notFound,
            ),
          ),
        );
      },
    );
  });
}
