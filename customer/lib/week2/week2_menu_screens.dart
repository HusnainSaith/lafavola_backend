import 'package:flutter/material.dart';
import 'package:la_favola/week2/week2_models.dart';
import 'package:la_favola/week2/week2_theme.dart';
import 'package:la_favola/week2/week2_widgets.dart';

const _bresciaLocationId = '40000000-0000-4000-8000-000000000001';

final class MenuHierarchyScreen extends StatefulWidget {
  const MenuHierarchyScreen({
    required this.gateway,
    required this.onOpenItem,
    super.key,
  });

  final Week2Gateway gateway;
  final ValueChanged<String> onOpenItem;

  @override
  State<MenuHierarchyScreen> createState() => _MenuHierarchyScreenState();
}

final class _MenuHierarchyScreenState extends State<MenuHierarchyScreen> {
  final _search = TextEditingController();
  MenuSnapshot? _snapshot;
  Week2Failure? _failure;
  bool _loading = true;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
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
      _failure = null;
    });
    try {
      final snapshot = await widget.gateway.getMenu();
      if (mounted) {
        setState(() {
          _snapshot = snapshot;
          _selectedCategoryId = snapshot.categories.firstOrNull?.id;
        });
      }
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MenuItemSummary> _visibleItems() {
    final query = _search.text.trim().toLowerCase();
    return (_snapshot?.categories ?? const <MenuCategory>[])
        .where(
          (category) =>
              _selectedCategoryId == null || category.id == _selectedCategoryId,
        )
        .expand((category) => category.items)
        .where(
          (item) =>
              query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              (item.description?.toLowerCase().contains(query) ?? false),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Week2Page(
        title: 'Menu',
        child: Week2Loading(label: 'Caricamento menu'),
      );
    }
    if (_failure != null) {
      return Week2Page(
        title: 'Menu',
        child: Week2StatePanel.failure(_failure!, onRetry: _load),
      );
    }
    final snapshot = _snapshot!;
    if (snapshot.categories.isEmpty) {
      return Week2Page(
        title: 'Menu',
        child: Week2Empty(
          title: 'Nessuna categoria attiva',
          message:
              'La lettura pubblica non contiene categorie attive. Nessuna bozza viene mostrata.',
          action: OutlinedButton(
            onPressed: _load,
            child: const Text('Aggiorna'),
          ),
        ),
      );
    }
    final items = _visibleItems();
    final mode = week2LayoutMode(MediaQuery.sizeOf(context).width);
    final categoryPanel = Week2SectionCard(
      title: 'Categorie attive',
      subtitle: 'Versione catalogo ${snapshot.catalogVersion}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final category in snapshot.categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Semantics(
                selected: category.id == _selectedCategoryId,
                button: true,
                label: '${category.name}, categoria attiva',
                child: OutlinedButton(
                  onPressed:
                      () => setState(() => _selectedCategoryId = category.id),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    backgroundColor:
                        category.id == _selectedCategoryId
                            ? Week2Colors.infoContainer
                            : null,
                  ),
                  child: Text(category.name),
                ),
              ),
            ),
        ],
      ),
    );
    final listPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Cerca nel menu',
            prefixIcon: const Icon(Icons.search),
            suffixIcon:
                _search.text.isEmpty
                    ? null
                    : IconButton(
                      tooltip: 'Cancella ricerca',
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                    ),
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          label: '${items.length} risultati menu',
          child: Text(
            '${items.length} ${items.length == 1 ? "risultato" : "risultati"}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Week2Empty(
            title: 'Nessun risultato',
            message:
                'Modifica o cancella la ricerca per vedere le voci attive.',
            action: OutlinedButton(
              onPressed: () {
                _search.clear();
                setState(() {});
              },
              child: const Text('Cancella filtri'),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  mode == Week2LayoutMode.expanded && constraints.maxWidth > 680
                      ? 2
                      : 1;
              final itemWidth =
                  columns == 2
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: itemWidth,
                      child: Semantics(
                        button: true,
                        label:
                            '${item.name}. ${item.price ?? ""}. ${item.description ?? "Descrizione non disponibile"}. Apri dettaglio.',
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            key: Key('menu-item-${item.id}'),
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => widget.onOpenItem(item.id),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Week2Colors.primaryText,
                                          ),
                                        ),
                                      ),
                                      if (item.price != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Week2Colors.primaryAction,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            item.price!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (item.note != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.note!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Week2Colors.secondaryText,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    item.description ??
                                        'Descrizione e ingredienti.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: Week2Colors.secondaryText,
                                    ),
                                  ),
                                  if (item.attributes.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children:
                                          item.attributes
                                              .map(_buildDietaryBadge)
                                              .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
    return Week2Page(
      title: 'Menu La Favola',
      subtitle:
          'Consulta le nostre pizze, panini, sfizi e bevande con prezzi e allergeni.',
      actions: [
        OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Aggiorna'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          if (mode == Week2LayoutMode.compact) ...[
            categoryPanel,
            const SizedBox(height: 20),
            listPanel,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: mode == Week2LayoutMode.expanded ? 320 : 240,
                  child: categoryPanel,
                ),
                const SizedBox(width: 20),
                Expanded(child: listPanel),
              ],
            ),
        ],
      ),
    );
  }
}

