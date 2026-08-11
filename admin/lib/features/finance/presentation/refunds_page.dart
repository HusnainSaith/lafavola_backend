import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:la_favola_admin/app/providers.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

final refundsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final value = await ref
      .watch(apiClientProvider)
      .get(AdminApiRoutes.refundsAdmin);
  final envelope =
      value is Map
          ? Map<String, dynamic>.from(value)
          : const <String, dynamic>{};
  final rows = value is List ? value : envelope['data'];
  return rows is List
      ? rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : const [];
});

class RefundsPage extends ConsumerWidget {
  const RefundsPage({super.key});

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> row,
  ) async {
    final id = row['id']?.toString();
    if (id == null) return;
    final approved = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Approva rimborso'),
            content: const Text(
              'Questa azione può avviare un rimborso presso il provider di pagamento. Confermi?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Approva'),
              ),
            ],
          ),
    );
    if (approved != true || !context.mounted) return;
    try {
      await ref
          .read(apiClientProvider)
          .patch(
            AdminApiRoutes.approveRefund(id),
            body: const <String, dynamic>{},
          );
      ref.invalidate(refundsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Rimborso aggiornato.')));
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
    final rows = ref.watch(refundsProvider);
    return _AsyncListScaffold(
      title: 'Rimborsi',
      subtitle:
          'Coda finanziaria del ristorante. Le approvazioni richiedono conferma.',
      value: rows,
      onRefresh: () => ref.refresh(refundsProvider.future),
      emptyMessage: 'Nessun rimborso da mostrare.',
      rowBuilder: (row) {
        final amount = (num.tryParse('${row['amountMinor'] ?? 0}') ?? 0) / 100;
        final status = '${row['status'] ?? 'requested'}';
        return Card(
          child: ListTile(
            minVerticalPadding: 16,
            leading: const Icon(Icons.currency_exchange_outlined),
            title: Text(
              NumberFormat.currency(
                locale: 'it_IT',
                symbol: '€',
              ).format(amount),
            ),
            subtitle: Text('${row['reason'] ?? 'Rimborso'} · $status'),
            trailing:
                status == 'requested'
                    ? FilledButton.tonal(
                      onPressed: () => _approve(context, ref, row),
                      child: const Text('Approva'),
                    )
                    : Chip(label: Text(status)),
          ),
        );
      },
    );
  }
}

class _AsyncListScaffold extends StatelessWidget {
  const _AsyncListScaffold({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onRefresh,
    required this.emptyMessage,
    required this.rowBuilder,
  });
  final String title;
  final String subtitle;
  final AsyncValue<List<Map<String, dynamic>>> value;
  final Future<void> Function() onRefresh;
  final String emptyMessage;
  final Widget Function(Map<String, dynamic>) rowBuilder;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: RefreshIndicator(
      onRefresh: onRefresh,
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
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(subtitle),
                const SizedBox(height: 20),
                if (rows.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text(emptyMessage)),
                    ),
                  )
                else
                  for (final row in rows) ...[
                    rowBuilder(row),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
      ),
    ),
  );
}
