import 'package:flutter_test/flutter_test.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';
import 'package:la_favola_admin/features/pos/application/pos_controller.dart';
import 'package:la_favola_admin/features/pos/data/pos_repository.dart';
import 'package:la_favola_admin/features/pos/domain/pos_models.dart';

void main() {
  test(
    'POS keeps one order and reuses collection idempotency after timeout',
    () async {
      final repository = _FakePosRepository();
      final controller = PosController(repository);
      controller.add(
        PosCartLine(
          key: 'line-1',
          item: const PosMenuItem(
            id: 'item-1',
            categoryId: 'category-1',
            name: 'Margherita',
            description: null,
            sizes: [],
            optionGroups: [],
          ),
          size: const PosMenuSize(
            id: 'size-1',
            name: 'Normale',
            priceMinor: 1000,
          ),
          quantity: 2,
          options: const [],
        ),
      );

      final first = await controller.checkout(
        orderType: 'takeaway',
        paymentMethod: 'cash',
      );

      expect(first, isNull);
      expect(repository.createCalls, 1);
      expect(controller.state.cart, isEmpty);
      expect(controller.state.pendingOrderId, 'order-1');
      expect(repository.collectionKeys, hasLength(1));

      final second = await controller.retryCollection();

      expect(second?.documentNumber, 'LF-R-1');
      expect(repository.createCalls, 1);
      expect(repository.collectionKeys, hasLength(2));
      expect(repository.collectionKeys[1], repository.collectionKeys[0]);
      expect(controller.state.pendingOrderId, isNull);
    },
  );
}

class _FakePosRepository implements PosRepository {
  var createCalls = 0;
  final collectionKeys = <String>[];

  @override
  Future<PosCatalog> catalog() async =>
      const PosCatalog(restaurantId: 'restaurant-1', categories: [], items: []);

  @override
  Future<Map<String, dynamic>> createOrder(Map<String, Object?> body) async {
    createCalls += 1;
    return {
      'order': {'id': 'order-1'},
    };
  }

  @override
  Future<PrintableReceipt> collect({
    required String orderId,
    required String paymentMethod,
    required String idempotencyKey,
  }) async {
    collectionKeys.add(idempotencyKey);
    if (collectionKeys.length == 1) {
      throw const AdminApiException('timeout');
    }
    return _receipt;
  }

  @override
  Future<PrintableReceipt> receipt(String orderId) async => _receipt;

  @override
  Future<List<Map<String, dynamic>>> receipts({int page = 1}) async => const [];
}

final _receipt = PrintableReceipt(
  documentType: 'payment_receipt',
  documentNumber: 'LF-R-1',
  issuedAt: DateTime(2026, 8, 11),
  fiscalNotice: 'COPIA DI CORTESIA - NON FISCALE',
  restaurant: const {'name': 'La Favola'},
  order: const {'grandTotalMinor': 2000},
  items: const [],
);
