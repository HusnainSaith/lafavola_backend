import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_favola/app/la_favola_app.dart';
import 'package:la_favola/prototype/prototype_state.dart';

Future<void> pumpCase(
  WidgetTester tester, {
  required Size size,
  required double textScale,
  PrototypeScreen screen = PrototypeScreen.homeMenu,
  MenuPrototypeState menuState = MenuPrototypeState.ready,
  BuilderPrototypeState builderState = BuilderPrototypeState.ready,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  await tester.pumpWidget(
    LaFavolaApp(
      initialScreen: screen,
      initialMenuState: menuState,
      initialBuilderState: builderState,
    ),
  );
  await tester.pump();
}

Future<Finder> reveal(
  WidgetTester tester,
  Key key, {
  required Size viewport,
  bool mustBeHitTestable = false,
}) async {
  final finder = find.byKey(key).first;
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump();
  final rect = tester.getRect(finder);
  expect(rect.bottom, greaterThan(0));
  expect(rect.top, lessThan(viewport.height));
  if (mustBeHitTestable) {
    expect(finder.hitTestable(), findsOneWidget);
  }
  return finder;
}

void expectControlEnabled(
  WidgetTester tester,
  Finder finder, {
  required bool enabled,
}) {
  final widget = tester.widget(finder);
  final Object? callback;
  if (widget is RadioListTile<String>) {
    callback = widget.onChanged;
  } else {
    callback = switch (widget) {
      OutlinedButton(:final onPressed) => onPressed,
      FilledButton(:final onPressed) => onPressed,
      IconButton(:final onPressed) => onPressed,
      CheckboxListTile(:final onChanged) => onChanged,
      _ =>
        throw TestFailure(
          'Unsupported control ${widget.runtimeType} in reachability matrix',
        ),
    };
  }
  expect(callback, enabled ? isNotNull : isNull);
}

Future<void> exerciseMenuState(
  WidgetTester tester, {
  required MenuPrototypeState state,
  required Size size,
  required double scale,
}) async {
  await pumpCase(tester, size: size, textScale: scale, menuState: state);

  switch (state) {
    case MenuPrototypeState.ready:
      final open = await reveal(
        tester,
        const Key('open-builder'),
        viewport: size,
        mustBeHitTestable: true,
      );
      expectControlEnabled(tester, open, enabled: true);
      await tester.tap(open);
      await tester.pump();
      expect(find.byKey(const Key('pizza-builder-title')), findsOneWidget);
    case MenuPrototypeState.loading:
      await reveal(tester, const Key('menu-loading-item-2'), viewport: size);
      expect(find.byKey(const Key('menu-loading-state')), findsOneWidget);
    case MenuPrototypeState.empty:
      final refresh = await reveal(
        tester,
        const Key('refresh-empty-menu'),
        viewport: size,
        mustBeHitTestable: true,
      );
      expectControlEnabled(tester, refresh, enabled: true);
      await tester.tap(refresh);
      await tester.pump();
      expect(find.byKey(const Key('menu-loading-state')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const Key('menu-ready-state')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const Key('menu-ready-state')), findsOneWidget);
    case MenuPrototypeState.noResults:
      final clear = await reveal(
        tester,
        const Key('clear-menu-filters'),
        viewport: size,
        mustBeHitTestable: true,
      );
      expectControlEnabled(tester, clear, enabled: true);
      await tester.tap(clear);
      await tester.pump();
      expect(find.byKey(const Key('menu-ready-state')), findsOneWidget);
    case MenuPrototypeState.itemUnavailable:
      for (final key in const [Key('favorite-item'), Key('open-builder')]) {
        final disabled = await reveal(tester, key, viewport: size);
        expectControlEnabled(tester, disabled, enabled: false);
      }
      expect(find.byKey(const Key('menu-unavailable-state')), findsOneWidget);
    case MenuPrototypeState.stale:
      for (final key in const [Key('favorite-item'), Key('open-builder')]) {
        final disabled = await reveal(tester, key, viewport: size);
        expectControlEnabled(tester, disabled, enabled: false);
      }
      final refresh = await reveal(
        tester,
        const Key('refresh-stale-menu'),
        viewport: size,
        mustBeHitTestable: true,
      );
      expectControlEnabled(tester, refresh, enabled: true);
      await tester.tap(refresh);
      await tester.pump();
      expect(find.byKey(const Key('menu-loading-state')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const Key('menu-ready-state')), findsOneWidget);
    case MenuPrototypeState.offline:
      for (final key in const [Key('favorite-item'), Key('open-builder')]) {
        final disabled = await reveal(tester, key, viewport: size);
        expectControlEnabled(tester, disabled, enabled: false);
      }
      final retry = await reveal(
        tester,
        const Key('retry-offline-menu'),
        viewport: size,
        mustBeHitTestable: true,
      );
      expectControlEnabled(tester, retry, enabled: true);
      await tester.tap(retry);
      await tester.pump();
      expect(find.byKey(const Key('menu-loading-state')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const Key('menu-ready-state')), findsOneWidget);
    case MenuPrototypeState.favoriteAuthRequired:
      final back = await reveal(
        tester,
        const Key('return-to-menu-item'),
        viewport: size,
        mustBeHitTestable: true,
      );
      expectControlEnabled(tester, back, enabled: true);
      await tester.tap(back);
      await tester.pump();
      expect(find.byKey(const Key('menu-ready-state')), findsOneWidget);
  }
  expect(tester.takeException(), isNull);
}

Future<void> exerciseBuilderState(
  WidgetTester tester, {
  required BuilderPrototypeState state,
  required Size size,
  required double scale,
}) async {
  await pumpCase(
    tester,
    size: size,
    textScale: scale,
    screen: PrototypeScreen.pizzaBuilder,
    builderState: state,
  );

  final base = await reveal(
    tester,
    const Key('builder-base-choice-a'),
    viewport: size,
  );
  expectControlEnabled(
    tester,
    base,
    enabled: state != BuilderPrototypeState.refreshPending,
  );

  final additional = await reveal(
    tester,
    const Key('builder-additional-choice-0'),
    viewport: size,
  );
  expectControlEnabled(
    tester,
    additional,
    enabled: state != BuilderPrototypeState.refreshPending,
  );

  final decrease = await reveal(
    tester,
    const Key('decrease-quantity'),
    viewport: size,
  );
  expectControlEnabled(tester, decrease, enabled: false);
  final increase = await reveal(
    tester,
    const Key('increase-quantity'),
    viewport: size,
    mustBeHitTestable: state != BuilderPrototypeState.refreshPending,
  );
  expectControlEnabled(
    tester,
    increase,
    enabled: state != BuilderPrototypeState.refreshPending,
  );

  final primary = await reveal(
    tester,
    const Key('builder-primary-action'),
    viewport: size,
  );
  final primaryEnabled =
      !const {
        BuilderPrototypeState.requiredError,
        BuilderPrototypeState.minMax,
        BuilderPrototypeState.refreshPending,
        BuilderPrototypeState.refreshError,
        BuilderPrototypeState.versionPriceChange,
      }.contains(state);
  expectControlEnabled(tester, primary, enabled: primaryEnabled);
  if (primaryEnabled) {
    expect(primary.hitTestable(), findsOneWidget);
  }

  switch (state) {
    case BuilderPrototypeState.ready ||
        BuilderPrototypeState.unavailable ||
        BuilderPrototypeState.success:
      await tester.tap(primary);
      await tester.pump();
      expect(find.byKey(const Key('builder-success-state')), findsOneWidget);
    case BuilderPrototypeState.requiredError:
      final focusLink = await reveal(
        tester,
        const Key('focus-first-invalid-group'),
        viewport: size,
        mustBeHitTestable: true,
      );
      expectControlEnabled(tester, focusLink, enabled: true);
      await tester.tap(focusLink);
      await tester.pump();
      expect(
        find.byKey(const Key('builder-invalid-focus-indicator')),
        findsOneWidget,
      );
    case BuilderPrototypeState.minMax:
      final nextChoice = await reveal(
        tester,
        const Key('builder-additional-choice-2'),
        viewport: size,
      );
      expectControlEnabled(tester, nextChoice, enabled: false);
    case BuilderPrototypeState.refreshPending:
      await reveal(
        tester,
        const Key('builder-refresh-progress'),
        viewport: size,
      );
    case BuilderPrototypeState.refreshError:
      final retry = await reveal(
        tester,
        const Key('retry-builder-refresh'),
        viewport: size,
        mustBeHitTestable: true,
      );
      expectControlEnabled(tester, retry, enabled: true);
      await tester.tap(retry);
      await tester.pump();
      expect(
        find.byKey(const Key('builder-refresh-pending-state')),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const Key('builder-ready-state')), findsOneWidget);
    case BuilderPrototypeState.versionPriceChange:
      final review = await reveal(
        tester,
        const Key('review-builder-change'),
        viewport: size,
        mustBeHitTestable: true,
      );
      expectControlEnabled(tester, review, enabled: true);
      await tester.tap(review);
      await tester.pump();
      expect(find.byKey(const Key('builder-ready-state')), findsOneWidget);
  }
  expect(tester.takeException(), isNull);
}

void main() {
  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.clearTextScaleFactorTestValue();
  });

  for (final size in const [Size(320, 800), Size(390, 844)]) {
    for (final scale in const [1.0, 2.0]) {
      for (final state in MenuPrototypeState.values) {
        testWidgets('menu ${state.name} controls reachable at '
            '${size.width}x${size.height} ${scale}x', (tester) async {
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await exerciseMenuState(
            tester,
            state: state,
            size: size,
            scale: scale,
          );
        });
      }

      for (final state in BuilderPrototypeState.values) {
        testWidgets('builder ${state.name} controls reachable at '
            '${size.width}x${size.height} ${scale}x', (tester) async {
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await exerciseBuilderState(
            tester,
            state: state,
            size: size,
            scale: scale,
          );
        });
      }
    }
  }
}
