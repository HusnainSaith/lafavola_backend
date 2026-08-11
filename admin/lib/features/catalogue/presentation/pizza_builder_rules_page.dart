import 'package:flutter/material.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

class PizzaBuilderRulesPage extends StatefulWidget {
  const PizzaBuilderRulesPage({super.key, required this.api});
  final AdminApiClient api;

  @override
  State<PizzaBuilderRulesPage> createState() => _PizzaBuilderRulesPageState();
}

class _PizzaBuilderRulesPageState extends State<PizzaBuilderRulesPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _rules = const [];
  List<Map<String, dynamic>> _menu = const [];
  List<Map<String, dynamic>> _groups = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final restaurant = _map(await widget.api.get(AdminApiRoutes.restaurant));
      final id = restaurant['id']?.toString();
      if (id == null) {
        throw const AdminApiException('Ristorante non configurato.');
      }
      final values = await Future.wait<Object?>([
        widget.api.get(AdminApiRoutes.pizzaBuilderRules),
        widget.api.get(AdminApiRoutes.menu, query: {'restaurantId': id}),
        widget.api.get(
          AdminApiRoutes.optionGroups,
          query: {'restaurantId': id},
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _rules = _list(values[0]);
        _menu = _list(values[1]);
        _groups = _list(values[2]);
      });
    } on AdminApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([Map<String, dynamic>? rule]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder:
          (_) => _RuleDialog(
            api: widget.api,
            menu: _menu,
            groups: _groups,
            existing: rule,
          ),
    );
    if (saved == true) await _load();
  }

  Future<void> _deactivate(Map<String, dynamic> rule) async {
    final id = rule['id']?.toString();
    if (id == null) return;
    final approved = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Disattiva compositore'),
            content: Text('Disattivare “${rule['name'] ?? 'questa regola'}”?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Disattiva'),
              ),
            ],
          ),
    );
    if (approved != true) return;
    setState(() => _saving = true);
    try {
      await widget.api.delete(AdminApiRoutes.pizzaBuilderRule(id));
      await _load();
    } on AdminApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _preview(Map<String, dynamic> rule) async {
    final menuItemId = rule['menuItemId']?.toString();
    if (menuItemId == null) return;
    setState(() => _saving = true);
    try {
      final response = await widget.api.get(
        AdminApiRoutes.pizzaBuilder(menuItemId),
      );
      final configuration = _map(response);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Anteprima configurazione cliente'),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        configuration['name']?.toString() ??
                            rule['name']?.toString() ??
                            'Compositore pizza',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Condimenti inclusi: ${configuration['freeToppingCount'] ?? rule['freeToppingCount'] ?? 0}',
                      ),
                      Text(
                        'Condimenti massimi: ${configuration['maxTotalToppings'] ?? rule['maxTotalToppings'] ?? '—'}',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Questa anteprima legge la stessa configurazione usata dal sito e dall’app cliente.',
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Chiudi'),
                ),
              ],
            ),
      );
    } on AdminApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Compositore pizza')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Regole per impasto, salsa, formaggio e condimenti.',
                  ),
                ),
                FilledButton.icon(
                  onPressed: _loading || _saving ? null : () => _edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuova regola'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(
                        child: FilledButton(
                          onPressed: _load,
                          child: Text('Riprova: $_error'),
                        ),
                      )
                      : _rules.isEmpty
                      ? const Center(child: Text('Nessuna regola configurata.'))
                      : ListView.separated(
                        itemCount: _rules.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final rule = _rules[index];
                          return Card(
                            child: ListTile(
                              minVerticalPadding: 12,
                              title: Text(rule['name']?.toString() ?? 'Regola'),
                              subtitle: Text(
                                '${_menuName(rule['menuItemId'])} · '
                                '${rule['freeToppingCount'] ?? 0} condimenti inclusi · '
                                'max ${rule['maxTotalToppings'] ?? '—'}',
                              ),
                              leading: Icon(
                                rule['isActive'] == false
                                    ? Icons.toggle_off_outlined
                                    : Icons.tune_rounded,
                              ),
                              trailing: Wrap(
                                children: [
                                  IconButton(
                                    tooltip: 'Anteprima cliente',
                                    onPressed:
                                        _saving ? null : () => _preview(rule),
                                    icon: const Icon(Icons.visibility_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Modifica',
                                    onPressed:
                                        _saving ? null : () => _edit(rule),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Disattiva',
                                    onPressed:
                                        _saving || rule['isActive'] == false
                                            ? null
                                            : () => _deactivate(rule),
                                    icon: const Icon(Icons.archive_outlined),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    ),
  );

  String _menuName(Object? id) =>
      _menu
          .where((item) => item['id']?.toString() == id?.toString())
          .map((item) => item['name']?.toString() ?? 'Prodotto')
          .firstOrNull ??
      'Prodotto';
}

class _RuleDialog extends StatefulWidget {
  const _RuleDialog({
    required this.api,
    required this.menu,
    required this.groups,
    required this.existing,
  });
  final AdminApiClient api;
  final List<Map<String, dynamic>> menu;
  final List<Map<String, dynamic>> groups;
  final Map<String, dynamic>? existing;

  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _max;
  late final TextEditingController _free;
  String? _menuItemId;
  String? _size;
  String? _dough;
  String? _sauce;
  String? _cheese;
  String? _toppings;
  bool _active = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final source = widget.existing ?? const <String, dynamic>{};
    _name = TextEditingController(text: '${source['name'] ?? ''}');
    _max = TextEditingController(text: '${source['maxTotalToppings'] ?? 10}');
    _free = TextEditingController(text: '${source['freeToppingCount'] ?? 0}');
    _menuItemId =
        source['menuItemId']?.toString() ??
        (widget.menu.isEmpty ? null : widget.menu.first['id']?.toString());
    _size = source['sizeGroupId']?.toString();
    _dough = source['doughGroupId']?.toString();
    _sauce = source['sauceGroupId']?.toString();
    _cheese = source['cheeseGroupId']?.toString();
    _toppings = source['toppingsGroupId']?.toString();
    _active = source['isActive'] != false;
  }

  @override
  void dispose() {
    _name.dispose();
    _max.dispose();
    _free.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate() || _menuItemId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final body = {
      'menuItemId': _menuItemId,
      'name': _name.text.trim(),
      'sizeGroupId': _size,
      'doughGroupId': _dough,
      'sauceGroupId': _sauce,
      'cheeseGroupId': _cheese,
      'toppingsGroupId': _toppings,
      'maxTotalToppings': int.parse(_max.text),
      'freeToppingCount': int.parse(_free.text),
      'isActive': _active,
    };
    try {
      final id = widget.existing?['id']?.toString();
      if (id == null) {
        await widget.api.post(AdminApiRoutes.pizzaBuilderRules, body: body);
      } else {
        await widget.api.patch(AdminApiRoutes.pizzaBuilderRule(id), body: body);
      }
      if (mounted) Navigator.pop(context, true);
    } on AdminApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'Nuova regola' : 'Modifica regola'),
    content: SizedBox(
      width: 620,
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nome regola'),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Campo obbligatorio'
                            : null,
              ),
              const SizedBox(height: 12),
              _dropdown(
                'Prodotto componibile',
                _menuItemId,
                widget.menu,
                (v) => _menuItemId = v,
                required: true,
              ),
              const SizedBox(height: 12),
              _dropdown(
                'Gruppo formato',
                _size,
                widget.groups,
                (v) => _size = v,
              ),
              const SizedBox(height: 12),
              _dropdown(
                'Gruppo impasto',
                _dough,
                widget.groups,
                (v) => _dough = v,
              ),
              const SizedBox(height: 12),
              _dropdown(
                'Gruppo salsa',
                _sauce,
                widget.groups,
                (v) => _sauce = v,
              ),
              const SizedBox(height: 12),
              _dropdown(
                'Gruppo formaggio',
                _cheese,
                widget.groups,
                (v) => _cheese = v,
              ),
              const SizedBox(height: 12),
              _dropdown(
                'Gruppo condimenti',
                _toppings,
                widget.groups,
                (v) => _toppings = v,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _integer(_free, 'Condimenti inclusi')),
                  const SizedBox(width: 12),
                  Expanded(child: _integer(_max, 'Condimenti massimi')),
                ],
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Regola attiva'),
                value: _active,
                onChanged: _saving ? null : (v) => setState(() => _active = v),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Annulla'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Salvataggio…' : 'Salva'),
      ),
    ],
  );

  Widget _dropdown(
    String label,
    String? value,
    List<Map<String, dynamic>> rows,
    ValueChanged<String?> onChanged, {
    bool required = false,
  }) => DropdownButtonFormField<String?>(
    value: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      if (!required)
        const DropdownMenuItem<String?>(value: null, child: Text('Nessuno')),
      ...rows.map(
        (row) => DropdownMenuItem<String?>(
          value: row['id']?.toString(),
          child: Text(row['name']?.toString() ?? 'Elemento'),
        ),
      ),
    ],
    onChanged: _saving ? null : (v) => setState(() => onChanged(v)),
    validator:
        required && value == null ? (_) => 'Seleziona un prodotto' : null,
  );

  Widget _integer(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator:
            (value) =>
                int.tryParse(value ?? '') == null ? 'Numero non valido' : null,
      );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
List<Map<String, dynamic>> _list(Object? value) {
  final rows = value is Map ? value['data'] : value;
  return rows is List
      ? rows
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList()
      : const [];
}
