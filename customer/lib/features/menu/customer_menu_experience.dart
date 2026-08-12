import 'dart:async';

import 'package:flutter/material.dart';
import 'package:la_favola/core/api/customer_api_client.dart';
import 'package:la_favola/design_system/tokens.dart';
import 'package:la_favola/l10n/generated/app_localizations.dart';
import 'package:la_favola/l10n/generated/app_localizations_en.dart';
import 'package:la_favola/week2/week2_models.dart';

AppLocalizations _strings(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    AppLocalizationsEn();

/// The production customer menu.  It deliberately reads every visible menu
/// value from [Week2Gateway]; no prototype content is rendered on this route.
final class CustomerMenuScreen extends StatefulWidget {
  const CustomerMenuScreen({
    required this.gateway,
    required this.onOpenItem,
    required this.onOpenBuilder,
    super.key,
  });

  final Week2Gateway gateway;
  final ValueChanged<String> onOpenItem;
  final ValueChanged<String> onOpenBuilder;

  @override
  State<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

final class _CustomerMenuScreenState extends State<CustomerMenuScreen> {
  final _search = TextEditingController();
  MenuSnapshot? _snapshot;
  Week2Failure? _failure;
  String? _categoryId;
  bool _loading = true;

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
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _categoryId =
            snapshot.categories.any((item) => item.id == _categoryId)
                ? _categoryId
                : snapshot.categories.firstOrNull?.id;
      });
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MenuItemSummary> get _items {
    final query = _search.text.trim().toLowerCase();
    return (_snapshot?.categories ?? const <MenuCategory>[])
        .where((category) => category.id == _categoryId)
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: LaFavolaTokens.canvas,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
          child:
              _loading
                  ? const _MenuLoading(key: ValueKey('loading'))
                  : _failure != null
                  ? _MenuFailure(
                    key: const ValueKey('failure'),
                    failure: _failure!,
                    onRetry: _load,
                  )
                  : _snapshot!.categories.isEmpty
                  ? _MenuEmpty(key: const ValueKey('empty'), onRetry: _load)
                  : _MenuContent(
                    key: const ValueKey('content'),
                    snapshot: _snapshot!,
                    selectedCategoryId: _categoryId!,
                    search: _search,
                    items: _items,
                    onCategoryChanged: (id) => setState(() => _categoryId = id),
                    onSearchChanged: () => setState(() {}),
                    onClearSearch: () {
                      _search.clear();
                      setState(() {});
                    },
                    onRefresh: _load,
                    onOpenItem: widget.onOpenItem,
                    onOpenBuilder: widget.onOpenBuilder,
                  ),
        ),
      ),
    );
  }
}

final class CustomerMenuDetailScreen extends StatefulWidget {
  const CustomerMenuDetailScreen({
    required this.gateway,
    required this.itemId,
    this.openBuilder = false,
    this.onSaveFavorite,
    super.key,
  });

  final Week2Gateway gateway;
  final String itemId;
  final bool openBuilder;
  final Future<bool> Function(MenuItemSummary item)? onSaveFavorite;

  @override
  State<CustomerMenuDetailScreen> createState() =>
      _CustomerMenuDetailScreenState();
}

final class _CustomerMenuDetailScreenState
    extends State<CustomerMenuDetailScreen> {
  MenuItemSummary? _item;
  Week2Failure? _failure;
  bool _loading = true;
  bool _builderOpened = false;
  bool _savingFavorite = false;

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
      if (!mounted) return;
      setState(() => _item = item);
      if (widget.openBuilder && item.isBuilderProduct && !_builderOpened) {
        _builderOpened = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openCheckout(item);
        });
      }
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openCheckout(MenuItemSummary item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LiveCheckoutSheet(gateway: widget.gateway, item: item),
    );
  }

  Future<void> _saveFavorite(MenuItemSummary item) async {
    final callback = widget.onSaveFavorite;
    if (callback == null || _savingFavorite) return;
    setState(() => _savingFavorite = true);
    try {
      final saved = await callback(item);
      if (!mounted || !saved) return;
      final italian = Localizations.localeOf(context).languageCode == 'it';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item.name +
                (italian ? ' aggiunto ai preferiti.' : ' added to favorites.'),
          ),
        ),
      );
    } on CustomerApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _savingFavorite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return Scaffold(
      backgroundColor: LaFavolaTokens.canvas,
      appBar: AppBar(
        backgroundColor: LaFavolaTokens.canvas,
        surfaceTintColor: Colors.transparent,
        title: const Text('La Favola'),
      ),
      body:
          _loading
              ? const _MenuLoading()
              : _failure != null
              ? _MenuFailure(failure: _failure!, onRetry: _load)
              : item == null
              ? _MenuEmpty(onRetry: _load)
              : _ItemDetail(
                item: item,
                onOrder: () => _openCheckout(item),
                onSaveFavorite:
                    widget.onSaveFavorite == null
                        ? null
                        : () => _saveFavorite(item),
                savingFavorite: _savingFavorite,
              ),
    );
  }
}

final class _MenuContent extends StatelessWidget {
  const _MenuContent({
    required this.snapshot,
    required this.selectedCategoryId,
    required this.search,
    required this.items,
    required this.onCategoryChanged,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onRefresh,
    required this.onOpenItem,
    required this.onOpenBuilder,
    super.key,
  });

  final MenuSnapshot snapshot;
  final String selectedCategoryId;
  final TextEditingController search;
  final List<MenuItemSummary> items;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onSearchChanged;
  final VoidCallback onClearSearch;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onOpenItem;
  final ValueChanged<String> onOpenBuilder;

