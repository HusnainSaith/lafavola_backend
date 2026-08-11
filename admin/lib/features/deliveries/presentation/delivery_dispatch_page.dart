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
  final _formKey = GlobalKey<FormState>();
  final _orderId = TextEditingController();
  final _driverId = TextEditingController();
  Map<String, Object?>? _assignment;
  Map<String, Object?>? _tracking;
  List<Map<String, dynamic>> _assignments = const [];
  String? _error;
  var _loading = false;
  var _boardLoading = true;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _loadBoard();
  }

  @override
  void dispose() {
    _orderId.dispose();
    _driverId.dispose();
    super.dispose();
  }

  Future<void> _loadBoard() async {
    setState(() {
      _boardLoading = true;
      _error = null;
    });
    try {
      final value = await widget.api.get(AdminApiRoutes.deliveriesAdmin);
      final data = value is Map ? value['data'] : value;
      final rows =
          data is List
              ? data
                  .whereType<Map>()
                  .map((row) => Map<String, dynamic>.from(row))
                  .toList()
              : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() => _assignments = rows);
      if (_orderId.text.isEmpty && rows.isNotEmpty) {
        _orderId.text = rows.first['orderId']?.toString() ?? '';
      }
    } on AdminApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _boardLoading = false);
    }
  }

  Future<void> _load() async {
    if (!_formKey.currentState!.validate()) return;
    final id = _orderId.text.trim();
    setState(() {
      _loading = true;
      _error = null;
      _assignment = null;
      _tracking = null;
    });
    try {
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
    if (!_formKey.currentState!.validate()) return;
    final driver = _driverId.text.trim();
    if (driver.isEmpty) {
      setState(() => _error = 'Inserisci l’ID del driver da assegnare.');
      return;
    }
    await _mutate(
      () => widget.api.post(
        AdminApiRoutes.deliveryAssign(_orderId.text.trim()),
        body: {'driverUserId': driver},
      ),
    );
  }

  Future<void> _transition(String status) => _mutate(
    () => widget.api.patch(
      AdminApiRoutes.deliveryStatus(_orderId.text.trim()),
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
      await _load();
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
        else if (_assignments.isEmpty)
          const _DispatchNotice(
            message:
                'Non ci sono consegne attive. Gli ordini pronti possono essere assegnati qui.',
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                value:
                    _assignments.any(
                          (row) => '${row['orderId']}' == _orderId.text,
                        )
                        ? _orderId.text
                        : null,
                decoration: const InputDecoration(labelText: 'Consegna attiva'),
                items: [
                  for (final row in _assignments)
                    DropdownMenuItem(
                      value: row['orderId']?.toString(),
                      child: Text(
                        '${(row['order'] as Map?)?['orderNumber'] ?? row['orderId']} · ${row['status'] ?? ''}',
                      ),
                    ),
                ],
                onChanged:
                    _saving
                        ? null
                        : (value) {
                          if (value == null) return;
                          _orderId.text = value;
                          _load();
                        },
              ),
            ),
          ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    width: 420,
                    child: TextFormField(
                      controller: _orderId,
                      autocorrect: false,
                      decoration: const InputDecoration(labelText: 'ID ordine'),
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Inserisci l’ID ordine.'
                                  : null,
                    ),
                  ),
                  SizedBox(
                    width: 420,
                    child: TextField(
                      controller: _driverId,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'ID utente driver',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _loading || _saving ? null : _load,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Verifica consegna'),
                  ),
                  FilledButton.icon(
                    onPressed: _loading || _saving ? null : _assign,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Assegna driver'),
                  ),
                ],
              ),
            ),
          ),
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
            saving: _saving,
            onTransition: _transition,
          ),
      ],
    ),
  );
}

class _DeliveryStatus extends StatelessWidget {
  const _DeliveryStatus({
    required this.assignment,
    required this.tracking,
    required this.saving,
    required this.onTransition,
  });

  final Map<String, Object?>? assignment;
  final Map<String, Object?>? tracking;
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
                if (_text(assignment?['driverUserId']) case final driver?)
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
