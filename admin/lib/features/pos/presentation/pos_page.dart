import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_favola_admin/app/providers.dart';
import 'package:la_favola_admin/core/api/admin_api_client.dart';
import 'package:la_favola_admin/core/theme/app_theme.dart';
import 'package:la_favola_admin/features/pos/application/pos_controller.dart';
import 'package:la_favola_admin/features/pos/domain/pos_models.dart';
import 'package:la_favola_admin/features/printing/application/thermal_printer_controller.dart';
import 'package:uuid/uuid.dart';

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(posControllerProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Material(
        color: BrandColors.paper,
        child: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.point_of_sale), text: 'Nuovo ordine'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Ricevute e stampante'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabs,
          children: const [_NewPosOrder(), _ReceiptArchive()],
        ),
      ),
    ],
  );
}

class _NewPosOrder extends ConsumerStatefulWidget {
  const _NewPosOrder();

  @override
  ConsumerState<_NewPosOrder> createState() => _NewPosOrderState();
}

class _NewPosOrderState extends ConsumerState<_NewPosOrder> {
  final _search = TextEditingController();
  final _table = TextEditingController();
  final _customer = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  String? _categoryId;
  String _orderType = 'takeaway';
  String _paymentMethod = 'cash';

  @override
  void dispose() {
    for (final controller in [_search, _table, _customer, _phone, _note]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posControllerProvider);
    if (state.loading && state.catalog == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.catalog == null) {
      return _Failure(
        message: state.error ?? 'Catalogo cassa non disponibile.',
        onRetry: () => ref.read(posControllerProvider.notifier).load(),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        final catalogue = _Catalogue(
          catalog: state.catalog!,
          categoryId: _categoryId,
          search: _search,
          onCategory: (value) => setState(() => _categoryId = value),
          onAdd: _configure,
        );
        final cart = _Cart(
          state: state,
          orderType: _orderType,
          paymentMethod: _paymentMethod,
          table: _table,
          customer: _customer,
          phone: _phone,
          note: _note,
          onOrderType: (value) => setState(() => _orderType = value),
          onPaymentMethod: (value) => setState(() => _paymentMethod = value),
          onCheckout: _checkout,
        );
        if (wide) {
          return Row(
            children: [
              Expanded(flex: 7, child: catalogue),
              const VerticalDivider(width: 1),
              SizedBox(width: 390, child: cart),
            ],
          );
        }
        return Column(
          children: [
            Expanded(child: catalogue),
            SizedBox(height: 360, child: cart),
          ],
        );
      },
    );
  }

  Future<void> _configure(PosMenuItem item) async {
    final line = await showDialog<PosCartLine>(
      context: context,
      builder: (_) => _ConfigureItemDialog(item: item),
    );
    if (line != null) ref.read(posControllerProvider.notifier).add(line);
  }

  Future<void> _checkout() async {
    if (_orderType == 'dine_in' && _table.text.trim().isEmpty) {
      _message('Inserisci il tavolo per un ordine in sala.', error: true);
      return;
    }
    final receipt = await ref
        .read(posControllerProvider.notifier)
        .checkout(
          orderType: _orderType,
          tableLabel: _table.text,
          customerName: _customer.text,
          customerPhone: _phone.text,
          customerNote: _note.text,
          paymentMethod: _paymentMethod,
        );
    if (!mounted || receipt == null) return;
    _table.clear();
    _customer.clear();
    _phone.clear();
    _note.clear();
    await showPrintableReceiptDialog(context, receipt);
  }

  void _message(String value, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}

class _Catalogue extends StatelessWidget {
  const _Catalogue({
    required this.catalog,
    required this.categoryId,
    required this.search,
    required this.onCategory,
    required this.onAdd,
  });
  final PosCatalog catalog;
  final String? categoryId;
  final TextEditingController search;
  final ValueChanged<String?> onCategory;
  final ValueChanged<PosMenuItem> onAdd;

