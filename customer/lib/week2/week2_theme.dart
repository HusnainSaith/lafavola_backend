import 'package:flutter/material.dart';

abstract final class Week2Colors {
  static const canvas = Color(0xFFFFFAF5);
  static const base = Color(0xFFFFFDF9);
  static const muted = Color(0xFFF4EDE6);
  static const strong = Color(0xFF6F4E37);
  static const primaryText = Color(0xFF3D2B20);
  static const secondaryText = Color(0xFF6F4E37);
  static const primaryAction = Color(0xFF925E3E);
  static const focus = Color(0xFF315E7A);
  static const border = Color(0xFFD8C9BC);
  static const inputBoundary = Color(0xFF6F4E37);
  static const success = Color(0xFF2F6B4F);
  static const successContainer = Color(0xFFE4F2E9);
  static const warning = Color(0xFF805B1E);
  static const warningContainer = Color(0xFFF7ECD8);
  static const error = Color(0xFF9C2B2B);
  static const errorContainer = Color(0xFFFBE7E5);
  static const info = Color(0xFF315E7A);
  static const infoContainer = Color(0xFFE5F0F6);
}

ThemeData buildWeek2Theme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Week2Colors.primaryAction,
    brightness: Brightness.light,
    primary: Week2Colors.primaryAction,
    onPrimary: Week2Colors.base,
    surface: Week2Colors.base,
    onSurface: Week2Colors.primaryText,
    error: Week2Colors.error,
    onError: Week2Colors.base,
  );
  final textTheme = Typography.material2021().black.apply(
    bodyColor: Week2Colors.primaryText,
    displayColor: Week2Colors.primaryText,
    fontFamily: 'Poppins',
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Week2Colors.canvas,
    textTheme: textTheme.copyWith(
      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontFamily: 'Poppins',
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontFamily: 'Poppins',
        fontSize: 22,
        height: 30 / 22,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontFamily: 'Poppins',
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 14, height: 20 / 14),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Week2Colors.base,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Week2Colors.inputBoundary),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Week2Colors.inputBoundary),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Week2Colors.focus, width: 2),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Week2Colors.error, width: 2),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    ),
    cardTheme: const CardThemeData(
      color: Week2Colors.base,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Week2Colors.border),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    focusColor: Week2Colors.focus.withValues(alpha: 0.14),
    splashFactory: NoSplash.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _NoMotionPageTransitionsBuilder(),
        TargetPlatform.iOS: _NoMotionPageTransitionsBuilder(),
        TargetPlatform.macOS: _NoMotionPageTransitionsBuilder(),
        TargetPlatform.windows: _NoMotionPageTransitionsBuilder(),
        TargetPlatform.linux: _NoMotionPageTransitionsBuilder(),
      },
    ),
  );
}

final class _NoMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoMotionPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
