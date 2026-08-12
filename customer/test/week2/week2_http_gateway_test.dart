import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_favola/week2/week2_account_screens.dart';
import 'package:la_favola/week2/week2_app.dart';
import 'support/deterministic_week2_gateway.dart';
import 'package:la_favola/week2/week2_http_gateway.dart';
import 'package:la_favola/week2/week2_models.dart';

typedef _Handler =
    FutureOr<Week2HttpResponse> Function({
      required String method,
      required Uri uri,
      required Map<String, String> headers,
      required String? body,
    });

final class _SentRequest {
  const _SentRequest({
    required this.method,
    required this.uri,
    required this.headers,
    required this.body,
  });

  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final String? body;
}

final class _RecordingTransport implements Week2HttpTransport {
  _RecordingTransport(this.handlers);

  final List<_Handler> handlers;
  final List<_SentRequest> requests = [];

  @override
  Future<Week2HttpResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required String? body,
    required Duration timeout,
  }) async {
    requests.add(
      _SentRequest(
        method: method,
        uri: uri,
        headers: Map.unmodifiable(headers),
        body: body,
      ),
    );
    return handlers.removeAt(0)(
      method: method,
      uri: uri,
      headers: headers,
      body: body,
    );
  }
}

Week2HttpResponse _jsonResponse(int status, Object body) => Week2HttpResponse(
  statusCode: status,
  headers: const {'x-correlation-id': 'http-test-0001'},
  body: jsonEncode(body),
);