  @override
  Widget build(BuildContext context) => StatefulBuilder(
    builder: (context, refresh) {
      final query = search.text.trim().toLowerCase();
      final items =
          catalog.items
              .where(
                (item) =>
                    (categoryId == null || item.categoryId == categoryId) &&
                    (query.isEmpty ||
                        item.name.toLowerCase().contains(query) ||
                        (item.description ?? '').toLowerCase().contains(query)),
              )
              .toList();
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('pos-search'),
              controller: search,
              onChanged: (_) => refresh(() {}),
              decoration: const InputDecoration(
                labelText: 'Cerca prodotto',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Tutto'),
                    selected: categoryId == null,
                    onSelected: (_) => onCategory(null),
                  ),
                  for (final category in catalog.categories) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(category.name),
                      selected: categoryId == category.id,
                      onSelected: (_) => onCategory(category.id),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  items.isEmpty
                      ? const Center(
                        child: Text('Nessun prodotto disponibile.'),
                      )
                      : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.sizeOf(context).width >= 1200 ? 3 : 2,
                          childAspectRatio: 1.55,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, index) {
                          final item = items[index];
                          final from =
                              item.sizes.isEmpty
                                  ? 0
                                  : item.sizes
                                      .map((size) => size.priceMinor)
                                      .reduce((a, b) => a < b ? a : b);
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: Key('pos-product-${item.id}'),
                              onTap: () => onAdd(item),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (item.description != null)
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 6,
                                          ),
                                          child: Text(
                                            item.description!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                    else
                                      const Spacer(),
                                    Row(
                                      children: [
                                        Text(
                                          'da ${_money(from)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: BrandColors.espresso,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(Icons.add_circle_outline),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      );
    },
  );
}

class _Cart extends ConsumerWidget {
  const _Cart({
    required this.state,
    required this.orderType,
    required this.paymentMethod,
    required this.table,
    required this.customer,
    required this.phone,
    required this.note,
    required this.onOrderType,
    required this.onPaymentMethod,
    required this.onCheckout,
  });
  final PosState state;
  final String orderType;
  final String paymentMethod;
  final TextEditingController table;
  final TextEditingController customer;
  final TextEditingController phone;
  final TextEditingController note;
  final ValueChanged<String> onOrderType;
  final ValueChanged<String> onPaymentMethod;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Material(
    color: BrandColors.paper,
    child: ListView(
      key: const Key('pos-cart-list'),
      padding: const EdgeInsets.all(16),
      children: [
        Text('Carrello', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'takeaway',
              icon: Icon(Icons.takeout_dining),
              label: Text('Asporto'),
            ),
            ButtonSegment(
              value: 'dine_in',
              icon: Icon(Icons.table_restaurant),
              label: Text('Sala'),
            ),
          ],
          selected: {orderType},
          onSelectionChanged: (value) => onOrderType(value.first),
        ),
        if (orderType == 'dine_in') ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('pos-table'),
            controller: table,
            decoration: const InputDecoration(labelText: 'Tavolo *'),
          ),
        ],
        const SizedBox(height: 12),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Cliente e note (facoltativi)'),
          children: [
            TextField(
              controller: customer,
              decoration: const InputDecoration(labelText: 'Nome cliente'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefono (+39...)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: note,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Nota ordine'),
            ),
          ],
        ),
        const Divider(),
        if (state.cart.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Il carrello è vuoto.')),
          ),
        for (final line in state.cart)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(line.item.name),
            subtitle: Text(
              '${line.size.name}${line.options.isEmpty ? '' : ' · ${line.options.map((e) => e.name).join(', ')}'}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: SizedBox(
              width: 148,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Riduci',
                    onPressed:
                        () => ref
                            .read(posControllerProvider.notifier)
                            .changeQuantity(line.key, line.quantity - 1),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('${line.quantity}'),
                  IconButton(
                    tooltip: 'Aumenta',
                    onPressed:
                        () => ref
                            .read(posControllerProvider.notifier)
                            .changeQuantity(line.key, line.quantity + 1),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  Expanded(child: Text(_money(line.lineTotalMinor))),
                ],
              ),
            ),
          ),
        const Divider(),
        Row(
          children: [
            const Text('Totale stimato'),
            const Spacer(),
            Text(
              _money(state.estimatedTotalMinor),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const Text(
          'Il totale definitivo e l’IVA sono calcolati dal server.',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'cash',
              label: Text('Contanti'),
              icon: Icon(Icons.payments_outlined),
            ),
            ButtonSegment(
              value: 'card_on_delivery',
              label: Text('Carta'),
              icon: Icon(Icons.credit_card),
            ),
          ],
          selected: {paymentMethod},
          onSelectionChanged: (value) => onPaymentMethod(value.first),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          Text(
            state.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (state.pendingOrderId != null) ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed:
                state.submitting
                    ? null
                    : () async {
                      final receipt =
                          await ref
                              .read(posControllerProvider.notifier)
                              .retryCollection();
                      if (context.mounted && receipt != null) {
                        await showPrintableReceiptDialog(context, receipt);
                      }
                    },
            icon: const Icon(Icons.refresh),
            label: const Text('Riprova incasso ordine già creato'),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('pos-checkout'),
          onPressed:
              state.submitting || state.pendingOrderId != null
                  ? null
                  : onCheckout,
          icon:
              state.submitting
                  ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.point_of_sale),
          label: const Text('Crea ordine e registra incasso'),
        ),
      ],
    ),
  );
}

