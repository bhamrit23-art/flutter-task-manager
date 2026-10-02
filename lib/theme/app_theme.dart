import 'package:flutter/material.dart';

import '../models/task_model.dart';

/// A quiet, mostly monochrome look: ink on paper in light mode, the reverse in
/// dark mode. Colour is reserved for meaning (priority, overdue, errors).
class AppTheme {
  AppTheme._();

  // Neutral ramp
  static const Color _ink = Color(0xFF18181B);
  static const Color _paper = Color(0xFFFAFAFA);
  static const Color _grey100 = Color(0xFFF4F4F5);
  static const Color _grey200 = Color(0xFFE4E4E7);
  static const Color _grey300 = Color(0xFFD4D4D8);
  static const Color _grey400 = Color(0xFFA1A1AA);
  static const Color _grey500 = Color(0xFF71717A);
  static const Color _grey600 = Color(0xFF52525B);
  static const Color _grey800 = Color(0xFF27272A);
  static const Color _night = Color(0xFF0C0C0E);
  static const Color _nightSurface = Color(0xFF161618);

  static const double radius = 14;

  static ThemeData get lightTheme => _build(_lightScheme, _paper);
  static ThemeData get darkTheme => _build(_darkScheme, _night);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _ink,
    onPrimary: Colors.white,
    primaryContainer: _grey200,
    onPrimaryContainer: _ink,
    secondary: Color(0xFF15803D),
    onSecondary: Colors.white,
    secondaryContainer: _grey200,
    onSecondaryContainer: _ink,
    error: Color(0xFFDC2626),
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF991B1B),
    surface: Colors.white,
    onSurface: _ink,
    onSurfaceVariant: _grey500,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Colors.white,
    surfaceContainer: Colors.white,
    surfaceContainerHigh: Colors.white,
    surfaceContainerHighest: _grey100,
    outline: _grey300,
    outlineVariant: _grey200,
    inverseSurface: _ink,
    onInverseSurface: _paper,
    inversePrimary: Colors.white,
    surfaceTint: Colors.transparent,
    shadow: Colors.black,
    scrim: Colors.black,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _paper,
    onPrimary: _ink,
    primaryContainer: _grey800,
    onPrimaryContainer: _paper,
    secondary: Color(0xFF4ADE80),
    onSecondary: _ink,
    secondaryContainer: _grey800,
    onSecondaryContainer: _paper,
    error: Color(0xFFF87171),
    onError: _ink,
    errorContainer: Color(0xFF450A0A),
    onErrorContainer: Color(0xFFFECACA),
    surface: _nightSurface,
    onSurface: _paper,
    onSurfaceVariant: _grey400,
    surfaceContainerLowest: _night,
    surfaceContainerLow: _nightSurface,
    surfaceContainer: _nightSurface,
    surfaceContainerHigh: Color(0xFF1C1C1F),
    surfaceContainerHighest: _grey800,
    outline: _grey600,
    outlineVariant: _grey800,
    inverseSurface: _paper,
    onInverseSurface: _ink,
    inversePrimary: _ink,
    surfaceTint: Colors.transparent,
    shadow: Colors.black,
    scrim: Colors.black,
  );

  /// Dot colour used to mark a task's priority.
  static Color priorityColor(TaskPriority priority, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (priority) {
      case TaskPriority.high:
        return dark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
      case TaskPriority.medium:
        return dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      case TaskPriority.low:
        return dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    }
  }

  static ThemeData _build(ColorScheme scheme, Color background) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      // Flutter shrinks controls on desktop by default. One density everywhere
      // keeps sizes identical across phone, web and desktop.
      visualDensity: VisualDensity.standard,
    );

    final textTheme = base.textTheme
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
        .copyWith(
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: scheme.onSurface,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: scheme.onSurface,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: scheme.onSurface,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
            color: scheme.onSurface,
          ),
        );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const buttonTextStyle =
        TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 20),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape.copyWith(side: BorderSide(color: scheme.outlineVariant)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: inputBorder(scheme.outlineVariant),
        enabledBorder: inputBorder(scheme.outlineVariant),
        focusedBorder: inputBorder(scheme.primary, 1.5),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 1.5),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: buttonShape,
          textStyle: buttonTextStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: scheme.outlineVariant),
          shape: buttonShape,
          textStyle: buttonTextStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: buttonShape,
          textStyle: buttonTextStyle,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 4,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedTextStyle: buttonTextStyle,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurfaceVariant,
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: scheme.onPrimary,
          side: BorderSide(color: scheme.outlineVariant),
          shape: buttonShape,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          visualDensity: VisualDensity.standard,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const CircleBorder(),
        side: BorderSide(color: scheme.outline, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 19),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        elevation: 3,
        shape: shape.copyWith(side: BorderSide(color: scheme.outlineVariant)),
        textStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: scheme.onInverseSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: scheme.onInverseSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}
