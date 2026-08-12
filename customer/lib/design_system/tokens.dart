import 'package:flutter/material.dart';

abstract final class LaFavolaTokens {
  static const canvas = Color(0xFFFFFAF5);
  static const surface = Color(0xFFFFFDF9);
  static const surfaceMuted = Color(0xFFF4EDE6);
  static const surfaceStrong = Color(0xFF6F4E37);

  static const contentPrimary = Color(0xFF3D2B20);
  static const contentSecondary = Color(0xFF6F4E37);
  static const contentOnStrong = Color(0xFFFFFDF9);

  static const borderSubtle = Color(0xFFD8C9BC);
  static const borderStrong = Color(0xFF774E32);

  static const actionPrimary = Color(0xFF925E3E);
  static const actionOnPrimary = Color(0xFFFFFDF9);
  static const actionSecondary = Color(0xFF6F4E37);
  static const actionDisabled = Color(0xFFD8C9BC);

  static const focusOnLight = Color(0xFF315E7A);
  static const focusOnFilled = Color(0xFFFFFDF9);
  static const accentTerracotta = Color(0xFFB7825F);
  static const accentSand = Color(0xFFC0A891);

  static const success = Color(0xFF2F6B4F);
  static const successContainer = Color(0xFFE4F2E9);
  static const warning = Color(0xFF805B1E);
  static const warningContainer = Color(0xFFF7ECD8);
  static const error = Color(0xFF9C2B2B);
  static const errorContainer = Color(0xFFFBE7E5);
  static const information = Color(0xFF315E7A);
  static const informationContainer = Color(0xFFE5F0F6);

  static const compactBreakpoint = 600.0;
  static const expandedBreakpoint = 1024.0;

  static const radiusSmall = 8.0;
  static const radiusMedium = 12.0;
  static const radiusLarge = 16.0;
  static const minimumTouchTarget = 48.0;
  static const primaryTaskTarget = 56.0;
}

enum LaFavolaLayoutClass { compact, medium, expanded }

LaFavolaLayoutClass layoutClassFor(double width) {
  if (width < LaFavolaTokens.compactBreakpoint) {
    return LaFavolaLayoutClass.compact;
  }
  if (width < LaFavolaTokens.expandedBreakpoint) {
    return LaFavolaLayoutClass.medium;
  }
  return LaFavolaLayoutClass.expanded;
}