  @override
  Widget build(BuildContext context) {
    final builderItem =
        snapshot.categories
            .expand((category) => category.items)
            .where((item) => item.isBuilderProduct)
            .firstOrNull;
    return CustomScrollView(
      key: const Key('customer-menu-scroll'),
      slivers: [
        SliverToBoxAdapter(
          child: _CustomerMenuHero(version: snapshot.catalogVersion),
        ),
        SliverToBoxAdapter(
          child: _HorizontalCategories(
            categories: snapshot.categories,
            selectedId: selectedCategoryId,
            onChanged: onCategoryChanged,
            onBuildPizza:
                builderItem == null
                    ? null
                    : () => onOpenBuilder(builderItem.id),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          sliver: SliverToBoxAdapter(
            child: _Catalogue(
              items: items,
              search: search,
              onSearchChanged: onSearchChanged,
              onClearSearch: onClearSearch,
              onRefresh: onRefresh,
              onOpenItem: onOpenItem,
            ),
          ),
        ),
      ],
    );
  }
}

final class _CustomerMenuHero extends StatelessWidget {
  const _CustomerMenuHero({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final strings = _strings(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LaFavolaTokens.surfaceStrong, LaFavolaTokens.actionPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LaFavolaTokens.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.bresciaItaly,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: LaFavolaTokens.contentOnStrong.withValues(
                          alpha: .76,
                        ),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.menuHeroTitle,
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(color: LaFavolaTokens.contentOnStrong),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      strings.liveCatalogue(version),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LaFavolaTokens.contentOnStrong.withValues(
                          alpha: .82,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const _PizzaMark(size: 88),
            ],
          ),
        ],
      ),
    );
  }
}

final class _HorizontalCategories extends StatelessWidget {
  const _HorizontalCategories({
    required this.categories,
    required this.selectedId,
    required this.onChanged,
    required this.onBuildPizza,
  });

  final List<MenuCategory> categories;
  final String selectedId;
  final ValueChanged<String> onChanged;
  final VoidCallback? onBuildPizza;

