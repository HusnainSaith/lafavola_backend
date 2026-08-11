import 'package:flutter/material.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

/// Structured restaurant profile and weekly-hours editor. Each weekday is
/// individually upserted, matching the backend contract and avoiding an unsafe
/// bulk overwrite when a tablet has stale data.
class RestaurantSettingsPage extends StatefulWidget {
  const RestaurantSettingsPage({super.key, required this.api});
  final AdminApiClient api;

  @override
  State<RestaurantSettingsPage> createState() => _RestaurantSettingsPageState();
}

class _RestaurantSettingsPageState extends State<RestaurantSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _slug = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _deliveryMinutes = TextEditingController();
  final _deliveryFee = TextEditingController();
  final _minimumOrder = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<_BusinessDay> _hours = List.generate(7, _BusinessDay.empty);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _slug,
      _phone,
      _email,
      _address,
      _city,
      _deliveryMinutes,
      _deliveryFee,
      _minimumOrder,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait<Object?>([
        widget.api.get(AdminApiRoutes.restaurant),
        widget.api.get(AdminApiRoutes.restaurantHours),
      ]);
      final restaurant = _asMap(result[0]);
      final byDay = <int, Map<String, dynamic>>{};
      for (final row in _asList(result[1])) {
        final day = row['dayOfWeek'];
        if (day is num) byDay[day.toInt()] = row;
      }
      _name.text = restaurant['name']?.toString() ?? '';
      _slug.text = restaurant['slug']?.toString() ?? '';
      _phone.text = restaurant['phone']?.toString() ?? '';
      _email.text = restaurant['email']?.toString() ?? '';
      _address.text = restaurant['addressLine1']?.toString() ?? '';
      _city.text = restaurant['city']?.toString() ?? '';
      _deliveryMinutes.text =
          restaurant['defaultDeliveryMinutes']?.toString() ?? '';
      _deliveryFee.text = restaurant['deliveryFeeMinor']?.toString() ?? '';
      _minimumOrder.text = restaurant['minimumOrderMinor']?.toString() ?? '';
      if (!mounted) return;
      setState(
        () =>
            _hours = List.generate(
              7,
              (day) => _BusinessDay.fromMap(day, byDay[day]),
            ),
      );
    } on AdminApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Non è stato possibile caricare le impostazioni.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.api.patch(
        AdminApiRoutes.restaurant,
        body: {
          'name': _name.text.trim(),
          'slug': _slug.text.trim(),
          'phone': _optional(_phone),
          'email': _optional(_email),
          'addressLine1': _optional(_address),
          'city': _optional(_city),
          'defaultDeliveryMinutes': _integer(_deliveryMinutes),
          'deliveryFeeMinor': _integer(_deliveryFee),
          'minimumOrderMinor': _integer(_minimumOrder),
        },
      );
      for (final day in _hours) {
        await widget.api.put(
          AdminApiRoutes.restaurantHours,
          body: day.toRequest(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Impostazioni salvate.')));
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
  Widget build(BuildContext context) {
    if (_loading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return SafeArea(
        child: Center(
          child: FilledButton(
            onPressed: _load,
            child: Text('Riprova: $_error'),
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Impostazioni ristorante',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Profilo, consegna e orari di apertura.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            _section('Profilo', [
              Row(
                children: [
                  Expanded(child: _field(_name, 'Nome', required: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_slug, 'Slug', required: true)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field(_phone, 'Telefono')),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_email, 'Email', email: true)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field(_address, 'Indirizzo')),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_city, 'Città')),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            _section('Consegna', [
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _deliveryMinutes,
                      'Tempo di consegna (minuti)',
                      number: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      _deliveryFee,
                      'Costo consegna (centesimi)',
                      number: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      _minimumOrder,
                      'Ordine minimo (centesimi)',
                      number: true,
                    ),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            _section('Orari settimanali', [
              for (var i = 0; i < _hours.length; i++) _hoursRow(i),
            ]),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Salvataggio…' : 'Salva impostazioni'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    bool number = false,
    bool email = false,
  }) => TextFormField(
    controller: c,
    keyboardType:
        number
            ? TextInputType.number
            : (email ? TextInputType.emailAddress : TextInputType.text),
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      final text = value?.trim() ?? '';
      if (required && text.isEmpty) {
        return 'Campo obbligatorio';
      }
      if (number && text.isNotEmpty && int.tryParse(text) == null) {
        return 'Numero non valido';
      }
      if (email && text.isNotEmpty && !text.contains('@')) {
        return 'Email non valida';
      }
      return null;
    },
  );
  Widget _hoursRow(int index) {
    final day = _hours[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(day.label)),
          Switch(
            value: day.closed,
            onChanged:
                _saving
                    ? null
                    : (v) =>
                        setState(() => _hours[index] = day.copyWith(closed: v)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              enabled: !day.closed && !_saving,
              initialValue: day.opensAt,
              decoration: const InputDecoration(
                labelText: 'Apre',
                hintText: '18:00',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _hours[index] = day.copyWith(opensAt: v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              enabled: !day.closed && !_saving,
              initialValue: day.closesAt,
              decoration: const InputDecoration(
                labelText: 'Chiude',
                hintText: '23:30',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _hours[index] = day.copyWith(closesAt: v),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessDay {
  const _BusinessDay({
    required this.day,
    required this.closed,
    required this.opensAt,
    required this.closesAt,
  });
  factory _BusinessDay.empty(int day) =>
      _BusinessDay(day: day, closed: true, opensAt: '18:00', closesAt: '23:00');
  factory _BusinessDay.fromMap(int day, Map<String, dynamic>? map) =>
      _BusinessDay(
        day: day,
        closed: map?['isClosed'] == true,
        opensAt: map?['opensAt']?.toString() ?? '18:00',
        closesAt: map?['closesAt']?.toString() ?? '23:00',
      );
  final int day;
  final bool closed;
  final String opensAt;
  final String closesAt;
  String get label =>
      const [
        'Lunedì',
        'Martedì',
        'Mercoledì',
        'Giovedì',
        'Venerdì',
        'Sabato',
        'Domenica',
      ][day];
  _BusinessDay copyWith({bool? closed, String? opensAt, String? closesAt}) =>
      _BusinessDay(
        day: day,
        closed: closed ?? this.closed,
        opensAt: opensAt ?? this.opensAt,
        closesAt: closesAt ?? this.closesAt,
      );
  Map<String, Object> toRequest() => {
    'dayOfWeek': day,
    'isClosed': closed,
    if (!closed) 'opensAt': opensAt,
    if (!closed) 'closesAt': closesAt,
  };
}

Map<String, dynamic> _asMap(Object? value) =>
    value is Map<String, dynamic> ? value : const {};
List<Map<String, dynamic>> _asList(Object? value) {
  final raw =
      value is Map<String, dynamic> ? value['items'] ?? value['data'] : value;
  return raw is List
      ? raw.whereType<Map>().map((v) => Map<String, dynamic>.from(v)).toList()
      : const [];
}

String? _optional(TextEditingController controller) =>
    controller.text.trim().isEmpty ? null : controller.text.trim();
int? _integer(TextEditingController controller) =>
    controller.text.trim().isEmpty
        ? null
        : int.tryParse(controller.text.trim());
