import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_favola/app/customer_app.dart';
import 'package:la_favola/core/session/customer_session_controller.dart';
import 'package:la_favola/features/modernization/presentation/customer_feature_pages.dart';

void main() {
  test(
    'guard preserves intended destination and provider return is public',
    () {
      const signedOut = CustomerSessionState.signedOut();
      expect(
        customerGuardRedirect(
          session: signedOut,
          location: Uri.parse('/favorites'),
        ),
        '/signin?from=%2Ffavorites',
      );
      expect(isPublicCustomerPath('/provider/google'), isTrue);
      expect(
        customerGuardRedirect(
          session: signedOut,
          location: Uri.parse('/provider/google?from=%2Ffavorites'),
        ),
        isNull,
      );
    },
  );

  testWidgets('active home route reflows at 320px and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: CustomerHomePage(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Your La Favola'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
