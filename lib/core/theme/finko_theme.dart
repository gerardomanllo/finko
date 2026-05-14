import 'package:flutter/material.dart';

/// Design tokens from the Finko brand palette.
abstract final class FinkoColors {
  static const Color primary = Color(0xFF173FBA);
  static const Color primaryLight = Color(0xFF3E6FF5);
  static const Color cloud = Color(0xFFF0F4FE);
  static const Color grayDark = Color(0xFF4D5462);
  static const Color gray = Color(0xFF6D727F);
  static const Color grayLight = Color(0xFFD2D5DA);
  static const Color navy900 = Color(0xFF0E1630);
  static const Color navy800 = Color(0xFF141F3F);
  static const Color navy700 = Color(0xFF1B2A53);
  static const Color textOnDark = Color(0xFFE6EBFA);
  static const Color income = Color(0xFF2EA66B);
  static const Color expense = Color(0xFFE45A63);
}

abstract final class FinkoTheme {
  /// Light mode: all Material **surface** roles resolve to white so widgets pick up
  /// a white background by default. Use **containers** (e.g. [ColorScheme.primaryContainer]),
  /// **semantic** colors, or explicit [Color] / [BoxDecoration] when a non-white surface
  /// is intentional.
  static const String _font = 'Poppins';

  static const Color _lightSurface = Colors.white;