  @override
  Widget build(BuildContext context) {
    final strings = _strings(context);
    return Semantics(
      label: strings.menuCategories,
      child: SingleChildScrollView(
        key: const Key('customer-menu-category-row'),
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            if (onBuildPizza != null) ...[
              _PizzaBuilderAction(onPressed: onBuildPizza!),
              const SizedBox(width: 12),
            ],
            for (final category in categories) ...[
              _MenuCategoryPill(
                key: Key('menu-category-${category.id}'),
                category: category,
                selected: category.id == selectedId,
                onPressed: () => onChanged(category.id),
              ),
              const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }
}

final class _PizzaBuilderAction extends StatelessWidget {
  const _PizzaBuilderAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = _strings(context);
    return Semantics(
      button: true,
      label: strings.createPizzaWithLivePricing,
      child: Material(
        color: LaFavolaTokens.actionPrimary,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('open-custom-pizza'),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 18, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: LaFavolaTokens.contentOnStrong.withValues(
                      alpha: .16,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: LaFavolaTokens.contentOnStrong,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  strings.createYourPizza,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: LaFavolaTokens.contentOnStrong,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _MenuCategoryPill extends StatelessWidget {
  const _MenuCategoryPill({
    required this.category,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final MenuCategory category;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final foreground =
        selected
            ? LaFavolaTokens.contentOnStrong
            : LaFavolaTokens.contentPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: '${category.name}, ${category.items.length} menu items',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: AnimatedContainer(
            duration:
                reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color:
                  selected
                      ? LaFavolaTokens.surfaceStrong
                      : LaFavolaTokens.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: LaFavolaTokens.contentOnStrong,
                  ),
                  const SizedBox(width: 7),
                ],
                Text(
                  category.name,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _Catalogue extends StatelessWidget {
  const _Catalogue({
    required this.items,
    required this.search,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onRefresh,
    required this.onOpenItem,
  });

  final List<MenuItemSummary> items;
  final TextEditingController search;
  final VoidCallback onSearchChanged;
  final VoidCallback onClearSearch;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onOpenItem;

  @override
  Widget build(BuildContext context) {
    final strings = _strings(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strings.discoverFavourites,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              tooltip: strings.refresh,
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('customer-menu-search'),
          controller: search,
          onChanged: (_) => onSearchChanged(),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: strings.searchMenu,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon:
                search.text.isEmpty
                    ? null
                    : IconButton(
                      tooltip: strings.clearSearch,
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.close_rounded),
                    ),
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          label: strings.menuResultCount(items.length),
          child: Text(
            strings.menuResultCount(items.length),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const _NoResults()
        else
          for (final item in items) ...[
            _ProductCard(item: item, onOpen: () => onOpenItem(item.id)),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

final class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item, required this.onOpen});

  final MenuItemSummary item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '${item.name}, ${item.price ?? 'price available in details'}. Open details.',
      child: Material(
        color: LaFavolaTokens.surface,
        borderRadius: BorderRadius.circular(LaFavolaTokens.radiusLarge),
        child: InkWell(
          key: Key('customer-menu-item-${item.id}'),
          onTap: onOpen,
          borderRadius: BorderRadius.circular(LaFavolaTokens.radiusLarge),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: LaFavolaTokens.borderSubtle),
              borderRadius: BorderRadius.circular(LaFavolaTokens.radiusLarge),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PizzaMark(size: 76, accent: _accentFor(item.categoryId)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (item.price != null)
                            _PricePill(price: item.price!),
                        ],
                      ),
                      if (item.note != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.note!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (item.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (item.attributes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              item.attributes.map(_AttributeTag.new).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _ItemDetail extends StatelessWidget {
  const _ItemDetail({
    required this.item,
    required this.onOrder,
    required this.onSaveFavorite,
    required this.savingFavorite,
  });

  final MenuItemSummary item;
  final VoidCallback onOrder;
  final VoidCallback? onSaveFavorite;
  final bool savingFavorite;

  @override
  Widget build(BuildContext context) {
    final strings = _strings(context);
    return CustomScrollView(
      key: const Key('customer-item-detail-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 210,
                  decoration: BoxDecoration(
                    color: _accentFor(item.categoryId),
                    borderRadius: BorderRadius.circular(
                      LaFavolaTokens.radiusLarge,
                    ),
                  ),
                  child: Center(
                    child: _PizzaMark(size: 154, accent: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ),
                    if (item.price != null)
                      _PricePill(price: item.price!, large: true),
                  ],
                ),
                if (item.note != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.note!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  strings.madeWithCare,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  item.description ?? strings.detailsUnavailable,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (item.attributes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    strings.dietaryAllergenInfo,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.attributes.map(_AttributeTag.new).toList(),
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton.icon(
                  key: const Key('open-live-checkout'),
                  onPressed: onOrder,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(
                    item.isBuilderProduct
                        ? strings.customizePizza
                        : strings.addToOrder,
                  ),
                ),
                if (onSaveFavorite != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('save-live-favorite'),
                    onPressed: savingFavorite ? null : onSaveFavorite,
                    icon:
                        savingFavorite
                            ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.favorite_border_rounded),
                    label: Text(
                      Localizations.localeOf(context).languageCode == 'it'
                          ? 'Salva nei preferiti'
                          : 'Save to favorites',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  strings.livePriceNotice,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _LiveCheckoutSheet extends StatefulWidget {
  const _LiveCheckoutSheet({required this.gateway, required this.item});

  final Week2Gateway gateway;
  final MenuItemSummary item;

  @override
  State<_LiveCheckoutSheet> createState() => _LiveCheckoutSheetState();
}

final class _LiveCheckoutSheetState extends State<_LiveCheckoutSheet> {
  final _coupon = TextEditingController();
  final Set<String> _choiceIds = <String>{};
  Quote? _quote;
  Week2Failure? _failure;
  int _quantity = 1;
  FulfillmentType _fulfillment = FulfillmentType.delivery;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  List<CustomerAddress> _addresses = const [];
  String? _addressId;
  FulfillmentAvailability? _availability;
  DateTime? _availabilityDate;
  String? _scheduledFor;
  bool _availabilityLoading = true;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final group in widget.item.optionGroups.where(
      (group) => group.required || group.minChoices > 0,
    )) {
      final first =
          group.choices.where((choice) => choice.available).firstOrNull;
      if (first != null) _choiceIds.add(first.id);
    }
    _loadCheckout();
  }

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  Future<void> _loadCheckout() async {
    try {
      final addresses = (await widget.gateway.getAddresses())
          .where((address) => address.archivedAt == null)
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
        _addressId =
            addresses.where((address) => address.isDefault).firstOrNull?.id ??
            addresses.firstOrNull?.id;
        if (_addressId == null) _fulfillment = FulfillmentType.pickup;
      });
    } on Week2Failure {
      if (mounted) setState(() => _fulfillment = FulfillmentType.pickup);
    }
    await _loadAvailability(refreshQuote: false);
    await _refreshQuote();
  }

  Future<void> _loadAvailability({bool refreshQuote = true}) async {
    setState(() => _availabilityLoading = true);
    try {
      final availability = await widget.gateway.getFulfillmentAvailability(
        type: _fulfillment,
        date: _availabilityDate == null ? null : _apiDate(_availabilityDate!),
        menuItemId: widget.item.id,
      );
      if (!mounted) return;
      setState(() {
        _availability = availability;
        _availabilityDate =
            DateTime.tryParse(availability.date) ?? _availabilityDate;
        final stillAvailable = availability.slots.any(
          (slot) => slot.scheduledFor == _scheduledFor,
        );
        if (!stillAvailable) {
          _scheduledFor =
              availability.asapAvailable
                  ? null
                  : availability.slots.firstOrNull?.scheduledFor;
        }
      });
    } on Week2Failure catch (failure) {
      if (mounted) {
        setState(() {
          _availability = null;
          _scheduledFor = null;
          _failure = failure;
        });
      }
      return;
    } finally {
      if (mounted) setState(() => _availabilityLoading = false);
    }
    if (refreshQuote && mounted) await _refreshQuote();
  }

  Future<void> _pickAvailabilityDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate:
          _availabilityDate == null || _availabilityDate!.isBefore(now)
              ? now
              : _availabilityDate!,
      firstDate: now,
      lastDate: now.add(const Duration(days: 14)),
    );
    if (selected == null) return;
    setState(() => _availabilityDate = selected);
    await _loadAvailability();
  }

  Future<void> _refreshQuote() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final quote = await _createCurrentQuote();
      if (mounted) setState(() => _quote = quote);
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleChoice(OptionGroupSummary group, OptionChoiceSummary choice) {
    setState(() {
      if (_choiceIds.contains(choice.id)) {
        final groupIds = group.choices.map((item) => item.id).toSet();
        final selectedCount = _choiceIds.where(groupIds.contains).length;
        if (selectedCount > group.minChoices) _choiceIds.remove(choice.id);
      } else {
        final groupIds = group.choices.map((item) => item.id).toSet();
        if (group.maxChoices == 1) _choiceIds.removeWhere(groupIds.contains);
        if (_choiceIds.where(groupIds.contains).length < group.maxChoices) {
          _choiceIds.add(choice.id);
        }
      }
    });
    _refreshQuote();
  }

  String _money(int minor) =>
      '€${(minor / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  bool get _hasValidSelections => widget.item.optionGroups.every((group) {
    final groupIds = group.choices.map((choice) => choice.id).toSet();
    final selected = _choiceIds.where(groupIds.contains).length;
    return selected >= group.minChoices && selected <= group.maxChoices;
  });

  @override
  Widget build(BuildContext context) {
    final quote = _quote;
    final strings = _strings(context);
    return DraggableScrollableSheet(
      initialChildSize: .82,
      minChildSize: .5,
      maxChildSize: .96,
      builder:
          (context, scrollController) => Material(
            color: LaFavolaTokens.canvas,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: LaFavolaTokens.borderSubtle,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.item.isBuilderProduct
                            ? strings.createYourPizza
                            : strings.yourOrder,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: strings.closeCheckout,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                if (widget.item.isBuilderProduct)
                  _BuilderIntro(item: widget.item, money: _money)
                else
                  Text(
                    widget.item.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 20),
                _QuantityControl(
                  quantity: _quantity,
                  enabled: !_loading,
                  onChanged: (value) {
                    setState(() => _quantity = value);
                    _refreshQuote();
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  strings.fulfilment,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                SegmentedButton<FulfillmentType>(
                  segments: [
                    ButtonSegment(
                      value: FulfillmentType.delivery,
                      label: Text(strings.delivery),
                      icon: const Icon(Icons.delivery_dining_outlined),
                    ),
                    ButtonSegment(
                      value: FulfillmentType.pickup,
                      label: Text(strings.pickup),
                      icon: const Icon(Icons.storefront_outlined),
                    ),
                  ],
                  selected: {_fulfillment},
                  onSelectionChanged:
                      _loading
                          ? null
                          : (value) {
                            setState(() => _fulfillment = value.single);
                            _scheduledFor = null;
                            _loadAvailability();
                          },
                ),
                if (_fulfillment == FulfillmentType.delivery) ...[
                  const SizedBox(height: 12),
                  if (_addresses.isEmpty)
                    _CheckoutNotice(
                      icon: Icons.location_off_outlined,
                      message: strings.missingDeliveryAddress,
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _addressId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: strings.deliveryAddress,
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                      items: _addresses
                          .map(
                            (address) => DropdownMenuItem(
                              value: address.id,
                              child: Text(
                                '${address.label} · ${address.addressLine}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged:
                          _loading
                              ? null
                              : (value) {
                                setState(() => _addressId = value);
                                _refreshQuote();
                              },
                    ),
                ],
                const SizedBox(height: 18),
                Text(
                  strings.timing,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (_availabilityLoading)
                  const LinearProgressIndicator()
                else if (_availability == null)
                  _CheckoutNotice(
                    icon: Icons.schedule_outlined,
                    message: strings.noTimeSlots,
                  )
                else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(strings.asSoonAsPossible),
                        selected: _scheduledFor == null,
                        onSelected:
                            _availability!.asapAvailable
                                ? (_) {
                                  setState(() => _scheduledFor = null);
                                  _refreshQuote();
                                }
                                : null,
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          MaterialLocalizations.of(context).formatMediumDate(
                            _availabilityDate ?? DateTime.now(),
                          ),
                        ),
                        onPressed: _pickAvailabilityDate,
                      ),
                    ],
                  ),
                  if (!_availability!.asapAvailable) ...[
                    const SizedBox(height: 8),
                    _CheckoutNotice(
                      icon: Icons.storefront_outlined,
                      message: strings.closedNow,
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (_availability!.slots.isEmpty)
                    _CheckoutNotice(
                      icon: Icons.event_busy_outlined,
                      message: strings.noTimeSlots,
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _scheduledFor,
                      decoration: InputDecoration(
                        labelText: strings.scheduledTime,
                        prefixIcon: const Icon(Icons.schedule_outlined),
                      ),
                      items: _availability!.slots
                          .map(
                            (slot) => DropdownMenuItem(
                              value: slot.scheduledFor,
                              child: Text(slot.localTime),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        setState(() => _scheduledFor = value);
                        _refreshQuote();
                      },
                    ),
                  const SizedBox(height: 8),
                  Text(
                    strings.leadTime(_availability!.leadMinutes),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                for (final group in widget.item.optionGroups) ...[
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      _SelectionRule(group: group),
                    ],
                  ),
                  if (group.description != null)
                    Text(
                      group.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  for (final choice in group.choices.where(
                    (choice) => choice.available,
                  ))
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _choiceIds.contains(choice.id),
                      title: Text(choice.name),
                      subtitle:
                          choice.priceAdjustmentMinor == 0
                              ? null
                              : Text('+${_money(choice.priceAdjustmentMinor)}'),
                      onChanged:
                          _loading || _submitting
                              ? null
                              : (_) => _toggleChoice(group, choice),
                    ),
                  if (_selectionError(group, strings) case final error?)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        error,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: LaFavolaTokens.error,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 18),
                TextField(
                  controller: _coupon,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: strings.promoCode,
                    suffixIcon: TextButton(
                      onPressed: _loading ? null : _refreshQuote,
                      child: Text(strings.apply),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _QuotePanel(
                  loading: _loading,
                  quote: quote,
                  failure: _failure,
                  money: _money,
                  onRetry: _refreshQuote,
                ),
                const SizedBox(height: 18),
                Text(
                  strings.payment,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    RadioListTile<PaymentMethod>(
                      contentPadding: EdgeInsets.zero,
                      value: PaymentMethod.cash,
                      groupValue: _paymentMethod,
                      onChanged:
                          _loading
                              ? null
                              : (value) {
                                if (value != null) {
                                  setState(() => _paymentMethod = value);
                                }
                              },
                      title: Text(
                        _fulfillment == FulfillmentType.delivery
                            ? strings.cashOnDelivery
                            : strings.cashOnPickup,
                      ),
                      subtitle: Text(strings.payOnHandover),
                    ),
                    RadioListTile<PaymentMethod>(
                      contentPadding: EdgeInsets.zero,
                      value: PaymentMethod.onlineCard,
                      groupValue: PaymentMethod.cash,
                      onChanged: null,
                      title: Text(strings.onlineCard),
                      subtitle: Text(strings.onlineCardUnavailable),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed:
                      _loading ||
                              _submitting ||
                              _failure != null ||
                              quote == null ||
                              _availabilityLoading ||
                              _availability == null ||
                              (!_availability!.asapAvailable &&
                                  _scheduledFor == null) ||
                              !_hasValidSelections ||
                              (_fulfillment == FulfillmentType.delivery &&
                                  _addressId == null)
                          ? null
                          : () => _submitOrder(context, quote),
                  child:
                      _submitting
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(strings.placeOrder),
                ),
              ],
            ),
          ),
    );
  }

  Future<OrderReceipt> _submitWithFreshQuote(Quote quote) async {
    try {
      return await widget.gateway.submitOrder(quote.quoteId, _paymentMethod);
    } on Week2Failure catch (failure) {
      if (failure.kind != Week2FailureKind.notFound) rethrow;
      final refreshed = await _createCurrentQuote();
      if (mounted) setState(() => _quote = refreshed);
      return widget.gateway.submitOrder(refreshed.quoteId, _paymentMethod);
    }
  }

  Future<Quote> _createCurrentQuote() => widget.gateway.createQuote(
    locationId: 'la-favola',
    lines: [
      QuoteLineInput(
        itemId: widget.item.id,
        quantity: _quantity,
        choiceIds: _choiceIds.toList(growable: false),
      ),
    ],
    fulfillmentContext: FulfillmentContext(
      type: _fulfillment,
      addressId: _fulfillment == FulfillmentType.delivery ? _addressId : null,
      scheduledFor: _scheduledFor,
    ),
    couponCode: _coupon.text.trim().isEmpty ? null : _coupon.text.trim(),
  );
  String _apiDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  String? _selectionError(OptionGroupSummary group, AppLocalizations strings) {
    final groupIds = group.choices.map((choice) => choice.id).toSet();
    final selected = _choiceIds.where(groupIds.contains).length;
    if (selected < group.minChoices) {
      return strings.selectionRequired(group.minChoices);
    }
    if (selected > group.maxChoices) {
      return strings.selectionTooMany(group.maxChoices);
    }
    return null;
  }

  Future<void> _submitOrder(BuildContext context, Quote quote) async {
    final navigator = Navigator.of(context);
    final strings = _strings(context);
    setState(() {
      _submitting = true;
      _failure = null;
    });
    try {
      final receipt = await _submitWithFreshQuote(quote);
      if (!mounted) return;
      final track = await showDialog<bool>(
        context: navigator.context,
        builder:
            (context) => AlertDialog(
              icon: const Icon(
                Icons.check_circle_rounded,
                color: LaFavolaTokens.success,
                size: 48,
              ),
              title: Text(strings.orderReceived),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.reference(receipt.reference)),
                  const SizedBox(height: 8),
                  Text(strings.total(_money(receipt.totalMinor))),
                  const SizedBox(height: 8),
                  Text(strings.orderVisibleToTeam),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(strings.backToMenu),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(strings.trackOrder),
                ),
              ],
            ),
      );
      navigator.pop();
      if (track == true) {
        await navigator.push<void>(
          MaterialPageRoute(
            builder:
                (_) => CustomerOrderTrackingScreen(
                  gateway: widget.gateway,
                  orderId: receipt.orderId,
                ),
          ),
        );
      }
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _failure = Week2Failure(
                kind: Week2FailureKind.malformedResponse,
                message:
                    Localizations.localeOf(context).languageCode == 'it'
                        ? 'L’ordine potrebbe essere stato ricevuto. Controlla I tuoi ordini prima di riprovare.'
                        : 'The order may have been received. Check Your orders before trying again.',
                correlationId: 'checkout-confirmation',
                retryable: false,
              ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

final class _CheckoutNotice extends StatelessWidget {
  const _CheckoutNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: LaFavolaTokens.informationContainer,
      borderRadius: BorderRadius.circular(LaFavolaTokens.radiusMedium),
    ),
    child: Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

final class _OrderHistorySummary extends StatelessWidget {
  const _OrderHistorySummary({
    required this.total,
    required this.active,
    required this.completed,
  });

  final int total;
  final int active;
  final int completed;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '$total orders. $active active. $completed completed.',
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LaFavolaTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(LaFavolaTokens.radiusLarge),
        border: Border.all(color: LaFavolaTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _strings(context).orderHistory,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HistoryMetric(
                  value: total,
                  label: _strings(context).allOrders,
                ),
              ),
              Expanded(
                child: _HistoryMetric(
                  value: active,
                  label: _strings(context).active,
                ),
              ),
              Expanded(
                child: _HistoryMetric(
                  value: completed,
                  label: _strings(context).completed,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

final class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$value', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 2),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

final class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({required this.gateway, super.key});

  final Week2Gateway gateway;

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

final class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  List<OrderReceipt>? _orders;
  Week2Failure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failure = null);
    try {
      final orders = await widget.gateway.getOrders();
      if (mounted) setState(() => _orders = orders);
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = _strings(context);
    final orders = _orders;
    if (_failure != null) {
      return _MenuFailure(failure: _failure!, onRetry: _load);
    }
    if (orders == null) return const _MenuLoading();
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: _CheckoutNotice(
            icon: Icons.receipt_long_outlined,
            message: strings.noOrders,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: orders.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            final completed =
                orders
                    .where(
                      (order) => const {
                        'delivered',
                        'picked_up',
                        'closed',
                      }.contains(order.status),
                    )
                    .length;
            final active =
                orders
                    .where(
                      (order) =>
                          !const {
                            'delivered',
                            'picked_up',
                            'closed',
                            'rejected',
                            'cancelled',
                          }.contains(order.status),
                    )
                    .length;
            return _OrderHistorySummary(
              total: orders.length,
              active: active,
              completed: completed,
            );
          }
          final order = orders[index - 1];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(order.reference),
              subtitle: Text(
                '${_orderStatusLabel(strings, order.status)} · ${_formatOrderMoney(order.totalMinor)}',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap:
                  () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => CustomerOrderTrackingScreen(
                            gateway: widget.gateway,
                            orderId: order.orderId,
                          ),
                    ),
                  ).then((_) => _load()),
            ),
          );
        },
      ),
    );
  }
}

final class CustomerOrderTrackingScreen extends StatefulWidget {
  const CustomerOrderTrackingScreen({
    required this.gateway,
    required this.orderId,
    super.key,
  });

  final Week2Gateway gateway;
  final String orderId;

  @override
  State<CustomerOrderTrackingScreen> createState() =>
      _CustomerOrderTrackingScreenState();
}

final class _CustomerOrderTrackingScreenState
    extends State<CustomerOrderTrackingScreen>
    with WidgetsBindingObserver {
  Timer? _pollTimer;
  Timer? _clockTimer;
  Timer? _reconnectTimer;
  StreamSubscription<OrderRealtimeEvent>? _eventSubscription;
  Duration _serverOffset = Duration.zero;
  DateTime _now = DateTime.now();
  OrderReceipt? _order;
  Week2Failure? _failure;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _connectLiveUpdates();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _load());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now().add(_serverOffset));
      }
    });
  }

  void _connectLiveUpdates() {
    _reconnectTimer?.cancel();
    _eventSubscription?.cancel();
    _eventSubscription = widget.gateway
        .watchOrderEvents(widget.orderId)
        .listen(
          (_) => _load(),
          onError: (_) => _scheduleReconnect(),
          onDone: _scheduleReconnect,
        );
  }

  void _scheduleReconnect() {
    if (!mounted ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), _connectLiveUpdates);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
      _connectLiveUpdates();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _eventSubscription?.cancel();
      _reconnectTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    _reconnectTimer?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final order = await widget.gateway.getOrder(widget.orderId);
      if (mounted) {
        final rawServerTime = order.serverTime;
        final serverTime =
            rawServerTime == null
                ? null
                : DateTime.tryParse(rawServerTime)?.toLocal();
        final offset =
            serverTime == null
                ? Duration.zero
                : serverTime.difference(DateTime.now());
        setState(() {
          _order = order;
          _serverOffset = offset;
          _now = DateTime.now().add(offset);
          _failure = null;
        });
      }
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    }
  }

  Future<void> _cancel() async {
    final order = _order;
    if (order == null) return;
    final strings = _strings(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(strings.requestCancellation),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 240,
            decoration: InputDecoration(labelText: strings.cancelReason),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.keepOrder),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) Navigator.pop(context, value);
              },
              child: Text(strings.sendRequest),
            ),
          ],
        );
      },
    );
    if (reason == null) return;
    setState(() => _cancelling = true);
    try {
      final updated = await widget.gateway.requestOrderCancellation(
        orderId: order.orderId,
        expectedVersion: order.version,
        reason: reason,
      );
      if (mounted) setState(() => _order = updated);
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = _strings(context);
    final order = _order;
    final canCancel =
        order != null &&
        !const {
          'delivered',
          'picked_up',
          'served',
          'closed',
          'rejected',
          'cancelled',
        }.contains(order.status) &&
        order.cancellationStatus == 'not_requested';
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.orderTracking),
        actions: [
          IconButton(
            tooltip: strings.refresh,
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body:
          order == null
              ? _failure != null
                  ? _MenuFailure(failure: _failure!, onRetry: _load)
                  : const _MenuLoading()
              : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    order.reference,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _orderStatusLabel(strings, order.status),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _OrderProgressCard(order: order, now: _now),
                  const SizedBox(height: 18),
                  _CheckoutNotice(
                    icon: Icons.payments_outlined,
                    message:
                        '${order.paymentMethod == PaymentMethod.cash ? 'Cash' : 'Online card'} · ${order.paymentStatus.replaceAll('_', ' ')}',
                  ),
                  if (order.cancellationStatus != 'not_requested' ||
                      order.refundStatus != 'not_applicable') ...[
                    const SizedBox(height: 12),
                    _CheckoutNotice(
                      icon: Icons.assignment_return_outlined,
                      message:
                          'Cancellation: ${order.cancellationStatus.replaceAll('_', ' ')} · Refund: ${order.refundStatus.replaceAll('_', ' ')}',
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    strings.timeline,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (order.timeline.isEmpty)
                    Text(strings.orderReceivedTimeline)
                  else
                    for (final event in order.timeline)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_circle_outline_rounded),
                        title: Text(
                          _orderStatusLabel(
                            strings,
                            event.nextStatus ?? event.type,
                          ),
                        ),
                        subtitle:
                            event.reason == null ? null : Text(event.reason!),
                      ),
                  if (_failure != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _failure!.message,
                      style: const TextStyle(color: LaFavolaTokens.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.tonalIcon(
                    onPressed:
                        () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => CustomerOrderReceiptScreen(
                                  gateway: widget.gateway,
                                  orderId: order.orderId,
                                ),
                          ),
                        ),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: Text(strings.viewReceipt),
                  ),
                  const SizedBox(height: 12),
                  if (canCancel)
                    OutlinedButton.icon(
                      onPressed: _cancelling ? null : _cancel,
                      icon: const Icon(Icons.close_rounded),
                      label: Text(
                        _cancelling
                            ? strings.sendingRequest
                            : strings.requestCancellation,
                      ),
                    ),
                ],
              ),
    );
  }
}

