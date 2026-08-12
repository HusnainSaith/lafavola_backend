import 'package:flutter/material.dart';
import 'package:la_favola/design_system/tokens.dart';
import 'package:la_favola/prototype/prototype_components.dart';
import 'package:la_favola/prototype/prototype_state.dart';

class HomeMenuScreen extends StatefulWidget {
  const HomeMenuScreen({
    super.key,
    required this.state,
    required this.onStateChanged,
    required this.onOpenBuilder,
  });

  final MenuPrototypeState state;
  final ValueChanged<MenuPrototypeState> onStateChanged;
  final VoidCallback onOpenBuilder;

  @override
  State<HomeMenuScreen> createState() => _HomeMenuScreenState();
}

class _HomeMenuScreenState extends State<HomeMenuScreen> {
  final _searchController = TextEditingController();
  bool _cardView = false;
  bool _filterActive = false;
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retry() {
    widget.onStateChanged(MenuPrototypeState.loading);
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (mounted) widget.onStateChanged(MenuPrototypeState.ready);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = layoutClassFor(constraints.maxWidth);
        final horizontal = layout == LaFavolaLayoutClass.compact ? 16.0 : 24.0;
        return SingleChildScrollView(
          key: const Key('home-menu-scroll'),
          padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (layout != LaFavolaLayoutClass.compact) ...[
                _EditorialWelcome(layout: layout),
                const SizedBox(height: 20),
                const _SourceStatusMessage(),
                const SizedBox(height: 20),
              ],
              Text(
                'Esplora il menu',
                key: const Key('home-menu-title'),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Contenuti segnaposto: nessun nome, prezzo, ingrediente o '
                'allergene è presentato come dato reale.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('menu-search'),
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Cerca nel menu prototipo',
                  helperText: 'La ricerca usa soltanto segnaposto locali.',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchController.text.isEmpty
                          ? null
                          : IconButton(
                            key: const Key('clear-search'),
                            tooltip: 'Cancella ricerca',
                            onPressed: () {
                              _searchController.clear();
                              widget.onStateChanged(MenuPrototypeState.ready);
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          ),
                ),
                onChanged: (value) {
                  widget.onStateChanged(
                    value.trim().isEmpty ||
                            '[nome voce richiesto]'.contains(
                              value.trim().toLowerCase(),
                            )
                        ? MenuPrototypeState.ready
                        : MenuPrototypeState.noResults,
                  );
                  setState(() {});
                },
              ),
              if (layout == LaFavolaLayoutClass.compact) ...[
                const SizedBox(height: 16),
                const _SourceStatusMessage(),
              ],
              const SizedBox(height: 16),
              _CategoryFilters(
                selected: _selectedCategory,
                onSelected: (value) {
                  setState(() {
                    _selectedCategory =
                        _selectedCategory == value ? null : value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('toggle-filter'),
                    onPressed:
                        () => setState(() {
                          _filterActive = !_filterActive;
                        }),
                    icon: Icon(
                      _filterActive
                          ? Icons.filter_alt
                          : Icons.filter_alt_outlined,
                    ),
                    label: Text(
                      _filterActive
                          ? 'Rimuovi filtro prototipo'
                          : 'Applica filtro prototipo',
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const Key('show-list'),
                    onPressed: () => setState(() => _cardView = false),
                    icon: const Icon(Icons.view_list_outlined),
                    label: const Text('Vista elenco'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('show-cards'),
                    onPressed: () => setState(() => _cardView = true),
                    icon: const Icon(Icons.grid_view_outlined),
                    label: const Text('Vista schede'),
                  ),
                ],
              ),
              if (layout == LaFavolaLayoutClass.compact) ...[
                const SizedBox(height: 20),
                _EditorialWelcome(layout: layout),
              ],
              const SizedBox(height: 20),
              _MenuStateContent(
                state: widget.state,
                layout: layout,
                cardView: _cardView,
                onOpenBuilder: widget.onOpenBuilder,
                onFavorite:
                    () => widget.onStateChanged(
                      MenuPrototypeState.favoriteAuthRequired,
                    ),
                onClear: () {
                  _searchController.clear();
                  setState(() {
                    _filterActive = false;
                    _selectedCategory = null;
                  });
                  widget.onStateChanged(MenuPrototypeState.ready);
                },
                onRetry: _retry,
                onReturnToItem:
                    () => widget.onStateChanged(MenuPrototypeState.ready),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SourceStatusMessage extends StatelessWidget {
  const _SourceStatusMessage();

  @override
  Widget build(BuildContext context) {
    return const PrototypeMessage(
      title: '[stato servizio richiesto]',
      message:
          'Stato, orari e disponibilità devono arrivare dalla fonte '
          'approvata. Questo prototipo non dichiara che il servizio sia aperto.',
    );
  }
}

class _EditorialWelcome extends StatelessWidget {
  const _EditorialWelcome({required this.layout});

  final LaFavolaLayoutClass layout;

  @override
  Widget build(BuildContext context) {
    final productHeading =
        layout == LaFavolaLayoutClass.compact
            ? Theme.of(context).textTheme.headlineLarge
            : Theme.of(context).textTheme.headlineMedium;
    return Container(
      padding: EdgeInsets.all(layout == LaFavolaLayoutClass.compact ? 20 : 28),
      decoration: BoxDecoration(
        color: LaFavolaTokens.surfaceStrong,
        borderRadius: BorderRadius.circular(LaFavolaTokens.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[modalità di servizio richiesta]',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: LaFavolaTokens.contentOnStrong,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Una scelta alla volta.',
            style: productHeading?.copyWith(
              color: LaFavolaTokens.contentOnStrong,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Disponibilità, modalità di servizio, prezzo, allergeni ed '
            'etichette dietetiche dipendono dalla fonte approvata.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LaFavolaTokens.contentOnStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const categories = [
      '[categoria richiesta A]',
      '[categoria richiesta B]',
      '[categoria richiesta C]',
    ];
    return Semantics(
      container: true,
      label: 'Categorie del menu prototipo',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final category in categories)
            FilterChip(
              label: Text(category),
              selected: selected == category,
              onSelected: (_) => onSelected(category),
            ),
        ],
      ),
    );
  }
}

class _MenuStateContent extends StatelessWidget {
  const _MenuStateContent({
    required this.state,
    required this.layout,
    required this.cardView,
    required this.onOpenBuilder,
    required this.onFavorite,
    required this.onClear,
    required this.onRetry,
    required this.onReturnToItem,
  });

  final MenuPrototypeState state;
  final LaFavolaLayoutClass layout;
  final bool cardView;
  final VoidCallback onOpenBuilder;
  final VoidCallback onFavorite;
  final VoidCallback onClear;
  final VoidCallback onRetry;
  final VoidCallback onReturnToItem;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      MenuPrototypeState.loading => const _MenuLoading(),
      MenuPrototypeState.empty => PrototypeMessage(
        messageKey: Key('menu-empty-state'),
        title: 'Catalogo vuoto',
        message:
            'La fonte del catalogo non contiene voci. Ricerca e filtri non '
            'sono la causa di questo stato.',
        kind: PrototypeMessageKind.information,
        action: OutlinedButton(
          key: const Key('refresh-empty-menu'),
          onPressed: onRetry,
          child: const Text('Verifica di nuovo il catalogo'),
        ),
      ),
      MenuPrototypeState.noResults => Semantics(
        key: const Key('menu-no-results-state'),
        container: true,
        excludeSemantics: true,
        liveRegion: true,
        label:
            '0 risultati. Ricerca e filtri sono stati mantenuti. '
            'Cancella ricerca e filtri per tornare al menu prototipo.',
        child: PrototypeMessage(
          title: '0 risultati',
          message:
              'Nessun segnaposto corrisponde. La query e i filtri correnti '
              'restano visibili e invariati.',
          kind: PrototypeMessageKind.information,
          action: OutlinedButton(
            key: const Key('clear-menu-filters'),
            onPressed: onClear,
            child: const Text('Cancella ricerca e filtri'),
          ),
        ),
      ),
      MenuPrototypeState.itemUnavailable => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PrototypeMessage(
            messageKey: Key('menu-unavailable-state'),
            title: 'Voce non disponibile',
            message:
                'Motivo e prossima azione devono arrivare dalla fonte approvata. '
                'Nessuna sostituzione viene proposta automaticamente.',
            kind: PrototypeMessageKind.warning,
          ),
          const SizedBox(height: 12),
          const _PrototypeMenuCard(
            itemIndex: 0,
            unavailable: true,
            onOpen: null,
            onFavorite: null,
          ),
        ],
      ),
      MenuPrototypeState.stale => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrototypeMessage(
            messageKey: const Key('menu-stale-state'),
            title: 'Catalogo non aggiornato',
            message:
                'Ultimo aggiornamento: [orario richiesto]. La consultazione '
                'della copia locale è consentita, ma apertura e preferiti '
                'restano disabilitati finché la fonte non viene aggiornata.',
            kind: PrototypeMessageKind.warning,
            action: OutlinedButton(
              key: const Key('refresh-stale-menu'),
              onPressed: onRetry,
              child: const Text('Aggiorna il catalogo'),
            ),
          ),
          const SizedBox(height: 12),
          _MenuItems(
            layout: layout,
            cardView: cardView,
            onOpenBuilder: onOpenBuilder,
            onFavorite: onFavorite,
            cached: true,
          ),
        ],
      ),
      MenuPrototypeState.offline => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrototypeMessage(
            messageKey: const Key('menu-offline-state'),
            title: 'Connessione assente',
            message:
                'La copia locale è di sola consultazione. Non è possibile '
                'verificare disponibilità, aprire il builder o salvare '
                'preferiti finché la connessione non torna disponibile.',
            kind: PrototypeMessageKind.error,
            action: OutlinedButton(
              key: const Key('retry-offline-menu'),
              onPressed: onRetry,
              child: const Text('Riprova la connessione'),
            ),
          ),
          const SizedBox(height: 12),
          _MenuItems(
            layout: layout,
            cardView: cardView,
            onOpenBuilder: onOpenBuilder,
            onFavorite: onFavorite,
            cached: true,
          ),
        ],
      ),
      MenuPrototypeState.favoriteAuthRequired => PrototypeMessage(
        messageKey: const Key('favorite-auth-required-state'),
        title: 'Accedi per salvare il preferito',
        message:
            'Il preferito non è stato salvato. Il ritorno previsto è '
            '[voce richiesta]; il flusso di accesso è fuori da questo prototipo.',
        kind: PrototypeMessageKind.information,
        action: OutlinedButton(
          key: const Key('return-to-menu-item'),
          onPressed: onReturnToItem,
          child: const Text('Torna alla voce'),
        ),
      ),
      MenuPrototypeState.ready => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PrototypeMessage(
            messageKey: Key('menu-ready-state'),
            title: 'Fonte del catalogo richiesta',
            message:
                'Versione, data di efficacia e disponibilità sono segnaposto. '
                'Aprire una voce porta solo al builder visuale locale.',
          ),
          const SizedBox(height: 12),
          _MenuItems(
            layout: layout,
            cardView: cardView,
            onOpenBuilder: onOpenBuilder,
            onFavorite: onFavorite,
          ),
        ],
      ),
    };
  }
}

