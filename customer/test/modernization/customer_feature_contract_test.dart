import 'package:flutter_test/flutter_test.dart';
import 'package:la_favola/core/api/customer_api_client.dart';
import 'package:la_favola/features/modernization/data/customer_feature_repositories.dart';

final class _Call {
  const _Call(this.method, this.path, this.body);
  final String method;
  final String path;
  final Object? body;
}

final class _RecordingClient extends CustomerApiClient {
  _RecordingClient()
    : super(
        baseUri: Uri.parse('https://example.test'),
        accessToken: () => 'token',
        refreshSession: () async => null,
      );
  final calls = <_Call>[];
  final responses = <String, Object?>{};

  @override
  Future<Object?> get(
    String path, {
    Map<String, Object?> query = const {},
  }) async {
    calls.add(_Call('GET', path, query));
    return responses[path];
  }

  @override
  Future<Object?> post(String path, {Object? body}) async {
    calls.add(_Call('POST', path, body));
    return responses[path];
  }

  @override
  Future<Object?> patch(String path, {Object? body}) async {
    calls.add(_Call('PATCH', path, body));
    return responses[path];
  }

  @override
  Future<Object?> delete(
    String path, {
    Map<String, Object?> query = const {},
    Object? body,
  }) async {
    calls.add(_Call('DELETE', path, body ?? query));
    return responses[path];
  }
}

void main() {
  group('customer feature API contracts', () {
    late _RecordingClient client;
    late HttpCustomerServices services;
    setUp(() {
      client = _RecordingClient();
      services = HttpCustomerServices(client);
    });

    test('favorite add-to-cart sends required default quantity', () async {
      await services.addToCart('favorite-id');
      expect(client.calls.single.body, {'quantity': 1});
    });

    test('favorite creation resolves restaurant and sends menu item', () async {
      client.responses['/api/v1/restaurant'] = {'id': 'restaurant-id'};
      await services.saveFavorite(
        menuItemId: 'menu-item-id',
        label: 'Margherita',
      );
      expect(client.calls[1].path, '/api/v1/favorites');
      expect(client.calls[1].body, {
        'restaurantId': 'restaurant-id',
        'menuItemId': 'menu-item-id',
        'label': 'Margherita',
      });
    });

    test('global API envelope unwraps to its data contract', () {
      expect(
        unwrapCustomerApiResponse({
          'success': true,
          'data': {'id': 'restaurant-id'},
        }),
        {'id': 'restaurant-id'},
      );
      expect(unwrapCustomerApiResponse({'items': []}), {'items': []});
    });
    test('notification read and payment default use PATCH', () async {
      await services.markRead('notification-id');
      await services.makeDefault('payment-id');
      expect(client.calls[0].method, 'PATCH');
      expect(
        client.calls[0].path,
        '/api/v1/notifications/notification-id/read',
      );
      expect(client.calls[1].method, 'PATCH');
      expect(
        client.calls[1].path,
        '/api/v1/payments/methods/payment-id/default',
      );
    });

    test('support payloads use category and message body contract', () async {
      client.responses['/api/v1/support/tickets'] = {
        'id': 'ticket-id',
        'subject': 'Delivery',
        'status': 'open',
      };
      await services.create(
        category: 'delivery_issue',
        subject: 'Delivery',
        message: 'Late order',
      );
      await services.sendMessage('ticket-id', 'Please update me');
      expect(client.calls[0].body, {
        'category': 'delivery_issue',
        'subject': 'Delivery',
        'message': 'Late order',
      });
      expect(client.calls[1].body, {'body': 'Please update me'});
    });

    test('loyalty redemption requires eligible order identifier', () async {
      await services.redeem(
        orderId: '11111111-1111-4111-8111-111111111111',
        points: 100,
      );
      expect(client.calls.single.body, {
        'orderId': '11111111-1111-4111-8111-111111111111',
        'points': 100,
      });
    });

    test(
      'payment response maps public card fields without raw id labels',
      () async {
        client.responses['/api/v1/payments/methods'] = [
          {
            'id': 'method-id',
            'paymentMethodType': 'card',
            'cardBrand': 'Visa',
            'cardLast4': '4242',
            'expMonth': 12,
            'expYear': 2030,
            'isDefault': true,
          },
        ];
        final methods = await services.listPaymentMethods();
        expect(methods.single.label, 'Visa •••• 4242');
        expect(methods.single.expiry, '12/2030');
        expect(methods.single.isDefault, isTrue);
        expect(methods.single.label, isNot(contains('method-id')));
      },
    );

    test(
      'cart is restaurant scoped and line mutations use exact contracts',
      () async {
        client.responses['/api/v1/restaurant'] = {'id': 'restaurant-id'};
        client.responses['/api/v1/cart'] = {
          'cart': {'id': 'cart-id'},
          'items': [
            {
              'id': 'line-id',
              'itemNameSnapshot': 'Margherita',
              'quantity': 2,
              'lineTotalMinor': 1800,
            },
          ],
          'subtotalMinor': 1800,
        };
        final cart = await services.loadCart();
        expect(cart.id, 'cart-id');
        expect(cart.lines.single.id, 'line-id');
        expect(client.calls[1].body, {'restaurantId': 'restaurant-id'});
        await services.updateLine('line-id', 3);
        await services.removeLine('line-id');
        expect(client.calls[2].method, 'PATCH');
        expect(client.calls[2].body, {'quantity': 3});
        expect(client.calls[3].method, 'DELETE');
      },
    );

    test(
      'checkout sends idempotency in the exact body and omits pickup address',
      () async {
        await services.checkout(
          cartId: 'cart-id',
          orderType: 'pickup',
          paymentMethod: 'cash',
          scheduledFor: '2026-08-12T18:30:00Z',
          idempotencyKey: 'customer-safe-key',
        );
        expect(client.calls.single.path, '/api/v1/checkout');
        expect(client.calls.single.body, {
          'cartId': 'cart-id',
          'orderType': 'pickup',
          'paymentMethod': 'cash',
          'scheduledFor': '2026-08-12T18:30:00Z',
          'idempotencyKey': 'customer-safe-key',
        });
      },
    );
  });
}
