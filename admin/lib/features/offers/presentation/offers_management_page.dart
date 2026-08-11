import 'package:flutter/material.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

/// Promotions and coupons use the same lifecycle: list, create, update,
/// deactivate/archive. The editor only sends values accepted by the OpenAPI
/// contract and never applies an offer to a customer order from the tablet.
class OffersManagementPage extends StatefulWidget {
  const OffersManagementPage({super.key, required this.api});
  final AdminApiClient api;

  @override
  State<OffersManagementPage> createState() => _OffersManagementPageState();
}

class _OffersManagementPageState extends State<OffersManagementPage> {
  final _search = TextEditingController();
  String _kind = 'promotions';
  String? _restaurantId;
  List<Map<String, dynamic>> _promotions = const [];
  List<Map<String, dynamic>> _coupons = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await Future.wait<Object?>([
        widget.api.get(AdminApiRoutes.restaurant),
        widget.api.get(AdminApiRoutes.promotions),
        widget.api.get(AdminApiRoutes.coupons),
      ]);
      if (!mounted) return;
      setState(() {
        _restaurantId = _object(response[0])['id']?.toString();
        _promotions = _objects(response[1]);
        _coupons = _objects(response[2]);
      });
    } on AdminApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Non è stato possibile caricare le offerte.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _rows {
    final source = _kind == 'promotions' ? _promotions : _coupons;
    final term = _search.text.trim().toLowerCase();
    return term.isEmpty
        ? source
        : source
            .where(
              (row) =>
                  '${row['name'] ?? ''} ${row['code'] ?? ''} ${row['description'] ?? ''}'
                      .toLowerCase()
                      .contains(term),
            )
            .toList();
  }

  Future<void> _edit([Map<String, dynamic>? item]) async {
    if (_restaurantId == null) {
      _notify('Ristorante non disponibile. Ricarica e riprova.', error: true);
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      builder:
          (_) => _OfferEditor(
            api: widget.api,
            promotion: _kind == 'promotions',
            restaurantId: _restaurantId!,
            existing: item,
          ),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              _kind == 'promotions' ? 'Elimina promozione' : 'Elimina coupon',
            ),
            content: const Text(
              'Questa azione interrompe definitivamente l’uso dell’offerta.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Elimina'),
              ),
            ],
          ),
    );
    if (accepted != true) return;
    setState(() => _saving = true);
    try {
      await widget.api.delete(
        _kind == 'promotions'
            ? AdminApiRoutes.promotion(id)
            : AdminApiRoutes.coupon(id),
      );
      if (mounted) _notify('Offerta eliminata.');
      await _load();
    } on AdminApiException catch (error) {
      if (mounted) _notify(error.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _notify(String text, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: error ? Theme.of(context).colorScheme.error : null,
          content: Text(text),
        ),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Offerte', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Promozioni e coupon con date, sconti e stato di attivazione.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'promotions',
                icon: Icon(Icons.campaign_outlined),
                label: Text('Promozioni'),
              ),
              ButtonSegment(
                value: 'coupons',
                icon: Icon(Icons.confirmation_number_outlined),
                label: Text('Coupon'),
              ),
            ],
            selected: {_kind},
            onSelectionChanged:
                _saving ? null : (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Cerca un’offerta',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _loading || _saving ? null : () => _edit(),
                  icon: const Icon(Icons.add),
                  label: Text(
                    _kind == 'promotions' ? 'Nuova promozione' : 'Nuovo coupon',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _body()),
        ],
      ),
    ),
  );

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: FilledButton(onPressed: _load, child: Text('Riprova: $_error')),
      );
    }
    if (_rows.isEmpty) {
      return const Center(child: Text('Nessuna offerta da mostrare.'));
    }
    return ListView.separated(
      itemCount: _rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final row = _rows[index];
        final active = row['isActive'] != false;
        final discount = row['discountValue'];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              child: Icon(
                _kind == 'promotions'
                    ? Icons.campaign_outlined
                    : Icons.confirmation_number_outlined,
              ),
            ),
            title: Text(
              _kind == 'promotions'
                  ? row['name']?.toString() ?? 'Promozione'
                  : row['code']?.toString() ?? 'Coupon',
            ),
            subtitle: Text(
              '${row['discountType'] ?? row['promotionType'] ?? 'sconto'}${discount == null ? '' : ' · $discount'}${row['expiresAt'] ?? row['endsAt'] == null ? '' : ' · Scade ${_date(row['expiresAt'] ?? row['endsAt'])}'}',
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                Chip(label: Text(active ? 'Attivo' : 'Disattivo')),
                IconButton(
                  tooltip: 'Modifica',
                  onPressed: _saving ? null : () => _edit(row),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Elimina',
                  onPressed: _saving ? null : () => _delete(row),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OfferEditor extends StatefulWidget {
  const _OfferEditor({
    required this.api,
    required this.promotion,
    required this.restaurantId,
    this.existing,
  });
  final AdminApiClient api;
  final bool promotion;
  final String restaurantId;
  final Map<String, dynamic>? existing;
  @override
  State<_OfferEditor> createState() => _OfferEditorState();
}

class _OfferEditorState extends State<_OfferEditor> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _description;
  late final TextEditingController _value;
  late final TextEditingController _start;
  late final TextEditingController _end;
  late final TextEditingController _minimum;
  String _type = 'percentage';
  bool _active = true;
  bool _automatic = false;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final row = widget.existing ?? const <String, dynamic>{};
    _name = TextEditingController(text: row['name']?.toString() ?? '');
    _code = TextEditingController(text: row['code']?.toString() ?? '');
    _description = TextEditingController(
      text: row['description']?.toString() ?? '',
    );
    _value = TextEditingController(
      text: row['discountValue']?.toString() ?? '',
    );
    _start = TextEditingController(
      text: _iso(row['startsAt']) ?? DateTime.now().toUtc().toIso8601String(),
    );
    _end = TextEditingController(
      text: _iso(row['endsAt'] ?? row['expiresAt']) ?? '',
    );
    _minimum = TextEditingController(
      text: row['minOrderMinor']?.toString() ?? '',
    );
    _type =
        row['promotionType']?.toString() ??
        row['discountType']?.toString() ??
        'percentage';
    _active = row['isActive'] != false;
    _automatic = row['isAutomatic'] == true;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _code,
      _description,
      _value,
      _start,
      _end,
      _minimum,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    final id = widget.existing?['id']?.toString();
    final body = <String, Object?>{
      'description': _optional(_description),
      'discountValue': _number(_value),
      'minOrderMinor': _number(_minimum),
      'isActive': _active,
      if (widget.promotion) ...{
        'name': _name.text.trim(),
        'promotionType': _type,
        'startsAt': _start.text.trim(),
        'endsAt': _optional(_end),
        'isAutomatic': _automatic,
      } else ...{
        'code': _code.text.trim().toUpperCase(),
        'discountType': _type,
        'startsAt': _optional(_start),
        'expiresAt': _optional(_end),
      },
    };
    if (id == null) body['restaurantId'] = widget.restaurantId;
    try {
      if (id == null) {
        await widget.api.post(
          widget.promotion ? AdminApiRoutes.promotions : AdminApiRoutes.coupons,
          body: body,
        );
      } else {
        await widget.api.patch(
          widget.promotion
              ? AdminApiRoutes.promotion(id)
              : AdminApiRoutes.coupon(id),
          body: body,
        );
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on AdminApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.existing == null
          ? (widget.promotion ? 'Nuova promozione' : 'Nuovo coupon')
          : 'Modifica offerta',
    ),
    content: SizedBox(
      width: 560,
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.promotion)
                _field(_name, 'Nome', required: true)
              else
                _field(_code, 'Codice coupon', required: true),
              const SizedBox(height: 12),
              _field(_description, 'Descrizione'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Tipo sconto',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          const ['percentage', 'fixed_amount', 'free_delivery']
                              .map(
                                (v) =>
                                    DropdownMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                      onChanged:
                          _saving ? null : (v) => setState(() => _type = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(_value, 'Valore sconto', number: true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(_minimum, 'Ordine minimo (centesimi)', number: true),
              const SizedBox(height: 12),
              _field(
                _start,
                widget.promotion
                    ? 'Inizio ISO-8601'
                    : 'Inizio ISO-8601 (facoltativo)',
                required: widget.promotion,
              ),
              const SizedBox(height: 12),
              _field(_end, 'Fine ISO-8601 (facoltativo)'),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: _saving ? null : (v) => setState(() => _active = v),
                title: const Text('Attiva'),
              ),
              if (widget.promotion)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _automatic,
                  onChanged:
                      _saving ? null : (v) => setState(() => _automatic = v),
                  title: const Text('Applica automaticamente'),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Annulla'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Salvataggio…' : 'Salva'),
      ),
    ],
  );

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    bool number = false,
  }) => TextFormField(
    controller: c,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: (v) {
      final text = v?.trim() ?? '';
      if (required && text.isEmpty) {
        return 'Campo obbligatorio';
      }
      if (number && text.isNotEmpty && int.tryParse(text) == null) {
        return 'Numero non valido';
      }
      return null;
    },
  );
}

Map<String, dynamic> _object(Object? value) =>
    value is Map<String, dynamic> ? value : const {};
List<Map<String, dynamic>> _objects(Object? value) {
  final raw =
      value is Map<String, dynamic> ? value['items'] ?? value['data'] : value;
  return raw is List
      ? raw.whereType<Map>().map((v) => Map<String, dynamic>.from(v)).toList()
      : const [];
}

String? _optional(TextEditingController c) =>
    c.text.trim().isEmpty ? null : c.text.trim();
int? _number(TextEditingController c) =>
    c.text.trim().isEmpty ? null : int.tryParse(c.text.trim());
String? _iso(Object? value) => value?.toString();
String _date(Object? value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed == null
      ? value?.toString() ?? ''
      : '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}
