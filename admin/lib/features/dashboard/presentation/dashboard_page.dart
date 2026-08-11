import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:la_favola_admin/app/providers.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

final dashboardSummaryProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final value = await ref
          .watch(apiClientProvider)
          .get(AdminApiRoutes.dashboardSummary);
      if (value is Map) return Map<String, dynamic>.from(value);
      throw const AdminApiException('La panoramica non contiene dati validi.');
    });

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardSummaryProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Operazioni di oggi',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Dati live e limitati al ristorante associato al tuo account.',
            ),
            const SizedBox(height: 24),
            summary.when(
              loading: () => const _DashboardSkeleton(),
              error:
                  (error, _) => _DashboardError(
                    message:
                        error is AdminApiException
                            ? error.message
                            : 'Impossibile caricare la panoramica.',
                    onRetry: () => ref.invalidate(dashboardSummaryProvider),
                  ),
              data: (data) => _DashboardContent(data: data),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data});

  final Map<String, dynamic> data;

  int _value(String section, String key) {
    final block = data[section];
    return block is Map ? int.tryParse('${block[key] ?? 0}') ?? 0 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final revenue = _value('revenue', 'paidMinorToday') / 100;
    final cards = [
      (
        'Ordini oggi',
        _value('orders', 'today'),
        Icons.receipt_long_outlined,
        '/orders',
      ),
      (
        'Da gestire',
        _value('orders', 'attention'),
        Icons.priority_high_rounded,
        '/orders',
      ),
      (
        'Pronti',
        _value('orders', 'ready'),
        Icons.takeout_dining_outlined,
        '/orders',
      ),
      (
        'Consegne attive',
        _value('deliveries', 'active'),
        Icons.delivery_dining_outlined,
        '/deliveries',
      ),
      (
        'Rimborsi richiesti',
        _value('refunds', 'requested'),
        Icons.currency_exchange_outlined,
        '/refunds',
      ),
      (
        'Supporto aperto',
        _value('support', 'open'),
        Icons.forum_outlined,
        '/support',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth >= 1000
                    ? 3
                    : constraints.maxWidth >= 620
                    ? 2
                    : 1;
            final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final item in cards)
                  SizedBox(
                    width: width,
                    child: Card(
                      child: InkWell(
                        onTap: () => context.go(item.$4),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(item.$3, size: 32),
                              const SizedBox(width: 16),
                              Expanded(child: Text(item.$1)),
                              Text(
                                '${item.$2}',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            minVerticalPadding: 20,
            leading: const Icon(Icons.euro_rounded, size: 32),
            title: const Text('Incasso pagato di oggi'),
            subtitle: const Text(
              'Totale confermato dal backend; rimborsi nei report netti.',
            ),
            trailing: Text(
              NumberFormat.currency(
                locale: 'it_IT',
                symbol: '€',
              ).format(revenue),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 260,
    child: Center(child: CircularProgressIndicator()),
  );
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Riprova'),
          ),
        ],
      ),
    ),
  );
}
