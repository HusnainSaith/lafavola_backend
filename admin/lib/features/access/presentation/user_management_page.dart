import 'package:flutter/material.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({
    super.key,
    required this.api,
    this.roleFilter,
    this.title = 'Utenti',
    this.subtitle =
        'Crea account operativi, assegna un ruolo e mantieni il minimo privilegio.',
  });
  final AdminApiClient api;
  final String? roleFilter;
  final String title;
  final String subtitle;

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _users = const [];
  List<Map<String, dynamic>> _roles = const [];
  List<Map<String, dynamic>> _permissions = const [];
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
      final data = await Future.wait<Object?>([
        widget.api.get(AdminApiRoutes.users),
        widget.api.get(AdminApiRoutes.roles),
        widget.api.get(AdminApiRoutes.permissions),
      ]);
      if (!mounted) return;
      setState(() {
        _users = _list(data[0]);
        _roles = _list(data[1]);
        _permissions = _list(data[2]);
      });
    } on AdminApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Non è stato possibile caricare gli utenti.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _rows {
    final term = _search.text.trim().toLowerCase();
    final scoped =
        widget.roleFilter == null
            ? _users
            : _users.where((user) {
              final role = user['role'];
              final name =
                  role is Map ? role['name']?.toString() : role?.toString();
              return name?.toLowerCase() == widget.roleFilter;
            }).toList();
    return term.isEmpty
        ? scoped
        : scoped
            .where(
              (v) =>
                  '${v['fullName'] ?? ''} ${v['email'] ?? ''} ${v['phone'] ?? ''}'
                      .toLowerCase()
                      .contains(term),
            )
            .toList();
  }

  Future<void> _edit([Map<String, dynamic>? user]) async {
    final changed = await showDialog<bool>(
      context: context,
      builder:
          (_) => _UserEditor(
            api: widget.api,
            roles: _roles,
            permissions: _permissions,
            existing: user,
            initialRoleName: widget.roleFilter,
          ),
    );
    if (changed == true) await _load();
  }

  Future<void> _remove(Map<String, dynamic> user) async {
    final id = user['id']?.toString();
    if (id == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Elimina utente'),
            content: Text(
              'Eliminare ${user['fullName'] ?? user['email'] ?? 'questo utente'}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Annulla'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Elimina'),
              ),
            ],
          ),
    );
    if (yes != true) return;
    setState(() => _saving = true);
    try {
      await widget.api.delete(AdminApiRoutes.user(id));
      if (mounted) _notice('Utente eliminato.');
      await _load();
    } on AdminApiException catch (e) {
      if (mounted) _notice(e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _managePermissions(Map<String, dynamic> user) async {
    final id = user['id']?.toString();
    if (id == null) return;
    await showDialog<void>(
      context: context,
      builder:
          (_) => _UserPermissionsDialog(
            api: widget.api,
            userId: id,
            userName: user['fullName']?.toString() ?? 'Utente',
            permissions: _permissions,
            roleId:
                user['role'] is Map
                    ? (user['role'] as Map)['id']?.toString()
                    : user['roleId']?.toString(),
          ),
    );
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
          Text(widget.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(widget.subtitle, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Cerca utente',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _loading || _saving ? null : () => _edit(),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Nuovo utente'),
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
      return const Center(child: Text('Nessun utente disponibile.'));
    }
    return ListView.separated(
      itemCount: _rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = _rows[index];
        final role = user['role'];
        final roleName =
            role is Map
                ? role['name']?.toString()
                : user['roleName']?.toString();
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(user['fullName']?.toString() ?? 'Utente'),
            subtitle: Text(
              '${user['email'] ?? user['phone'] ?? 'Nessun contatto'}\nRuolo: ${roleName ?? 'Non assegnato'}',
            ),
            isThreeLine: true,
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: 'Modifica',
                  onPressed: _saving ? null : () => _edit(user),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Permessi specifici',
                  onPressed: _saving ? null : () => _managePermissions(user),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                ),
                IconButton(
                  tooltip: 'Elimina',
                  onPressed: _saving ? null : () => _remove(user),
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

class _UserPermissionsDialog extends StatefulWidget {
  const _UserPermissionsDialog({
    required this.api,
    required this.userId,
    required this.userName,
    required this.permissions,
    this.roleId,
  });

  final AdminApiClient api;
  final String userId;
  final String userName;
  final List<Map<String, dynamic>> permissions;
  final String? roleId;

  @override
  State<_UserPermissionsDialog> createState() => _UserPermissionsDialogState();
}

class _UserPermissionsDialogState extends State<_UserPermissionsDialog> {
  Set<String> _assigned = const {};
  Set<String> _roleGranted = const {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

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
      final responses = await Future.wait<Object?>([
        widget.api.get(AdminApiRoutes.userPermissions(widget.userId)),
        if (widget.roleId != null)
          widget.api.get(AdminApiRoutes.rolePermissions(widget.roleId!)),
      ]);
      final permissions = _list(responses[0]);
      final rolePermissions =
          responses.length > 1
              ? _list(responses[1])
              : const <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _assigned =
            permissions
                .map((permission) => permission['name']?.toString())
                .whereType<String>()
                .toSet();
        _roleGranted =
            rolePermissions
                .map((permission) => permission['name']?.toString())
                .whereType<String>()
                .toSet();
      });
    } on AdminApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(Map<String, dynamic> permission, bool enabled) async {
    final resource = permission['resource']?.toString();
    final action = permission['action']?.toString();
    final name = permission['name']?.toString();
    if (resource == null || action == null || name == null) return;
    setState(() => _saving = true);
    try {
      await widget.api.post(
        AdminApiRoutes.userPermissions(widget.userId),
        body: {
          'feature': resource,
          'actions': [action],
          'assignmentAction': enabled ? 'add' : 'remove',
        },
      );
      if (!mounted) return;
      setState(() {
        final next = {..._assigned};
        enabled ? next.add(name) : next.remove(name);
        _assigned = next;
      });
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
    title: Text('Permessi · ${widget.userName}'),
    content: SizedBox(
      width: 640,
      height: 560,
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
              : ListView.builder(
                itemCount: widget.permissions.length,
                itemBuilder: (context, index) {
                  final permission = widget.permissions[index];
                  final name = permission['name']?.toString() ?? '';
                  final inherited = _roleGranted.contains(name);
                  return SwitchListTile(
                    value: _assigned.contains(name),
                    onChanged:
                        _saving || inherited
                            ? null
                            : (value) => _toggle(permission, value),
                    title: Text(name),
                    subtitle: Text(
                      inherited
                          ? 'Ereditato dal ruolo'
                          : '${permission['resource'] ?? 'risorsa'} · ${permission['action'] ?? 'azione'}',
                    ),
                  );
                },
              ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Chiudi'),
      ),
    ],
  );
}

class _UserEditor extends StatefulWidget {
  const _UserEditor({
    required this.api,
    required this.roles,
    required this.permissions,
    this.existing,
    this.initialRoleName,
  });
  final AdminApiClient api;
  final List<Map<String, dynamic>> roles;
  final List<Map<String, dynamic>> permissions;
  final Map<String, dynamic>? existing;
  final String? initialRoleName;
  @override
  State<_UserEditor> createState() => _UserEditorState();
}

class _UserEditorState extends State<_UserEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _password;
  String? _roleId;
  String _status = 'active';
  final Set<String> _permissionIds = {};
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final user = widget.existing ?? const <String, dynamic>{};
    _name = TextEditingController(text: user['fullName']?.toString() ?? '');
    _email = TextEditingController(text: user['email']?.toString() ?? '');
    _password = TextEditingController();
    final role = user['role'];
    _roleId = role is Map ? role['id']?.toString() : user['roleId']?.toString();
    if (_roleId == null && widget.initialRoleName != null) {
      _roleId =
          widget.roles
              .where(
                (role) =>
                    role['name']?.toString().toLowerCase() ==
                    widget.initialRoleName,
              )
              .firstOrNull?['id']
              ?.toString();
    }
    _status = user['status']?.toString() ?? 'active';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final id = widget.existing?['id']?.toString();
    final body = <String, Object?>{
      'fullName': _name.text.trim(),
      'email': _email.text.trim(),
      'roleId': _roleId,
      'status': _status,
    };
    if (_password.text.isNotEmpty) body['password'] = _password.text;
    try {
      if (id == null) {
        if (_permissionIds.isEmpty) {
          await widget.api.post(AdminApiRoutes.users, body: body);
        } else {
          body.remove('status');
          body['permissionIds'] = _permissionIds.toList();
          await widget.api.post(
            AdminApiRoutes.usersWithPermissions,
            body: body,
          );
        }
      } else {
        await widget.api.patch(AdminApiRoutes.user(id), body: body);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on AdminApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'Nuovo utente' : 'Modifica utente'),
    content: SizedBox(
      width: 540,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_name, 'Nome completo', required: true),
              const SizedBox(height: 12),
              _field(_email, 'Email lavoro', required: true, email: true),
              const SizedBox(height: 12),
              _field(
                _password,
                widget.existing == null
                    ? 'Password temporanea'
                    : 'Nuova password (facoltativa)',
                required: widget.existing == null,
                secret: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _roleId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ruolo',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Nessun ruolo'),
                  ),
                  ...widget.roles.map(
                    (r) => DropdownMenuItem(
                      value: r['id']?.toString(),
                      child: Text(r['name']?.toString() ?? 'Ruolo'),
                    ),
                  ),
                ],
                onChanged:
                    _saving ? null : (value) => setState(() => _roleId = value),
              ),
              if (widget.existing == null && widget.permissions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Permessi diretti facoltativi',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          widget.permissions.map((permission) {
                            final id = permission['id']?.toString();
                            if (id == null) return const SizedBox.shrink();
                            return FilterChip(
                              selected: _permissionIds.contains(id),
                              onSelected:
                                  _saving
                                      ? null
                                      : (selected) => setState(
                                        () =>
                                            selected
                                                ? _permissionIds.add(id)
                                                : _permissionIds.remove(id),
                                      ),
                              label: Text(
                                permission['name']?.toString() ?? 'Permesso',
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Stato',
                  border: OutlineInputBorder(),
                ),
                items:
                    const ['active', 'inactive', 'suspended']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                onChanged:
                    _saving
                        ? null
                        : (value) => setState(() => _status = value!),
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
    bool email = false,
    bool secret = false,
  }) => TextFormField(
    controller: c,
    obscureText: secret,
    keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: (v) {
      final text = v?.trim() ?? '';
      if (required && text.isEmpty) {
        return 'Campo obbligatorio';
      }
      if (email && text.isNotEmpty && !text.contains('@')) {
        return 'Email non valida';
      }
      if (secret && text.isNotEmpty && text.length < 8) {
        return 'Minimo 8 caratteri';
      }
      return null;
    },
  );
}

List<Map<String, dynamic>> _list(Object? value) {
  final raw =
      value is Map<String, dynamic> ? value['items'] ?? value['data'] : value;
  return raw is List
      ? raw.whereType<Map>().map((v) => Map<String, dynamic>.from(v)).toList()
      : const [];
}
