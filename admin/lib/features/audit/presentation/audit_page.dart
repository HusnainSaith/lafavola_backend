import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:la_favola_admin/app/providers.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

final auditProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final value = await ref.watch(apiClientProvider).get(AdminApiRoutes.audit);
  final rows = value is Map ? value['data'] : value;
  return rows is List
      ? rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : const [];
});

class AuditPage extends ConsumerWidget {
  const AuditPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(auditProvider);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(auditProvider.future),
        child: value.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, _) => ListView(
                padding: const EdgeInsets.all(24),
                children: [Text(error.toString())],
              ),
          data:
              (rows) => ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Attività amministrativa',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Registro in sola lettura, limitato al ristorante corrente.',
                  ),
                  const SizedBox(height: 20),
                  if (rows.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('Nessuna attività registrata.'),
                        ),
                      ),
                    )
                  else
                    for (final row in rows)
                      Card(
                        child: ListTile(
                          minVerticalPadding: 14,
                          leading: const Icon(Icons.history_rounded),
                          title: Text('${row['action'] ?? 'Azione'}'),
                          subtitle: Text(
                            '${row['resourceType'] ?? 'risorsa'} · ${row['correlationId'] ?? 'senza correlazione'}',
                          ),
                          trailing: Text(_date(row['createdAt'])),
                        ),
                      ),
                ],
              ),
        ),
      ),
    );
  }

  static String _date(Object? value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    return date == null ? '' : DateFormat('dd/MM HH:mm').format(date);
  }
}
