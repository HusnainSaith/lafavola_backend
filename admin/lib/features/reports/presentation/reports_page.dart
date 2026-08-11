import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:la_favola_admin/app/providers.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';

class ReportRange {
  const ReportRange(this.from, this.to);
  final DateTime from;
  final DateTime to;

  Map<String, dynamic> get query => {
    'from': DateFormat('yyyy-MM-dd').format(from),
    'to': DateFormat('yyyy-MM-dd').format(to),
  };
}

final reportRangeProvider = StateProvider<ReportRange>((_) {
  final today = DateUtils.dateOnly(DateTime.now());
  return ReportRange(today.subtract(const Duration(days: 29)), today);
});

final reportsProvider = FutureProvider<ReportSnapshot>((ref) async {
  final api = ref.watch(apiClientProvider);
  final range = ref.watch(reportRangeProvider);
  final values = await Future.wait<Object?>([
    api.get(AdminApiRoutes.reportsSales, query: range.query),
    api.get(AdminApiRoutes.reportsDailyRevenue, query: range.query),
    api.get(AdminApiRoutes.reportsPopularItems, query: range.query),
  ]);
  return ReportSnapshot(
    sales: _map(values[0]),
    daily: _list(values[1]),
    popular: _list(values[2]),
  );
});

class ReportSnapshot {
  const ReportSnapshot({
    required this.sales,
    required this.daily,
    required this.popular,
  });
  final Map<String, dynamic> sales;
  final List<Map<String, dynamic>> daily;
  final List<Map<String, dynamic>> popular;
}

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportRangeProvider);
    final reports = ref.watch(reportsProvider);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(reportsProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report e analisi',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ricavi riconosciuti, rimborsi e prodotti più richiesti.',
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => _selectRange(context, ref, range),
                  icon: const Icon(Icons.date_range_outlined),
                  label: Text(
                    '${DateFormat('dd/MM/yyyy').format(range.from)} – '
                    '${DateFormat('dd/MM/yyyy').format(range.to)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            reports.when(
              loading: () => const _ReportLoading(),
              error:
                  (error, _) => _ReportError(
                    message:
                        error is AdminApiException
                            ? error.message
                            : 'Non è stato possibile caricare i report.',
                    onRetry: () => ref.invalidate(reportsProvider),
                  ),
              data: (data) => _ReportContent(data: data),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectRange(
    BuildContext context,
    WidgetRef ref,
    ReportRange current,
  ) async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: current.from, end: current.to),
      helpText: 'Intervallo del report',
      cancelText: 'Annulla',
      confirmText: 'Applica',
      saveText: 'Applica',
    );
    if (selected != null) {
      ref.read(reportRangeProvider.notifier).state = ReportRange(
        DateUtils.dateOnly(selected.start),
        DateUtils.dateOnly(selected.end),
      );
    }
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.data});
  final ReportSnapshot data;

  @override
  Widget build(BuildContext context) {
    final sales = data.sales;
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth >= 1000
                    ? 4
                    : constraints.maxWidth >= 600
                    ? 2
                    : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio:
                  columns == 4
                      ? 2.1
                      : columns == 2
                      ? 1.8
                      : 3.0,
              children: [
                _KpiCard(
                  label: 'Ricavo netto',
                  value: _money(sales['netRevenueMinor']),
                  icon: Icons.payments_outlined,
                ),
                _KpiCard(
                  label: 'Ordini completati',
                  value: '${_number(sales['successfulOrders'])}',
                  icon: Icons.receipt_long_outlined,
                ),
                _KpiCard(
                  label: 'Valore medio',
                  value: _money(sales['averageOrderValueMinor']),
                  icon: Icons.query_stats_outlined,
                ),
                _KpiCard(
                  label: 'Rimborsi',
                  value: _money(sales['refundsMinor']),
                  icon: Icons.currency_exchange_outlined,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final revenue = _RevenuePanel(rows: data.daily);
            final popular = _PopularItems(rows: data.popular);
            return wide
                ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: revenue),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: popular),
                  ],
                )
                : Column(
                  children: [revenue, const SizedBox(height: 16), popular],
                );
          },
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(child: Icon(icon)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _RevenuePanel extends StatelessWidget {
  const _RevenuePanel({required this.rows});
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final recent = rows.length > 14 ? rows.sublist(rows.length - 14) : rows;
    final maxValue = recent.fold<num>(
      0,
      (max, row) =>
          _number(row['netRevenueMinor']) > max
              ? _number(row['netRevenueMinor'])
              : max,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ricavo giornaliero',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(child: Text('Nessun ricavo nel periodo.')),
              )
            else
              for (final row in recent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Semantics(
                    label: '${row['date']}: ${_money(row['netRevenueMinor'])}',
                    child: Row(
                      children: [
                        SizedBox(
                          width: 72,
                          child: Text(_shortDate(row['date']?.toString())),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(6),
                            value:
                                maxValue == 0
                                    ? 0
                                    : _number(row['netRevenueMinor']) /
                                        maxValue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 88,
                          child: Text(
                            _money(row['netRevenueMinor']),
                            textAlign: TextAlign.end,
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
}

class _PopularItems extends StatelessWidget {
  const _PopularItems({required this.rows});
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Piatti popolari',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: Text('Nessun prodotto venduto.')),
            )
          else
            for (var index = 0; index < rows.length && index < 10; index++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(rows[index]['name']?.toString() ?? 'Prodotto'),
                subtitle: Text('${_number(rows[index]['quantity'])} venduti'),
                trailing: Text(_money(rows[index]['revenueMinor'])),
              ),
        ],
      ),
    ),
  );
}

class _ReportLoading extends StatelessWidget {
  const _ReportLoading();
  @override
  Widget build(BuildContext context) => const Card(
    child: SizedBox(
      height: 280,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

class _ReportError extends StatelessWidget {
  const _ReportError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
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

num _number(Object? value) =>
    value is num ? value : num.tryParse('$value') ?? 0;
String _money(Object? minor) => NumberFormat.currency(
  locale: 'it_IT',
  symbol: '€',
).format(_number(minor) / 100);
String _shortDate(String? value) {
  final date = DateTime.tryParse(value ?? '');
  return date == null ? '—' : DateFormat('dd/MM').format(date);
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
