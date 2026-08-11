import 'package:flutter/material.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

/// Conversation-first support desk for administrators and support staff.
class SupportDeskPage extends StatefulWidget {
  const SupportDeskPage({super.key, required this.api});
  final AdminApiClient api;

  @override
  State<SupportDeskPage> createState() => _SupportDeskPageState();
}

class _SupportDeskPageState extends State<SupportDeskPage> {
  final _composer = TextEditingController();
  List<Map<String, Object?>> _tickets = const [];
  List<Map<String, Object?>> _messages = const [];
  Map<String, Object?>? _ticket;
  String? _selectedId;
  String? _error;
  var _loading = true;
  var _loadingDetail = false;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _loadQueue() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final value = await widget.api.get(AdminApiRoutes.supportQueue);
      if (mounted) setState(() => _tickets = _list(value));
    } on AdminApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Coda supporto non disponibile.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(Map<String, Object?> ticket) async {
    final id = _text(ticket['id']);
    if (id == null) return;
    setState(() {
      _selectedId = id;
      _ticket = null;
      _messages = const [];
      _loadingDetail = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object?>([
        widget.api.get(AdminApiRoutes.supportTicket(id)),
        widget.api.get(AdminApiRoutes.supportMessages(id)),
      ]);
      if (!mounted || _selectedId != id) return;
      final detail = _map(values[0]);
      setState(() {
        _ticket = _map(detail?['ticket']) ?? detail;
        _messages = _list(values[1]);
      });
      await widget.api.patch(AdminApiRoutes.readSupportTicket(id), body: {});
    } on AdminApiException catch (error) {
      if (mounted && _selectedId == id) setState(() => _error = error.message);
    } finally {
      if (mounted && _selectedId == id) setState(() => _loadingDetail = false);
    }
  }

  Future<void> _claim() =>
      _perform((id) => widget.api.post(AdminApiRoutes.supportClaim(id)));

  Future<void> _setStatus(String status) => _perform(
    (id) => widget.api.patch(
      AdminApiRoutes.supportStatus(id),
      body: {'status': status},
    ),
  );

  Future<void> _send() async {
    final body = _composer.text.trim();
    if (body.isEmpty) {
      setState(() => _error = 'Scrivi un messaggio prima di inviare.');
      return;
    }
    await _perform(
      (id) => widget.api.post(
        AdminApiRoutes.supportMessages(id),
        body: {'body': body},
      ),
      clearComposer: true,
    );
  }

  Future<void> _perform(
    Future<Object?> Function(String id) action, {
    bool clearComposer = false,
  }) async {
    final id = _selectedId;
    if (id == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await action(id);
      if (clearComposer) _composer.clear();
      await _loadQueue();
      await _select({'id': id});
    } on AdminApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supporto',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontFamily: 'Lora',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text('Prendi in carico le richieste e rispondi dal tablet.'),
            const SizedBox(height: 16),
            Expanded(
              child:
                  wide
                      ? Row(
                        children: [
                          Expanded(flex: 4, child: _queue()),
                          const SizedBox(width: 16),
                          Expanded(flex: 6, child: _conversation()),
                        ],
                      )
                      : DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            const TabBar(
                              tabs: [Tab(text: 'Coda'), Tab(text: 'Ticket')],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: TabBarView(
                                children: [_queue(), _conversation()],
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _queue() => Card(
    child:
        _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _tickets.isEmpty
            ? _SupportNotice(message: _error!, onRetry: _loadQueue)
            : _tickets.isEmpty
            ? const _SupportNotice(message: 'La coda supporto è vuota.')
            : ListView.separated(
              itemCount: _tickets.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final ticket = _tickets[index];
                return ListTile(
                  selected: _text(ticket['id']) == _selectedId,
                  title: Text(_text(ticket['subject']) ?? 'Richiesta supporto'),
                  subtitle: Text(
                    '${_text(ticket['category']) ?? 'generale'} · '
                    '${_text(ticket['priority']) ?? 'normale'}',
                  ),
                  trailing: Chip(label: Text(_label(_text(ticket['status'])))),
                  onTap: () => _select(ticket),
                );
              },
            ),
  );

  Widget _conversation() {
    if (_loadingDetail) {
      return const Card(child: Center(child: CircularProgressIndicator()));
    }
    if (_ticket == null) {
      return Card(
        child: _SupportNotice(
          message: _error ?? 'Seleziona una conversazione dalla coda.',
          onRetry: _error == null ? null : _loadQueue,
        ),
      );
    }
    final status = _text(_ticket!['status']) ?? 'open';
    final canReply = !{'resolved', 'closed'}.contains(status);
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _text(_ticket!['subject']) ?? 'Conversazione',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Chip(label: Text(_label(status))),
                OutlinedButton.icon(
                  onPressed: _submitting ? null : _claim,
                  icon: const Icon(Icons.assignment_ind_outlined),
                  label: const Text('Prendi in carico'),
                ),
                if (canReply)
                  FilledButton.tonal(
                    onPressed:
                        _submitting ? null : () => _setStatus('resolved'),
                    child: const Text('Risolvi'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child:
                _messages.isEmpty
                    ? const Center(child: Text('Nessun messaggio disponibile.'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final staff = _text(message['authorType']) == 'staff';
                        return Align(
                          alignment:
                              staff
                                  ? AlignmentDirectional.centerEnd
                                  : AlignmentDirectional.centerStart,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 460),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  staff
                                      ? const Color(0x1F774E32)
                                      : const Color(0xFFF4EDE6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_text(message['body']) ?? ''),
                          ),
                        );
                      },
                    ),
          ),
          if (canReply) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      minLines: 1,
                      maxLines: 4,
                      enabled: !_submitting,
                      decoration: const InputDecoration(
                        labelText: 'Risposta al cliente',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Invia risposta',
                    onPressed: _submitting ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SupportNotice extends StatelessWidget {
  const _SupportNotice({required this.message, this.onRetry});
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.forum_outlined, size: 36),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Riprova'),
            ),
          ],
        ],
      ),
    ),
  );
}

List<Map<String, Object?>> _list(Object? value) {
  final source = value is Map ? value['items'] ?? value['data'] : value;
  if (source is! List) return const [];
  return source
      .whereType<Map>()
      .map((item) => Map<String, Object?>.from(item))
      .toList(growable: false);
}

Map<String, Object?>? _map(Object? value) =>
    value is Map ? Map<String, Object?>.from(value) : null;

String? _text(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

String _label(String? value) => switch (value) {
  'open' => 'Aperto',
  'in_progress' => 'In lavorazione',
  'waiting_customer' => 'Attesa cliente',
  'resolved' => 'Risolto',
  'closed' => 'Chiuso',
  _ => value ?? '—',
};
