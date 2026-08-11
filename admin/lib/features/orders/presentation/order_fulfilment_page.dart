import 'package:flutter/material.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';
import 'package:la_favola_admin/features/pos/domain/pos_models.dart';
import 'package:la_favola_admin/features/pos/presentation/pos_page.dart';
import 'package:uuid/uuid.dart';

/// Tablet-first queue and fulfilment workspace backed by the admin order APIs.
///
/// It deliberately permits only backend-valid state transitions. A detail is
/// fetched from the admin-owned endpoint before an order can be actioned.
class OrderFulfilmentPage extends StatefulWidget {
  const OrderFulfilmentPage({super.key, required this.api});

  final AdminApiClient api;

  @override
  State<OrderFulfilmentPage> createState() => _OrderFulfilmentPageState();
}

class _OrderFulfilmentPageState extends State<OrderFulfilmentPage> {
  static const _filters = <String?>[
    null,
    'placed',
    'accepted',
    'preparing',
    'baking',
    'packing',
    'ready',
    'driver_assigned',
    'out_for_delivery',
  ];

  List<Map<String, Object?>> _orders = const [];
  Map<String, Object?>? _detail;
  String? _selectedId;
  String? _filter;
  String? _error;
  var _loading = true;
  var _loadingDetail = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final value = await widget.api.get(
        AdminApiRoutes.orders,
        query: _filter == null ? null : {'status': _filter!},
      );
      if (!mounted) return;
      setState(() => _orders = _list(value));
    } on AdminApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Non è stato possibile caricare gli ordini.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(Map<String, Object?> item) async {
    final id = _string(item['id']);
    if (id == null) return;
    setState(() {
      _selectedId = id;
      _detail = null;
      _loadingDetail = true;
      _error = null;
    });
    try {
      final value = await widget.api.get(AdminApiRoutes.orderDetail(id));
      if (!mounted || _selectedId != id) return;
      setState(() => _detail = _map(value));
    } on AdminApiException catch (error) {
      if (mounted && _selectedId == id) setState(() => _error = error.message);
    } catch (_) {
      if (mounted && _selectedId == id) {
        setState(() => _error = 'Dettaglio ordine non disponibile.');
      }
    } finally {
      if (mounted && _selectedId == id) setState(() => _loadingDetail = false);
    }
  }

  Future<void> _changeStatus(String next) async {
    final order = _map(_detail?['order']);
    final id = _string(order?['id']);
    if (id == null) return;
    final note = TextEditingController();
    final approved = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Conferma avanzamento'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vuoi aggiornare l’ordine a “${_statusLabel(next)}”?'),
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Nota operativa (facoltativa)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Conferma'),
              ),
            ],
          ),
    );
    final message = note.text.trim();
    note.dispose();
    if (approved != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.api.patch(
        AdminApiRoutes.orderStatus(id),
        body: {'status': next, if (message.isNotEmpty) 'note': message},
      );
      await _loadOrders();
      await _select({'id': id});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ordine aggiornato: ${_statusLabel(next)}')),
        );
      }
    } on AdminApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _collectPayment() async {
    final order = _map(_detail?['order']);
    final id = _string(order?['id']);
    final method = _string(order?['paymentMethod']);
    if (id == null || !{'cash', 'card_on_delivery'}.contains(method)) return;
    final approved = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Conferma incasso'),
            content: Text(
              method == 'cash'
                  ? 'Confermi di avere ricevuto il pagamento in contanti?'
                  : 'Confermi che il pagamento con terminale è stato completato?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Conferma incasso'),
              ),
            ],
          ),
    );
    if (approved != true || !mounted) return;
    final key = const Uuid().v4();
    setState(() => _saving = true);
    try {
      await widget.api.post(
        AdminApiRoutes.collectPayment(id),
        body: {
          'orderId': id,
          'paymentMethodType': method,
          'idempotencyKey': key,
        },
        idempotencyKey: key,
      );
      await _select({'id': id});
      if (mounted) _notice('Pagamento registrato correttamente.');
    } on AdminApiException catch (error) {
      if (mounted) _notice(error.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _requestRefund() async {
    final order = _map(_detail?['order']);
    final id = _string(order?['id']);
    if (id == null) return;
    final amount = TextEditingController(
      text: (_minor(order?['grandTotalMinor']) / 100).toStringAsFixed(2),
    );
    final reason = TextEditingController();
    final approved = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Richiedi rimborso'),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Importo EUR',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reason,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Motivo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Crea richiesta'),
              ),
            ],
          ),
    );
    final parsed = double.tryParse(amount.text.trim().replaceAll(',', '.'));
    final reasonText = reason.text.trim();
    amount.dispose();
    reason.dispose();
    if (approved != true ||
        parsed == null ||
        parsed <= 0 ||
        reasonText.isEmpty) {
      if (approved == true && mounted) {
        _notice('Inserisci un importo e un motivo validi.', error: true);
      }
      return;
    }
    final key = const Uuid().v4();
    setState(() => _saving = true);
    try {
      await widget.api.post(
        AdminApiRoutes.refunds,
        body: {
          'orderId': id,
          'amountMinor': (parsed * 100).round(),
          'reason': reasonText,
          'idempotencyKey': key,
        },
        idempotencyKey: key,
      );
      if (mounted) _notice('Richiesta di rimborso creata.');
    } on AdminApiException catch (error) {
      if (mounted) _notice(error.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _printReceipt() async {
    final order = _map(_detail?['order']);
    final id = _string(order?['id']);
    if (id == null) return;
    setState(() => _saving = true);
    try {
      final value = await widget.api.get(AdminApiRoutes.posReceipt(id));
      if (!mounted || value is! Map) return;
      await showPrintableReceiptDialog(
        context,
        PrintableReceipt.fromJson(Map<String, dynamic>.from(value)),
      );
    } on AdminApiException catch (error) {
      if (mounted) _notice(error.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _notice(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ordini',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontFamily: 'Lora',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text('Gestisci la coda e conferma ogni passaggio operativo.'),
            const SizedBox(height: 16),
            _OrderFilters(
              selected: _filter,
              filters: _filters,
              onChanged: (value) {
                setState(() {
                  _filter = value;
                  _selectedId = null;
                  _detail = null;
                });
                _loadOrders();
              },
              onRefresh: _loading ? null : _loadOrders,
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  wide
                      ? Row(
                        children: [
                          Expanded(flex: 4, child: _queue()),
                          const SizedBox(width: 16),
                          Expanded(flex: 6, child: _detailPanel()),
                        ],
                      )
                      : _MobileOrderView(
                        queue: _queue(),
                        detail: _detailPanel(),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _queue() => Card(
    child:
        _loading
            ? const _OrderLoading(label: 'Caricamento coda ordini…')
            : _error != null && _orders.isEmpty
            ? _OrderError(message: _error!, onRetry: _loadOrders)
            : _orders.isEmpty
            ? const _OrderEmpty(message: 'Non ci sono ordini in questa coda.')
            : ListView.separated(
              itemCount: _orders.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _orders[index];
                final selected = _string(item['id']) == _selectedId;
                return ListTile(
                  selected: selected,
                  selectedTileColor: const Color(0x1A774E32),
                  minTileHeight: 76,
                  title: Text(_string(item['orderNumber']) ?? 'Ordine'),
                  subtitle: Text(
                    '${_money(item['grandTotalMinor'], item['currency'])} · '
                    '${_string(item['orderType']) ?? 'ordine'}',
                  ),
                  trailing: _StatusChip(
                    status: _string(item['status']) ?? 'unknown',
                  ),
                  onTap: () => _select(item),
                );
              },
            ),
  );

  Widget _detailPanel() {
    if (_loadingDetail) {
      return const Card(child: _OrderLoading(label: 'Caricamento dettaglio…'));
    }
    if (_detail == null) {
      return Card(
        child:
            _error != null
                ? _OrderError(message: _error!, onRetry: _loadOrders)
                : const _OrderEmpty(
                  message:
                      'Seleziona un ordine per vedere righe, note e azioni.',
                ),
      );
    }
    final order = _map(_detail!['order']) ?? const <String, Object?>{};
    final status = _string(order['status']) ?? 'unknown';
    final paymentStatus = _string(order['paymentStatus']) ?? 'unknown';
    final paymentMethod = _string(order['paymentMethod']);
    final orderType = _string(order['orderType']);
    final next = [
      ...?_transitions[status],
      if (status == 'ready' &&
          {'pickup', 'dine_in', 'takeaway'}.contains(orderType))
        'closed',
    ];
    final items = _list(_detail!['items']);
    final history = _list(_detail!['statusHistory']);
    return Card(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _string(order['orderNumber']) ?? 'Ordine',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(_money(order['grandTotalMinor'], order['currency'])),
                ],
              ),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle('Azioni consentite'),
          const SizedBox(height: 8),
          if (next.isEmpty)
            const Text('Non sono disponibili ulteriori passaggi di stato.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  next
                      .map(
                        (value) => FilledButton.tonal(
                          onPressed:
                              _saving ? null : () => _changeStatus(value),
                          child: Text(_statusLabel(value)),
                        ),
                      )
                      .toList(),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                avatar: const Icon(Icons.payments_outlined, size: 18),
                label: Text('Pagamento: ${_paymentStatusLabel(paymentStatus)}'),
              ),
              if (paymentStatus != 'paid' &&
                  {'cash', 'card_on_delivery'}.contains(paymentMethod))
                FilledButton.icon(
                  onPressed: _saving ? null : _collectPayment,
                  icon: const Icon(Icons.point_of_sale_outlined),
                  label: const Text('Registra incasso'),
                ),
              if (paymentStatus == 'paid')
                OutlinedButton.icon(
                  onPressed: _saving ? null : _requestRefund,
                  icon: const Icon(Icons.currency_exchange_outlined),
                  label: const Text('Richiedi rimborso'),
                ),
              OutlinedButton.icon(
                onPressed: _saving ? null : _printReceipt,
                icon: const Icon(Icons.print_outlined),
                label: Text(
                  paymentStatus == 'paid'
                      ? 'Stampa ricevuta'
                      : 'Stampa comanda',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle('Righe ordine'),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('Nessuna riga disponibile.')
          else
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_string(item['itemNameSnapshot']) ?? 'Prodotto'),
                subtitle: Text('Quantità: ${item['quantity'] ?? '—'}'),
                trailing: Text(
                  _money(item['lineTotalMinor'], order['currency']),
                ),
              ),
            ),
          if (_string(order['customerNote']) case final note?) ...[
            const SizedBox(height: 16),
            _SectionTitle('Nota cliente'),
            const SizedBox(height: 6),
            Text(note),
          ],
          const SizedBox(height: 20),
          _SectionTitle('Cronologia'),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Text('Nessun evento di stato registrato.')
          else
            ...history.map(
              (event) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timeline_outlined),
                title: Text(
                  '${_statusLabel(_string(event['previousStatus']) ?? '—')} → '
                  '${_statusLabel(_string(event['newStatus']) ?? '—')}',
                ),
                subtitle: Text(_string(event['note']) ?? ''),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderFilters extends StatelessWidget {
  const _OrderFilters({
    required this.selected,
    required this.filters,
    required this.onChanged,
    required this.onRefresh,
  });

  final String? selected;
  final List<String?> filters;
  final ValueChanged<String?> onChanged;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      ...filters.map(
        (filter) => FilterChip(
          label: Text(filter == null ? 'Tutti' : _statusLabel(filter)),
          selected: selected == filter,
          onSelected: (_) => onChanged(filter),
        ),
      ),
      IconButton(
        tooltip: 'Aggiorna coda',
        onPressed: onRefresh == null ? null : () => onRefresh!(),
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  );
}

class _MobileOrderView extends StatelessWidget {
  const _MobileOrderView({required this.queue, required this.detail});
  final Widget queue;
  final Widget detail;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Column(
      children: [
        const TabBar(tabs: [Tab(text: 'Coda'), Tab(text: 'Dettaglio')]),
        const SizedBox(height: 12),
        Expanded(child: TabBarView(children: [queue, detail])),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(_statusIcon(status), size: 18),
    label: Text(_statusLabel(status)),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);
  final String value;

  @override
  Widget build(BuildContext context) =>
      Text(value, style: Theme.of(context).textTheme.titleMedium);
}

class _OrderLoading extends StatelessWidget {
  const _OrderLoading({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      liveRegion: true,
      label: label,
      child: const CircularProgressIndicator(),
    ),
  );
}

class _OrderEmpty extends StatelessWidget {
  const _OrderEmpty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
  );
}

class _OrderError extends StatelessWidget {
  const _OrderError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 36),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Riprova'),
          ),
        ],
      ),
    ),
  );
}

