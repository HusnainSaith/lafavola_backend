import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';
import 'package:la_favola_admin/shared/presentation/typed_resource_page.dart';

class OptionGroupsPage extends StatefulWidget {
  const OptionGroupsPage({
    super.key,
    required this.api,
    required this.groupConfig,
  });
  final AdminApiClient api;
  final TypedResourceConfig groupConfig;

  @override
  State<OptionGroupsPage> createState() => _OptionGroupsPageState();
}

class _OptionGroupsPageState extends State<OptionGroupsPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _selectedGroupId;
  List<Map<String, dynamic>> _groups = const [];
  List<Map<String, dynamic>> _choices = const [];
  List<Map<String, dynamic>> _ingredients = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? selectGroup}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final restaurant = _map(await widget.api.get(AdminApiRoutes.restaurant));
      final restaurantId = restaurant['id']?.toString();
      if (restaurantId == null) {
        throw const AdminApiException(
          'Il ristorante dell’account non è configurato.',
        );
      }
      final values = await Future.wait<Object?>([
        widget.api.get(
          AdminApiRoutes.optionGroups,
          query: {'restaurantId': restaurantId},
        ),
        widget.api.get(
          AdminApiRoutes.ingredients,
          query: {'restaurantId': restaurantId},
        ),
      ]);
      final groups = _list(values[0]);
      final selected =
          selectGroup ??
          _selectedGroupId ??
          (groups.isEmpty ? null : groups.first['id']?.toString());
      final detail =
          selected == null
              ? const <String, dynamic>{}
              : _map(
                await widget.api.get(AdminApiRoutes.optionGroup(selected)),
              );
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _ingredients = _list(values[1]);
        _selectedGroupId = selected;
        _choices = _list(detail['choices']);
      });
    } on AdminApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _manageGroups() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) =>
                TypedResourcePage(api: widget.api, config: widget.groupConfig),
      ),
    );
    await _load();
  }

  Future<void> _editChoice([Map<String, dynamic>? choice]) async {
    final groupId = _selectedGroupId;
    if (groupId == null) return;
    final saved = await showDialog<bool>(
      context: context,
      builder:
          (_) => _ChoiceDialog(
            api: widget.api,
            groupId: groupId,
            existing: choice,
            ingredients: _ingredients,
          ),
    );
    if (saved == true) await _load(selectGroup: groupId);
  }

  Future<void> _deactivate(Map<String, dynamic> choice) async {
    final groupId = _selectedGroupId;
    final choiceId = choice['id']?.toString();
    if (groupId == null || choiceId == null) return;
    final approved = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Disattiva scelta'),
            content: Text(
              '“${choice['name'] ?? 'Questa scelta'}” non sarà più disponibile nel menu.',
            ),
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
      await widget.api.delete(AdminApiRoutes.optionChoice(groupId, choiceId));
      await _load(selectGroup: groupId);
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
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gruppi e scelte',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Varianti, extra, ingredienti collegati e prezzi aggiuntivi.',
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _saving ? null : _manageGroups,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Gestisci gruppi'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: FilledButton(
                  onPressed: _load,
                  child: Text('Riprova: $_error'),
                ),
              ),
            )
          else if (_groups.isEmpty)
            Expanded(
              child: Center(
                child: FilledButton.icon(
                  onPressed: _manageGroups,
                  icon: const Icon(Icons.add),
                  label: const Text('Crea il primo gruppo'),
                ),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGroupId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Gruppo di opzioni',
                    ),
                    items:
                        _groups
                            .map(
                              (group) => DropdownMenuItem(
                                value: group['id']?.toString(),
                                child: Text(
                                  group['name']?.toString() ?? 'Gruppo',
                                ),
                              ),
                            )
                            .toList(),
                    onChanged:
                        _saving
                            ? null
                            : (value) {
                              if (value != null) _load(selectGroup: value);
                            },
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _editChoice(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuova scelta'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _choices.isEmpty
                      ? const Center(
                        child: Text(
                          'Nessuna scelta configurata per il gruppo.',
                        ),
                      )
                      : ListView.separated(
                        itemCount: _choices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final choice = _choices[index];
                          return Card(
                            child: ListTile(
                              minVerticalPadding: 12,
                              title: Text(
                                choice['name']?.toString() ?? 'Scelta',
                              ),
                              subtitle: Text(
                                '${choice['code'] ?? '—'} · '
                                '${_money(choice['priceAdjustmentMinor'])}'
                                '${choice['isDefault'] == true ? ' · Predefinita' : ''}',
                              ),
                              trailing: Wrap(
                                children: [
                                  IconButton(
                                    tooltip: 'Modifica scelta',
                                    onPressed:
                                        _saving
                                            ? null
                                            : () => _editChoice(choice),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Disattiva scelta',
                                    onPressed:
                                        _saving
                                            ? null
                                            : () => _deactivate(choice),
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
        ],
      ),
    ),
  );
}

class _ChoiceDialog extends StatefulWidget {
  const _ChoiceDialog({
    required this.api,
    required this.groupId,
    required this.existing,
    required this.ingredients,
  });
  final AdminApiClient api;
  final String groupId;
  final Map<String, dynamic>? existing;
  final List<Map<String, dynamic>> ingredients;

  @override
  State<_ChoiceDialog> createState() => _ChoiceDialogState();
}

class _ChoiceDialogState extends State<_ChoiceDialog> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _price;
  late final TextEditingController _calories;
  late final TextEditingController _order;
  String? _ingredientId;
  bool _default = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final source = widget.existing ?? const <String, dynamic>{};
    _name = TextEditingController(text: '${source['name'] ?? ''}');
    _code = TextEditingController(text: '${source['code'] ?? ''}');
    _price = TextEditingController(
      text: '${source['priceAdjustmentMinor'] ?? 0}',
    );
    _calories = TextEditingController(
      text: '${source['caloriesAdjustment'] ?? 0}',
    );
    _order = TextEditingController(text: '${source['displayOrder'] ?? 0}');
    _ingredientId = source['ingredientId']?.toString();
    _default = source['isDefault'] == true;
  }

  @override
  void dispose() {
    for (final controller in [_name, _code, _price, _calories, _order]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final body = <String, Object?>{
      'name': _name.text.trim(),
      'code': _code.text.trim(),
      'ingredientId': _ingredientId,
      'priceAdjustmentMinor': int.parse(_price.text.trim()),
      'caloriesAdjustment': int.parse(_calories.text.trim()),
      'isDefault': _default,
      'displayOrder': int.parse(_order.text.trim()),
    };
    try {
      final id = widget.existing?['id']?.toString();
      if (id == null) {
        await widget.api.post(
          AdminApiRoutes.optionChoices(widget.groupId),
          body: {...body, 'isActive': true},
        );
      } else {
        await widget.api.patch(
          AdminApiRoutes.optionChoice(widget.groupId, id),
          body: body,
        );
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
    title: Text(widget.existing == null ? 'Nuova scelta' : 'Modifica scelta'),
    content: SizedBox(
      width: 560,
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_name, 'Nome', required: true),
              const SizedBox(height: 12),
              _field(_code, 'Codice', required: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _ingredientId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ingrediente collegato (facoltativo)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Nessun ingrediente'),
                  ),
                  ...widget.ingredients.map(
                    (row) => DropdownMenuItem<String?>(
                      value: row['id']?.toString(),
                      child: Text(row['name']?.toString() ?? 'Ingrediente'),
                    ),
                  ),
                ],
                onChanged:
                    _saving
                        ? null
                        : (value) => setState(() => _ingredientId = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _price,
                      'Prezzo extra (centesimi)',
                      number: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(_calories, 'Calorie extra', number: true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(_order, 'Ordine di visualizzazione', number: true),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Scelta predefinita'),
                value: _default,
                onChanged:
                    _saving
                        ? null
                        : (value) => setState(() => _default = value),
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

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
  }) => TextFormField(
    controller: controller,
    enabled: !_saving,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final text = value?.trim() ?? '';
      if (required && text.isEmpty) return 'Campo obbligatorio';
      if (number && int.tryParse(text) == null) return 'Numero non valido';
      return null;
    },
  );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
List<Map<String, dynamic>> _list(Object? value) {
  final rows = value is Map ? value['data'] ?? value['items'] : value;
  return rows is List
      ? rows
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList()
      : const [];
}

String _money(Object? minor) => NumberFormat.currency(
  locale: 'it_IT',
  symbol: '€',
).format((minor is num ? minor : num.tryParse('$minor') ?? 0) / 100);
