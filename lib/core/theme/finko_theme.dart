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
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: FinkoColors.primary,
      primary: FinkoColors.primary,
      secondary: FinkoColors.primaryLight,
      tertiary: FinkoColors.gray,
      surface: Colors.white,
      onSurface: FinkoColors.grayDark,
      error: const Color(0xFFBA1A1A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: const [FinkoSemanticColors.light()],
      scaffoldBackgroundColor: FinkoColors.cloud,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: FinkoColors.grayDark,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerColor: FinkoColors.grayLight,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: FinkoColors.grayDark,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: FinkoColors.grayDark,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: FinkoColors.grayDark),
        bodyMedium: TextStyle(color: FinkoColors.gray),
        labelLarge: TextStyle(
          color: FinkoColors.grayDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FinkoColors.grayLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FinkoColors.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: FinkoColors.cloud,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
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
    );
  }

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
      extensions: const [FinkoSemanticColors.dark()],
      scaffoldBackgroundColor: FinkoColors.navy900,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      appBarTheme: const AppBarTheme(
        backgroundColor: FinkoColors.navy800,
        foregroundColor: FinkoColors.textOnDark,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: FinkoColors.navy800,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerColor: FinkoColors.navy700,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: FinkoColors.textOnDark,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: FinkoColors.textOnDark,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: FinkoColors.textOnDark),
        bodyMedium: TextStyle(color: FinkoColors.grayLight),
        labelLarge: TextStyle(
          color: FinkoColors.textOnDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FinkoColors.navy700,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
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
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: FinkoColors.navy800,
        indicatorColor: FinkoColors.navy700,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
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
