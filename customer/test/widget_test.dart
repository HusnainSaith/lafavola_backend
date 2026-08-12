import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_favola/app/la_favola_app.dart';

void main() {
  testWidgets('renders the bounded local prototype shell', (tester) async {
    await tester.pumpWidget(const LaFavolaApp());

    expect(find.textContaining('PROTOTIPO LOCALE'), findsOneWidget);
    expect(find.byKey(const Key('home-menu-title')), findsOneWidget);
    expect(find.textContaining('carrello', findRichText: true), findsNothing);
  });
}
