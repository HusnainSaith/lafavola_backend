import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_favola/design_system/la_favola_theme.dart';
import 'package:la_favola/features/menu/customer_menu_experience.dart';
import '../../week2/support/deterministic_week2_gateway.dart';

void main() {
  const categoryId = '44444444-4444-4444-8444-444444444444';
  const itemId = '55555555-5555-4555-8555-555555555555';
  const builderItemId = '11000000-0000-4000-8000-000000000011';

  testWidgets('uses one horizontal category row with a pizza builder entry', (
    tester,
  ) async {
    final gateway = DeterministicWeek2Gateway(latency: Duration.zero);
    var builderOpened = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLaFavolaTheme(),
        home: CustomerMenuScreen(
          gateway: gateway,
          onOpenItem: (_) {},
          onOpenBuilder: (_) => builderOpened = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('customer-menu-category-row')), findsOneWidget);
    expect(find.byKey(Key('menu-category-$categoryId')), findsOneWidget);
    expect(find.text('Create your pizza'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byKey(Key('customer-menu-item-$itemId')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-custom-pizza')));
    expect(builderOpened, isTrue);
  });

  testWidgets('product detail calculates checkout total through the gateway', (
    tester,
  ) async {
    final gateway = DeterministicWeek2Gateway(latency: Duration.zero);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLaFavolaTheme(),
        home: CustomerMenuDetailScreen(gateway: gateway, itemId: itemId),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('customer-item-detail-scroll')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-live-checkout')));
    await tester.pumpAndSettle();

    expect(find.text('Your order'), findsOneWidget);
    expect(find.textContaining('€'), findsWidgets);
  });

  testWidgets(
    'separate custom pizza entry opens server-backed builder choices',
    (tester) async {
      final gateway = DeterministicWeek2Gateway(latency: Duration.zero);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLaFavolaTheme(),
          home: CustomerMenuDetailScreen(
            gateway: gateway,
            itemId: builderItemId,
            openBuilder: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Make it yours. Live price updates as you choose.'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Dough'),
        280,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Dough'), findsOneWidget);
      final requiredChoice = find.byType(CheckboxListTile).first;
      expect(tester.widget<CheckboxListTile>(requiredChoice).value, isTrue);
      await tester.tap(requiredChoice);
      await tester.pump();
      expect(tester.widget<CheckboxListTile>(requiredChoice).value, isTrue);
      expect(find.textContaining(builderItemId), findsNothing);
    },
  );

  testWidgets('tracking uses a server-clock estimate and opens the receipt', (
    tester,
  ) async {
    final gateway = DeterministicWeek2Gateway(latency: Duration.zero);
    final order = (await gateway.getOrders()).single;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLaFavolaTheme(),
        home: CustomerOrderTrackingScreen(
          gateway: gateway,
          orderId: order.orderId,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Order tracking'), findsOneWidget);
    expect(find.textContaining('remaining'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('View receipt'),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('View receipt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Order receipt'), findsOneWidget);
    expect(find.text('Pizza Margherita · Classica'), findsOneWidget);
    expect(find.textContaining('not a fiscal invoice'), findsOneWidget);
    expect(find.textContaining(order.orderId), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