class _ConfigureItemDialog extends StatefulWidget {
  const _ConfigureItemDialog({required this.item});
  final PosMenuItem item;

  @override
  State<_ConfigureItemDialog> createState() => _ConfigureItemDialogState();
}

class _ConfigureItemDialogState extends State<_ConfigureItemDialog> {
  late PosMenuSize? _size = widget.item.sizes.firstOrNull;
  late final Set<String> _choices = {
    for (final group in widget.item.optionGroups)
      for (final choice in group.choices)
        if (choice.isDefault) choice.id,
  };
  final _instructions = TextEditingController();
  var _quantity = 1;
  String? _error;

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item.name),
    content: SizedBox(
      width: 620,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Formato', style: Theme.of(context).textTheme.titleMedium),
            for (final size in widget.item.sizes)
              RadioListTile<String>(
                value: size.id,
                groupValue: _size?.id,
                onChanged: (_) => setState(() => _size = size),
                title: Text(size.name),
                secondary: Text(_money(size.priceMinor)),
              ),
            for (final group in widget.item.optionGroups) ...[
              const Divider(),
              Text(
                '${group.name}${group.minSelect > 0 ? ' · minimo ${group.minSelect}' : ''}${group.maxSelect != null ? ' · massimo ${group.maxSelect}' : ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final choice in group.choices)
                CheckboxListTile(
                  value: _choices.contains(choice.id),
                  onChanged:
                      (selected) => _toggle(group, choice, selected == true),
                  title: Text(choice.name),
                  secondary:
                      choice.priceMinor == 0
                          ? null
                          : Text('+ ${_money(choice.priceMinor)}'),
                ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _instructions,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Istruzioni cucina (facoltative)',
              ),
            ),
            Row(
              children: [
                const Text('Quantità'),
                const Spacer(),
                IconButton(
                  onPressed:
                      _quantity == 1 ? null : () => setState(() => _quantity--),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_quantity'),
                IconButton(
                  onPressed:
                      _quantity == 99
                          ? null
                          : () => setState(() => _quantity++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annulla'),
      ),
      FilledButton(onPressed: _add, child: const Text('Aggiungi al carrello')),
    ],
  );

  void _toggle(PosOptionGroup group, PosOptionChoice choice, bool selected) {
    setState(() {
      if (selected) {
        final inGroup = group.choices.where(
          (item) => _choices.contains(item.id),
        );
        if (group.maxSelect == 1) {
          _choices.removeAll(group.choices.map((item) => item.id));
        } else if (group.maxSelect != null &&
            inGroup.length >= group.maxSelect!) {
          _error =
              'Puoi selezionare al massimo ${group.maxSelect} opzioni per ${group.name}.';
          return;
        }
        _choices.add(choice.id);
      } else {
        _choices.remove(choice.id);
      }
      _error = null;
    });
  }

  void _add() {
    if (_size == null) {
      setState(() => _error = 'Seleziona un formato.');
      return;
    }
    for (final group in widget.item.optionGroups) {
      final count =
          group.choices.where((choice) => _choices.contains(choice.id)).length;
      if (count < group.minSelect || (group.required && count == 0)) {
        setState(() => _error = 'Completa la selezione “${group.name}”.');
        return;
      }
    }
    Navigator.pop(
      context,
      PosCartLine(
        key: const Uuid().v4(),
        item: widget.item,
        size: _size!,
        quantity: _quantity,
        options: [
          for (final group in widget.item.optionGroups)
            for (final choice in group.choices)
              if (_choices.contains(choice.id)) choice,
        ],
        instructions: _instructions.text.trim(),
      ),
    );
  }
}

class _ReceiptArchive extends ConsumerStatefulWidget {
  const _ReceiptArchive();

  @override
  ConsumerState<_ReceiptArchive> createState() => _ReceiptArchiveState();
}

class _ReceiptArchiveState extends ConsumerState<_ReceiptArchive> {
  List<Map<String, dynamic>> _receipts = const [];
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(posRepositoryProvider).receipts();
      if (mounted) setState(() => _receipts = data);
    } on AdminApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final printer = const _PrinterPanel();
      final archive = Card(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: const Text('Ricevute pagate'),
              subtitle: const Text('Apri una ricevuta per ristamparla.'),
              trailing: IconButton(
                tooltip: 'Aggiorna',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? _Failure(message: _error!, onRetry: _load)
                      : _receipts.isEmpty
                      ? const Center(child: Text('Nessuna ricevuta POS.'))
                      : ListView.builder(
                        itemCount: _receipts.length,
                        itemBuilder: (context, index) {
                          final receipt = _receipts[index];
                          final order = receipt['order'];
                          final map =
                              order is Map
                                  ? Map<String, dynamic>.from(order)
                                  : <String, dynamic>{};
                          return ListTile(
                            leading: const Icon(Icons.receipt_long_outlined),
                            title: Text(
                              receipt['receiptNumber']?.toString() ??
                                  'Ricevuta',
                            ),
                            subtitle: Text(
                              '${map['orderNumber'] ?? ''} · ${map['orderType'] == 'dine_in' ? 'Sala' : 'Asporto'}',
                            ),
                            trailing: Text(
                              _money(_minor(receipt['amountMinor'])),
                            ),
                            onTap: () async {
                              final id = map['id']?.toString();
                              if (id == null) return;
                              try {
                                final printable = await ref
                                    .read(posRepositoryProvider)
                                    .receipt(id);
                                if (context.mounted) {
                                  await showPrintableReceiptDialog(
                                    context,
                                    printable,
                                  );
                                }
                              } on AdminApiException catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error.message)),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      );
      if (constraints.maxWidth >= 960) {
        return Row(
          children: [
            Expanded(flex: 3, child: archive),
            SizedBox(width: 390, child: printer),
          ],
        );
      }
      return Column(
        children: [
          Expanded(child: archive),
          SizedBox(height: 420, child: printer),
        ],
      );
    },
  );
}

class _PrinterPanel extends ConsumerStatefulWidget {
  const _PrinterPanel();

  @override
  ConsumerState<_PrinterPanel> createState() => _PrinterPanelState();
}

class _PrinterPanelState extends ConsumerState<_PrinterPanel> {
  final _host = TextEditingController();
  final _port = TextEditingController(text: '9100');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = ref.read(thermalPrinterControllerProvider);
    if (_host.text.isEmpty) _host.text = state.networkHost;
    if (_port.text == '9100') _port.text = '${state.networkPort}';
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(thermalPrinterControllerProvider);
    final controller = ref.read(thermalPrinterControllerProvider.notifier);
    return Card(
      margin: const EdgeInsets.all(16),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Stampante termica',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<ReceiptPaper>(
            segments: const [
              ButtonSegment(value: ReceiptPaper.mm58, label: Text('58 mm')),
              ButtonSegment(value: ReceiptPaper.mm80, label: Text('80 mm')),
            ],
            selected: {state.paper},
            onSelectionChanged: (value) => controller.setPaper(value.first),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: state.scanning ? controller.stopScan : controller.scan,
            icon:
                state.scanning
                    ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.bluetooth_searching),
            label: Text(
              state.scanning ? 'Interrompi ricerca' : 'Cerca Bluetooth / USB',
            ),
          ),
          for (final printer in state.printers)
            RadioListTile<String>(
              value: printer.uniqueId,
              groupValue: state.selected?.uniqueId,
              onChanged: (_) => controller.select(printer),
              title: Text(
                printer.name?.trim().isNotEmpty == true
                    ? printer.name!
                    : 'Stampante',
              ),
              subtitle: Text(printer.connectionTypeString),
            ),
          if (state.printers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Nessuna stampante Bluetooth/USB rilevata.'),
            ),
          const Divider(),
          Text(
            'Stampante di rete',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _host,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'Indirizzo IP'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _port,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Porta',
              hintText: '9100',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              final port = int.tryParse(_port.text) ?? 9100;
              if (port < 1 || port > 65535) return;
              controller.setNetwork(_host.text, port);
            },
            child: const Text('Salva stampante di rete'),
          ),
          if (state.message != null) ...[
            const SizedBox(height: 8),
            Text(state.message!),
          ],
          const SizedBox(height: 8),
          const Text(
            'La stampa è una copia di cortesia non fiscale. La ricevuta resta ristampabile se la stampante non risponde.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

Future<void> showPrintableReceiptDialog(
  BuildContext context,
  PrintableReceipt receipt,
) => showDialog<void>(
  context: context,
  builder: (_) => PrintableReceiptDialog(receipt: receipt),
);

class PrintableReceiptDialog extends ConsumerWidget {
  const PrintableReceiptDialog({super.key, required this.receipt});
  final PrintableReceipt receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printer = ref.watch(thermalPrinterControllerProvider);
    return AlertDialog(
      title: Text(receipt.isPaid ? 'Ricevuta pronta' : 'Comanda non pagata'),
      content: SizedBox(
        width: 520,
        height: 520,
        child: Column(
          children: [
            Expanded(
              child: Card(
                color: Colors.white,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: Text(
                        receipt.restaurant['name']?.toString() ?? 'LA FAVOLA',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Divider(),
                    Text('Documento ${receipt.documentNumber}'),
                    Text('Ordine ${receipt.order['orderNumber']}'),
                    Text(
                      receipt.order['orderType'] == 'dine_in'
                          ? 'Sala · Tavolo ${receipt.order['tableLabel']}'
                          : 'Asporto',
                    ),
                    const Divider(),
                    for (final item in receipt.items)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('${item['quantity']} × ${item['name']}'),
                        subtitle:
                            item['size'] == null
                                ? null
                                : Text('${item['size']}'),
                        trailing: Text(_money(_minor(item['lineTotalMinor']))),
                      ),
                    const Divider(),
                    Row(
                      children: [
                        const Text(
                          'TOTALE',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          _money(receipt.totalMinor),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        receipt.fiscalNotice,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (printer.message != null) Text(printer.message!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Chiudi'),
        ),
        FilledButton.icon(
          key: const Key('print-receipt'),
          onPressed:
              printer.printing
                  ? null
                  : () => ref
                      .read(thermalPrinterControllerProvider.notifier)
                      .printReceipt(receipt),
          icon: const Icon(Icons.print),
          label: Text(printer.printing ? 'Stampa…' : 'Stampa'),
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Riprova')),
        ],
      ),
    ),
  );
}

String _money(int minor) => '${(minor / 100).toStringAsFixed(2)} €';
int _minor(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