final class CustomerOrderReceiptScreen extends StatefulWidget {
  const CustomerOrderReceiptScreen({
    required this.gateway,
    required this.orderId,
    super.key,
  });

  final Week2Gateway gateway;
  final String orderId;

  @override
  State<CustomerOrderReceiptScreen> createState() =>
      _CustomerOrderReceiptScreenState();
}

final class _CustomerOrderReceiptScreenState
    extends State<CustomerOrderReceiptScreen> {
  CustomerOrderReceiptDocument? _receipt;
  Week2Failure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failure = null);
    try {
      final receipt = await widget.gateway.getOrderReceipt(widget.orderId);
      if (mounted) setState(() => _receipt = receipt);
    } on Week2Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = _strings(context);
    final receipt = _receipt;
    return Scaffold(
      appBar: AppBar(title: Text(strings.orderReceipt)),
      body:
          receipt == null
              ? _failure != null
                  ? _MenuFailure(failure: _failure!, onRetry: _load)
                  : Center(
                    child: Semantics(
                      label: strings.receiptLoading,
                      child: const CircularProgressIndicator(),
                    ),
                  )
              : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      receipt.restaurant.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  if (receipt.restaurant.address.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(receipt.restaurant.address.join(', ')),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    receipt.order.number,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.issuedAt(
                      _formatReceiptDate(context, receipt.issuedAt),
                    ),
                  ),
                  const Divider(height: 32),
                  for (final item in receipt.order.items) ...[
                    _ReceiptItemTile(item: item),
                    const Divider(),
                  ],
                  _PriceRow(
                    strings.subtotal,
                    _formatOrderMoney(receipt.order.totals.subtotalMinor),
                  ),
                  if (receipt.order.totals.optionChargesMinor > 0)
                    _PriceRow(
                      strings.optionCharges,
                      _formatOrderMoney(
                        receipt.order.totals.optionChargesMinor,
                      ),
                    ),
                  if (receipt.order.totals.deliveryFeeMinor > 0)
                    _PriceRow(
                      strings.deliveryFee,
                      _formatOrderMoney(receipt.order.totals.deliveryFeeMinor),
                    ),
                  if (receipt.order.totals.discountMinor > 0)
                    _PriceRow(
                      strings.discount,
                      '-${_formatOrderMoney(receipt.order.totals.discountMinor)}',
                    ),
                  _PriceRow(
                    strings.tax,
                    _formatOrderMoney(receipt.order.totals.taxMinor),
                  ),
                  const Divider(),
                  _PriceRow(
                    strings.grandTotal,
                    _formatOrderMoney(receipt.order.totals.grandTotalMinor),
                    strong: true,
                  ),
                  const SizedBox(height: 20),
                  _CheckoutNotice(
                    icon: Icons.info_outline_rounded,
                    message: strings.receiptNotice,
                  ),
                ],
              ),
    );
  }
}

