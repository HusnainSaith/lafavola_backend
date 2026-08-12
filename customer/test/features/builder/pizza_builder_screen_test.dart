import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_favola/app/la_favola_app.dart';
import 'package:la_favola/design_system/la_favola_theme.dart';
import 'package:la_favola/design_system/tokens.dart';
import 'package:la_favola/features/builder/pizza_builder_screen.dart';
import 'package:la_favola/prototype/prototype_state.dart';

void main() {
  final expectedKeys = <BuilderPrototypeState, Key>{
    BuilderPrototypeState.ready: const Key('builder-ready-state'),
    BuilderPrototypeState.requiredError: const Key('builder-required-error'),
    BuilderPrototypeState.minMax: const Key('builder-min-max-state'),
    BuilderPrototypeState.unavailable: const Key('builder-unavailable-state'),
    BuilderPrototypeState.refreshPending: const Key(
      'builder-refresh-pending-state',
    ),
    BuilderPrototypeState.refreshError: const Key(
      'builder-refresh-error-state',
    ),
    BuilderPrototypeState.versionPriceChange: const Key(
      'builder-version-change-state',
    ),
    BuilderPrototypeState.success: const Key('builder-success-state'),
  };

  for (final entry in expectedKeys.entries) {
    testWidgets('CUS-UI-02 reaches exact ${entry.key.name} state', (
      tester,
    ) async {
      await tester.pumpWidget(
        LaFavolaApp(
          initialScreen: PrototypeScreen.pizzaBuilder,
          initialBuilderState: entry.key,
        ),
      );
      await tester.pump();

      expect(find.byKey(entry.value), findsOneWidget);
      expect(find.byKey(const Key('builder-quantity-bounds')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('required error focuses and links to first invalid group', (
    tester,
  ) async {
    await tester.pumpWidget(
      const LaFavolaApp(
        initialScreen: PrototypeScreen.pizzaBuilder,
        initialBuilderState: BuilderPrototypeState.requiredError,
      ),
    );
    await tester.pump();

    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'builder required option group',
    );
    expect(
      find.byKey(const Key('builder-required-option-group')),
      findsOneWidget,
    );
    final link = find.byKey(const Key('focus-first-invalid-group'));
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'builder required option group',
    );
    expect(
      find.byKey(const Key('builder-invalid-focus-indicator')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Prima scelta non valida con focus visibile'),
      findsOneWidget,
    );
    final focusedDecoration =
        tester
                .widget<Container>(
                  find.byKey(const Key('builder-required-option-group')),
                )
                .decoration
            as BoxDecoration;
    final focusedBorder = focusedDecoration.border! as Border;
    expect(focusedBorder.top.color, LaFavolaTokens.focusOnLight);
    expect(focusedBorder.top.width, 3);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('builder-primary-action')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('deterministic maximum disables only the next selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      const LaFavolaApp(
        initialScreen: PrototypeScreen.pizzaBuilder,
        initialBuilderState: BuilderPrototypeState.minMax,
      ),
    );
    await tester.pump();

    expect(find.textContaining('2 di 2 opzioni selezionate'), findsOneWidget);
    expect(find.textContaining('2 di 2 selezionate'), findsOneWidget);
    final third = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, '[opzione aggiuntiva richiesta C]'),
    );
    expect(third.value, isFalse);
    expect(third.onChanged, isNull);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('builder-primary-action')))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'additional choices survive required and refresh/version transitions',
    (tester) async {
      final state = ValueNotifier(BuilderPrototypeState.ready);
      addTearDown(state.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLaFavolaTheme(),
          home: Scaffold(
            body: ValueListenableBuilder<BuilderPrototypeState>(
              valueListenable: state,
              builder:
                  (context, value, _) => PizzaBuilderScreen(
                    state: value,
                    onStateChanged: (next) => state.value = next,
                    onBack: () {},
                  ),
            ),
          ),
        ),
      );

      final firstAdditional = find.byKey(
        const Key('builder-additional-choice-0'),
      );
      await tester.ensureVisible(firstAdditional);
      await tester.tap(firstAdditional);
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.widget<CheckboxListTile>(firstAdditional).value, isTrue);

      for (final next in const [
        BuilderPrototypeState.requiredError,
        BuilderPrototypeState.refreshPending,
        BuilderPrototypeState.refreshError,
        BuilderPrototypeState.versionPriceChange,
      ]) {
        state.value = next;
        await tester.pump();
        expect(
          tester.widget<CheckboxListTile>(firstAdditional).value,
          isTrue,
          reason: 'choice must survive ${next.name}',
        );
      }
    },
  );

  testWidgets(
    'quantity remains bounded from synthetic minimum 1 to maximum 5',
    (tester) async {
      await tester.pumpWidget(
        const LaFavolaApp(initialScreen: PrototypeScreen.pizzaBuilder),
      );
      final decrease = find.byKey(const Key('decrease-quantity'));
      final increase = find.byKey(const Key('increase-quantity'));
      await tester.ensureVisible(decrease);
      expect(tester.widget<IconButton>(decrease).onPressed, isNull);

      for (var step = 0; step < 4; step++) {
        await tester.ensureVisible(increase);
        await tester.tap(increase);
        await tester.pump(const Duration(milliseconds: 250));
      }

      expect(find.text('5'), findsOneWidget);
      expect(tester.widget<IconButton>(increase).onPressed, isNull);
    },
  );

  testWidgets('builder exposes source-required labels and media fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const LaFavolaApp(initialScreen: PrototypeScreen.pizzaBuilder),
    );
    await tester.pump();

    expect(find.text('[allergene richiesto]'), findsWidgets);
    expect(find.text('[etichetta dietetica richiesta]'), findsWidgets);
    expect(find.byKey(const Key('builder-media-fallback')), findsOneWidget);
  });

  testWidgets('builder primary action is 56dp and yields durable success', (
    tester,
  ) async {
    await tester.pumpWidget(
      const LaFavolaApp(initialScreen: PrototypeScreen.pizzaBuilder),
    );
    final action = find.byKey(const Key('builder-primary-action'));
    await tester.ensureVisible(action);

    expect(tester.getSize(action).height, greaterThanOrEqualTo(56));
    await tester.tap(action);
    await tester.pump();
    expect(find.byKey(const Key('builder-success-state')), findsOneWidget);
  });
}
