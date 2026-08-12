import 'package:flutter/material.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

/// Dispatch console that keeps delivery mutations explicit and traceable.
class DeliveryDispatchPage extends StatefulWidget {
  const DeliveryDispatchPage({super.key, required this.api});
  final AdminApiClient api;

  @override
  State<DeliveryDispatchPage> createState() => _DeliveryDispatchPageState();
}

class _DeliveryDispatchPageState extends State<DeliveryDispatchPage> {
  Map<String, Object?>? _assignment;
  Map<String, Object?>? _tracking;
  List<Map<String, dynamic>> _orders = const [];
  List<Map<String, dynamic>> _drivers = const [];
  String? _selectedOrderId;
  String? _selectedDriverUserId;
  String? _error;
  var _loading = false;
  var _boardLoading = true;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _loadBoard();
  }

  Future<void> _loadBoard() async {
    setState(() {
      _boardLoading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object?>([
        widget.api.get(AdminApiRoutes.dispatchBoard),
        widget.api.get(AdminApiRoutes.drivers),
      ]);
      final orders = _list(values[0]);
      final drivers = _list(values[1]);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _drivers = drivers;
        if (_selectedOrderId == null ||
            !orders.any((row) => row['id']?.toString() == _selectedOrderId)) {
          _selectedOrderId = orders.firstOrNull?['id']?.toString();
        }
        if (_selectedDriverUserId == null ||
            !drivers.any(
              (row) =>
                  row['userId']?.toString() == _selectedDriverUserId &&
                  row['isActive'] == true,
            )) {
          _selectedDriverUserId =
              drivers
                  .where((row) => row['isActive'] == true)
                  .firstOrNull?['userId']
                  ?.toString();
        }
      });
      await _loadSelection();
    } on AdminApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _boardLoading = false);
    }
  }

  Future<void> _loadSelection() async {
    final id = _selectedOrderId;
    if (id == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _assignment = null;
      _tracking = null;
    });
    try {
      final order = _orders.firstWhere((row) => row['id']?.toString() == id);
      final assignment = order['assignment'];
      if (assignment is! Map) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final values = await Future.wait<Object?>([
        widget.api.get(AdminApiRoutes.deliveryAssignment(id)),
        widget.api.get(AdminApiRoutes.deliveryTracking(id)),
      ]);
      if (mounted) {
        setState(() {
          _assignment = _map(values[0]);
          _tracking = _map(values[1]);
        });
      }
    } on AdminApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _assign() async {
    final orderId = _selectedOrderId;
    final driver = _selectedDriverUserId;
    if (orderId == null) {
      setState(() => _error = 'Seleziona un ordine pronto per la consegna.');
      return;
    }
    if (driver == null) {
      setState(() => _error = 'Crea o attiva un driver prima di assegnare.');
      return;
    }
    await _mutate(
      () => widget.api.post(
        AdminApiRoutes.deliveryAssign(orderId),
        body: {'driverUserId': driver},
      ),
    );
  }

  Future<void> _transition(String status) => _mutate(
    () => widget.api.patch(
      AdminApiRoutes.deliveryStatus(_selectedOrderId!),
      body: {'status': status},
    ),
  );

  Future<void> _mutate(Future<Object?> Function() action) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action();
      await _loadBoard();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Consegna aggiornata.')));
      }
    } on AdminApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Consegne',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontFamily: 'Lora',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        const Text('Assegna il driver e verifica il percorso della consegna.'),
        const SizedBox(height: 20),
        if (_boardLoading)
          const LinearProgressIndicator()
        else if (_orders.isEmpty)
          const _DispatchNotice(
            message: 'Non ci sono ordini di consegna pronti o in corso.',
          )
        else
          _DispatchSelectors(
            orders: _orders,
            drivers: _drivers,
            selectedOrderId: _selectedOrderId,
            selectedDriverUserId: _selectedDriverUserId,
            saving: _saving,
            onOrderChanged: (value) {
              setState(() => _selectedOrderId = value);
              _loadSelection();
            },
            onDriverChanged:
                (value) => setState(() => _selectedDriverUserId = value),
            onAssign: _assign,
          ),
        const SizedBox(height: 16),
        if (_loading)
          const Card(
            child: SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_error != null)
          _DispatchNotice(message: _error!, error: true)
        else if (_assignment == null && _tracking == null)
          const _DispatchNotice(
            message:
                'Cerca un ordine pronto per controllare o avviare la consegna.',
          )
        else
          _DeliveryStatus(
            assignment: _assignment,
            tracking: _tracking,
            driverName: _selectedDriverName,
            saving: _saving,
            onTransition: _transition,
          ),
      ],
    ),
  );

  String? get _selectedDriverName {
    final assignedUserId = _assignment?['driverUserId']?.toString();
    if (assignedUserId == null) return null;
    for (final driver in _drivers) {
      if (driver['userId']?.toString() == assignedUserId) {
        final user = driver['user'];
        if (user is Map &&
            user['fullName']?.toString().trim().isNotEmpty == true) {
          return user['fullName'].toString();
        }
        return driver['fullName']?.toString();
      }
    }
    return 'Driver assegnato';
  }
}

