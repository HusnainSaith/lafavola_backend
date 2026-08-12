import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_favola/core/api/customer_api_client.dart';

String _text(
  Map<String, Object?> map,
  List<String> keys, [
  String fallback = '',
]) {
  for (final key in keys) {
    final value = map[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return fallback;
}

int _number(Map<String, Object?> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is num) return value.toInt();
  }
  return 0;
}

bool _flag(Map<String, Object?> map, List<String> keys) {
  for (final key in keys) {
    if (map[key] is bool) return map[key] as bool;
  }
  return false;
}

final class FavoriteView {
  const FavoriteView({
    required this.id,
    required this.name,
    required this.details,
  });
  final String id;
  final String name;
  final String details;
  factory FavoriteView.fromJson(Object? value) {
    final map = objectMap(value);
    final item = objectMap(map['menuItem'] ?? map['item']);
    return FavoriteView(
      id: _text(map, const ['id']),
      name: _text(map, const [
        'name',
        'displayName',
      ], _text(item, const ['name'], 'Favorite')),
      details: _text(map, const [
        'description',
        'configurationLabel',
      ], _text(item, const ['description'])),
    );
  }
}

abstract interface class FavoritesRepository {
  Future<List<FavoriteView>> listFavorites();
  Future<void> saveFavorite({
    required String menuItemId,
    required String label,
  });
  Future<void> addToCart(String id);
  Future<void> removeFavorite(String id);
}

final class RewardView {
  const RewardView({
    required this.title,
    required this.subtitle,
    required this.points,
  });
  final String title;
  final String subtitle;
  final int points;
}

final class RewardsSnapshot {
  const RewardsSnapshot({required this.balance, required this.history});
  final int balance;
  final List<RewardView> history;
}

abstract interface class RewardsRepository {
  Future<RewardsSnapshot> loadRewards();
  Future<void> redeem({required String orderId, required int points});
}

final class NotificationView {
  const NotificationView({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
  });
  final String id;
  final String title;
  final String body;
  final bool read;
}

abstract interface class NotificationsRepository {
  Future<List<NotificationView>> listNotifications();
  Future<void> markRead(String id);
  Future<Map<String, bool>> preferences();
  Future<void> updatePreferences(Map<String, bool> values);
}

final class SupportTicketView {
  const SupportTicketView({
    required this.id,
    required this.subject,
    required this.status,
    required this.preview,
  });
  final String id;
  final String subject;
  final String status;
  final String preview;
}

abstract interface class SupportRepository {
  Future<List<SupportTicketView>> listTickets();
  Future<SupportTicketView> create({
    required String category,
    required String subject,
    required String message,
  });
  Future<List<String>> messages(String id);
  Future<void> sendMessage(String id, String message);
}

final class FaqView {
  const FaqView({
    required this.question,
    required this.answer,
    required this.category,
  });
  final String question;
  final String answer;
  final String category;
}

abstract interface class FaqRepository {
  Future<List<FaqView>> listFaq({String? search});
}

final class PaymentMethodView {
  const PaymentMethodView({
    required this.id,
    required this.label,
    required this.expiry,
    required this.isDefault,
  });
  final String id;
  final String label;
  final String expiry;
  final bool isDefault;
}

abstract interface class PaymentMethodsRepository {
  Future<List<PaymentMethodView>> listPaymentMethods();
  Future<void> makeDefault(String id);
  Future<void> removePaymentMethod(String id);
}

final class CartLineView {
  const CartLineView({
    required this.id,
    required this.name,
    required this.quantity,
    required this.totalMinor,
  });
  final String id;
  final String name;
  final int quantity;
  final int totalMinor;
}

final class CartSnapshot {
  const CartSnapshot({
    required this.id,
    required this.restaurantId,
    required this.lines,
    required this.totalMinor,
    required this.currency,
  });
  final String id;
  final String restaurantId;
  final List<CartLineView> lines;
  final int totalMinor;
  final String currency;
  bool get isEmpty => lines.isEmpty;
}

abstract interface class CartRepository {
  Future<CartSnapshot> loadCart();
  Future<void> clear();
  Future<void> updateLine(String id, int quantity);
  Future<void> removeLine(String id);
  Future<Map<String, Object?>> checkout({
    required String cartId,
    required String orderType,
    String? deliveryAddressId,
    required String paymentMethod,
    String? scheduledFor,
    required String idempotencyKey,
  });
  Future<CartSnapshot> reorder(String orderId);
}

final customerServicesProvider = Provider<HttpCustomerServices>(
  (ref) => HttpCustomerServices(ref.watch(customerApiClientProvider)),
);
final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => ref.watch(customerServicesProvider),
);
final rewardsRepositoryProvider = Provider<RewardsRepository>(
  (ref) => ref.watch(customerServicesProvider),
);
final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => ref.watch(customerServicesProvider),
);
final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => ref.watch(customerServicesProvider),
);
final faqRepositoryProvider = Provider<FaqRepository>(
  (ref) => ref.watch(customerServicesProvider),
);
final paymentMethodsRepositoryProvider = Provider<PaymentMethodsRepository>(
  (ref) => ref.watch(customerServicesProvider),
);
final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => ref.watch(customerServicesProvider),
);

