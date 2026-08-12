import 'package:flutter/material.dart';
import 'package:la_favola/design_system/tokens.dart';
import 'package:la_favola/prototype/prototype_components.dart';
import 'package:la_favola/prototype/prototype_state.dart';

class PizzaBuilderScreen extends StatefulWidget {
  const PizzaBuilderScreen({
    super.key,
    required this.state,
    required this.onStateChanged,
    required this.onBack,
  });

  final BuilderPrototypeState state;
  final ValueChanged<BuilderPrototypeState> onStateChanged;
  final VoidCallback onBack;

  @override
  State<PizzaBuilderScreen> createState() => _PizzaBuilderScreenState();
}

class _PizzaBuilderScreenState extends State<PizzaBuilderScreen> {
  static const _quantityMinimum = 1;
  static const _quantityMaximum = 5;
  static const _additionalMaximum = 2;
  final _requiredGroupFocusNode = FocusNode(
    debugLabel: 'builder required option group',
  );
  String? _baseChoice = '[opzione richiesta A]';
  final Set<String> _additionalChoices = {};
  int _quantity = _quantityMinimum;

  @override
  void initState() {
    super.initState();
    _applyDeterministicStateFixture(widget.state);
    _focusErrorIfNeeded();
  }

  @override
  void didUpdateWidget(covariant PizzaBuilderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _applyDeterministicStateFixture(widget.state);
      _focusErrorIfNeeded();
    }
  }

  @override
  void dispose() {
    _requiredGroupFocusNode.dispose();
    super.dispose();
  }

  void _applyDeterministicStateFixture(BuilderPrototypeState state) {
    if (state == BuilderPrototypeState.requiredError) {
      _baseChoice = null;
    } else {
      _baseChoice ??= '[opzione richiesta A]';
    }
    if (state == BuilderPrototypeState.minMax) {
      _additionalChoices
        ..clear()
        ..addAll(const [
          '[opzione aggiuntiva richiesta A]',
          '[opzione aggiuntiva richiesta B]',
        ]);
    }
    _quantity = _quantity.clamp(_quantityMinimum, _quantityMaximum);
  }

  void _focusErrorIfNeeded() {
    if (widget.state != BuilderPrototypeState.requiredError) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requiredGroupFocusNode.requestFocus();
    });
  }

  void _simulateRefresh(VoidCallback update) {
    update();
    widget.onStateChanged(BuilderPrototypeState.refreshPending);
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (mounted) widget.onStateChanged(BuilderPrototypeState.ready);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = layoutClassFor(constraints.maxWidth);
        final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final useSingleColumn =
            layout == LaFavolaLayoutClass.compact || textScale > 1.5;
        final horizontal = layout == LaFavolaLayoutClass.compact ? 16.0 : 24.0;

        final form = _BuilderForm(
          state: widget.state,
          baseChoice: _baseChoice,
          additionalChoices: _additionalChoices,
          quantity: _quantity,
          requiredGroupFocusNode: _requiredGroupFocusNode,
          onBaseChanged:
              (value) => _simulateRefresh(() {
                setState(() => _baseChoice = value);
              }),
          onAdditionalChanged:
              (value, selected) => _simulateRefresh(() {
                setState(() {
                  selected
                      ? _additionalChoices.add(value)
                      : _additionalChoices.remove(value);
                });
              }),
          onDecrease:
              _quantity <= _quantityMinimum
                  ? null
                  : () => _simulateRefresh(() {
                    setState(() => _quantity -= 1);
                  }),
          onIncrease:
              _quantity >= _quantityMaximum
                  ? null
                  : () => _simulateRefresh(() {
                    setState(() => _quantity += 1);
                  }),
          onRetry: () => _simulateRefresh(() {}),
          onReviewChange:
              () => widget.onStateChanged(BuilderPrototypeState.ready),
        );
        final summary = _BuilderSummary(
          state: widget.state,
          onConfirm: () => widget.onStateChanged(BuilderPrototypeState.success),
          onBack: widget.onBack,
        );

        return SingleChildScrollView(
          key: const Key('pizza-builder-scroll'),
          padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Configura la voce',
                key: const Key('pizza-builder-title'),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '[nome voce richiesto] • [fonte e versione richieste]',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '[descrizione e ingredienti richiesti]',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                '[allergene richiesto]',
                key: Key('builder-allergen-label'),
              ),
              const Text(
                '[etichetta dietetica richiesta]',
                key: Key('builder-dietary-label'),
              ),
              const SizedBox(height: 12),
              Semantics(
                container: true,
                label:
                    'Immagine opzionale non fornita. '
                    'La configurazione resta disponibile.',
                child: Container(
                  key: const Key('builder-media-fallback'),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: LaFavolaTokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(
                      LaFavolaTokens.radiusMedium,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.image_not_supported_outlined),
                      SizedBox(width: 12),
                      Expanded(child: Text('[immagine opzionale non fornita]')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (useSingleColumn) ...[
                form,
                const SizedBox(height: 20),
                summary,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: form),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: summary),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BuilderForm extends StatelessWidget {
  const _BuilderForm({
    required this.state,
    required this.baseChoice,
    required this.additionalChoices,
    required this.quantity,
    required this.requiredGroupFocusNode,
    required this.onBaseChanged,
    required this.onAdditionalChanged,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRetry,
    required this.onReviewChange,
  });

  final BuilderPrototypeState state;
  final String? baseChoice;
  final Set<String> additionalChoices;
  final int quantity;
  final FocusNode requiredGroupFocusNode;
  final ValueChanged<String?> onBaseChanged;
  final void Function(String, bool) onAdditionalChanged;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback onRetry;
  final VoidCallback onReviewChange;

  @override
  Widget build(BuildContext context) {
    final stateMessage = switch (state) {
      BuilderPrototypeState.requiredError => PrototypeMessage(
        messageKey: const Key('builder-required-error'),
        title: 'Completa la scelta richiesta',
        message:
            'Riepilogo errori: seleziona [gruppo richiesto]. '
            'Il focus è collegato al primo gruppo non valido senza '
            'cancellare le altre scelte.',
        kind: PrototypeMessageKind.error,
        action: OutlinedButton(
          key: const Key('focus-first-invalid-group'),
          onPressed: requiredGroupFocusNode.requestFocus,
          child: const Text('Vai alla prima scelta non valida'),
        ),
      ),
      BuilderPrototypeState.minMax => const PrototypeMessage(
        messageKey: Key('builder-min-max-state'),
        title: 'Limite di selezione',
        message:
            '2 di 2 opzioni selezionate. Minimo 0, massimo 2 • '
            '[fonte richiesta]. Le opzioni non selezionate sono disabilitate '
            'e la conferma resta bloccata in questo stato.',
        kind: PrototypeMessageKind.warning,
      ),
      BuilderPrototypeState.unavailable => const PrototypeMessage(
        messageKey: Key('builder-unavailable-state'),
        title: 'Opzione non disponibile',
        message:
            '[opzione richiesta B] non può essere selezionata. '
            'Motivo e alternativa devono provenire dalla fonte approvata.',
        kind: PrototypeMessageKind.warning,
      ),
      BuilderPrototypeState.refreshPending => const PrototypeMessage(
        messageKey: Key('builder-refresh-pending-state'),
        title: 'Aggiornamento in corso',
        message:
            'Prezzo, [allergene richiesto] ed '
            '[etichetta dietetica richiesta] restano non confermati '
            'fino al risultato autorevole.',
      ),
      BuilderPrototypeState.refreshError => PrototypeMessage(
        messageKey: const Key('builder-refresh-error-state'),
        title: 'Aggiornamento non riuscito',
        message:
            'Le scelte locali sono preservate. Non è possibile confermare '
            'prezzo, [allergene richiesto] o '
            '[etichetta dietetica richiesta].',
        kind: PrototypeMessageKind.error,
        action: OutlinedButton(
          key: const Key('retry-builder-refresh'),
          onPressed: onRetry,
          child: const Text('Riprova aggiornamento'),
        ),
      ),
      BuilderPrototypeState.versionPriceChange => PrototypeMessage(
        messageKey: const Key('builder-version-change-state'),
        title: 'Versione o prezzo cambiato',
        message:
            'Prima: [prezzo precedente richiesto]. '
            'Adesso: [prezzo aggiornato richiesto]. '
            'La differenza deve essere riesaminata esplicitamente.',
        kind: PrototypeMessageKind.warning,
        action: OutlinedButton(
          key: const Key('review-builder-change'),
          onPressed: onReviewChange,
          child: const Text('Ho riesaminato il cambiamento'),
        ),
      ),
      BuilderPrototypeState.success => const PrototypeMessage(
        messageKey: Key('builder-success-state'),
        title: 'Configurazione prototipo aggiornata',
        message:
            'Risultato visuale persistente. Nessun carrello, ordine o '
            'pagamento è stato creato.',
        kind: PrototypeMessageKind.success,
      ),
      BuilderPrototypeState.ready => const PrototypeMessage(
        messageKey: Key('builder-ready-state'),
        title: 'Dati autorevoli richiesti',
        message:
            'Ogni modifica simula un aggiornamento locale. Prezzo, compatibilità '
            '[allergene richiesto] ed [etichetta dietetica richiesta] '
            'restano segnaposto.',
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        stateMessage,
        if (state == BuilderPrototypeState.refreshPending) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(key: Key('builder-refresh-progress')),
        ],
        const SizedBox(height: 20),
        _OptionSection(
          sectionKey: const Key('builder-required-option-group'),
          title: '[gruppo richiesto]',
          help: 'Obbligatorio • minimo 1, massimo 1 • [fonte richiesta]',
          hasError: state == BuilderPrototypeState.requiredError,
          focusNode:
              state == BuilderPrototypeState.requiredError
                  ? requiredGroupFocusNode
                  : null,
          child: Column(
            children: [
              RadioListTile<String>(
                key: const Key('builder-base-choice-a'),
                contentPadding: EdgeInsets.zero,
                title: const Text('[opzione richiesta A]'),
                subtitle: const Text('[prezzo richiesto]'),
                value: '[opzione richiesta A]',
                groupValue:
                    state == BuilderPrototypeState.requiredError
                        ? null
                        : baseChoice,
                onChanged:
                    state == BuilderPrototypeState.refreshPending
                        ? null
                        : onBaseChanged,
              ),
              RadioListTile<String>(
                key: const Key('builder-base-choice-b'),
                contentPadding: EdgeInsets.zero,
                title: const Text('[opzione richiesta B]'),
                subtitle: Text(
                  state == BuilderPrototypeState.unavailable
                      ? 'Non disponibile • [motivo richiesto]'
                      : '[prezzo richiesto]',
                ),
                value: '[opzione richiesta B]',
                groupValue:
                    state == BuilderPrototypeState.requiredError
                        ? null
                        : baseChoice,
                onChanged:
                    state == BuilderPrototypeState.unavailable ||
                            state == BuilderPrototypeState.refreshPending
                        ? null
                        : onBaseChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _OptionSection(
          title: '[gruppo aggiuntivo richiesto]',
          help:
              'Facoltativo • minimo 0, massimo 2 • [fonte richiesta] • '
              '${additionalChoices.length} di 2 selezionate',
          child: Column(
            children: [
              for (final (index, option)
                  in const [
                    '[opzione aggiuntiva richiesta A]',
                    '[opzione aggiuntiva richiesta B]',
                    '[opzione aggiuntiva richiesta C]',
                  ].indexed)
                CheckboxListTile(
                  key: Key('builder-additional-choice-$index'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(option),
                  subtitle: const Text('[prezzo richiesto]'),
                  value: additionalChoices.contains(option),
                  onChanged:
                      state == BuilderPrototypeState.refreshPending ||
                              (state == BuilderPrototypeState.minMax &&
                                  !additionalChoices.contains(option) &&
                                  additionalChoices.length >=
                                      _PizzaBuilderScreenState
                                          ._additionalMaximum)
                          ? null
                          : (value) =>
                              onAdditionalChanged(option, value ?? false),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _QuantityControl(
          quantity: quantity,
          onDecrease:
              state == BuilderPrototypeState.refreshPending ? null : onDecrease,
          onIncrease:
              state == BuilderPrototypeState.refreshPending ? null : onIncrease,
        ),
      ],
    );
  }
}

class _OptionSection extends StatelessWidget {
  const _OptionSection({
    required this.title,
    required this.help,
    required this.child,
    this.sectionKey,
    this.hasError = false,
    this.focusNode,
  });

  final String title;
  final String help;
  final Widget child;
  final Key? sectionKey;
  final bool hasError;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    Widget section(bool hasFocus) {
      return Semantics(
        container: true,
        explicitChildNodes: true,
        label:
            '$title. $help'
            '${hasError ? ". Errore di scelta richiesta" : ""}'
            '${hasFocus ? ". Focus visibile sulla prima scelta non valida" : ""}',
        child: Container(
          key: sectionKey,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: LaFavolaTokens.surface,
            border: Border.all(
              color:
                  hasFocus
                      ? LaFavolaTokens.focusOnLight
                      : hasError
                      ? LaFavolaTokens.error
                      : LaFavolaTokens.borderSubtle,
              width: hasFocus ? 3 : (hasError ? 2 : 1),
            ),
            borderRadius: BorderRadius.circular(LaFavolaTokens.radiusMedium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              Text(help, style: Theme.of(context).textTheme.bodySmall),
              if (hasError)
                Text(
                  'Seleziona una voce in questo gruppo.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: LaFavolaTokens.error),
                ),
              if (hasError && hasFocus)
                Semantics(
                  container: true,
                  excludeSemantics: true,
                  label: 'Prima scelta non valida con focus visibile',
                  child: Container(
                    key: const Key('builder-invalid-focus-indicator'),
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: LaFavolaTokens.informationContainer,
                      borderRadius: BorderRadius.circular(
                        LaFavolaTokens.radiusSmall,
                      ),
                    ),
                    child: Text(
                      'Prima scelta non valida • focus attivo',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: LaFavolaTokens.focusOnLight,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      );
    }

    if (focusNode == null) return section(false);
    return Focus(
      focusNode: focusNode,
      child: AnimatedBuilder(
        animation: focusNode!,
        builder: (context, _) => section(focusNode!.hasFocus),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Quantità prototipo: $quantity',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LaFavolaTokens.surface,
          border: Border.all(color: LaFavolaTokens.borderSubtle),
          borderRadius: BorderRadius.circular(LaFavolaTokens.radiusMedium),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Quantità prototipo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'Limiti sintetici: minimo 1, massimo 5',
              key: Key('builder-quantity-bounds'),
            ),
            IconButton(
              key: const Key('decrease-quantity'),
              tooltip: 'Riduci quantità',
              onPressed: onDecrease,
              icon: const Icon(Icons.remove),
            ),
            Text('$quantity', style: Theme.of(context).textTheme.titleLarge),
            IconButton(
              key: const Key('increase-quantity'),
              tooltip: 'Aumenta quantità',
              onPressed: onIncrease,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuilderSummary extends StatelessWidget {
  const _BuilderSummary({
    required this.state,
    required this.onConfirm,
    required this.onBack,
  });

  final BuilderPrototypeState state;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final blocked =
        state == BuilderPrototypeState.refreshPending ||
        state == BuilderPrototypeState.requiredError ||
        state == BuilderPrototypeState.minMax ||
        state == BuilderPrototypeState.refreshError ||
        state == BuilderPrototypeState.versionPriceChange;
    return Container(
      key: const Key('builder-summary'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LaFavolaTokens.surfaceStrong,
        borderRadius: BorderRadius.circular(LaFavolaTokens.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Riepilogo prototipo',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: LaFavolaTokens.contentOnStrong,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '[scelte richieste]\n[allergene richiesto]\n'
            '[etichetta dietetica richiesta]',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LaFavolaTokens.contentOnStrong,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Totale: [prezzo richiesto]',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: LaFavolaTokens.contentOnStrong,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('builder-primary-action'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(
                LaFavolaTokens.primaryTaskTarget,
                LaFavolaTokens.primaryTaskTarget,
              ),
            ),
            onPressed: blocked ? null : onConfirm,
            child: Text(
              state == BuilderPrototypeState.success
                  ? 'Aggiorna ancora il prototipo'
                  : 'Conferma nel prototipo',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('builder-return-menu'),
            style: OutlinedButton.styleFrom(
              foregroundColor: LaFavolaTokens.contentOnStrong,
              side: const BorderSide(color: LaFavolaTokens.contentOnStrong),
            ),
            onPressed: onBack,
            child: const Text('Torna al menu'),
          ),
        ],
      ),
    );
  }
}
