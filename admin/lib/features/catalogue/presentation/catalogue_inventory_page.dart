import 'package:flutter/material.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

/// A tablet-first catalogue workflow for the two resources operators change
/// most: menu products and categories. Ingredient and option configuration stay
/// reachable from the catalogue landing page because they have more specialised
/// dependent data than a simple row editor.
class CatalogueInventoryPage extends StatefulWidget {
  const CatalogueInventoryPage({super.key, required this.api});

  final AdminApiClient api;

  @override
  State<CatalogueInventoryPage> createState() => _CatalogueInventoryPageState();
}

class _CatalogueInventoryPageState extends State<CatalogueInventoryPage> {
  final _searchController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _restaurantId;
  List<Map<String, dynamic>> _categories = const [];
  List<Map<String, dynamic>> _items = const [];
  String _view = 'menu';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
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
          AdminApiRoutes.categories,
          query: {'restaurantId': restaurantId},
        ),
        widget.api.get(
          AdminApiRoutes.menu,
          query: {'restaurantId': restaurantId},
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _restaurantId = restaurantId;
        _categories = _list(values[0]);
        _items = _list(values[1]);
      });
    } on AdminApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Non è stato possibile caricare il catalogo.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _visibleRows {
    final source = _view == 'menu' ? _items : _categories;
    final search = _searchController.text.trim().toLowerCase();
    if (search.isEmpty) return source;
    return source.where((row) {
      return '${row['name'] ?? ''} ${row['description'] ?? ''} ${row['slug'] ?? ''}'
          .toLowerCase()
          .contains(search);
    }).toList();
  }

  Future<void> _showEditor([Map<String, dynamic>? existing]) async {
    if (_restaurantId == null) {
      _message('Profilo ristorante non disponibile. Ricarica e riprova.');
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      builder:
          (_) => _CatalogueEditorDialog(
            item: _view == 'menu',
            restaurantId: _restaurantId!,
            categories: _categories,
            existing: existing,
            api: widget.api,
          ),
    );
    if (saved == true) await _load();
  }

  Future<void> _archive(Map<String, dynamic> item) async {
    final id = item['id']?.toString();
    if (id == null) return;
    final kind = _view == 'menu' ? 'prodotto' : 'categoria';
    final approved = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Archivia $kind'),
            content: Text(
              '“${item['name'] ?? kind}” non sarà più disponibile.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Archivia'),
              ),
            ],
          ),
    );
    if (approved != true) return;
    setState(() => _saving = true);
    try {
      await widget.api.delete(
        _view == 'menu'
            ? AdminApiRoutes.menuItem(id)
            : AdminApiRoutes.category(id),
      );
      if (mounted) _message('$kind archiviato.');
      await _load();
    } on AdminApiException catch (error) {
      if (mounted) _message(error.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
        content: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Catalogo', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Pubblica prodotti e categorie senza modificare JSON.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'menu',
                  icon: Icon(Icons.local_pizza_outlined),
                  label: Text('Menu'),
                ),
                ButtonSegment(
                  value: 'categories',
                  icon: Icon(Icons.category_outlined),
                  label: Text('Categorie'),
                ),
              ],
              selected: {_view},
              onSelectionChanged:
                  _saving
                      ? null
                      : (selection) => setState(() => _view = selection.first),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Cerca nel catalogo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _loading || _saving ? null : () => _showEditor(),
                    icon: const Icon(Icons.add),
                    label: Text(
                      _view == 'menu' ? 'Nuovo prodotto' : 'Nuova categoria',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _content(theme)),
          ],
        ),
      ),
    );
  }

  Widget _content(ThemeData theme) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Riprova')),
          ],
        ),
      );
    }
    if (_visibleRows.isEmpty) {
      return const Center(
        child: Text('Nessun elemento corrisponde alla ricerca.'),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return ListView.separated(
          itemCount: _visibleRows.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final row = _visibleRows[index];
            final active = row['isActive'] != false;
            final price = _menuPrice(row);
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      active
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    _view == 'menu'
                        ? Icons.local_pizza_outlined
                        : Icons.category_outlined,
                  ),
                ),
                title: Text(row['name']?.toString() ?? 'Senza nome'),
                subtitle: Text(
                  _view == 'menu'
                      ? '${row['category'] is Map ? (row['category'] as Map)['name'] ?? 'Senza categoria' : 'Senza categoria'}${price == null ? '' : ' · €$price'}'
                      : (row['description']?.toString().isNotEmpty == true
                          ? row['description'].toString()
                          : row['slug']?.toString() ?? ''),
                ),
                trailing: Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (wide)
                      Chip(label: Text(active ? 'Attivo' : 'Archiviato')),
                    IconButton(
                      tooltip: 'Modifica',
                      onPressed: _saving ? null : () => _showEditor(row),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Archivia',
                      onPressed:
                          _saving || !active ? null : () => _archive(row),
                      icon: const Icon(Icons.archive_outlined),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CatalogueEditorDialog extends StatefulWidget {
  const _CatalogueEditorDialog({
    required this.item,
    required this.restaurantId,
    required this.categories,
    required this.existing,
    required this.api,
  });
  final bool item;
  final String restaurantId;
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? existing;
  final AdminApiClient api;

  @override
  State<_CatalogueEditorDialog> createState() => _CatalogueEditorDialogState();
}

class _CatalogueEditorDialogState extends State<_CatalogueEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _description;
  late final TextEditingController _price;
  String? _categoryId;
  String _itemType = 'standard';
  String _sizeCode = 'medium';
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final source = widget.existing ?? const <String, dynamic>{};
    _name = TextEditingController(text: source['name']?.toString() ?? '');
    _slug = TextEditingController(text: source['slug']?.toString() ?? '');
    _description = TextEditingController(
      text: source['description']?.toString() ?? '',
    );
    final category = source['category'];
    _categoryId =
        category is Map
            ? category['id']?.toString()
            : source['categoryId']?.toString();
    _active = source['isActive'] != false;
    _itemType = source['itemType']?.toString() ?? 'standard';
    final sizes = source['sizes'];
    final firstSize =
        sizes is List && sizes.isNotEmpty && sizes.first is Map
            ? sizes.first as Map
            : null;
    _price = TextEditingController(
      text: firstSize?['basePriceMinor']?.toString() ?? '',
    );
    _sizeCode = firstSize?['sizeCode']?.toString() ?? 'medium';
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final existingId = widget.existing?['id']?.toString();
    final body = <String, Object?>{
      'name': _name.text.trim(),
      'slug': _slug.text.trim(),
      'description':
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      'isActive': _active,
      if (widget.item) 'categoryId': _categoryId,
    };
    if (existingId == null) {
      body['restaurantId'] = widget.restaurantId;
      if (widget.item) {
        final minor = int.parse(_price.text.trim());
        body.addAll({
          'itemType': _itemType,
          'sizes': [
            {
              'sizeCode': _sizeCode,
              'displayName':
                  _sizeCode == 'single'
                      ? 'Porzione'
                      : _sizeCode[0].toUpperCase() + _sizeCode.substring(1),
              'basePriceMinor': minor,
              'isActive': _active,
            },
          ],
        });
      }
    }
    try {
      if (existingId == null) {
        await widget.api.post(
          widget.item ? AdminApiRoutes.menu : AdminApiRoutes.categories,
          body: body,
        );
      } else {
        await widget.api.patch(
          widget.item
              ? AdminApiRoutes.menuItem(existingId)
              : AdminApiRoutes.category(existingId),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.existing == null
          ? (widget.item ? 'Nuovo prodotto' : 'Nuova categoria')
          : 'Modifica',
    ),
    content: SizedBox(
      width: 560,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_name, 'Nome', required: true),
              const SizedBox(height: 12),
              _field(_slug, 'Slug', required: true),
              const SizedBox(height: 12),
              _field(_description, 'Descrizione', maxLines: 2),
              if (widget.item) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _categoryId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Senza categoria'),
                    ),
                    ...widget.categories.map(
                      (c) => DropdownMenuItem(
                        value: c['id']?.toString(),
                        child: Text(c['name']?.toString() ?? 'Categoria'),
                      ),
                    ),
                  ],
                  onChanged:
                      _saving
                          ? null
                          : (value) => setState(() => _categoryId = value),
                ),
                if (widget.existing == null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _itemType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo prodotto',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        const [
                              'standard',
                              'modifiable',
                              'build_your_own',
                              'side',
                              'drink',
                              'other',
                            ]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                    onChanged: (value) => setState(() => _itemType = value!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sizeCode,
                          decoration: const InputDecoration(
                            labelText: 'Formato',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              const ['small', 'medium', 'large', 'single']
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) => setState(() => _sizeCode = value!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          _price,
                          'Prezzo in centesimi',
                          required: true,
                          number: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Visibile nel catalogo'),
                value: _active,
                onChanged:
                    _saving ? null : (value) => setState(() => _active = value),
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
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      final text = value?.trim() ?? '';
      if (required && text.isEmpty) return 'Campo obbligatorio';
      if (number && int.tryParse(text) == null) {
        return 'Inserisci un numero intero';
      }
      return null;
    },
  );
}

List<Map<String, dynamic>> _list(Object? value) {
  final raw =
      value is Map<String, dynamic>
          ? value['items'] ?? value['data'] ?? value['results']
          : value;
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList();
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

String? _menuPrice(Map<String, dynamic> row) {
  final sizes = row['sizes'];
  if (sizes is! List || sizes.isEmpty || sizes.first is! Map) return null;
  final minor = (sizes.first as Map)['basePriceMinor'];
  final value =
      minor is num
          ? minor.toDouble() / 100
          : double.tryParse(minor?.toString() ?? '');
  return value?.toStringAsFixed(2);
}
