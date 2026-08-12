import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_favola/app/la_favola_app.dart';
import 'package:la_favola/prototype/prototype_state.dart';

void main() {
  final expectedKeys = <MenuPrototypeState, Key>{
    MenuPrototypeState.ready: const Key('menu-ready-state'),
    MenuPrototypeState.loading: const Key('menu-loading-state'),
    MenuPrototypeState.empty: const Key('menu-empty-state'),
    MenuPrototypeState.noResults: const Key('menu-no-results-state'),
    MenuPrototypeState.itemUnavailable: const Key('menu-unavailable-state'),
    MenuPrototypeState.stale: const Key('menu-stale-state'),
    MenuPrototypeState.offline: const Key('menu-offline-state'),
    MenuPrototypeState.favoriteAuthRequired: const Key(
      'favorite-auth-required-state',
    ),
  };

  for (final entry in expectedKeys.entries) {
    testWidgets('CUS-UI-01 reaches exact ${entry.key.name} state', (
      tester,
    ) async {
      await tester.pumpWidget(LaFavolaApp(initialMenuState: entry.key));
      await tester.pump();

      expect(find.byKey(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('loading exposes three stable item-shaped skeletons', (
    tester,
  ) async {
    await tester.pumpWidget(
      const LaFavolaApp(initialMenuState: MenuPrototypeState.loading),
    );
    await tester.pump();

    for (var index = 0; index < 3; index++) {
      expect(find.byKey(Key('menu-loading-item-$index')), findsOneWidget);
    }
  });

  testWidgets('no results retains query and emits one bounded announcement', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const LaFavolaApp());
    final search = find.byKey(const Key('menu-search'));
    await tester.enterText(search, 'query sintetica senza corrispondenza');
    await tester.pump();

    expect(find.byKey(const Key('menu-no-results-state')), findsOneWidget);
    expect(
      tester.widget<TextField>(search).controller?.text,
      'query sintetica senza corrispondenza',
    );
    expect(
      find.bySemanticsLabel(
        '0 risultati. Ricerca e filtri sono stati mantenuti. '
        'Cancella ricerca e filtri per tornare al menu prototipo.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('empty is catalog-empty and does not announce zero results', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const LaFavolaApp(initialMenuState: MenuPrototypeState.empty),
    );
    await tester.pump();

    expect(find.byKey(const Key('menu-empty-state')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^0 risultati')), findsNothing);
    semantics.dispose();
  });

  testWidgets('catalog empty offers non-destructive verified recovery', (
    tester,
  ) async {
    await tester.pumpWidget(
      const LaFavolaApp(initialMenuState: MenuPrototypeState.empty),
    );
    await tester.pump();

    final recovery = find.byKey(const Key('refresh-empty-menu'));
    await tester.ensureVisible(recovery);
    await tester.pumpAndSettle();
    expect(recovery.hitTestable(), findsOneWidget);
    await tester.tap(recovery);
    await tester.pump();
    expect(find.byKey(const Key('menu-loading-state')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const Key('menu-ready-state')), findsOneWidget);
  });

  for (final size in const [Size(320, 800), Size(390, 844)]) {
    testWidgets('compact ${size.width} exposes search without prior scroll', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const LaFavolaApp());
      await tester.pump();

      expect(
        find.byKey(const Key('menu-search')).hitTestable(),
        findsOneWidget,
      );
    });
  }

  for (final state in const [
    MenuPrototypeState.stale,
    MenuPrototypeState.offline,
  ]) {
    testWidgets('${state.name} cached actions remain disabled', (tester) async {
      await tester.pumpWidget(LaFavolaApp(initialMenuState: state));
      await tester.pump();

      final favorite = find.byKey(const Key('favorite-item')).first;
      final open = find.byKey(const Key('open-builder')).first;
      expect(tester.widget<OutlinedButton>(favorite).onPressed, isNull);
      expect(tester.widget<FilledButton>(open).onPressed, isNull);
      expect(
        find.byKey(
          Key(
            state == MenuPrototypeState.stale
                ? 'refresh-stale-menu'
                : 'retry-offline-menu',
          ),
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('menu actions have unique context and preserve return intent', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const LaFavolaApp());

    expect(
      find.bySemanticsLabel('Salva preferito per voce segnaposto 1'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Apri voce segnaposto 2'), findsOneWidget);

    final favorite = find.byKey(const Key('favorite-item')).first;
    await tester.ensureVisible(favorite);
    await tester.tap(favorite);
    await tester.pump();
    expect(
      find.byKey(const Key('favorite-auth-required-state')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('return-to-menu-item')));
    await tester.pump();
    final open = find.byKey(const Key('open-builder')).first;
    await tester.ensureVisible(open);
    await tester.tap(open);
    await tester.pump();

    expect(find.byKey(const Key('pizza-builder-title')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('debug selector changes the visible surface', (tester) async {
    await tester.pumpWidget(const LaFavolaApp());
    await tester.tap(
      find.byKey(const Key('prototype-state-selector-expansion')),
    );
    await tester.pumpAndSettle();
    final showBuilder = find.byKey(const Key('show-pizza-builder'));
    await tester.ensureVisible(showBuilder);
    await tester.pumpAndSettle();
    expect(showBuilder.hitTestable(), findsOneWidget);
    await tester.tap(showBuilder.hitTestable());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pizza-builder-title')), findsOneWidget);
  });
}