Widget _buildDietaryBadge(String attribute) {
  final label = switch (attribute) {
    'vegetarian' => '🍃 Vegetariana',
    'spicy' => '🌶️ Piccante',
    'gluten' => '🌾 Glutine',
    'lactose' => '🥛 Lattosio',
    'egg' => '🥚 Uovo',
    'fish' => '🐟 Pesce',
    'nuts' => '🌰 Nocciole/Pistacchio',
    _ => attribute,
  };
  final color = switch (attribute) {
    'vegetarian' => Week2Colors.success,
    'spicy' => Colors.redAccent,
    'gluten' => Colors.amber.shade800,
    'lactose' => Colors.blueAccent,
    _ => Week2Colors.secondaryText,
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

final class MenuItemDetailScreen extends StatefulWidget {
  const MenuItemDetailScreen({
    required this.gateway,
    required this.itemId,
    super.key,
  });

  final Week2Gateway gateway;
  final String itemId;

  @override
  State<MenuItemDetailScreen> createState() => _MenuItemDetailScreenState();
}

final class _MenuItemDetailScreenState extends State<MenuItemDetailScreen> {
  MenuItemSummary? _item;
  Week2Failure? _failure;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final item = await widget.gateway.getMenuItem(widget.itemId);
      if (mounted) setState(() => _item = item);
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dettaglio Prodotto')),
      body:
          _loading
              ? const Week2Page(
                title: 'Dettaglio voce',
                child: Week2Loading(label: 'Caricamento dettaglio menu'),
              )
              : _failure != null
              ? Week2Page(
                title: 'Dettaglio voce',
                child: Week2StatePanel.failure(_failure!, onRetry: _load),
              )
              : Week2Page(
                title: _item!.name,
                subtitle: 'Pizzeria Ristorante La Favola · Brescia',
                maxWidth: 860,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Week2Colors.base,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Week2Colors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _item!.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Week2Colors.primaryText,
                                  ),
                                ),
                              ),
                              if (_item!.price != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Week2Colors.primaryAction,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _item!.price!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (_item!.note != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _item!.note!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Week2Colors.secondaryText,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          Text(
                            'Ingredienti e Descrizione',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Week2Colors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _item!.description ??
                                'Ingredienti freschi della tradizione campana e bresciana.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (_item!.attributes.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Caratteristiche e Allergeni',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Week2Colors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _item!.attributes
                                      .map(_buildDietaryBadge)
                                      .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action Buttons: Pizza Customization & Add to Cart
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openPizzaCustomizer(context),
                            icon: const Icon(Icons.tune),
                            label: const Text('Personalizza Pizza'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Week2Colors.primaryAction,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openCartCheckout(context),
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text('Aggiungi al Carrello'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Week2Colors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Week2Colors.infoContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.store, color: Week2Colors.info),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'La Favola Brescia',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Via Vittorio Veneto 23/C, Brescia · Tel: 030 6180079',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Torna al menu'),
                    ),
                  ],
                ),
              ),
    );
  }

  void _openPizzaCustomizer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PizzaCustomizerBottomSheet(item: _item!),
    );
  }

  void _openCartCheckout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) =>
              _CartCheckoutBottomSheet(gateway: widget.gateway, item: _item!),
    );
  }
}

