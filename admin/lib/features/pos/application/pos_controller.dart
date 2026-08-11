import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';
import 'package:la_favola_admin/features/pos/data/pos_repository.dart';
import 'package:la_favola_admin/features/pos/domain/pos_models.dart';
import 'package:uuid/uuid.dart';

class PosState {
  const PosState({
    this.catalog,
    this.cart = const [],
    this.loading = false,
    this.submitting = false,
    this.error,
    this.pendingOrderId,
    this.pendingPaymentMethod,
    this.pendingCollectionKey,
    this.receipt,
  });
  final PosCatalog? catalog;
  final List<PosCartLine> cart;
  final bool loading;
  final bool submitting;
  final String? error;
  final String? pendingOrderId;
  final String? pendingPaymentMethod;
  final String? pendingCollectionKey;
  final PrintableReceipt? receipt;

  int get estimatedTotalMinor =>
      cart.fold(0, (sum, line) => sum + line.lineTotalMinor);

  PosState copyWith({
    PosCatalog? catalog,
    List<PosCartLine>? cart,
    bool? loading,
    bool? submitting,
    String? error,
    bool clearError = false,
    String? pendingOrderId,
    String? pendingPaymentMethod,
    String? pendingCollectionKey,
    bool clearPending = false,
    PrintableReceipt? receipt,
    bool clearReceipt = false,
  }) => PosState(
    catalog: catalog ?? this.catalog,
    cart: cart ?? this.cart,
    loading: loading ?? this.loading,
    submitting: submitting ?? this.submitting,
    error: clearError ? null : error ?? this.error,
    pendingOrderId: clearPending ? null : pendingOrderId ?? this.pendingOrderId,
    pendingPaymentMethod:
        clearPending ? null : pendingPaymentMethod ?? this.pendingPaymentMethod,
    pendingCollectionKey:
        clearPending ? null : pendingCollectionKey ?? this.pendingCollectionKey,
    receipt: clearReceipt ? null : receipt ?? this.receipt,
  );
}

class PosController extends StateNotifier<PosState> {
  PosController(this._repository) : super(const PosState());
  final PosRepository _repository;

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      state = state.copyWith(catalog: await _repository.catalog());
    } on AdminApiException catch (error) {
      state = state.copyWith(error: error.message);
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  void add(PosCartLine line) {
    state = state.copyWith(cart: [...state.cart, line], clearError: true);
  }

  void changeQuantity(String key, int quantity) {
    if (quantity < 1) return remove(key);
    state = state.copyWith(
      cart: [
        for (final line in state.cart)
          if (line.key == key) line.copyWith(quantity: quantity) else line,
      ],
    );
  }

  void remove(String key) {
    state = state.copyWith(
      cart: state.cart.where((line) => line.key != key).toList(),
    );
  }

  Future<PrintableReceipt?> checkout({
    required String orderType,
    String? tableLabel,
    String? customerName,
    String? customerPhone,
    String? customerNote,
    required String paymentMethod,
  }) async {
    if (state.cart.isEmpty) {
      state = state.copyWith(error: 'Aggiungi almeno un prodotto.');
      return null;
    }
    state = state.copyWith(
      submitting: true,
      clearError: true,
      clearReceipt: true,
    );
    try {
      final creationKey = const Uuid().v4();
      final response = await _repository.createOrder({
        'orderType': orderType,
        if (tableLabel?.trim().isNotEmpty == true)
          'tableLabel': tableLabel!.trim(),
        if (customerName?.trim().isNotEmpty == true)
          'customerName': customerName!.trim(),
        if (customerPhone?.trim().isNotEmpty == true)
          'customerPhone': customerPhone!.trim(),
        if (customerNote?.trim().isNotEmpty == true)
          'customerNote': customerNote!.trim(),
        'paymentMethod': paymentMethod,
        'idempotencyKey': creationKey,
        'items': [for (final line in state.cart) line.toRequest()],
      });
      final order = response['order'];
      final orderId = order is Map ? order['id']?.toString() : null;
      if (orderId == null || orderId.isEmpty) {
        throw const AdminApiException('Ordine creato senza identificativo.');
      }
      state = state.copyWith(
        cart: const [],
        pendingOrderId: orderId,
        pendingPaymentMethod: paymentMethod,
        pendingCollectionKey: const Uuid().v4(),
      );
      return retryCollection();
    } on AdminApiException catch (error) {
      state = state.copyWith(error: error.message);
      return null;
    } finally {
      state = state.copyWith(submitting: false);
    }
  }

  Future<PrintableReceipt?> retryCollection() async {
    final orderId = state.pendingOrderId;
    final paymentMethod = state.pendingPaymentMethod;
    final collectionKey = state.pendingCollectionKey;
    if (orderId == null || paymentMethod == null || collectionKey == null) {
      return null;
    }
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final receipt = await _repository.collect(
        orderId: orderId,
        paymentMethod: paymentMethod,
        idempotencyKey: collectionKey,
      );
      state = state.copyWith(
        receipt: receipt,
        clearPending: true,
        clearError: true,
      );
      return receipt;
    } on AdminApiException catch (error) {
      state = state.copyWith(
        error:
            'Ordine creato ma incasso non completato: ${error.message} '
            'Usa “Riprova incasso” senza ricreare l’ordine.',
      );
      return null;
    } finally {
      state = state.copyWith(submitting: false);
    }
  }
}