void main() {
  group('HttpWeek2Gateway', () {
    test(
      'uses the Android emulator base and keeps public menu anonymous',
      () async {
        final transport = _RecordingTransport([
          ({required method, required uri, required headers, required body}) {
            expect(method, 'GET');
            expect(uri, Uri.parse('http://10.0.2.2:3001/api/v1/categories'));
            expect(headers, isNot(contains('Authorization')));
            return _jsonResponse(200, {'data': []});
          },
          ({required method, required uri, required headers, required body}) {
            expect(
              uri,
              Uri.parse('http://10.0.2.2:3001/api/v1/menu?limit=100'),
            );
            return _jsonResponse(200, {
              'data': {'items': []},
            });
          },
        ]);
        final gateway = HttpWeek2Gateway(
          baseUri: Uri.parse('http://10.0.2.2:3001'),
          transport: transport,
        );

        final menu = await gateway.getMenu();

        expect(menu.catalogVersion, 'empty');
        expect(menu.categories, isEmpty);
      },
    );

    test('parses the production public-menu JSON shape', () async {
      final transport = _RecordingTransport([
        ({required method, required uri, required headers, required body}) =>
            _jsonResponse(200, {
              'data': [
                {
                  'id': '10000000-0000-4000-8000-000000000001',
                  'name': 'Le Pizze',
                  'description': 'Pizze dal forno.',
                  'displayOrder': 1,
                },
              ],
            }),
        ({required method, required uri, required headers, required body}) =>
            _jsonResponse(200, {
              'data': {
                'items': [
                  {
                    'id': '11000000-0000-4000-8000-000000000001',
                    'categoryId': '10000000-0000-4000-8000-000000000001',
                    'name': 'Americana',
                    'description': 'Pomodoro e fiordilatte.',
                    'itemType': 'standard',
                    'isVegetarian': true,
                    'sizes': [
                      {
                        'id': '21000000-0000-4000-8000-000000000001',
                        'sizeCode': 'normal',
                        'displayName': 'Normale',
                        'basePriceMinor': 900,
                      },
                    ],
                  },
                ],
              },
            }),
      ]);
      final gateway = HttpWeek2Gateway(
        baseUri: Uri.parse('https://api.example.invalid'),
        transport: transport,
      );

      final menu = await gateway.getMenu();

      expect(menu.catalogVersion, '1');
      expect(menu.categories.single.name, 'Le Pizze');
      expect(menu.categories.single.items.single.price, '€9,00');
      expect(menu.categories.single.items.single.attributes, ['Vegetarian']);
    });

    test(
      'opens a live-priced menu item from the production response shape',
      () async {
        const itemId = '11000000-0000-4000-8000-000000000001';
        final transport = _RecordingTransport([
          ({required method, required uri, required headers, required body}) {
            expect(method, 'GET');
            expect(
              uri,
              Uri.parse('https://api.example.invalid/api/v1/menu/$itemId'),
            );
            return _jsonResponse(200, {
              'data': {
                'id': itemId,
                'categoryId': '10000000-0000-4000-8000-000000000001',
                'name': 'Americana',
                'description': 'Pomodoro e fiordilatte.',
                'itemType': 'standard',
                'isVegetarian': true,
                'sizes': [
                  {
                    'id': '21000000-0000-4000-8000-000000000001',
                    'sizeCode': 'normal',
                    'displayName': 'Normale',
                    'basePriceMinor': 900,
                  },
                ],
              },
            });
          },
        ]);
        final gateway = HttpWeek2Gateway(
          baseUri: Uri.parse('https://api.example.invalid'),
          transport: transport,
        );

        final item = await gateway.getMenuItem(itemId);

        expect(item.name, 'Americana');
        expect(item.price, '€9,00');
        expect(item.attributes, ['Vegetarian']);
      },
    );

    test(
      'activates bearer state only after a valid generated response',
      () async {
        final transport = _RecordingTransport([
          ({required method, required uri, required headers, required body}) =>
              _jsonResponse(201, {
                'accessToken': 'access-token-http-0001',
                'refreshToken': 'refresh-token-http-0001',
                'expiresIn': 900,
                'sessionId': '11111111-1111-4111-8111-111111111111',
              }),
          ({required method, required uri, required headers, required body}) {
            expect(headers['Authorization'], 'Bearer access-token-http-0001');
            return _jsonResponse(200, {
              'version': '1',
              'displayName': 'Cliente Demo',
              'email': 'cliente.demo@example.invalid',
              'emailVerified': true,
              'phone': null,
              'locale': 'it-IT',
            });
          },
        ]);
        final gateway = HttpWeek2Gateway(
          baseUri: Uri.parse('https://api.example.invalid'),
          transport: transport,
        );

        await gateway.login(
          email: 'cliente.demo@example.invalid',
          password: 'password-demo',
        );
        final profile = await gateway.getProfile();

        expect(profile.displayName, 'Cliente Demo');
        expect(transport.requests, hasLength(2));
      },
    );

    test('maps a timeout and permits a safe registration retry', () async {
      final transport = _RecordingTransport([
        ({required method, required uri, required headers, required body}) =>
            throw TimeoutException('uncertain result'),
        ({required method, required uri, required headers, required body}) =>
            _jsonResponse(202, {'message': 'Registration accepted'}),
      ]);
      final gateway = HttpWeek2Gateway(
        baseUri: Uri.parse('https://api.example.invalid'),
        transport: transport,
      );

      await expectLater(
        gateway.register(
          displayName: 'Cliente Demo',
          email: 'cliente.demo@example.invalid',
          password: 'password-demo',
        ),
        throwsA(
          isA<Week2Failure>().having(
            (failure) => failure.kind,
            'kind',
            Week2FailureKind.timeout,
          ),
        ),
      );
      await gateway.register(
        displayName: 'Cliente Demo',
        email: 'cliente.demo@example.invalid',
        password: 'password-demo',
      );

      expect(transport.requests, hasLength(2));
    });

    test('loads readable server-authoritative fulfilment slots', () async {
      const itemId = '11000000-0000-4000-8000-000000000001';
      final transport = _RecordingTransport([
        ({required method, required uri, required headers, required body}) {
          expect(method, 'GET');
          expect(uri.path, '/api/v1/restaurant/availability');
          expect(uri.queryParameters, {
            'orderType': 'pickup',
            'date': '2026-08-14',
            'menuItemId': itemId,
          });
          return _jsonResponse(200, {
            'serverNow': '2026-08-12T12:00:00Z',
            'timezone': 'Europe/Rome',
            'date': '2026-08-14',
            'orderType': 'pickup',
            'leadMinutes': 20,
            'asapAvailable': false,
            'estimatedReadyAt': null,
            'estimatedDeliveryAt': null,
            'slots': [
              {'scheduledFor': '2026-08-14T16:00:00Z', 'localTime': '18:00'},
            ],
          });
        },
      ]);
      final gateway = HttpWeek2Gateway(
        baseUri: Uri.parse('https://api.example.invalid'),
        transport: transport,
      );

      final availability = await gateway.getFulfillmentAvailability(
        type: FulfillmentType.pickup,
        date: '2026-08-14',
        menuItemId: itemId,
      );

      expect(availability.asapAvailable, isFalse);
      expect(availability.slots.single.localTime, '18:00');
      expect(availability.leadMinutes, 20);
    });

    test(
      'parses an empty authenticated order list after envelope unwrapping',
      () async {
        final transport = _RecordingTransport([
          ({required method, required uri, required headers, required body}) =>
              _jsonResponse(200, {
                'accessToken': 'orders-access-token',
                'refreshToken': 'orders-refresh-token',
              }),
          ({required method, required uri, required headers, required body}) {
            expect(method, 'GET');
            expect(
              uri,
              Uri.parse(
                'https://api.example.invalid/api/v1/orders/me?page=1&limit=100',
              ),
            );
            expect(headers['Authorization'], 'Bearer orders-access-token');
            return _jsonResponse(200, {'success': true, 'data': <Object?>[]});
          },
        ]);
        final gateway = HttpWeek2Gateway(
          baseUri: Uri.parse('https://api.example.invalid'),
          transport: transport,
        );
        await gateway.login(
          email: 'customer@example.test',
          password: 'password',
        );

        expect(await gateway.getOrders(), isEmpty);
      },
    );
    test(
      'parses an authenticated customer order receipt without raw ids',
      () async {
        const orderId = '91000000-0000-4000-8000-000000000001';
        final transport = _RecordingTransport([
          ({required method, required uri, required headers, required body}) =>
              _jsonResponse(200, {
                'accessToken': 'receipt-access-token',
                'refreshToken': 'receipt-refresh-token',
              }),
          ({required method, required uri, required headers, required body}) {
            expect(method, 'GET');
            expect(
              uri,
              Uri.parse(
                'https://api.example.invalid/api/v1/orders/me/$orderId/receipt',
              ),
            );
            expect(headers['Authorization'], 'Bearer receipt-access-token');
            return _jsonResponse(200, {
              'documentType': 'order_receipt',
              'fiscalDocument': false,
              'issuedAt': '2026-08-12T12:00:00Z',
              'restaurant': {
                'name': 'La Favola',
                'address': ['Via Test 1', '25100 Brescia'],
              },
              'order': {
                'number': 'LF-2026-000001',
                'type': 'delivery',
                'status': 'placed',
                'paymentStatus': 'collection_pending',
                'paymentMethod': 'cash',
                'currency': 'EUR',
                'items': [
                  {
                    'name': 'Margherita',
                    'size': 'Normale',
                    'quantity': 1,
                    'unitPriceMinor': 900,
                    'lineTotalMinor': 1000,
                    'options': [
                      {
                        'name': 'Olive',
                        'quantity': 1,
                        'totalPriceAdjustmentMinor': 100,
                      },
                    ],
                  },
                ],
                'totals': {
                  'subtotalMinor': 900,
                  'optionChargesMinor': 100,
                  'discountMinor': 0,
                  'deliveryFeeMinor': 200,
                  'taxMinor': 0,
                  'grandTotalMinor': 1200,
                },
              },
              'notice': 'Order receipt only.',
            });
          },
        ]);
        final gateway = HttpWeek2Gateway(
          baseUri: Uri.parse('https://api.example.invalid'),
          transport: transport,
        );
        await gateway.login(
          email: 'customer@example.test',
          password: 'password',
        );

        final receipt = await gateway.getOrderReceipt(orderId);

        expect(receipt.fiscalDocument, isFalse);
        expect(receipt.restaurant.name, 'La Favola');
        expect(receipt.order.items.single.options.single.name, 'Olive');
        expect(receipt.order.totals.grandTotalMinor, 1200);
      },
    );

    test(
      'maps validated stable errors without parsing their message',
      () async {
        final transport = _RecordingTransport([
          ({required method, required uri, required headers, required body}) =>
              _jsonResponse(401, {
                'error': {
                  'code': 'AUTH_INVALID_CREDENTIALS',
                  'messageKey': 'auth.invalid_credentials',
                  'message': 'Credenziali non valide.',
                  'correlationId': 'http-test-0001',
                  'retryable': false,
                },
              }),
        ]);
        final gateway = HttpWeek2Gateway(
          baseUri: Uri.parse('https://api.example.invalid'),
          transport: transport,
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
                  Week2FailureKind.unauthenticated,
                )
                .having(
                  (failure) => failure.correlationId,
                  'correlation',
                  'http-test-0001',
                ),
          ),
        );
      },
    );
  });

  testWidgets('anonymous menu is reachable without creating a session', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1000);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      Week2App(gateway: DeterministicWeek2Gateway(latency: Duration.zero)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-public-menu')));
    await tester.pumpAndSettle();

    expect(find.text('Menu pubblico'), findsOneWidget);
    expect(find.textContaining('Menu'), findsWidgets);
    expect(find.text('Accedi'), findsOneWidget);
  });

  testWidgets('privacy exchanges password for proof before mutation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrivacyScreen(
            gateway: DeterministicWeek2Gateway(latency: Duration.zero),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('privacy-reauth-password')),
      'password-demo',
    );
    await tester.tap(find.text('Richiedi esportazione'));
    await tester.pumpAndSettle();

    expect(find.text('Esportazione'), findsOneWidget);
    expect(find.textContaining('Richiesta ·'), findsOneWidget);
  });
}