class _DispatchSelectors extends StatelessWidget {
  const _DispatchSelectors({
    required this.orders,
    required this.drivers,
    required this.selectedOrderId,
    required this.selectedDriverUserId,
    required this.saving,
    required this.onOrderChanged,
    required this.onDriverChanged,
    required this.onAssign,
  });

  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> drivers;
  final String? selectedOrderId;
  final String? selectedDriverUserId;
  final bool saving;
  final ValueChanged<String?> onOrderChanged;
  final ValueChanged<String?> onDriverChanged;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final activeDrivers = drivers.where((row) => row['isActive'] == true);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: 420,
              child: DropdownButtonFormField<String>(
                value: selectedOrderId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ordine da consegnare',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                ),
                items: [
                  for (final order in orders)
                    DropdownMenuItem(
                      value: order['id']?.toString(),
                      child: Text(
                        '${order['orderNumber'] ?? 'Ordine'} · ${_orderStatusLabel(order['status']?.toString())}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: saving ? null : onOrderChanged,
              ),
            ),
            SizedBox(
              width: 420,
              child: DropdownButtonFormField<String>(
                value:
                    activeDrivers.any(
                          (row) =>
                              row['userId']?.toString() == selectedDriverUserId,
                        )
                        ? selectedDriverUserId
                        : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Driver disponibile',
                  prefixIcon: Icon(Icons.delivery_dining_outlined),
                ),
                items: [
                  for (final driver in activeDrivers)
                    DropdownMenuItem(
                      value: driver['userId']?.toString(),
                      child: Text(
                        '${driver['fullName'] ?? 'Driver'}${driver['employeeCode'] == null ? '' : ' · ${driver['employeeCode']}'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: saving ? null : onDriverChanged,
              ),
            ),
            FilledButton.icon(
              onPressed:
                  saving || selectedOrderId == null || activeDrivers.isEmpty
                      ? null
                      : onAssign,
              icon: const Icon(Icons.assignment_ind_outlined),
              label: const Text('Assegna driver'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryStatus extends StatelessWidget {
  const _DeliveryStatus({
    required this.assignment,
    required this.tracking,
    required this.driverName,
    required this.saving,
    required this.onTransition,
  });

  final Map<String, Object?>? assignment;
  final Map<String, Object?>? tracking;
  final String? driverName;
  final bool saving;
  final ValueChanged<String> onTransition;

  @override
  Widget build(BuildContext context) {
    final status =
        _text(assignment?['status']) ??
        _text(tracking?['status']) ??
        'assigned';
    final next = _transitions[status] ?? const <String>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stato consegna',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                Chip(label: Text(_deliveryLabel(status))),
                if (driverName case final driver?)
                  Chip(label: Text('Driver: $driver')),
                if (_text(tracking?['updatedAt']) case final updated?)
                  Chip(label: Text('Aggiornato: $updated')),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Passaggi consentiti',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (next.isEmpty)
              const Text('Non sono disponibili ulteriori passaggi.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    next
                        .map(
                          (value) => FilledButton.tonal(
                            onPressed:
                                saving ? null : () => onTransition(value),
                            child: Text(_deliveryLabel(value)),
                          ),
                        )
                        .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _DispatchNotice extends StatelessWidget {
  const _DispatchNotice({required this.message, this.error = false});
  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.info_outline_rounded,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

Map<String, Object?>? _map(Object? value) =>
    value is Map ? Map<String, Object?>.from(value) : null;

String? _text(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

const _transitions = <String, List<String>>{
  'assigned': ['accepted', 'cancelled'],
  'accepted': ['picked_up', 'failed', 'cancelled'],
  'picked_up': ['en_route'],
  'en_route': ['arriving', 'delivered', 'failed'],
  'arriving': ['delivered', 'failed'],
};

String _deliveryLabel(String status) => switch (status) {
  'assigned' => 'Assegnato',
  'accepted' => 'Accettato',
  'picked_up' => 'Ritirato',
  'en_route' => 'In arrivo',
  'arriving' => 'Quasi arrivato',
  'delivered' => 'Consegnato',
  'failed' => 'Non riuscito',
  'cancelled' => 'Annullato',
  _ => status,
};

String _orderStatusLabel(String? status) => switch (status) {
  'ready' => 'Pronto',
  'driver_assigned' => 'Driver assegnato',
  'out_for_delivery' => 'In consegna',
  _ => status ?? 'Da gestire',
};

List<Map<String, dynamic>> _list(Object? value) {
  final raw = value is Map ? value['items'] ?? value['data'] : value;
  return raw is List
      ? raw
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList()
      : const [];
}
