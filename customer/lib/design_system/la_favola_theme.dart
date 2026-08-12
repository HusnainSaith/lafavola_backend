import 'package:flutter/material.dart';
import 'package:la_favola/design_system/tokens.dart';

ThemeData buildLaFavolaTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: LaFavolaTokens.actionPrimary,
    onPrimary: LaFavolaTokens.actionOnPrimary,
    secondary: LaFavolaTokens.actionSecondary,
    onSecondary: LaFavolaTokens.actionOnPrimary,
    error: LaFavolaTokens.error,
    onError: LaFavolaTokens.actionOnPrimary,
    surface: LaFavolaTokens.surface,
    onSurface: LaFavolaTokens.contentPrimary,
  );

  const textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Lora',
      fontSize: 48,
      height: 56 / 48,
      fontWeight: FontWeight.w600,
      color: LaFavolaTokens.contentPrimary,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Lora',
      fontSize: 36,
      height: 44 / 36,
      fontWeight: FontWeight.w600,
      color: LaFavolaTokens.contentPrimary,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 28,
      height: 36 / 28,
      fontWeight: FontWeight.w600,
      color: LaFavolaTokens.contentPrimary,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 22,
      height: 30 / 22,
      fontWeight: FontWeight.w600,
      color: LaFavolaTokens.contentPrimary,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 18,
      height: 26 / 18,
      fontWeight: FontWeight.w600,
      color: LaFavolaTokens.contentPrimary,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 18,
      height: 28 / 18,
      color: LaFavolaTokens.contentPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 16,
      height: 1.5,
      color: LaFavolaTokens.contentPrimary,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      height: 20 / 14,
      color: LaFavolaTokens.contentSecondary,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 12,
      height: 1.5,
      fontWeight: FontWeight.w600,
    ),
  );

  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(LaFavolaTokens.radiusSmall),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: LaFavolaTokens.canvas,
    fontFamily: 'Poppins',
    textTheme: textTheme,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    focusColor: LaFavolaTokens.focusOnLight,
    dividerColor: LaFavolaTokens.borderSubtle,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LaFavolaTokens.actionPrimary,
        foregroundColor: LaFavolaTokens.actionOnPrimary,
        disabledBackgroundColor: LaFavolaTokens.actionDisabled,
        disabledForegroundColor: LaFavolaTokens.contentSecondary,
        minimumSize: const Size(
          LaFavolaTokens.minimumTouchTarget,
          LaFavolaTokens.minimumTouchTarget,
        ),
        shape: rounded,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LaFavolaTokens.actionSecondary,
        minimumSize: const Size(
          LaFavolaTokens.minimumTouchTarget,
          LaFavolaTokens.minimumTouchTarget,
        ),
        side: const BorderSide(color: LaFavolaTokens.borderStrong),
        shape: rounded,
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: LaFavolaTokens.actionSecondary,
        minimumSize: const Size.square(LaFavolaTokens.minimumTouchTarget),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LaFavolaTokens.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LaFavolaTokens.radiusSmall),
        borderSide: const BorderSide(color: LaFavolaTokens.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LaFavolaTokens.radiusSmall),
        borderSide: const BorderSide(color: LaFavolaTokens.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LaFavolaTokens.radiusSmall),
        borderSide: const BorderSide(
          color: LaFavolaTokens.focusOnLight,
          width: 2,
        ),
      ),
      labelStyle: textTheme.bodyMedium,
      floatingLabelStyle: textTheme.bodySmall?.copyWith(
        color: LaFavolaTokens.contentSecondary,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: LaFavolaTokens.contentSecondary,
      ),
      prefixIconColor: LaFavolaTokens.contentSecondary,
      suffixIconColor: LaFavolaTokens.contentSecondary,
      helperStyle: textTheme.bodySmall,
      errorStyle: textTheme.bodySmall?.copyWith(color: LaFavolaTokens.error),
    ),
    chipTheme: ChipThemeData(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      backgroundColor: LaFavolaTokens.surface,
      selectedColor: LaFavolaTokens.informationContainer,
      disabledColor: LaFavolaTokens.surfaceMuted,
      side: const BorderSide(color: LaFavolaTokens.borderStrong),
      shape: rounded,
      labelStyle: textTheme.labelLarge?.copyWith(
        color: LaFavolaTokens.contentPrimary,
      ),
      secondaryLabelStyle: textTheme.labelLarge?.copyWith(
        color: LaFavolaTokens.contentPrimary,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? LaFavolaTokens.contentOnStrong
                  : states.contains(WidgetState.disabled)
                  ? LaFavolaTokens.contentSecondary
                  : LaFavolaTokens.contentPrimary,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? LaFavolaTokens.surfaceStrong
                  : LaFavolaTokens.surface,
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: LaFavolaTokens.borderStrong),
        ),
      ),
    ),
  );
}
