import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_favola_admin/app/providers.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

final mediaLibraryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final value = await ref
          .watch(apiClientProvider)
          .get(AdminApiRoutes.mediaAdmin);
      final rows = value is Map ? value['data'] : value;
      return rows is List
          ? rows
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [];
    });

class MediaLibraryPage extends ConsumerWidget {
  const MediaLibraryPage({super.key});

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> asset,
  ) async {
    final id = asset['id']?.toString();
    if (id == null) return;
    final approved = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Elimina media'),
            content: Text(
              'Eliminare “${asset['originalFileName'] ?? 'questa risorsa'}” dallo storage?',
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
    try {
      await ref.read(apiClientProvider).delete(AdminApiRoutes.media(id));
      ref.invalidate(mediaLibraryProvider);
    } on AdminApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _upload(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
      dialogTitle: 'Seleziona immagine La Favola',
    );
    if (picked == null || picked.files.isEmpty || !context.mounted) return;
    final file = picked.files.single;
    try {
      final api = ref.read(apiClientProvider);
      final restaurant = _map(await api.get(AdminApiRoutes.restaurant));
      final restaurantId = restaurant['id']?.toString();
      if (restaurantId == null) {
        throw const AdminApiException(
          'Il ristorante dell’account non è configurato.',
        );
      }
      final resources = await Future.wait<Object?>([
        api.get(AdminApiRoutes.menu, query: {'restaurantId': restaurantId}),
        api.get(
          AdminApiRoutes.categories,
          query: {'restaurantId': restaurantId},
        ),
        api.get(
          AdminApiRoutes.ingredients,
          query: {'restaurantId': restaurantId},
        ),
      ]);
      if (!context.mounted) return;
      final target = await showDialog<_MediaTarget>(
        context: context,
        builder:
            (_) => _MediaTargetDialog(
              fileName: file.name,
              menu: _list(resources[0]),
              categories: _list(resources[1]),
              ingredients: _list(resources[2]),
            ),
      );
      if (target == null) return;
      await api.uploadFile(
        AdminApiRoutes.mediaUpload,
        fileName: file.name,
        filePath: file.path,
        bytes: file.bytes,
        fields: {
          'purpose': target.purpose,
          'restaurantId': restaurantId,
          'targetId': target.targetId,
          if (target.altText.isNotEmpty) 'altText': target.altText,
        },
      );
      ref.invalidate(mediaLibraryProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Immagine caricata e collegata.')),
        );
      }
    } on AdminApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(mediaLibraryProvider);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(mediaLibraryProvider.future),
        child: value.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, _) => ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Libreria media',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _upload(context, ref),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Carica immagine'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    error is AdminApiException
                        ? error.message
                        : 'Libreria non disponibile.',
                  ),
                ],
              ),
          data:
              (rows) => ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Libreria media',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Risorse caricate per menu, categorie e ingredienti.',
                  ),
                  const SizedBox(height: 20),
                  if (rows.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('Nessuna risorsa media.')),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width =
                            constraints.maxWidth >= 1000
                                ? (constraints.maxWidth - 32) / 3
                                : constraints.maxWidth >= 620
                                ? (constraints.maxWidth - 16) / 2
                                : constraints.maxWidth;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            for (final row in rows)
                              SizedBox(
                                width: width,
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child:
                                                row['publicUrl'] is String
                                                    ? Image.network(
                                                      '${row['publicUrl']}',
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            _,
                                                            __,
                                                            ___,
                                                          ) => const Icon(
                                                            Icons
                                                                .broken_image_outlined,
                                                            size: 42,
                                                          ),
                                                    )
                                                    : const Icon(
                                                      Icons.image_outlined,
                                                      size: 42,
                                                    ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          '${row['originalFileName'] ?? row['purpose'] ?? 'Media'}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${row['status'] ?? ''} · ${row['mimeType'] ?? ''}',
                                        ),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: IconButton(
                                            tooltip: 'Elimina',
                                            onPressed:
                                                () =>
                                                    _remove(context, ref, row),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
        ),
      ),
    );
  }
}

class _MediaTarget {
  const _MediaTarget({
    required this.purpose,
    required this.targetId,
    required this.altText,
  });
  final String purpose;
  final String targetId;
  final String altText;
}

class _MediaTargetDialog extends StatefulWidget {
  const _MediaTargetDialog({
    required this.fileName,
    required this.menu,
    required this.categories,
    required this.ingredients,
  });
  final String fileName;
  final List<Map<String, dynamic>> menu;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> ingredients;

  @override
  State<_MediaTargetDialog> createState() => _MediaTargetDialogState();
}

class _MediaTargetDialogState extends State<_MediaTargetDialog> {
  final _alt = TextEditingController();
  String _purpose = 'menu_image';
  String? _targetId;

  List<Map<String, dynamic>> get _targets => switch (_purpose) {
    'category_image' => widget.categories,
    'ingredient_image' => widget.ingredients,
    _ => widget.menu,
  };

  @override
  void initState() {
    super.initState();
    _selectFirstTarget();
  }

  @override
  void dispose() {
    _alt.dispose();
    super.dispose();
  }

  void _selectFirstTarget() {
    _targetId = _targets.isEmpty ? null : _targets.first['id']?.toString();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Collega immagine'),
    content: SizedBox(
      width: 540,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.image_outlined),
            title: Text(widget.fileName),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _purpose,
            decoration: const InputDecoration(labelText: 'Tipo di immagine'),
            items: const [
              DropdownMenuItem(
                value: 'menu_image',
                child: Text('Prodotto del menu'),
              ),
              DropdownMenuItem(
                value: 'category_image',
                child: Text('Categoria'),
              ),
              DropdownMenuItem(
                value: 'ingredient_image',
                child: Text('Ingrediente'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _purpose = value;
                _selectFirstTarget();
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _targetId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Elemento collegato'),
            items:
                _targets
                    .map(
                      (row) => DropdownMenuItem(
                        value: row['id']?.toString(),
                        child: Text(row['name']?.toString() ?? 'Elemento'),
                      ),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _targetId = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _alt,
            decoration: const InputDecoration(
              labelText: 'Testo alternativo',
              helperText: 'Descrivi l’immagine per l’accessibilità.',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annulla'),
      ),
      FilledButton(
        onPressed:
            _targetId == null
                ? null
                : () => Navigator.pop(
                  context,
                  _MediaTarget(
                    purpose: _purpose,
                    targetId: _targetId!,
                    altText: _alt.text.trim(),
                  ),
                ),
        child: const Text('Carica e collega'),
      ),
    ],
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
