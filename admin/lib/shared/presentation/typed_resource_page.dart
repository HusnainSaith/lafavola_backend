import 'package:flutter/material.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

enum AdminFieldType { text, multiline, integer, boolean, stringList }

class AdminField {
  const AdminField(
    this.key,
    this.label, {
    this.type = AdminFieldType.text,
    this.required = false,
    this.booleanDefault = false,
  });
  final String key;
  final String label;
  final AdminFieldType type;
  final bool required;
  final bool booleanDefault;
}

class TypedResourceConfig {
  const TypedResourceConfig({
    required this.title,
    required this.subtitle,
    required this.endpoint,
    required this.itemPath,
    required this.fields,
    required this.primaryField,
    this.restaurantScoped = false,
  });
  final String title;
  final String subtitle;
  final String endpoint;
  final String Function(String id) itemPath;
  final List<AdminField> fields;
  final String primaryField;
  final bool restaurantScoped;
}

class TypedResourcePage extends StatefulWidget {
  const TypedResourcePage({super.key, required this.api, required this.config});
  final AdminApiClient api;
  final TypedResourceConfig config;
  @override
  State<TypedResourcePage> createState() => _TypedResourcePageState();
}

class _TypedResourcePageState extends State<TypedResourcePage> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _rows = const [];
  String? _restaurantId;
  String? _error;
  bool _loading = true;
  bool _saving = false;

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
      String? restaurantId;
      if (widget.config.restaurantScoped) {
        restaurantId =
            _asMap(
              await widget.api.get(AdminApiRoutes.restaurant),
            )['id']?.toString();
        if (restaurantId == null) {
          throw const AdminApiException(
            'Il ristorante dell’account non è configurato.',
          );
        }
      }
      final rows = await widget.api.get(
        widget.config.endpoint,
        query: restaurantId == null ? null : {'restaurantId': restaurantId},
      );
      if (!mounted) return;
      setState(() {
        _rows = _asList(rows);
        _restaurantId = restaurantId;
      });
    } on AdminApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final term = _search.text.trim().toLowerCase();
    if (term.isEmpty) return _rows;
    return _rows
        .where((row) => row.values.join(' ').toLowerCase().contains(term))
        .toList();
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder:
          (_) => _TypedEditor(
            api: widget.api,
            config: widget.config,
            existing: row,
            restaurantId: _restaurantId,
          ),
    );
    if (saved == true) await _load();
  }

  Future<void> _remove(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null) return;
    final approved = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Elimina ${widget.config.title.toLowerCase()}'),
            content: Text(
              'Confermi la rimozione di “${row[widget.config.primaryField] ?? id}”?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Elimina'),
              ),
            ],
          ),
    );
    if (approved != true) return;
    setState(() => _saving = true);
    try {
      await widget.api.delete(widget.config.itemPath(id));
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

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.config.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(widget.config.subtitle),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    labelText: 'Cerca',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _saving ? null : () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('Nuovo'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _load,
                            child: const Text('Riprova'),
                          ),
                        ],
                      ),
                    )
                    : _filtered.isEmpty
                    ? const Center(child: Text('Nessun elemento disponibile.'))
                    : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final row = _filtered[index];
                        return Card(
                          child: ListTile(
                            minVerticalPadding: 14,
                            title: Text(
                              '${row[widget.config.primaryField] ?? 'Elemento'}',
                            ),
                            subtitle: Text(
                              widget.config.fields
                                  .skip(1)
                                  .take(2)
                                  .map(
                                    (field) =>
                                        '${field.label}: ${row[field.key] ?? '—'}',
                                  )
                                  .join(' · '),
                            ),
                            onTap: () => _edit(row),
                            trailing: Wrap(
                              children: [
                                IconButton(
                                  tooltip: 'Modifica',
                                  onPressed: () => _edit(row),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Elimina',
                                  onPressed: () => _remove(row),
                                  icon: const Icon(Icons.delete_outline),
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
  );
}

class _TypedEditor extends StatefulWidget {
  const _TypedEditor({
    required this.api,
    required this.config,
    required this.existing,
    required this.restaurantId,
  });
  final AdminApiClient api;
  final TypedResourceConfig config;
  final Map<String, dynamic>? existing;
  final String? restaurantId;
  @override
  State<_TypedEditor> createState() => _TypedEditorState();
}

class _TypedEditorState extends State<_TypedEditor> {
  final _key = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, bool> _switches;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.config.fields.where(
        (field) => field.type != AdminFieldType.boolean,
      ))
        field.key: TextEditingController(
          text:
              field.type == AdminFieldType.stringList &&
                      widget.existing?[field.key] is List
                  ? (widget.existing![field.key] as List).join(', ')
                  : '${widget.existing?[field.key] ?? ''}',
        ),
    };
    _switches = {
      for (final field in widget.config.fields.where(
        (field) => field.type == AdminFieldType.boolean,
      ))
        field.key: widget.existing?[field.key] as bool? ?? field.booleanDefault,
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
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
    final body = <String, dynamic>{
      if (widget.existing == null && widget.config.restaurantScoped)
        'restaurantId': widget.restaurantId,
      for (final field in widget.config.fields)
        field.key:
            field.type == AdminFieldType.boolean
                ? _switches[field.key]
                : field.type == AdminFieldType.integer
                ? int.tryParse(_controllers[field.key]!.text.trim())
                : field.type == AdminFieldType.stringList
                ? _controllers[field.key]!.text
                    .split(',')
                    .map((value) => value.trim())
                    .where((value) => value.isNotEmpty)
                    .toList()
                : _controllers[field.key]!.text.trim(),
    };
    try {
      final id = widget.existing?['id']?.toString();
      if (id == null) {
        await widget.api.post(widget.config.endpoint, body: body);
      } else {
        await widget.api.patch(widget.config.itemPath(id), body: body);
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
    title: Text(
      widget.existing == null ? 'Nuovo elemento' : 'Modifica elemento',
    ),
    content: SizedBox(
      width: 560,
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final field in widget.config.fields) ...[
                if (field.type == AdminFieldType.boolean)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(field.label),
                    value: _switches[field.key]!,
                    onChanged:
                        _saving
                            ? null
                            : (value) =>
                                setState(() => _switches[field.key] = value),
                  )
                else
                  TextFormField(
                    controller: _controllers[field.key],
                    enabled: !_saving,
                    maxLines: field.type == AdminFieldType.multiline ? 4 : 1,
                    keyboardType:
                        field.type == AdminFieldType.integer
                            ? TextInputType.number
                            : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: field.label,
                      helperText:
                          field.type == AdminFieldType.stringList
                              ? 'Separa i valori con una virgola'
                              : null,
                    ),
                    validator:
                        field.required
                            ? (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Campo obbligatorio'
                                    : null
                            : null,
                  ),
                const SizedBox(height: 12),
              ],
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
}

List<Map<String, dynamic>> _asList(Object? value) {
  final rows = value is Map ? value['data'] : value;
  return rows is List
      ? rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : const [];
}

Map<String, dynamic> _asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
