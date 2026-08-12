import 'package:flutter/material.dart';

abstract final class BrandColors {
  static const espresso = Color(0xFF774E32);
  static const coffee = Color(0xFF6F4E37);
  static const terracotta = Color(0xFFB7825F);
  static const destructive = Color(0xFF925E3E);
  static const sand = Color(0xFFC0A891);
  static const sandLight = Color(0xFFF4EDE6);
  static const paper = Color(0xFFFFFAF5);
  static const ink = Color(0xFF3D2B20);
  static const divider = Color(0xFFE2D5CA);
}

abstract final class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: BrandColors.espresso,
      onPrimary: BrandColors.paper,
      secondary: BrandColors.terracotta,
      onSecondary: BrandColors.ink,
      error: BrandColors.destructive,
      onError: BrandColors.paper,
      surface: BrandColors.paper,
      onSurface: BrandColors.ink,
      surfaceContainerHighest: BrandColors.sandLight,
      onSurfaceVariant: BrandColors.espresso,
      outline: BrandColors.sand,
      outlineVariant: BrandColors.divider,
      tertiary: BrandColors.coffee,
      onTertiary: BrandColors.paper,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: BrandColors.sandLight,
      textTheme: base.textTheme.apply(
        fontFamily: 'Poppins',
        bodyColor: BrandColors.ink,
        displayColor: BrandColors.coffee,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BrandColors.espresso,
        foregroundColor: BrandColors.paper,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrandColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BrandColors.coffee, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: BrandColors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: BrandColors.divider),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(BrandColors.paper),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          side: const WidgetStatePropertyAll(
            BorderSide(color: BrandColors.divider),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(color: BrandColors.ink, fontFamily: 'Poppins'),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(BrandColors.paper),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: BrandColors.paper,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: BrandColors.ink, fontFamily: 'Poppins'),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: BrandColors.paper,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: BrandColors.ink,
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: BrandColors.ink,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
