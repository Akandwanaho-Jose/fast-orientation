import 'package:flutter/material.dart';

// Edit this file first when changing FAST branding.
@immutable
class FastBrand {
  const FastBrand._();

  static const String appTitle = 'MUST-FAST CONNECT';
  static const String shortName = 'FAST Connect';
  static const String facultyName = 'Faculty of Applied Sciences and Technology';

  static const Color primary = Color(0xFF003087);
  static const Color primaryStrong = Color(0xFF0B58B4);
  static const Color secondary = Color(0xFF1D8557);
  static const Color accent = Color(0xFFFFC107);

  static const Color shellBackground = Color(0xFFF5F7FB);
  static const Color surface = Colors.white;
  static const Color softSurface = Color(0xFFF8FAFD);
  static const Color border = Color(0xFFE2E8F2);
  static const Color logoSurface = Color(0xFFF0F5FF);
  static const Color headingText = Color(0xFF152033);
  static const Color mutedText = Color(0xFF667085);
  static const Color supportText = Color(0xFF475467);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFB3261E);
  static const Color success = Color(0xFF166534);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primary, primaryStrong, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData theme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      tertiary: accent,
      surface: surface,
      onSurface: headingText,
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: shellBackground,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: surface,
        surfaceTintColor: surface,
        foregroundColor: headingText,
      ),
      cardColor: surface,
      dividerColor: border,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: headingText,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          color: headingText,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: headingText,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: supportText,
          fontSize: 15,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: supportText,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? primary : mutedText,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary,
        secondarySelectedColor: primary,
        side: BorderSide(color: primary.withValues(alpha: 0.18)),
        labelStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: mutedText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withValues(alpha: 0.18)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static BoxDecoration heroDecoration({double radius = 28}) {
    return BoxDecoration(
      gradient: heroGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.24),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }

  static BoxDecoration surfaceDecoration({double radius = 28}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [softShadow],
    );
  }

  static BoxDecoration mutedSurfaceDecoration({double radius = 22}) {
    return BoxDecoration(
      color: softSurface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
    );
  }

  static BoxDecoration tintDecoration(
    Color color, {
    double radius = 16,
    double opacity = 0.10,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static BoxDecoration glassPillDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
    );
  }

  static BoxDecoration solidPillDecoration(
    Color color, {
    double opacity = 0.10,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(999),
    );
  }

  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 18,
    offset: Offset(0, 10),
  );
}
