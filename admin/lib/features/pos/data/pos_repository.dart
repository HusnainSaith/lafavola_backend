import 'package:la_favola_admin/core/api/admin_api_client.dart';
import 'package:la_favola_admin/features/pos/domain/pos_models.dart';

class PosRepository {
  const PosRepository(this._api);
  final AdminApiClient _api;

  Future<PosCatalog> catalog() async =>
      PosCatalog.fromJson(_map(await _api.get(AdminApiRoutes.posCatalog)));

  Future<Map<String, dynamic>> createOrder(Map<String, Object?> body) async =>
      _map(
        await _api.post(
          AdminApiRoutes.posOrders,
          body: body,
          idempotencyKey: body['idempotencyKey']?.toString(),
        ),
      );

  Future<PrintableReceipt> collect({
    required String orderId,
    required String paymentMethod,
    required String idempotencyKey,
  }) async {
    final response = _map(
      await _api.post(
        AdminApiRoutes.posCollect(orderId),
        body: {
          'orderId': orderId,
          'paymentMethodType': paymentMethod,
          'idempotencyKey': idempotencyKey,
        },
        idempotencyKey: idempotencyKey,
      ),
    );
    return PrintableReceipt.fromJson(_map(response['receipt']));
  }

  Future<PrintableReceipt> receipt(String orderId) async =>
      PrintableReceipt.fromJson(
        _map(await _api.get(AdminApiRoutes.posReceipt(orderId))),
      );

  Future<List<Map<String, dynamic>>> receipts({int page = 1}) async {
    final response = _map(
      await _api.get(
        AdminApiRoutes.posReceipts,
        query: {'page': page, 'limit': 50},
      ),
    );
    final data = response['items'] ?? response['data'];
    return data is List ? data.whereType<Map>().map(_map).toList() : const [];
  }
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