  // ─── Light theme ───────────────────────────────────────────────────────────
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: FinkoColors.primary,
          primary: FinkoColors.primary,
          secondary: FinkoColors.primaryLight,
          tertiary: FinkoColors.gray,
          surface: _lightSurface,
          onSurface: FinkoColors.grayDark,
          error: const Color(0xFFBA1A1A),
        ).copyWith(
          surface: _lightSurface,
          surfaceDim: _lightSurface,
          surfaceBright: _lightSurface,
          surfaceContainerLowest: _lightSurface,
          surfaceContainerLow: _lightSurface,
          surfaceContainer: _lightSurface,
          surfaceContainerHigh: _lightSurface,
          surfaceContainerHighest: _lightSurface,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _font,
      extensions: const [FinkoSemanticColors.light()],
      scaffoldBackgroundColor: FinkoColors.cloud,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: FinkoColors.grayDark,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: _font,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: FinkoColors.grayDark,
        ),
      ),

      // ── Text theme — brand spec:
      //   Titles/Headlines → w500 (Medium)
      //   Subtitles/Labels → w400 (Regular)
      //   Body/Paragraphs  → w400 (Regular)
      // ────────────────────────────────────────────────────────────────────────
      textTheme: const TextTheme(
        // Display
        displayLarge: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.grayDark,
          letterSpacing: -0.02,
        ),
        displayMedium: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.grayDark,
          letterSpacing: -0.02,
        ),
        displaySmall: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.grayDark,
          letterSpacing: -0.02,
        ),
        // Headlines → Medium (500)
        headlineLarge: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.grayDark,
          letterSpacing: -0.02,
        ),
        headlineMedium: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.grayDark,
          letterSpacing: -0.01,
        ),
        headlineSmall: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.grayDark,
        ),
        // Titles → Medium (500)
        titleLarge: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.grayDark,
        ),
        titleMedium: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.grayDark,
        ),
        titleSmall: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.grayDark,
        ),
        // Body → Regular (400)
        bodyLarge: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w400,
          color: FinkoColors.grayDark,
        ),
        bodyMedium: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w400,
          color: FinkoColors.gray,
        ),
        bodySmall: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w400,
          color: FinkoColors.gray,
        ),
        // Labels → Regular/Medium
        labelLarge: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.grayDark,
        ),
        labelMedium: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w400,
          color: FinkoColors.grayDark,
        ),
        labelSmall: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w400,
          color: FinkoColors.gray,
          letterSpacing: 0.06,
        ),
      ),

      // ── Card ────────────────────────────────────────────────────────────────
      cardTheme: const CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // ── Inputs ──────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintStyle: const TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w300,
          color: FinkoColors.gray,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FinkoColors.grayLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FinkoColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
        ),
      ),

      // ── Buttons ─────────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FinkoColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FinkoColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FinkoColors.primary,
          side: const BorderSide(color: FinkoColors.primary, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FinkoColors.primary,
          textStyle: const TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),

      // ── Navigation bar ──────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: FinkoColors.cloud,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),

      // ── Remaining (unchanged from original) ─────────────────────────────────
      dividerColor: FinkoColors.grayLight,
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: FinkoColors.primary,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FinkoColors.primary,
        linearTrackColor: FinkoColors.grayLight,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: _lightSurface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _lightSurface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: _lightSurface,
        surfaceTintColor: Colors.transparent,
      ),
      menuTheme: const MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(_lightSurface),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _lightSurface,
        side: const BorderSide(color: FinkoColors.grayLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: _lightSurface,
        surfaceTintColor: Colors.transparent,
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: _lightSurface,
      ),
    );
  }

  // ─── Dark theme ────────────────────────────────────────────────────────────
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: FinkoColors.primaryLight,
      primary: FinkoColors.primaryLight,
      secondary: FinkoColors.primary,
      tertiary: FinkoColors.grayLight,
      surface: FinkoColors.navy800,
      onSurface: FinkoColors.textOnDark,
      error: const Color(0xFFFFB4AB),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _font,
      extensions: const [FinkoSemanticColors.dark()],
      scaffoldBackgroundColor: FinkoColors.navy900,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      appBarTheme: const AppBarTheme(
        backgroundColor: FinkoColors.navy800,
        foregroundColor: FinkoColors.textOnDark,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: _font,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: FinkoColors.textOnDark,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.textOnDark,
          letterSpacing: -0.02,
        ),
        displayMedium: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.textOnDark,
          letterSpacing: -0.02,
        ),
        displaySmall: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.textOnDark,
          letterSpacing: -0.02,
        ),
        headlineLarge: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.textOnDark,
        ),
        headlineMedium: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.textOnDark,
        ),
        headlineSmall: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.textOnDark,
        ),
        titleLarge: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.textOnDark,
        ),
        titleMedium: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.textOnDark,
        ),
        titleSmall: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.textOnDark,
        ),
        bodyLarge: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w400,
          color: FinkoColors.textOnDark,
        ),
        bodyMedium: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w400,
          color: FinkoColors.grayLight,
        ),
        bodySmall: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w400,
          color: FinkoColors.grayLight,
        ),
        labelLarge: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          color: FinkoColors.textOnDark,
        ),
        labelMedium: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w400,
          color: FinkoColors.textOnDark,
        ),
        labelSmall: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w400,
          color: FinkoColors.grayLight,
          letterSpacing: 0.06,
        ),
      ),
      cardTheme: const CardThemeData(
        color: FinkoColors.navy800,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FinkoColors.navy700,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintStyle: const TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w300,
          color: FinkoColors.gray,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FinkoColors.grayDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: FinkoColors.primaryLight,
            width: 1.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FinkoColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FinkoColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FinkoColors.primaryLight,
          side: const BorderSide(color: FinkoColors.primaryLight, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FinkoColors.primaryLight,
          textStyle: const TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: FinkoColors.navy800,
        indicatorColor: FinkoColors.navy700,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
      dividerColor: FinkoColors.navy700,
      drawerTheme: const DrawerThemeData(
        backgroundColor: FinkoColors.navy800,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: FinkoColors.primaryLight,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FinkoColors.primaryLight,
        linearTrackColor: FinkoColors.navy700,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
      ),
      chipTheme: ChipThemeData(
        labelStyle: const TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

@immutable
class FinkoSemanticColors extends ThemeExtension<FinkoSemanticColors> {
  const FinkoSemanticColors({required this.income, required this.expense});

  const FinkoSemanticColors.light()
    : income = FinkoColors.income,
      expense = FinkoColors.expense;

  const FinkoSemanticColors.dark()
    : income = const Color(0xFF57D497),
      expense = const Color(0xFFFF8991);

  final Color income;
  final Color expense;

  @override
  FinkoSemanticColors copyWith({Color? income, Color? expense}) {
    return FinkoSemanticColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }

  @override
  FinkoSemanticColors lerp(
    covariant ThemeExtension<FinkoSemanticColors>? other,
    double t,
  ) {
    if (other is! FinkoSemanticColors) return this;
    return FinkoSemanticColors(
      income: Color.lerp(income, other.income, t) ?? income,
      expense: Color.lerp(expense, other.expense, t) ?? expense,
    );
  }
}
