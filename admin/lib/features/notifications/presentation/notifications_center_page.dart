import 'package:flutter/material.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

class NotificationsCenterPage extends StatefulWidget {
  const NotificationsCenterPage({super.key, required this.api});
  final AdminApiClient api;

  @override
  State<NotificationsCenterPage> createState() =>
      _NotificationsCenterPageState();
}

class _NotificationsCenterPageState extends State<NotificationsCenterPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _notifications = const [];
  List<Map<String, dynamic>> _devices = const [];
  Map<String, dynamic> _preferences = const {};

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
      final result = await Future.wait<Object?>([
        widget.api.get(AdminApiRoutes.notifications),
        widget.api.get(AdminApiRoutes.notificationPreferences),
        widget.api.get(AdminApiRoutes.notificationDevices),
      ]);
      if (!mounted) return;
      setState(() {
        _notifications = _list(result[0]);
        _preferences = _map(result[1]);
        _devices = _list(result[2]);
      });
    } on AdminApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Non è stato possibile caricare le notifiche.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _read(Map<String, dynamic> notification) async {
    if (notification['readAt'] != null || notification['id'] == null) return;
    setState(() => _saving = true);
    try {
      await widget.api.patch(
        AdminApiRoutes.readNotification(notification['id'].toString()),
      );
      await _load();
    } on AdminApiException catch (error) {
      if (mounted) _message(error.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _open(Map<String, dynamic> notification) async {
    final id = notification['id']?.toString();
    if (id == null) return;
    setState(() => _saving = true);
    try {
      final response = await widget.api.get(AdminApiRoutes.notification(id));
      final detail = _map(response);
      if (notification['readAt'] == null) {
        await widget.api.patch(AdminApiRoutes.readNotification(id));
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(
                detail['title']?.toString() ??
                    notification['title']?.toString() ??
                    'Notifica',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Text(
                    detail['body']?.toString() ??
                        detail['message']?.toString() ??
                        notification['body']?.toString() ??
                        '',
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
      await _load();
    } on AdminApiException catch (error) {
      if (mounted) _message(error.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggle(String field, bool value) async {
    setState(() {
      _saving = true;
      _preferences = {..._preferences, field: value};
    });
    try {
      final saved = await widget.api.patch(
        AdminApiRoutes.notificationPreferences,
        body: {field: value},
      );
      if (mounted && saved is Map<String, dynamic>) {
        setState(() => _preferences = saved);
      }
    } on AdminApiException catch (error) {
      if (mounted) _message(error.message, error: true);
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deactivateDevice(Map<String, dynamic> device) async {
    final id = device['id']?.toString();
    if (id == null) return;
    setState(() => _saving = true);
    try {
      await widget.api.delete(AdminApiRoutes.notificationDevice(id));
      await _load();
      if (mounted) _message('Dispositivo disattivato.');
    } on AdminApiException catch (error) {
      if (mounted) _message(error.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String value, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: error ? Theme.of(context).colorScheme.error : null,
          content: Text(value),
        ),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
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
              : LayoutBuilder(
                builder: (context, box) {
                  final split = box.maxWidth >= 900;
                  final inbox = _inbox();
                  final preferences = Column(
                    children: [
                      _preferenceCard(),
                      const SizedBox(height: 16),
                      _devicesCard(),
                    ],
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifiche',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Avvisi operativi e preferenze del tablet.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child:
                            split
                                ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 3, child: inbox),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 2,
                                      child: SingleChildScrollView(
                                        child: preferences,
                                      ),
                                    ),
                                  ],
                                )
                                : ListView(
                                  children: [
                                    inbox,
                                    const SizedBox(height: 16),
                                    preferences,
                                  ],
                                ),
                      ),
                    ],
                  );
                },
              ),
    ),
  );

  Widget _inbox() => Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Posta in arrivo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                onPressed: _saving ? null : _load,
                tooltip: 'Aggiorna',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        if (_notifications.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Nessun avviso operativo.')),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _notifications.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = _notifications[index];
                final unread = row['readAt'] == null;
                return ListTile(
                  enabled: !_saving,
                  onTap: () => _open(row),
                  leading: Icon(
                    unread
                        ? Icons.mark_email_unread_outlined
                        : Icons.mark_email_read_outlined,
                  ),
                  title: Text(
                    row['title']?.toString() ??
                        row['type']?.toString() ??
                        'Notifica',
                  ),
                  subtitle: Text(
                    row['body']?.toString() ?? row['message']?.toString() ?? '',
                  ),
                  trailing:
                      unread
                          ? TextButton(
                            onPressed: () => _read(row),
                            child: const Text('Segna letta'),
                          )
                          : const Icon(Icons.done, size: 18),
                );
              },
            ),
          ),
      ],
    ),
  );
  Widget _preferenceCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preferenze', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Le modifiche si applicano solo al tuo account.'),
          const SizedBox(height: 8),
          _switch('pushOrderUpdates', 'Push aggiornamenti ordine'),
          _switch('emailOrderUpdates', 'Email aggiornamenti ordine'),
          _switch('smsOrderUpdates', 'SMS aggiornamenti ordine'),
          const Divider(),
          _switch('pushPromotions', 'Push promozioni'),
          _switch('emailPromotions', 'Email promozioni'),
          _switch('couponExpirationAlerts', 'Avvisi scadenza coupon'),
        ],
      ),
    ),
  );
  Widget _devicesCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dispositivi push',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (_devices.isEmpty)
            const Text('Nessun dispositivo push registrato.')
          else
            ..._devices.map(
              (device) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tablet_android_outlined),
                title: Text(device['platform']?.toString() ?? 'Android'),
                subtitle: Text(
                  device['isActive'] == false ? 'Disattivato' : 'Attivo',
                ),
                trailing:
                    device['isActive'] == false
                        ? null
                        : IconButton(
                          tooltip: 'Disattiva dispositivo',
                          onPressed:
                              _saving ? null : () => _deactivateDevice(device),
                          icon: const Icon(Icons.link_off_outlined),
                        ),
              ),
            ),
        ],
      ),
    ),
  );
  Widget _switch(String field, String label) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    value: _preferences[field] == true,
    onChanged: _saving ? null : (value) => _toggle(field, value),
    title: Text(label),
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