class _MenuLoading extends StatelessWidget {
  const _MenuLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('menu-loading-state'),
      container: true,
      excludeSemantics: true,
      liveRegion: true,
      label: 'Caricamento del menu prototipo. Tre voci in preparazione.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Caricamento dei segnaposto in corso…'),
          const SizedBox(height: 12),
          for (var index = 0; index < 3; index++) ...[
            _MenuSkeletonCard(index: index),
            if (index < 2) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _MenuSkeletonCard extends StatelessWidget {
  const _MenuSkeletonCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        key: Key('menu-loading-item-$index'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LaFavolaTokens.surface,
          border: Border.all(color: LaFavolaTokens.borderSubtle),
          borderRadius: BorderRadius.circular(LaFavolaTokens.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: LaFavolaTokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(
                      LaFavolaTokens.radiusSmall,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 18,
                        width: 180,
                        color: LaFavolaTokens.surfaceMuted,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 96,
                        color: LaFavolaTokens.surfaceMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 14,
              width: double.infinity,
              color: LaFavolaTokens.surfaceMuted,
            ),
            const SizedBox(height: 8),
            Container(
              height: 48,
              width: 160,
              decoration: BoxDecoration(
                color: LaFavolaTokens.surfaceMuted,
                borderRadius: BorderRadius.circular(LaFavolaTokens.radiusSmall),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItems extends StatelessWidget {
  const _MenuItems({
    required this.layout,
    required this.cardView,
    required this.onOpenBuilder,
    required this.onFavorite,
    this.cached = false,
  });

  final LaFavolaLayoutClass layout;
  final bool cardView;
  final VoidCallback onOpenBuilder;
  final VoidCallback onFavorite;
  final bool cached;

  @override
  Widget build(BuildContext context) {
    final columns =
        cardView
            ? switch (layout) {
              LaFavolaLayoutClass.compact => 1,
              LaFavolaLayoutClass.medium => 2,
              LaFavolaLayoutClass.expanded => 3,
            }
            : 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var index = 0; index < 3; index++)
              SizedBox(
                width: width,
                child: _PrototypeMenuCard(
                  itemIndex: index,
                  cached: cached,
                  onOpen: cached ? null : onOpenBuilder,
                  onFavorite: cached ? null : onFavorite,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PrototypeMenuCard extends StatelessWidget {
  const _PrototypeMenuCard({
    required this.itemIndex,
    required this.onOpen,
    required this.onFavorite,
    this.unavailable = false,
    this.cached = false,
  });

  final int itemIndex;
  final VoidCallback? onOpen;
  final VoidCallback? onFavorite;
  final bool unavailable;
  final bool cached;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '[nome voce richiesto], [prezzo richiesto], '
          '[allergene richiesto], [etichetta dietetica richiesta], '
          '${unavailable
              ? "non disponibile"
              : cached
              ? "copia locale"
              : "segnaposto"}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LaFavolaTokens.surface,
          border: Border.all(
            color:
                unavailable
                    ? LaFavolaTokens.warning
                    : LaFavolaTokens.borderSubtle,
          ),
          borderRadius: BorderRadius.circular(LaFavolaTokens.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: LaFavolaTokens.surfaceMuted,
                      borderRadius: BorderRadius.circular(
                        LaFavolaTokens.radiusSmall,
                      ),
                    ),
                    child: const Icon(Icons.image_outlined),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '[nome voce richiesto]',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '[prezzo richiesto]',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '[descrizione, ingredienti e indicazioni richiesti]',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            const Text('[allergene richiesto]'),
            const Text('[etichetta dietetica richiesta]'),
            if (cached) ...[
              const SizedBox(height: 8),
              Text(
                'Copia locale non aggiornata • sola consultazione',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: LaFavolaTokens.warning),
              ),
            ],
            if (unavailable) ...[
              const SizedBox(height: 8),
              Text(
                'Non disponibile • [motivo richiesto]',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: LaFavolaTokens.warning),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Semantics(
                  button: true,
                  excludeSemantics: true,
                  label:
                      'Salva preferito per voce segnaposto ${itemIndex + 1}'
                      '${onFavorite == null ? ", non disponibile" : ""}',
                  child: OutlinedButton.icon(
                    key: Key(
                      itemIndex == 0
                          ? 'favorite-item'
                          : 'favorite-item-$itemIndex',
                    ),
                    onPressed: onFavorite,
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('Salva preferito'),
                  ),
                ),
                Semantics(
                  button: true,
                  excludeSemantics: true,
                  label:
                      'Apri voce segnaposto ${itemIndex + 1}'
                      '${onOpen == null ? ", non disponibile" : ""}',
                  child: FilledButton(
                    key: Key(
                      itemIndex == 0
                          ? 'open-builder'
                          : 'open-builder-$itemIndex',
                    ),
                    onPressed: onOpen,
                    child: Text(
                      unavailable || cached
                          ? 'Voce non disponibile'
                          : 'Apri la voce',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
