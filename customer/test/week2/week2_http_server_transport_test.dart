import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:la_favola/week2/week2_http_gateway.dart';
import 'package:la_favola/week2/week2_models.dart';

const _sessionId = '11111111-1111-4111-8111-111111111111';
const _otherSessionId = '22222222-2222-4222-8222-222222222222';
const _addressId = '33333333-3333-4333-8333-333333333333';
const _categoryId = '44444444-4444-4444-8444-444444444444';
const _itemId = '55555555-5555-4555-8555-555555555555';
const _sizeId = '55555555-5555-4555-8555-555555555556';
const _exportId = '66666666-6666-4666-8666-666666666666';
const _deletionId = '77777777-7777-4777-8777-777777777777';
const _intentId = '88888888-8888-4888-8888-888888888888';
const _now = '2026-07-26T10:00:00Z';

typedef _ServerHandler =
    FutureOr<void> Function(HttpRequest request, _CapturedRequest captured);

final class _CapturedRequest {
  const _CapturedRequest({
    required this.method,
    required this.path,
    required this.headers,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, String> headers;
  final Object? body;
}

final class _LocalJsonServer {
  _LocalJsonServer._(this.server, this._subscription, this.handler);

  final HttpServer server;
  final StreamSubscription<HttpRequest> _subscription;
  final _ServerHandler handler;
  final List<_CapturedRequest> requests = [];

  Uri get baseUri => Uri.parse('http://${server.address.host}:${server.port}');

  static Future<_LocalJsonServer> start(_ServerHandler handler) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    late final _LocalJsonServer result;
    final subscription = server.listen((request) async {
      final bytes = await request.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      final text = utf8.decode(bytes);
      final headers = <String, String>{};
      request.headers.forEach((name, values) {
        headers[name.toLowerCase()] = values.join(',');
      });
      final captured = _CapturedRequest(
        method: request.method,
        path: request.uri.path,
        headers: Map.unmodifiable(headers),
        body: text.isEmpty ? null : jsonDecode(text),
      );
      result.requests.add(captured);
      try {
        await handler(request, captured);
      } catch (_) {
        await request.response.close();
      }
    });
    result = _LocalJsonServer._(server, subscription, handler);
    return result;
  }

  Future<void> close() async {
    await _subscription.cancel();
    await server.close(force: true);
  }
}

Future<void> _json(
  HttpRequest request,
  Object body, {
  int status = HttpStatus.ok,
  String correlationId = 'http-server-0001',
}) async {
  request.response
    ..statusCode = status
    ..headers.contentType = ContentType.json
    ..headers.set('X-Correlation-Id', correlationId)
    ..write(jsonEncode(body));
  await request.response.close();
}

Map<String, Object?> _session([String suffix = '0001']) => {
  'accessToken': 'access-token-http-$suffix',
  'refreshToken': 'refresh-token-http-$suffix',
  'expiresIn': 900,
  'sessionId': _sessionId,
};

Map<String, Object?> _profile({String version = '1'}) => {
  'version': version,
  'displayName': 'Cliente locale',
  'email': 'cliente@local.invalid',
  'emailVerified': true,
  'phone': null,
  'locale': 'it-IT',
};

Map<String, Object?> _address({String version = '1', String? archivedAt}) => {
  'id': _addressId,
  'version': version,
  'label': 'Casa',
  'recipientName': 'Cliente locale',
  'addressLine': 'Via Locale 1',
  'city': 'Brescia',
  'province': 'BS',
  'postalCode': '25100',
  'countryCode': 'IT',
  'deliveryNotes': null,
  'isDefault': archivedAt == null,
  'archivedAt': archivedAt,
};

Map<String, Object?> _privacy(String kind) => {
  'id': kind == 'export' ? _exportId : _deletionId,
  'kind': kind,
  'state': kind == 'export' ? 'requested' : 'retention_required',
  'requestedAt': _now,
  'completedAt': null,
  'recoveryAction': kind == 'export' ? null : 'Contatta il supporto.',
};

Map<String, Object?> _item() => {
  'id': _itemId,
  'categoryId': _categoryId,
  'name': 'Voce locale',
  'description': 'Contenuto strutturale locale.',
  'itemType': 'standard',
  'displayOrder': 1,
  'isVegetarian': true,
  'isVegan': false,
  'isGlutenFree': false,
  'isSpicy': false,
  'updatedAt': _now,
  'sizes': [
    {
      'id': _sizeId,
      'displayName': 'Classica',
      'sizeCode': 'CLASSIC',
      'basePriceMinor': 1000,
      'displayOrder': 1,
      'updatedAt': _now,
    },
  ],
};

Future<void> _successRouter(
  HttpRequest request,
  _CapturedRequest captured,
) async {
  final route = '${captured.method} ${captured.path}';
  final response = switch (route) {
    'POST /api/v1/auth/register' => {'message': 'Registration accepted'},
    'POST /api/v1/auth/login' => _session(),
    'POST /api/v1/auth/verify-email' => {'message': 'Email verified'},
    'POST /api/v1/auth/resend-verification' => {
      'message': 'Verification request accepted',
    },
    'POST /api/v1/auth/forgot-password' => {
      'message': 'Recovery request accepted',
    },
    'POST /api/v1/auth/reset-password' => {
      'message': 'Password reset successful',
    },
    'POST /api/v1/auth/customer/federated-intents' => {
      'provider': 'google',
      'intentId': _intentId,
      'nonce': 'local-provider-nonce-0001',
      'state': 'local-provider-state-0001',
      'live': false,
    },
    'POST /api/v1/auth/customer/federated-completions' => _session('0002'),
    'POST /api/v1/auth/customer/reauthentications' => {
      'reauthenticationProof': 'local-reauthentication-proof-0001',
      'expiresAt': '2026-07-26T10:15:00Z',
    },
    'POST /api/v1/auth/refresh' => _session('0003'),
    'POST /api/v1/auth/logout' => {'message': 'Logged out'},
    'GET /api/v1/customers/me/profile' => _profile(),
    'PATCH /api/v1/customers/me/profile' => _profile(version: '2'),
    'GET /api/v1/customers/me/addresses' => {
      'data': [_address()],
    },
    'POST /api/v1/customers/me/addresses' => _address(),
    'PATCH /api/v1/customers/me/addresses/$_addressId' => _address(
      version: '2',
    ),
    'DELETE /api/v1/customers/me/addresses/$_addressId' => _address(
      version: '2',
      archivedAt: _now,
    ),
    'GET /api/v1/customers/me/preferences' => {
      'version': '1',
      'marketingEmailOptIn': false,
      'securityAlertsEnabled': true,
    },
    'PATCH /api/v1/customers/me/preferences' => {
      'version': '2',
      'marketingEmailOptIn': true,
      'securityAlertsEnabled': true,
    },
    'GET /api/v1/customers/me/security/sessions' => {
      'data': [
        {
          'id': _otherSessionId,
          'createdAt': _now,
          'lastUsedAt': _now,
          'expiresAt': '2026-08-01T10:00:00Z',
          'deviceLabel': 'Browser locale',
          'current': false,
        },
      ],
    },
    'DELETE /api/v1/customers/me/security/sessions/$_otherSessionId' => {
      'message': 'Logged out',
    },
    'POST /api/v1/customer/privacy/exports' => _privacy('export'),
    'POST /api/v1/customer/privacy/deletions' => _privacy('deletion'),
    'GET /api/v1/customers/me/privacy/requests/$_exportId' => _privacy(
      'export',
    ),
    'GET /api/v1/categories' => {
      'data': [
        {
          'id': _categoryId,
          'parentCategoryId': null,
          'name': 'Categoria locale',
          'description': 'Gerarchia strutturale locale.',
          'displayOrder': 1,
          'updatedAt': _now,
        },
      ],
    },
    'GET /api/v1/menu' => {
      'data': {
        'items': [_item()],
        'meta': {'page': 1, 'limit': 100, 'total': 1, 'totalPages': 1},
      },
    },
    'GET /api/v1/menu/$_itemId' => _item(),
    _ => throw StateError('Unexpected route $route'),
  };
  await _json(request, response);
}

void main() {
  group('IoWeek2HttpTransport with a loopback HttpServer', () {
    test(
      'exercises every gateway method and its generated wire contract',
      () async {
        final server = await _LocalJsonServer.start(_successRouter);
        addTearDown(server.close);
        final gateway = HttpWeek2Gateway(
          baseUri: server.baseUri,
          configuredFederatedProviders: const {'google'},
        );

        await gateway.register(
          displayName: 'Cliente locale',
          email: 'cliente@local.invalid',
          password: 'password-locale',
        );
        final login = await gateway.login(
          email: 'cliente@local.invalid',
          password: 'password-locale',
        );
        await gateway.verifyEmail('verification-token-0001');
        await gateway.resendVerification('cliente@local.invalid');
        await gateway.requestPasswordRecovery('cliente@local.invalid');
        await gateway.resetPassword(
          token: 'recovery-token-0001',
          password: 'password-nuova',
        );
        final intent = await gateway.startFederated('google');
        await gateway.completeFederated(intent: intent, result: 'cancelled');
        expect(gateway.supportsCustomerReauthentication, isFalse);
        await expectLater(
          gateway.reauthenticate('password-locale'),
          throwsA(isA<Week2Failure>()),
        );
        await gateway.refreshSession(login.refreshToken);
        expect((await gateway.getProfile()).version, '1');
        expect(
          (await gateway.updateProfile(
            displayName: 'Cliente locale',
            phone: null,
            expectedVersion: '1',
          )).version,
          '2',
        );
        expect(await gateway.getAddresses(), hasLength(1));
        const address = CustomerAddress(
          id: _addressId,
          version: '1',
          label: 'Casa',
          recipientName: 'Cliente locale',
          addressLine: 'Via Locale 1',
          city: 'Brescia',
          province: 'BS',
          postalCode: '25100',
          countryCode: 'IT',
          deliveryNotes: null,
          isDefault: true,
          archivedAt: null,
        );
        await gateway.createAddress(address);
        await gateway.updateAddress(address);
        await gateway.archiveAddress(address);
        expect((await gateway.getPreferences()).version, '1');
        expect(
          (await gateway.updatePreferences(
            marketingEmailOptIn: true,
            expectedVersion: '1',
          )).version,
          '2',
        );
        expect(await gateway.getSecuritySessions(), hasLength(1));
        await gateway.revokeSecuritySession(_otherSessionId);
        await expectLater(
          gateway.requestPrivacyExport('local-reauthentication-proof-0001'),
          throwsA(isA<Week2Failure>()),
        );
        await expectLater(
          gateway.requestPrivacyDeletion('local-reauthentication-proof-0001'),
          throwsA(isA<Week2Failure>()),
        );
        expect(
          (await gateway.getPrivacyRequest(_exportId)).state,
          PrivacyRequestState.requested,
        );
        expect((await gateway.getMenu()).categories, hasLength(1));
        expect((await gateway.getMenuItem(_itemId)).id, _itemId);
        await gateway.logout();

        final routes =
            server.requests
                .map((request) => '${request.method} ${request.path}')
                .toSet();
        final expectedRoutes = <String>{
          'POST /api/v1/auth/register',
          'POST /api/v1/auth/login',
          'POST /api/v1/auth/verify-email',
          'POST /api/v1/auth/resend-verification',
          'POST /api/v1/auth/forgot-password',
          'POST /api/v1/auth/reset-password',
          'POST /api/v1/auth/customer/federated-intents',
          'POST /api/v1/auth/customer/federated-completions',
          'POST /api/v1/auth/refresh',
          'POST /api/v1/auth/logout',
          'GET /api/v1/customers/me/profile',
          'PATCH /api/v1/customers/me/profile',
          'GET /api/v1/customers/me/addresses',
          'POST /api/v1/customers/me/addresses',
          'PATCH /api/v1/customers/me/addresses/$_addressId',
          'DELETE /api/v1/customers/me/addresses/$_addressId',
          'GET /api/v1/customers/me/preferences',
          'PATCH /api/v1/customers/me/preferences',
          'GET /api/v1/customers/me/security/sessions',
          'DELETE /api/v1/customers/me/security/sessions/$_otherSessionId',
          'GET /api/v1/customers/me/privacy/requests/$_exportId',
          'GET /api/v1/categories',
          'GET /api/v1/menu',
          'GET /api/v1/menu/$_itemId',
        };
        expect(routes, containsAll(expectedRoutes));
        expect(
          server.requests
              .firstWhere(
                (request) =>
                    request.path == '/api/v1/customers/me/profile' &&
                    request.method == 'GET',
              )
              .headers['authorization'],
          startsWith('Bearer access-token-http-'),
        );
        expect(
          server.requests
              .firstWhere((request) => request.path == '/api/v1/categories')
              .headers,
          isNot(contains('authorization')),
        );
        for (final request in server.requests) {
          expect(request.headers['x-correlation-id'], isNotEmpty);
        }
        for (final request in server.requests.where(
          (request) =>
              const {
                '/api/v1/auth/customer/federated-intents',
                '/api/v1/auth/customer/federated-completions',
                '/api/v1/customer/privacy/exports',
                '/api/v1/customer/privacy/deletions',
              }.contains(request.path) &&
              request.method != 'GET',
        )) {
          expect(request.headers['idempotency-key'], isNotEmpty);
        }
      },
    );

    test(
      'maps a registration socket timeout and allows a safe retry',
      () async {
        var attempt = 0;
        final server = await _LocalJsonServer.start((request, captured) async {
          attempt += 1;
          if (attempt == 1) {
            await Future<void>.delayed(const Duration(milliseconds: 80));
          }
          await _json(request, {'message': 'Registration accepted'});
        });
        addTearDown(server.close);
        final gateway = HttpWeek2Gateway(
          baseUri: server.baseUri,
          timeout: const Duration(milliseconds: 20),
        );

        Future<void> register() => gateway.register(
          displayName: 'Cliente locale',
          email: 'cliente@local.invalid',
          password: 'password-locale',
        );

        await expectLater(
          register(),
          throwsA(
            isA<Week2Failure>().having(
              (failure) => failure.kind,
              'kind',
              Week2FailureKind.timeout,
            ),
          ),
        );
        await register();

        expect(server.requests, hasLength(2));
      },
    );

    test(
      'maps safe errors and clears bearer state after failed logout',
      () async {
        var profileCount = 0;
        final server = await _LocalJsonServer.start((request, captured) async {
          final route = '${captured.method} ${captured.path}';
          switch (route) {
            case 'POST /api/v1/auth/login':
              await _json(request, _session());
            case 'GET /api/v1/customers/me/profile':
              profileCount += 1;
              if (profileCount == 1) {
                await _json(
                  request,
                  {
                    'error': {
                      'code': 'DEPENDENCY_UNAVAILABLE',
                      'messageKey': 'dependency.unavailable',
                      'message': 'Servizio temporaneamente non disponibile.',
                      'correlationId': 'safe-http-error-0001',
                      'retryable': true,
                    },
                  },
                  status: HttpStatus.serviceUnavailable,
                  correlationId: 'safe-http-error-0001',
                );
              } else {
                await _json(request, _profile());
              }
            case 'POST /api/v1/auth/logout':
              await _json(request, {
                'error': {
                  'code': 'AUTH_SESSION_EXPIRED',
                  'messageKey': 'auth.session_expired',
                  'message': 'Sessione scaduta.',
                  'correlationId': 'logout-expired-0001',
                  'retryable': false,
                },
              }, status: HttpStatus.unauthorized);
            default:
              throw StateError('Unexpected route $route');
          }
        });
        addTearDown(server.close);
        final gateway = HttpWeek2Gateway(baseUri: server.baseUri);

        await gateway.login(
          email: 'cliente@local.invalid',
          password: 'password-locale',
        );
        await expectLater(
          gateway.getProfile(),
          throwsA(
            isA<Week2Failure>()
                .having(
                  (failure) => failure.kind,
                  'kind',
                  Week2FailureKind.dependencyUnavailable,
                )
                .having(
                  (failure) => failure.correlationId,
                  'correlationId',
                  'safe-http-error-0001',
                )
                .having((failure) => failure.retryable, 'retryable', isTrue),
          ),
        );
        await gateway.logout();
        await expectLater(
          gateway.getProfile(),
          throwsA(
            isA<Week2Failure>().having(
              (failure) => failure.kind,
              'kind',
              Week2FailureKind.unauthenticated,
            ),
          ),
        );

        final profiles =
            server.requests
                .where(
                  (request) => request.path == '/api/v1/customers/me/profile',
                )
                .toList();
        expect(profiles.first.headers['authorization'], isNotEmpty);
        expect(profiles, hasLength(1));
      },
    );
  });
}
