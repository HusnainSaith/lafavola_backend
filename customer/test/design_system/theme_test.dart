import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_favola/design_system/la_favola_theme.dart';
import 'package:la_favola/design_system/tokens.dart';

void main() {
  test('semantic theme uses the approved exact color roles', () {
    final theme = buildLaFavolaTheme();

    expect(theme.scaffoldBackgroundColor, LaFavolaTokens.canvas);
    expect(theme.colorScheme.primary, const Color(0xFF925E3E));
    expect(theme.colorScheme.onPrimary, const Color(0xFFFFFDF9));
    expect(theme.colorScheme.onSurface, const Color(0xFF3D2B20));
    expect(theme.textTheme.headlineLarge?.fontFamily, 'Poppins');
    expect(theme.textTheme.displayMedium?.fontFamily, 'Lora');
  });

  test('breakpoints follow the accepted compact medium expanded contract', () {
    expect(layoutClassFor(599), LaFavolaLayoutClass.compact);
    expect(layoutClassFor(600), LaFavolaLayoutClass.medium);
    expect(layoutClassFor(1023), LaFavolaLayoutClass.medium);
    expect(layoutClassFor(1024), LaFavolaLayoutClass.expanded);
  });
}