final class _ReceiptItemTile extends StatelessWidget {
  const _ReceiptItemTile({required this.item});

  final ReceiptOrderItem item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.quantity}× '),
            Expanded(
              child: Text(
                [item.name, item.size].whereType<String>().join(' · '),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(_formatOrderMoney(item.lineTotalMinor)),
          ],
        ),
        for (final option in item.options)
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 4),
            child: Text(
              '${option.quantity}× ${option.name}  '
              '${_formatOrderMoney(option.totalPriceAdjustmentMinor)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    ),
  );
}

String _formatReceiptDate(BuildContext context, String raw) {
  final value = DateTime.tryParse(raw)?.toLocal();
  if (value == null) return raw;
  final date = MaterialLocalizations.of(context).formatMediumDate(value);
  final time = TimeOfDay.fromDateTime(value).format(context);
  return '$date · $time';
}

final class _OrderProgressCard extends StatelessWidget {
  const _OrderProgressCard({required this.order, required this.now});

  final OrderReceipt order;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final strings = _strings(context);
    final isDelivery = order.fulfillmentType == 'delivery';
    final target =
        order.status == 'out_for_delivery'
            ? order.estimatedDeliveryAt
            : order.estimatedReadyAt;
    final timer = _orderCountdown(strings, target, now);
    final title = switch (order.status) {
      'placed' => strings.waitingConfirmation,
      'accepted' => strings.orderConfirmed,
      'preparing' => strings.orderBeingPrepared,
      'baking' => strings.pizzaInOven,
      'packing' => strings.packingOrder,
      'ready' when isDelivery => strings.readyForRider,
      'ready' => strings.readyForPickup,
      'out_for_delivery' => strings.riderOnWay,
      _ => _orderStatusLabel(strings, order.status),
    };
    final showTimer =
        target != null &&
        !const {
          'delivered',
          'picked_up',
          'cancelled',
          'rejected',
        }.contains(order.status);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      liveRegion: true,
      label: showTimer ? '$title. $timer.' : title,
      child: AnimatedContainer(
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 240),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: LaFavolaTokens.surfaceMuted,
          borderRadius: BorderRadius.circular(LaFavolaTokens.radiusLarge),
          border: Border.all(color: LaFavolaTokens.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDelivery
                      ? Icons.delivery_dining_rounded
                      : Icons.storefront_rounded,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (showTimer) ...[
              const SizedBox(height: 12),
              Text(timer, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                order.status == 'out_for_delivery'
                    ? strings.estimatedArrival
                    : order.fulfillmentType == 'pickup'
                    ? strings.estimatedCollectionReady
                    : strings.estimatedKitchenReady,
              ),
            ],
            const SizedBox(height: 16),
            _OrderStepStrip(order: order),
            if (order.tableLabel != null) ...[
              const SizedBox(height: 12),
              Text(strings.tableLabel(order.tableLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

final class _OrderStepStrip extends StatelessWidget {
  const _OrderStepStrip({required this.order});
  final OrderReceipt order;

  @override
  Widget build(BuildContext context) {
    final steps =
        order.fulfillmentType == 'delivery'
            ? const [
              'accepted',
              'preparing',
              'ready',
              'out_for_delivery',
              'delivered',
            ]
            : order.fulfillmentType == 'dine_in'
            ? const ['accepted', 'preparing', 'ready', 'served', 'closed']
            : const ['accepted', 'preparing', 'ready', 'picked_up'];
    final normalized =
        order.status == 'baking' || order.status == 'packing'
            ? 'preparing'
            : order.status;
    final current =
        order.status == 'closed' ? steps.length - 1 : steps.indexOf(normalized);
    return Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color:
                    index <= current
                        ? LaFavolaTokens.actionPrimary
                        : LaFavolaTokens.borderSubtle,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          if (index != steps.length - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }
}

String _orderCountdown(
  AppLocalizations strings,
  String? rawTarget,
  DateTime now,
) {
  if (rawTarget == null) return strings.estimatePending;
  final target = DateTime.tryParse(rawTarget)?.toLocal();
  if (target == null) return strings.estimatePending;
  final remaining = target.difference(now);
  if (remaining.inSeconds <= -60) {
    return strings.lateEstimate(remaining.inMinutes.abs());
  }
  if (remaining.inSeconds <= 0) return strings.finalisingNow;
  final minutes = remaining.inMinutes;
  final seconds = remaining.inSeconds.remainder(60);
  return strings.countdown(minutes, seconds.toString().padLeft(2, '0'));
}

String _formatOrderMoney(int minor) =>
    '€${(minor / 100).toStringAsFixed(2).replaceAll('.', ',')}';

String _orderStatusLabel(AppLocalizations strings, String status) =>
    switch (status) {
      'pending_payment' => strings.statusPendingPayment,
      'placed' => strings.statusPlaced,
      'accepted' => strings.statusAccepted,
      'preparing' => strings.statusPreparing,
      'baking' => strings.statusBaking,
      'packing' => strings.statusPacking,
      'ready' => strings.statusReady,
      'driver_assigned' => strings.statusDriverAssigned,
      'out_for_delivery' => strings.statusOutForDelivery,
      'delivered' => strings.statusDelivered,
      'picked_up' => strings.statusPickedUp,
      'served' => strings.statusServed,
      'closed' => strings.statusClosed,
      'cancelled' => strings.statusCancelled,
      'rejected' => strings.statusRejected,
      'delivery_failed' => strings.statusDeliveryFailed,
      _ => status.replaceAll('_', ' '),
    };

final class _BuilderIntro extends StatelessWidget {
  const _BuilderIntro({required this.item, required this.money});

  final MenuItemSummary item;
  final String Function(int minor) money;

  @override
  Widget build(BuildContext context) {
    final strings = _strings(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LaFavolaTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(LaFavolaTokens.radiusMedium),
      ),
      child: Row(
        children: [
          const _PizzaMark(size: 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(strings.builderIntro),
              ],
            ),
          ),
          if (item.basePriceMinor != null) ...[
            const SizedBox(width: 8),
            _PricePill(price: money(item.basePriceMinor!)),
          ],
        ],
      ),
    );
  }
}

final class _SelectionRule extends StatelessWidget {
  const _SelectionRule({required this.group});

  final OptionGroupSummary group;

  @override
  Widget build(BuildContext context) {
    final strings = _strings(context);
    final label =
        group.required
            ? strings.required
            : group.maxChoices == 1
            ? strings.chooseOne
            : strings.chooseUpTo(group.maxChoices);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color:
            group.required
                ? LaFavolaTokens.informationContainer
                : LaFavolaTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: LaFavolaTokens.contentSecondary,
        ),
      ),
    );
  }
}