final favoritesProvider = FutureProvider.autoDispose<List<FavoriteView>>(
  (ref) => ref.watch(favoritesRepositoryProvider).listFavorites(),
);
final rewardsProvider = FutureProvider.autoDispose<RewardsSnapshot>(
  (ref) => ref.watch(rewardsRepositoryProvider).loadRewards(),
);
final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationView>>(
      (ref) => ref.watch(notificationsRepositoryProvider).listNotifications(),
    );
final supportTicketsProvider =
    FutureProvider.autoDispose<List<SupportTicketView>>(
      (ref) => ref.watch(supportRepositoryProvider).listTickets(),
    );
final faqProvider = FutureProvider.autoDispose.family<List<FaqView>, String>(
  (ref, search) => ref.watch(faqRepositoryProvider).listFaq(search: search),
);
final paymentMethodsProvider =
    FutureProvider.autoDispose<List<PaymentMethodView>>(
      (ref) => ref.watch(paymentMethodsRepositoryProvider).listPaymentMethods(),
    );
final cartProvider = FutureProvider.autoDispose<CartSnapshot>(
  (ref) => ref.watch(cartRepositoryProvider).loadCart(),
);

final class HttpCustomerServices
    implements
        FavoritesRepository,
        RewardsRepository,
        NotificationsRepository,
        SupportRepository,
        FaqRepository,
        PaymentMethodsRepository,
        CartRepository {
  const HttpCustomerServices(this.api);
  final CustomerApiClient api;

  @override
  Future<List<FavoriteView>> listFavorites() async =>
      objectItems(await api.get('/api/v1/favorites'))
          .map(FavoriteView.fromJson)
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false);

  @override
  Future<void> saveFavorite({
    required String menuItemId,
    required String label,
  }) async {
    final restaurantId = await _restaurantId();
    await api.post(
      '/api/v1/favorites',
      body: {
        'restaurantId': restaurantId,
        'menuItemId': menuItemId,
        'label': label,
      },
    );
  }

  @override
  Future<void> addToCart(String id) async {
    await api.post(
      '/api/v1/favorites/${Uri.encodeComponent(id)}/cart',
      body: const {'quantity': 1},
    );
  }

  @override
  Future<void> removeFavorite(String id) async {
    await api.delete('/api/v1/favorites/${Uri.encodeComponent(id)}');
  }

  @override
  Future<RewardsSnapshot> loadRewards() async {
    final balanceMap = objectMap(await api.get('/api/v1/loyalty/balance'));
    final history = objectItems(await api.get('/api/v1/loyalty/history'))
        .map((value) {
          final map = objectMap(value);
          return RewardView(
            title: _text(map, const [
              'description',
              'reason',
              'type',
            ], 'Reward activity'),
            subtitle: _text(map, const ['createdAt', 'date']),
            points: _number(map, const ['points', 'amount']),
          );
        })
        .toList(growable: false);
    return RewardsSnapshot(
      balance: _number(balanceMap, const [
        'balance',
        'points',
        'availablePoints',
      ]),
      history: history,
    );
  }

  @override
  Future<void> redeem({required String orderId, required int points}) async {
    await api.post(
      '/api/v1/loyalty/redeem',
      body: {'orderId': orderId, 'points': points},
    );
  }

  @override
  Future<List<NotificationView>> listNotifications() async => objectItems(
        await api.get('/api/v1/notifications'),
      )
      .map((value) {
        final map = objectMap(value);
        return NotificationView(
          id: _text(map, const ['id']),
          title: _text(map, const ['title', 'subject'], 'Update'),
          body: _text(map, const ['body', 'message']),
          read: _flag(map, const ['read', 'isRead']) || map['readAt'] != null,
        );
      })
      .where((item) => item.id.isNotEmpty)
      .toList(growable: false);
  @override
  Future<void> markRead(String id) async {
    await api.patch('/api/v1/notifications/${Uri.encodeComponent(id)}/read');
  }

  @override
  Future<Map<String, bool>> preferences() async {
    final map = objectMap(
      await api.get('/api/v1/notifications/preferences/me'),
    );
    return {
      for (final entry in map.entries)
        if (entry.value is bool) entry.key: entry.value as bool,
    };
  }

  @override
  Future<void> updatePreferences(Map<String, bool> values) async {
    await api.patch('/api/v1/notifications/preferences/me', body: values);
  }

  @override
  Future<List<SupportTicketView>> listTickets() async => objectItems(
    await api.get('/api/v1/support/tickets'),
  ).map(_ticket).where((item) => item.id.isNotEmpty).toList(growable: false);
  SupportTicketView _ticket(Object? value) {
    final map = objectMap(value);
    return SupportTicketView(
      id: _text(map, const ['id']),
      subject: _text(map, const ['subject', 'title'], 'Support request'),
      status: _text(map, const ['status'], 'open'),
      preview: _text(map, const ['lastMessage', 'description', 'message']),
    );
  }

  @override
  Future<SupportTicketView> create({
    required String category,
    required String subject,
    required String message,
  }) async => _ticket(
    await api.post(
      '/api/v1/support/tickets',
      body: {'category': category, 'subject': subject, 'message': message},
    ),
  );
  @override
  Future<List<String>> messages(String id) async => objectItems(
        await api.get(
          '/api/v1/support/tickets/${Uri.encodeComponent(id)}/messages',
        ),
      )
      .map(
        (value) =>
            _text(objectMap(value), const ['message', 'body', 'content']),
      )
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  @override
  Future<void> sendMessage(String id, String message) async {
    await api.post(
      '/api/v1/support/tickets/${Uri.encodeComponent(id)}/messages',
      body: {'body': message},
    );
  }

  @override
  Future<List<FaqView>> listFaq({String? search}) async => objectItems(
        await api.get(
          '/api/v1/faq',
          query: {
            if (search != null && search.trim().isNotEmpty)
              'search': search.trim(),
          },
        ),
      )
      .map((value) {
        final map = objectMap(value);
        return FaqView(
          question: _text(map, const ['question', 'title']),
          answer: _text(map, const ['answer', 'content']),
          category: _text(map, const ['category', 'categoryName']),
        );
      })
      .where((item) => item.question.isNotEmpty)
      .toList(growable: false);

  @override
  Future<List<PaymentMethodView>> listPaymentMethods() async =>
      objectItems(await api.get('/api/v1/payments/methods'))
          .map((value) {
            final map = objectMap(value);
            final brand = _text(map, const [
              'cardBrand',
              'paymentMethodType',
            ], 'Card');
            final last4 = _text(map, const ['cardLast4']);
            final month = _text(map, const ['expMonth']);
            final year = _text(map, const ['expYear']);
            return PaymentMethodView(
              id: _text(map, const ['id']),
              label: last4.isEmpty ? brand : '$brand •••• $last4',
              expiry: month.isEmpty ? '' : '$month/$year',
              isDefault: _flag(map, const ['isDefault', 'default']),
            );
          })
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false);
  @override
  Future<void> makeDefault(String id) async {
    await api.patch(
      '/api/v1/payments/methods/${Uri.encodeComponent(id)}/default',
    );
  }

  @override
  Future<void> removePaymentMethod(String id) async {
    await api.delete('/api/v1/payments/methods/${Uri.encodeComponent(id)}');
  }

  Future<String> _restaurantId() async {
    final response = objectMap(await api.get('/api/v1/restaurant'));
    final restaurant = objectMap(
      response['restaurant'] ?? response['data'] ?? response,
    );
    final id = _text(restaurant, const ['id']);
    if (id.isEmpty) {
      throw const CustomerApiException(
        kind: 'contract',
        message: 'Restaurant ordering is not configured.',
      );
    }
    return id;
  }

  @override
  Future<CartSnapshot> loadCart() async {
    final restaurantId = await _restaurantId();
    final map = objectMap(
      await api.get('/api/v1/cart', query: {'restaurantId': restaurantId}),
    );
    final cart = objectMap(map['cart']);
    final lines = objectItems(map['items'])
        .map((value) {
          final line = objectMap(value);
          return CartLineView(
            id: _text(line, const ['id']),
            name: _text(line, const ['itemNameSnapshot'], 'Menu item'),
            quantity: _number(line, const ['quantity']),
            totalMinor: _number(line, const ['lineTotalMinor']),
          );
        })
        .where((line) => line.id.isNotEmpty)
        .toList(growable: false);
    return CartSnapshot(
      id: _text(cart, const ['id']),
      restaurantId: restaurantId,
      lines: lines,
      totalMinor: _number(map, const ['subtotalMinor']),
      currency: 'EUR',
    );
  }

  @override
  Future<void> clear() async {
    final restaurantId = await _restaurantId();
    await api.delete('/api/v1/cart', query: {'restaurantId': restaurantId});
  }

  @override
  Future<void> updateLine(String id, int quantity) async {
    await api.patch(
      '/api/v1/cart/items/${Uri.encodeComponent(id)}',
      body: {'quantity': quantity},
    );
  }

  @override
  Future<void> removeLine(String id) async {
    await api.delete('/api/v1/cart/items/${Uri.encodeComponent(id)}');
  }

  @override
  Future<Map<String, Object?>> checkout({
    required String cartId,
    required String orderType,
    String? deliveryAddressId,
    required String paymentMethod,
    String? scheduledFor,
    required String idempotencyKey,
  }) async => objectMap(
    await api.post(
      '/api/v1/checkout',
      body: {
        'cartId': cartId,
        'orderType': orderType,
        if (deliveryAddressId != null) 'deliveryAddressId': deliveryAddressId,
        'paymentMethod': paymentMethod,
        if (scheduledFor != null) 'scheduledFor': scheduledFor,
        'idempotencyKey': idempotencyKey,
      },
    ),
  );
  @override
  Future<CartSnapshot> reorder(String orderId) async {
    await api.post('/api/v1/orders/me/${Uri.encodeComponent(orderId)}/reorder');
    return loadCart();
  }
}
