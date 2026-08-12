import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_favola_admin/app/providers.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

final driverDirectoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final value = await ref
          .watch(apiClientProvider)
          .get(AdminApiRoutes.drivers);
      return _list(value);
    });

class DriverManagementPage extends ConsumerWidget {
  const DriverManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivers = ref.watch(driverDirectoryProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driver',
                        style: Theme.of(
                          context,
                        ).textTheme.displaySmall?.copyWith(
                          fontFamily: 'Lora',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Crea gli account dei driver e gestisci la loro disponibilità.',
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openEditor(context, ref),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Nuovo driver'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: drivers.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) => _DriverMessage(
                      message:
                          error is AdminApiException
                              ? error.message
                              : 'Non è stato possibile caricare i driver.',
                      action: () => ref.invalidate(driverDirectoryProvider),
                    ),
                data:
                    (rows) =>
                        rows.isEmpty
                            ? _DriverMessage(
                              message:
                                  'Nessun driver configurato. Crea il primo account per iniziare le consegne.',
                              action: () => _openEditor(context, ref),
                              actionLabel: 'Crea driver',
                            )
                            : RefreshIndicator(
                              onRefresh:
                                  () => ref.refresh(
                                    driverDirectoryProvider.future,
                                  ),
                              child: ListView.separated(
                                itemCount: rows.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final row = rows[index];
                                  final active = row['isActive'] == true;
                                  return Card(
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                      leading: CircleAvatar(
                                        child: Icon(
                                          active
                                              ? Icons.delivery_dining_outlined
                                              : Icons.person_off_outlined,
                                        ),
                                      ),
                                      title: Text(
                                        row['fullName']?.toString() ?? 'Driver',
                                      ),
                                      subtitle: Text(
                                        [
                                          row['email']?.toString(),
                                          row['phone']?.toString(),
                                          if (row['employeeCode'] != null)
                                            'Codice ${row['employeeCode']}',
                                        ].whereType<String>().join(' · '),
                                      ),
                                      trailing: Wrap(
                                        spacing: 6,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Chip(
                                            avatar: Icon(
                                              active
                                                  ? Icons.check_circle_outline
                                                  : Icons.pause_circle_outline,
                                              size: 18,
                                            ),
                                            label: Text(
                                              active
                                                  ? 'Disponibile'
                                                  : 'Inattivo',
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Modifica driver',
                                            onPressed:
                                                () => _openEditor(
                                                  context,
                                                  ref,
                                                  row,
                                                ),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                          ),
                                          if (active)
                                            IconButton(
                                              tooltip: 'Disattiva driver',
                                              onPressed:
                                                  () => _deactivate(
                                                    context,
                                                    ref,
                                                    row,
                                                  ),
                                              icon: const Icon(
                                                Icons.person_off_outlined,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, [
    Map<String, dynamic>? existing,
  ]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder:
          (_) => _DriverEditor(
            api: ref.read(apiClientProvider),
            existing: existing,
          ),
    );
    if (saved == true) ref.invalidate(driverDirectoryProvider);
  }

  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> driver,
  ) async {
    final approved = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Disattiva driver'),
            content: Text(
              '${driver['fullName'] ?? 'Il driver'} non potrà ricevere nuove consegne.',
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
    if (approved != true || !context.mounted) return;
    try {
      await ref
          .read(apiClientProvider)
          .delete(AdminApiRoutes.driver(driver['id'].toString()));
      ref.invalidate(driverDirectoryProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Driver disattivato.')));
      }
    } on AdminApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _DriverEditor extends StatefulWidget {
  const _DriverEditor({required this.api, this.existing});
  final AdminApiClient api;
  final Map<String, dynamic>? existing;

  @override
  State<_DriverEditor> createState() => _DriverEditorState();
}

class _DriverEditorState extends State<_DriverEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _code;
  late final TextEditingController _password;
  bool _active = true;
  bool _saving = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    final row = widget.existing ?? const <String, dynamic>{};
    _name = TextEditingController(text: row['fullName']?.toString() ?? '');
    _email = TextEditingController(text: row['email']?.toString() ?? '');
    _phone = TextEditingController(text: row['phone']?.toString() ?? '');
    _code = TextEditingController(text: row['employeeCode']?.toString() ?? '');
    _password = TextEditingController();
    _active = row['isActive'] != false;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = <String, Object?>{
      'fullName': _name.text.trim(),
      'email': _email.text.trim(),
      if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
      if (_code.text.trim().isNotEmpty) 'employeeCode': _code.text.trim(),
      if (_password.text.isNotEmpty) 'temporaryPassword': _password.text,
      if (widget.existing != null) 'isActive': _active,
    };
    try {
      if (widget.existing == null) {
        await widget.api.post(AdminApiRoutes.drivers, body: body);
      } else {
        await widget.api.patch(
          AdminApiRoutes.driver(widget.existing!['id'].toString()),
          body: body,
        );
      }
      if (mounted) Navigator.pop(context, true);
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
    title: Text(widget.existing == null ? 'Nuovo driver' : 'Modifica driver'),
    content: SizedBox(
      width: 560,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_name, 'Nome completo', required: true),
              const SizedBox(height: 12),
              _field(
                _email,
                'Email',
                required: true,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _field(
                _phone,
                'Telefono internazionale',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _field(_code, 'Codice dipendente'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText:
                      widget.existing == null
                          ? 'Password temporanea'
                          : 'Nuova password temporanea (facoltativa)',
                  suffixIcon: IconButton(
                    tooltip:
                        _showPassword ? 'Nascondi password' : 'Mostra password',
                    onPressed:
                        () => setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  final required = widget.existing == null;
                  if (required && (value?.isEmpty ?? true)) {
                    return 'Campo obbligatorio';
                  }
                  if ((value?.isNotEmpty ?? false) && value!.length < 8) {
                    return 'Usa almeno 8 caratteri';
                  }
                  return null;
                },
              ),
              if (widget.existing != null)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Driver attivo'),
                  value: _active,
                  onChanged:
                      _saving
                          ? null
                          : (value) => setState(() => _active = value),
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
    TextInputType? keyboardType,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final text = value?.trim() ?? '';
      if (required && text.isEmpty) return 'Campo obbligatorio';
      if (label == 'Email' && text.isNotEmpty && !text.contains('@')) {
        return 'Inserisci un indirizzo email valido';
      }
      return null;
    },
  );
}

class _DriverMessage extends StatelessWidget {
  const _DriverMessage({
    required this.message,
    required this.action,
    this.actionLabel = 'Riprova',
  });
  final String message;
  final VoidCallback action;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.delivery_dining_outlined, size: 48),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: action, child: Text(actionLabel)),
      ],
    ),
  );
}

List<Map<String, dynamic>> _list(Object? value) {
  final raw =
      value is Map<String, dynamic> ? value['items'] ?? value['data'] : value;
  return raw is List
      ? raw.whereType<Map>().map((row) {
        final normalized = Map<String, dynamic>.from(row);
        final user = normalized['user'];
        if (user is Map) {
          normalized['fullName'] ??= user['fullName'];
          normalized['email'] ??= user['email'];
          normalized['phone'] ??= user['phone'];
          normalized['userId'] ??= user['id'];
        }
        return normalized;
      }).toList()
      : const [];
}