final class _QuotePanel extends StatelessWidget {
  const _QuotePanel({
    required this.loading,
    required this.quote,
    required this.failure,
    required this.money,
    required this.onRetry,
  });

  final bool loading;
  final Quote? quote;
  final Week2Failure? failure;
  final String Function(int value) money;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = _strings(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LaFavolaTokens.surface,
        border: Border.all(color: LaFavolaTokens.borderSubtle),
        borderRadius: BorderRadius.circular(LaFavolaTokens.radiusMedium),
      ),
      child:
          loading
              ? Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(strings.checkingPrice),
                ],
              )
              : failure != null
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(failure!.message),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: onRetry,
                    child: Text(strings.retry),
                  ),
                ],
              )
              : quote == null
              ? Text(strings.livePriceUnavailable)
              : Column(
                children: [
                  _PriceRow(strings.items, money(quote!.subtotalMinor)),
                  _PriceRow(strings.deliveryFee, money(quote!.feeMinor)),
                  if (quote!.discountMinor > 0)
                    _PriceRow(
                      strings.discount,
                      '-${money(quote!.discountMinor)}',
                    ),
                  const Divider(),
                  _PriceRow(
                    strings.grandTotal,
                    money(quote!.totalMinor),
                    strong: true,
                  ),
                ],
              ),
    );
  }
}