List<Map<String, Object?>> _list(Object? value) {
  final source = value is Map ? value['items'] ?? value['data'] : value;
  if (source is! List) return const [];
  return source
      .whereType<Map>()
      .map((item) => Map<String, Object?>.from(item))
      .toList(growable: false);
}

Map<String, Object?>? _map(Object? value) =>
    value is Map ? Map<String, Object?>.from(value) : null;

String? _string(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

String _money(Object? minor, Object? currency) {
  final value =
      minor is num ? minor.toInt() : int.tryParse('${minor ?? 0}') ?? 0;
  final code = _string(currency) ?? 'EUR';
  return '${(value / 100).toStringAsFixed(2)} $code';
}

const _transitions = <String, List<String>>{
  'pending_payment': ['placed', 'cancelled'],
  'placed': ['accepted', 'rejected', 'cancelled'],
  'accepted': ['preparing', 'cancelled'],
  'preparing': ['baking', 'cancelled'],
  'baking': ['packing'],
  'packing': ['ready'],
  'ready': ['driver_assigned', 'out_for_delivery'],
  'driver_assigned': ['out_for_delivery'],
  'out_for_delivery': ['delivered'],
  'delivered': ['closed'],
};

String _statusLabel(String status) => switch (status) {
  'pending_payment' => 'In attesa pagamento',
  'placed' => 'Ricevuto',
  'accepted' => 'Accettato',
  'preparing' => 'In preparazione',
  'baking' => 'In cottura',
  'packing' => 'In confezionamento',
  'ready' => 'Pronto',
  'driver_assigned' => 'Driver assegnato',
  'out_for_delivery' => 'In consegna',
  'delivered' => 'Consegnato',
  'closed' => 'Chiuso',
  'cancelled' => 'Annullato',
  'rejected' => 'Rifiutato',
  _ => status,
};

String _paymentStatusLabel(String status) => switch (status) {
  'paid' => 'Pagato',
  'pending' || 'pending_payment' || 'collection_pending' => 'Da incassare',
  'partially_refunded' => 'Rimborsato in parte',
  'refunded' => 'Rimborsato',
  'failed' => 'Fallito',
  _ => status,
};

int _minor(Object? value) => switch (value) {
  int number => number,
  num number => number.round(),
  String text => int.tryParse(text) ?? 0,
  _ => 0,
};

IconData _statusIcon(String status) => switch (status) {
  'cancelled' || 'rejected' => Icons.cancel_outlined,
  'closed' || 'delivered' => Icons.check_circle_outline,
  'out_for_delivery' || 'driver_assigned' => Icons.delivery_dining_outlined,
  _ => Icons.schedule_outlined,
};
