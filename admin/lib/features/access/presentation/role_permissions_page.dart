import 'package:flutter/material.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

/// Scoped role-permission assignment. It does not mutate role definitions or
/// remove the current administrator; every permission removal is confirmed.
class RolePermissionsPage extends StatefulWidget {
  const RolePermissionsPage({super.key, required this.api});
  final AdminApiClient api;
  @override
  State<RolePermissionsPage> createState() => _RolePermissionsPageState();
}

class _RolePermissionsPageState extends State<RolePermissionsPage> {
  List<Map<String, dynamic>> _roles = const [];
  List<Map<String, dynamic>> _permissions = const [];
  Set<String> _assigned = const {};
  String? _roleId;
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
      final values = await Future.wait<Object?>([
        widget.api.get(AdminApiRoutes.roles),
        widget.api.get(AdminApiRoutes.permissions),
      ]);
      final roles = _list(values[0]);
      if (!mounted) return;
      setState(() {
        _roles = roles;
        _permissions = _list(values[1]);
        _roleId ??= roles.isEmpty ? null : roles.first['id']?.toString();
      });
      if (_roleId != null) {
        await _loadAssignments();
      }
    } on AdminApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Non è stato possibile caricare ruoli e permessi.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadAssignments() async {
    final id = _roleId;
    if (id == null) return;
    try {
      final existing = _list(
        await widget.api.get(AdminApiRoutes.rolePermissions(id)),
      );
      if (mounted) {
        setState(
          () =>
              _assigned =
                  existing
                      .map((p) => p['id']?.toString())
                      .whereType<String>()
                      .toSet(),
        );
      }
    } on AdminApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    }
  }

  Future<void> _selectRole(String? id) async {
    if (id == null) return;
    setState(() {
      _roleId = id;
      _assigned = const {};
      _loading = true;
    });
    await _loadAssignments();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle(Map<String, dynamic> permission, bool enabled) async {
    final roleId = _roleId;
    final permissionId = permission['id']?.toString();
    if (roleId == null || permissionId == null) return;
    if (!enabled) {
      final yes = await showDialog<bool>(
        context: context,
        builder:
            (c) => AlertDialog(
              title: const Text('Rimuovi permesso'),
              content: Text(
                'Rimuovere “${permission['name'] ?? permissionId}” da questo ruolo?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Annulla'),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('Rimuovi'),
                ),
              ],
            ),
      );
      if (yes != true) return;
    }
    setState(() => _saving = true);
    try {
      if (enabled) {
        await widget.api.post(
          AdminApiRoutes.rolePermissions(roleId),
          body: {
            'permissionIds': [permissionId],
          },
        );
      } else {
        await widget.api.delete(
          AdminApiRoutes.rolePermission(roleId, permissionId),
        );
      }
      await _loadAssignments();
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
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child:
          _loading && _roles.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: FilledButton(
                  onPressed: _load,
                  child: Text('Riprova: $_error'),
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ruoli e permessi',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Assegna solo le autorizzazioni strettamente necessarie al ruolo selezionato.',
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _roleId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Ruolo selezionato',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _roles
                            .map(
                              (role) => DropdownMenuItem(
                                value: role['id']?.toString(),
                                child: Text(
                                  role['name']?.toString() ?? 'Ruolo',
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: _saving ? null : _selectRole,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      child:
                          _permissions.isEmpty
                              ? const Center(
                                child: Text('Nessun permesso configurato.'),
                              )
                              : ListView.separated(
                                itemCount: _permissions.length,
                                separatorBuilder:
                                    (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final permission = _permissions[index];
                                  final id = permission['id']?.toString();
                                  final enabled =
                                      id != null && _assigned.contains(id);
                                  return SwitchListTile.adaptive(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    title: Text(
                                      permission['name']?.toString() ??
                                          'Permesso',
                                    ),
                                    subtitle: Text(
                                      '${permission['resource'] ?? 'risorsa'} · ${permission['action'] ?? 'azione'}',
                                    ),
                                    value: enabled,
                                    onChanged:
                                        _saving
                                            ? null
                                            : (value) =>
                                                _toggle(permission, value),
                                  );
                                },
                              ),
                    ),
                  ),
                ],
              ),
    ),
  );
}

List<Map<String, dynamic>> _list(Object? value) {
  final raw =
      value is Map<String, dynamic> ? value['items'] ?? value['data'] : value;
  return raw is List
      ? raw.whereType<Map>().map((v) => Map<String, dynamic>.from(v)).toList()
      : const [];
}
