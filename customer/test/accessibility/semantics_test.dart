import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_favola/app/la_favola_app.dart';
import 'package:la_favola/prototype/prototype_contract_probe.dart';

void main() {
  test(
    'generated contract parses metadata and known plus unknown envelopes',
    () {
      expect(PrototypeContractProbe.metadata.transports.rest, '/api/v1');
      expect(PrototypeContractProbe.metadata.transports.trpc, '/trpc');
      expect(PrototypeContractProbe.preservesKnownError, isTrue);
      expect(PrototypeContractProbe.preservesUnknownError, isTrue);
      expect(
        PrototypeContractProbe.knownRecovery.wireCode,
        'VALIDATION_FAILED',
      );
      expect(
        PrototypeContractProbe.unknownRecovery.wireCode,
        'PROTOTYPE_FUTURE_CODE',
      );
      expect(PrototypeContractProbe.unknownRecovery.retryable, isTrue);
    },
  );

  testWidgets('prototype exposes bounded semantic labels and 48dp controls', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const LaFavolaApp());

    expect(
      find.bySemanticsLabel(
        'Prototipo locale. Dati non autorevoli. Nessuna rete o transazione.',
      ),
      findsOneWidget,
    );
    final favorite = find.byKey(const Key('favorite-item')).first;
    await tester.ensureVisible(favorite);
    final size = tester.getSize(favorite);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    semantics.dispose();
  });

  testWidgets('debug gallery renders safe known and unknown recoveries', (
    tester,
  ) async {
    await tester.pumpWidget(const LaFavolaApp());
    await tester.tap(
      find.byKey(const Key('prototype-state-selector-expansion')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('known-error-recovery')), findsOneWidget);
    expect(find.byKey(const Key('unknown-error-recovery')), findsOneWidget);
    expect(find.textContaining('VALIDATION_FAILED'), findsOneWidget);
    expect(find.textContaining('PROTOTYPE_FUTURE_CODE'), findsOneWidget);
    expect(find.textContaining('messaggio remoto'), findsNothing);
  });
}