final class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.value, {this.strong = false});
  final String label;
  final String value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: strong ? Theme.of(context).textTheme.titleLarge : null,
        ),
        Text(
          value,
          style: strong ? Theme.of(context).textTheme.titleLarge : null,
        ),
      ],
    ),
  );
}

final class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.enabled,
    required this.onChanged,
  });
  final int quantity;
  final bool enabled;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        _strings(context).quantity,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const Spacer(),
      IconButton(
        onPressed:
            !enabled || quantity == 1 ? null : () => onChanged(quantity - 1),
        icon: const Icon(Icons.remove_circle_outline),
      ),
      Text('$quantity', style: Theme.of(context).textTheme.titleLarge),
      IconButton(
        onPressed: !enabled ? null : () => onChanged(quantity + 1),
        icon: const Icon(Icons.add_circle_outline),
      ),
    ],
  );
}

final class _MenuLoading extends StatelessWidget {
  const _MenuLoading({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: _strings(context).loading,
      child: const CircularProgressIndicator(),
    ),
  );
}

String _localizedWeek2Failure(BuildContext context, Week2Failure failure) {
  final italian = Localizations.localeOf(context).languageCode == 'it';
  return switch (failure.kind) {
    Week2FailureKind.timeout =>
      italian
          ? 'Tempo di attesa superato. Riprova.'
          : 'The request timed out. Try again.',
    Week2FailureKind.dependencyUnavailable =>
      italian
          ? 'Servizio non raggiungibile. Controlla la connessione.'
          : 'The service is unreachable. Check your connection.',
    Week2FailureKind.rateLimited =>
      italian
          ? 'Troppe richieste. Attendi e riprova.'
          : 'Too many requests. Wait and try again.',
    Week2FailureKind.unauthenticated || Week2FailureKind.sessionExpired =>
      italian ? 'Accedi per continuare.' : 'Sign in to continue.',
    _ =>
      italian
          ? 'Operazione non riuscita. Riprova.'
          : 'The operation failed. Try again.',
  };
}