class _PizzaCustomizerBottomSheet extends StatefulWidget {
  const _PizzaCustomizerBottomSheet({required this.item});
  final MenuItemSummary item;

  @override
  State<_PizzaCustomizerBottomSheet> createState() =>
      __PizzaCustomizerBottomSheetState();
}

class __PizzaCustomizerBottomSheetState
    extends State<_PizzaCustomizerBottomSheet> {
  String _selectedSize = 'Normale (€0.00)';
  String _selectedCrust = 'Classico Napoletano (€0.00)';
  final Set<String> _extraToppings = {};

  static const Map<String, double> _sizePrices = {
    'Normale (€0.00)': 0.0,
    'Maxxi Familiare (+€4.00)': 4.0,
    'Teglia Gigante (+€6.00)': 6.0,
  };

  static const Map<String, double> _crustPrices = {
    'Classico Napoletano (€0.00)': 0.0,
    'Bordo Sottile Croccante (+€0.50)': 0.5,
    'Cornicione Ripieno Ricotta (+€2.50)': 2.5,
  };

  static const Map<String, double> _toppingPrices = {
    'Extra Mozzarella di Bufala DOP (+€1.50)': 1.5,
    'Funghi Porcini Selezionati (+€1.50)': 1.5,
    'Salame Piccante Calabrese (+€1.50)': 1.5,
    'Gorgonzola DOP (+€1.00)': 1.0,
    'Olio EVO al Peperoncino (+€0.50)': 0.5,
  };

  double _calculateTotal() {
    final base =
        double.tryParse(
          widget.item.price
                  ?.replaceAll(RegExp(r'[^0-9,]'), '')
                  .replaceAll(',', '.') ??
              '7.00',
        ) ??
        7.0;
    double extra = _sizePrices[_selectedSize]! + _crustPrices[_selectedCrust]!;
    for (final t in _extraToppings) {
      extra += _toppingPrices[t] ?? 0.0;
    }
    return base + extra;
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotal();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Personalizza ${widget.item.name}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Dimensione Impasto',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            for (final size in _sizePrices.keys)
              RadioListTile<String>(
                title: Text(size),
                value: size,
                groupValue: _selectedSize,
                activeColor: Week2Colors.primaryAction,
                onChanged: (val) => setState(() => _selectedSize = val!),
              ),
            const SizedBox(height: 12),
            const Text(
              'Tipo Cornicione',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            for (final crust in _crustPrices.keys)
              RadioListTile<String>(
                title: Text(crust),
                value: crust,
                groupValue: _selectedCrust,
                activeColor: Week2Colors.primaryAction,
                onChanged: (val) => setState(() => _selectedCrust = val!),
              ),
            const SizedBox(height: 12),
            const Text(
              'Ingredienti Extra e Condimenti',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            for (final topping in _toppingPrices.keys)
              CheckboxListTile(
                title: Text(topping),
                value: _extraToppings.contains(topping),
                activeColor: Week2Colors.primaryAction,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _extraToppings.add(topping);
                    } else {
                      _extraToppings.remove(topping);
                    }
                  });
                },
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Week2Colors.infoContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Prezzo Personalizzato:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '€${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Week2Colors.primaryAction,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Pizza personalizzata (${widget.item.name}) salvata: €${total.toStringAsFixed(2)}',
                      ),
                      backgroundColor: Week2Colors.success,
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Conferma Personalizzazione'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Week2Colors.primaryAction,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartCheckoutBottomSheet extends StatefulWidget {
  const _CartCheckoutBottomSheet({required this.gateway, required this.item});

  final Week2Gateway gateway;
  final MenuItemSummary item;

  @override
  State<_CartCheckoutBottomSheet> createState() =>
      __CartCheckoutBottomSheetState();
}

class __CartCheckoutBottomSheetState extends State<_CartCheckoutBottomSheet> {
  int _quantity = 1;
  bool _isDelivery = true;
  final _couponController = TextEditingController();
  Quote? _quote;
  Week2Failure? _quoteFailure;
  bool _quoting = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _refreshQuote();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  String _euro(int minor) => '€${(minor / 100).toStringAsFixed(2)}';

