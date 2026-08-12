import 'package:flutter/material.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

/// Staff membership is deliberately separate from user provisioning. The API
/// requires an existing user account, so the UI presents a named selector and
/// never asks an operator to type a database ID or raw JSON payload.
class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key, required this.api});
  final AdminApiClient api;

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _staff = const [];
  List<Map<String, dynamic>> _users = const [];
  String? _restaurantId;
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
      final values = await Future.wait<Object?>([
        widget.api.get(AdminApiRoutes.restaurant),
        widget.api.get(AdminApiRoutes.staff),
        widget.api.get(AdminApiRoutes.users),
      ]);
      if (!mounted) return;
      setState(() {
        _restaurantId = _map(values[0])['id']?.toString();
        _staff = _list(values[1]);
        _users = _list(values[2]);
      });
    } on AdminApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Non è stato possibile caricare il team.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _rows {
    final term = _search.text.trim().toLowerCase();
    return term.isEmpty
        ? _staff
        : _staff
            .where(
              (row) =>
                  '${row['employeeCode'] ?? ''} ${row['jobTitle'] ?? ''} ${_userName(row['userId'])}'
                      .toLowerCase()
                      .contains(term),
            )
            .toList();
  }

  Future<void> _editor([Map<String, dynamic>? existing]) async {
    if (_restaurantId == null) {
      _notice('Ristorante non disponibile.', error: true);
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      builder:
          (_) => _StaffEditor(
            api: widget.api,
            restaurantId: _restaurantId!,
            users: _users,
            existing: existing,
          ),
    );
    if (saved == true) await _load();
  }

  Future<void> _deactivate(Map<String, dynamic> member) async {
    final id = member['id']?.toString();
    if (id == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Disattiva membro staff'),
            content: const Text(
              'L’account non potrà più essere utilizzato come membro attivo del ristorante.',
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
    if (yes != true) return;
    setState(() => _saving = true);
    try {
      await widget.api.delete(AdminApiRoutes.staffMember(id));
      if (mounted) _notice('Membro staff disattivato.');
      await _load();
    } on AdminApiException catch (error) {
      if (mounted) _notice(error.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _notice(String text, {bool error = false}) =>
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
          Text('Staff', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Assegna gli utenti esistenti al ristorante e gestisci il loro profilo operativo.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Cerca per nome, ruolo o codice',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _loading || _saving ? null : () => _editor(),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Assegna utente'),
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
      return const Center(child: Text('Nessun membro staff attivo.'));
    }
    return ListView.separated(
      itemCount: _rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final member = _rows[index];
        final code = member['employeeCode']?.toString();
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: const CircleAvatar(child: Icon(Icons.badge_outlined)),
            title: Text(member['jobTitle']?.toString() ?? 'Membro del team'),
            subtitle: Text(
              'Codice: ${code?.isNotEmpty == true ? code : '—'}\n${_userName(member['userId'])}',
            ),
            isThreeLine: true,
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: 'Modifica',
                  onPressed: _saving ? null : () => _editor(member),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Disattiva',
                  onPressed: _saving ? null : () => _deactivate(member),
                  icon: const Icon(Icons.person_off_outlined),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _userName(Object? userId) {
    final id = userId?.toString();
    final user = _users.where((row) => row['id']?.toString() == id).firstOrNull;
    if (user == null) return 'Account non disponibile';
    return '${user['fullName'] ?? 'Utente'} · ${user['email'] ?? 'senza email'}';
  }
}

class _StaffEditor extends StatefulWidget {
  const _StaffEditor({
    required this.api,
    required this.restaurantId,
    required this.users,
    this.existing,
  });
  final AdminApiClient api;
  final String restaurantId;
  final List<Map<String, dynamic>> users;
  final Map<String, dynamic>? existing;
  @override
  State<_StaffEditor> createState() => _StaffEditorState();
}

class _StaffEditorState extends State<_StaffEditor> {
  final _form = GlobalKey<FormState>();
  String? _userId;
  late final TextEditingController _employeeCode;
  late final TextEditingController _jobTitle;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final item = widget.existing ?? const <String, dynamic>{};
    _userId = item['userId']?.toString();
    _employeeCode = TextEditingController(
      text: item['employeeCode']?.toString() ?? '',
    );
    _jobTitle = TextEditingController(text: item['jobTitle']?.toString() ?? '');
  }

  @override
  void dispose() {
    _employeeCode.dispose();
    _jobTitle.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final id = widget.existing?['id']?.toString();
    final body = <String, Object?>{
      'employeeCode': _optional(_employeeCode),
      'jobTitle': _optional(_jobTitle),
    };
    if (id == null) {
      body.addAll({'userId': _userId, 'restaurantId': widget.restaurantId});
    }
    try {
      if (id == null) {
        await widget.api.post(AdminApiRoutes.staff, body: body);
      } else {
        await widget.api.patch(AdminApiRoutes.staffMember(id), body: body);
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
          ? 'Assegna utente allo staff'
          : 'Modifica membro staff',
    ),
    content: SizedBox(
      width: 520,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.existing == null) ...[
              DropdownButtonFormField<String>(
                value:
                    widget.users.any((row) => row['id']?.toString() == _userId)
                        ? _userId
                        : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Account utente'),
                items: [
                  for (final user in widget.users)
                    DropdownMenuItem(
                      value: user['id']?.toString(),
                      child: Text(
                        '${user['fullName'] ?? 'Utente'} · ${user['email'] ?? 'senza email'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged:
                    _saving ? null : (value) => setState(() => _userId = value),
                validator:
                    (value) =>
                        value == null ? 'Seleziona un account utente' : null,
              ),
              const SizedBox(height: 12),
              const Text(
                'Se l’account non è presente, crealo prima nella sezione Utenti.',
                textAlign: TextAlign.left,
              ),
            ],
            if (widget.existing == null) const SizedBox(height: 12),
            _field(_employeeCode, 'Codice dipendente'),
            const SizedBox(height: 12),
            _field(_jobTitle, 'Ruolo operativo'),
          ],
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
  }) => TextFormField(
    controller: c,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator:
        (v) =>
            required && (v?.trim().isEmpty ?? true)
                ? 'Campo obbligatorio'
                : null,
  );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};
List<Map<String, dynamic>> _list(Object? value) {
  final raw =
      value is Map<String, dynamic> ? value['items'] ?? value['data'] : value;
  return raw is List
      ? raw.whereType<Map>().map((v) => Map<String, dynamic>.from(v)).toList()
      : const [];
}

String? _optional(TextEditingController c) =>
    c.text.trim().isEmpty ? null : c.text.trim();
