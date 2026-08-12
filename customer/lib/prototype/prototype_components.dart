import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:la_favola/design_system/tokens.dart';
import 'package:la_favola/prototype/prototype_contract_probe.dart';
import 'package:la_favola/prototype/prototype_state.dart';

class PrototypeNotice extends StatelessWidget {
  const PrototypeNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          'Prototipo locale. Dati non autorevoli. Nessuna rete o transazione.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: LaFavolaTokens.informationContainer,
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(
              Icons.science_outlined,
              color: LaFavolaTokens.information,
              semanticLabel: 'Prototipo',
            ),
            Text(
              'PROTOTIPO LOCALE • DATI NON AUTOREVOLI',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: LaFavolaTokens.information,
              ),
            ),
            Text(
              'Nessuna rete, autenticazione, posizione, pagamento o ordine.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class PrototypeHeader extends StatelessWidget {
  const PrototypeHeader({
    super.key,
    required this.title,
    this.onBack,
    this.backKey,
  });

  final String title;
  final VoidCallback? onBack;
  final Key? backKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (onBack != null)
            IconButton(
              key: backKey,
              tooltip: 'Torna al menu',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
          Text(
            'La Favola',
            semanticsLabel: 'La Favola, titolo provvisorio',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Container(width: 1, height: 28, color: LaFavolaTokens.borderSubtle),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }
}

class PrototypeStateSelector extends StatelessWidget {
  const PrototypeStateSelector({
    super.key,
    required this.screen,
    required this.menuState,
    required this.builderState,
    required this.onScreenChanged,
    required this.onMenuStateChanged,
    required this.onBuilderStateChanged,
  });

  final PrototypeScreen screen;
  final MenuPrototypeState menuState;
  final BuilderPrototypeState builderState;
  final ValueChanged<PrototypeScreen> onScreenChanged;
  final ValueChanged<MenuPrototypeState> onMenuStateChanged;
  final ValueChanged<BuilderPrototypeState> onBuilderStateChanged;

  Future<T?> _choose<T>(
    BuildContext context, {
    required String title,
    required List<T> values,
    required String Function(T) label,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (context) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final value in values)
                    ListTile(
                      minTileHeight: LaFavolaTokens.minimumTouchTarget,
                      title: Text(label(value)),
                      onTap: () => Navigator.of(context).pop(value),
                    ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final stateLabel = switch (screen) {
      PrototypeScreen.homeMenu => menuState.label,
      PrototypeScreen.pizzaBuilder => builderState.label,
    };

    return Container(
      key: const Key('prototype-state-selector'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: LaFavolaTokens.surfaceMuted,
        border: Border.all(color: LaFavolaTokens.borderStrong),
        borderRadius: BorderRadius.circular(LaFavolaTokens.radiusMedium),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: const Key('prototype-state-selector-expansion'),
        initiallyExpanded: false,
        title: Text(
          'Verifica debug • $stateLabel',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: const Text('Espandi per scegliere schermata e stato.'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const Key('show-home-menu'),
                  onPressed: () => onScreenChanged(PrototypeScreen.homeMenu),
                  child: const Text('CUS-UI-01 Menu'),
                ),
                OutlinedButton(
                  key: const Key('show-pizza-builder'),
                  onPressed:
                      () => onScreenChanged(PrototypeScreen.pizzaBuilder),
                  child: const Text('CUS-UI-02 Builder'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('choose-prototype-state'),
              onPressed: () async {
                if (screen == PrototypeScreen.homeMenu) {
                  final result = await _choose<MenuPrototypeState>(
                    context,
                    title: 'Stato CUS-UI-01',
                    values: MenuPrototypeState.values,
                    label: (value) => value.label,
                  );
                  if (result != null) onMenuStateChanged(result);
                  return;
                }
                final result = await _choose<BuilderPrototypeState>(
                  context,
                  title: 'Stato CUS-UI-02',
                  values: BuilderPrototypeState.values,
                  label: (value) => value.label,
                );
                if (result != null) onBuilderStateChanged(result);
              },
              icon: const Icon(Icons.tune),
              label: Text('Scegli stato: $stateLabel'),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label:
                'Contratto Dart generato analizzato. Codici noti e futuri preservati.',
            child: Text(
              'Contratto ${PrototypeContractProbe.metadata.contractVersion} • '
              'errore noto: '
              '${PrototypeContractProbe.preservesKnownError ? "verificato" : "non valido"} • '
              'fallback futuro: '
              '${PrototypeContractProbe.preservesUnknownError ? "verificato" : "non valido"}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          const _ContractRecoveryGallery(),
        ],
      ),
    );
  }
}

class _ContractRecoveryGallery extends StatelessWidget {
  const _ContractRecoveryGallery();

  @override
  Widget build(BuildContext context) {
    final specimens = [
      (const Key('known-error-recovery'), PrototypeContractProbe.knownRecovery),
      (
        const Key('unknown-error-recovery'),
        PrototypeContractProbe.unknownRecovery,
      ),
    ];
    return Column(
      key: const Key('contract-recovery-gallery'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Recuperi sicuri • galleria debug',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final (key, specimen) in specimens) ...[
          Semantics(
            container: true,
            label:
                '${specimen.title}. Codice preservato ${specimen.wireCode}. '
                '${specimen.message}',
            child: Container(
              key: key,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LaFavolaTokens.surface,
                border: Border.all(color: LaFavolaTokens.borderSubtle),
                borderRadius: BorderRadius.circular(LaFavolaTokens.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    specimen.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(specimen.message),
                  Text(
                    'Codice preservato: ${specimen.wireCode} • '
                    '${specimen.retryable ? "riprova consentito" : "correzione richiesta"}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

enum PrototypeMessageKind { information, warning, error, success }

class PrototypeMessage extends StatelessWidget {
  const PrototypeMessage({
    super.key,
    required this.title,
    required this.message,
    this.kind = PrototypeMessageKind.information,
    this.action,
    this.focusNode,
    this.messageKey,
  });

  final String title;
  final String message;
  final PrototypeMessageKind kind;
  final Widget? action;
  final FocusNode? focusNode;
  final Key? messageKey;

  @override
  Widget build(BuildContext context) {
    final (foreground, background, icon, liveRegion) = switch (kind) {
      PrototypeMessageKind.information => (
        LaFavolaTokens.information,
        LaFavolaTokens.informationContainer,
        Icons.info_outline,
        false,
      ),
      PrototypeMessageKind.warning => (
        LaFavolaTokens.warning,
        LaFavolaTokens.warningContainer,
        Icons.warning_amber_rounded,
        true,
      ),
      PrototypeMessageKind.error => (
        LaFavolaTokens.error,
        LaFavolaTokens.errorContainer,
        Icons.error_outline,
        true,
      ),
      PrototypeMessageKind.success => (
        LaFavolaTokens.success,
        LaFavolaTokens.successContainer,
        Icons.check_circle_outline,
        true,
      ),
    };

    return Semantics(
      container: true,
      liveRegion: liveRegion,
      child: Focus(
        focusNode: focusNode,
        child: Container(
          key: messageKey,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: background,
            border: Border(left: BorderSide(color: foreground, width: 4)),
            borderRadius: BorderRadius.circular(LaFavolaTokens.radiusSmall),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(icon, color: foreground),
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: foreground),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(message),
              if (action != null) ...[
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: action!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