  Future<Quote?> _refreshQuote() async {
    setState(() {
      _quoting = true;
      _quoteFailure = null;
    });
    try {
      final quote = await widget.gateway.createQuote(
        locationId: _bresciaLocationId,
        lines: [
          QuoteLineInput(
            itemId: widget.item.id,
            quantity: _quantity,
            choiceIds: const [],
          ),
        ],
        fulfillmentContext: FulfillmentContext(
          type: _isDelivery ? FulfillmentType.delivery : FulfillmentType.pickup,
        ),
        couponCode:
            _couponController.text.trim().isEmpty
                ? null
                : _couponController.text.trim(),
      );
      if (mounted) setState(() => _quote = quote);
      return quote;
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _quoteFailure = failure);
      return null;
    } finally {
      if (mounted) setState(() => _quoting = false);
    }
  }

  Future<void> _changeQuantity(int value) async {
    setState(() => _quantity = value);
    await _refreshQuote();
  }

  Future<void> _changeFulfillment(bool delivery) async {
    setState(() => _isDelivery = delivery);
    await _refreshQuote();
  }

  Future<void> _applyCoupon() async {
    if (_couponController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un codice promozionale.')),
      );
      return;
    }
    await _refreshQuote();
  }

  Future<void> _submitOrder() async {
    setState(() => _submitting = true);
    try {
      final quote = await _refreshQuote();
      if (quote == null || !mounted) return;
      if (mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Week2Colors.success),
                    SizedBox(width: 8),
                    Text('Preventivo Calcolato'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prodotto: ${widget.item.name} x$_quantity'),
                    Text(
                      'Modalità: ${_isDelivery ? "Consegna a domicilio" : "Ritiro in Pizzeria"}',
                    ),
                    Text('Subtotale: ${_euro(quote.subtotalMinor)}'),
                    Text('Consegna: ${_euro(quote.feeMinor)}'),
                    if (quote.discountMinor > 0)
                      Text('Sconto: -${_euro(quote.discountMinor)}'),
                    const Divider(),
                    Text(
                      'Totale ufficiale: ${_euro(quote.totalMinor)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Week2Colors.primaryAction,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quote;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Carrello e Preventivo Ordine',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed:
                          _quoting || _quantity <= 1
                              ? null
                              : () => _changeQuantity(_quantity - 1),
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed:
                          _quoting
                              ? null
                              : () => _changeQuantity(_quantity + 1),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Modalità di Consegna',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Consegna'),
                    selected: _isDelivery,
                    selectedColor: Week2Colors.infoContainer,
                    onSelected:
                        _quoting ? null : (val) => _changeFulfillment(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Ritiro Pizzeria'),
                    selected: !_isDelivery,
                    selectedColor: Week2Colors.infoContainer,
                    onSelected:
                        _quoting ? null : (val) => _changeFulfillment(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: const InputDecoration(
                      hintText: 'Codice Promo (es: FAVOLA10)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _quoting ? null : _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Week2Colors.primaryAction,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Applica'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Week2Colors.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children:
                    _quoting
                        ? const [
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Calcolo del preventivo ufficiale…'),
                              ],
                            ),
                          ),
                        ]
                        : _quoteFailure != null
                        ? [
                          Text(
                            _quoteFailure!.message,
                            style: const TextStyle(color: Week2Colors.error),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _refreshQuote,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Riprova il calcolo'),
                          ),
                        ]
                        : quote == null
                        ? const [Text('Preventivo non disponibile.')]
                        : [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotale Prodotti:'),
                              Text(_euro(quote.subtotalMinor)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Costo Consegna:'),
                              Text(_euro(quote.feeMinor)),
                            ],
                          ),
                          if (quote.discountMinor > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Sconto Coupon:',
                                  style: TextStyle(color: Week2Colors.success),
                                ),
                                Text(
                                  '-${_euro(quote.discountMinor)}',
                                  style: const TextStyle(
                                    color: Week2Colors.success,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Totale Preventivo:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _euro(quote.totalMinor),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Week2Colors.primaryAction,
                                ),
                              ),
                            ],
                          ),
                        ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _submitting || _quoting || _quoteFailure != null
                        ? null
                        : _submitOrder,
                icon: const Icon(Icons.send),
                label: Text(
                  _submitting
                      ? 'Elaborazione...'
                      : 'Conferma e Calcola Preventivo',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Week2Colors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