final class _MenuFailure extends StatelessWidget {
  const _MenuFailure({required this.failure, required this.onRetry, super.key});
  final Week2Failure failure;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 40),
          const SizedBox(height: 12),
          Text(
            _strings(context).weCouldNotLoadMenu,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _localizedWeek2Failure(context, failure),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: Text(_strings(context).retry),
          ),
        ],
      ),
    ),
  );
}

final class _MenuEmpty extends StatelessWidget {
  const _MenuEmpty({required this.onRetry, super.key});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.restaurant_menu_outlined, size: 40),
          const SizedBox(height: 12),
          Text(
            _strings(context).menuUpdating,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(_strings(context).noLiveCategories),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(_strings(context).refresh),
          ),
        ],
      ),
    ),
  );
}

final class _NoResults extends StatelessWidget {
  const _NoResults();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: LaFavolaTokens.surface,
      borderRadius: BorderRadius.circular(LaFavolaTokens.radiusMedium),
    ),
    child: Text(_strings(context).noSearchResults),
  );
}

final class _PricePill extends StatelessWidget {
  const _PricePill({required this.price, this.large = false});
  final String price;
  final bool large;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: large ? 14 : 10,
      vertical: large ? 8 : 5,
    ),
    decoration: BoxDecoration(
      color: LaFavolaTokens.actionPrimary,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      price,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: LaFavolaTokens.actionOnPrimary),
    ),
  );
}

final class _AttributeTag extends StatelessWidget {
  const _AttributeTag(this.attribute);
  final String attribute;
  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (attribute) {
      'vegetarian' => (
        'Vegetarian',
        Icons.eco_outlined,
        LaFavolaTokens.success,
      ),
      'spicy' => (
        'Spicy',
        Icons.local_fire_department_outlined,
        Colors.deepOrange,
      ),
      'gluten' => ('Gluten', Icons.grain_outlined, const Color(0xFF9B6718)),
      'lactose' => (
        'Lactose',
        Icons.water_drop_outlined,
        LaFavolaTokens.information,
      ),
      'egg' => ('Egg', Icons.egg_alt_outlined, const Color(0xFF9B6718)),
      'fish' => ('Fish', Icons.set_meal_outlined, LaFavolaTokens.information),
      'nuts' => ('Nuts', Icons.spa_outlined, const Color(0xFF805B1E)),
      _ => (attribute, Icons.info_outline, LaFavolaTokens.contentSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

final class _PizzaMark extends StatelessWidget {
  const _PizzaMark({
    required this.size,
    this.accent = LaFavolaTokens.accentTerracotta,
  });
  final double size;
  final Color accent;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFFE8B97D),
      shape: BoxShape.circle,
      border: Border.all(color: accent, width: size * .08),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .12),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Center(
      child: Icon(
        Icons.local_pizza_rounded,
        size: size * .48,
        color: const Color(0xFFB85437),
      ),
    ),
  );
}

Color _accentFor(String categoryId) {
  final palette = [
    LaFavolaTokens.accentTerracotta,
    LaFavolaTokens.focusOnLight,
    LaFavolaTokens.success,
    const Color(0xFF805B1E),
  ];
  return palette[categoryId.codeUnits.fold<int>(
        0,
        (sum, value) => sum + value,
      ) %
      palette.length];
}
