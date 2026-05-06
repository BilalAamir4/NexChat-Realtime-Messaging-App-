import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// NexChat Design Tokens
// ─────────────────────────────────────────────

class NexColors {
  NexColors._();

  // Brand (shared across both themes)
  static const indigo = Color(0xFF4F46E5);
  static const violet = Color(0xFF7C3AED);
  static const indigo100 = Color(0xFFE0E7FF);
  static const indigo200 = Color(0xFFC7D2FE);

  // Dark brand variants (adjusted for dark bg contrast)
  static const indigoDark100 = Color(0xFF1E1B4B);
  static const indigoDark200 = Color(0xFF2D2A6E);

  // ── Light Theme ──────────────────────────
  static const lightPageDark = Color(0xFFE8EEFF);
  static const lightPageLight = Color(0xFFF0F4FF);
  static const lightCardSurface = Color(0xFFF7F8FF);
  static const lightSlateDark = Color(0xFF1E1B4B);
  static const lightSlateMid = Color(0xFF475569);
  static const lightSlateMuted = Color(0xFF94A3B8);

  // ── Dark Theme ───────────────────────────
  static const darkPage = Color(0xFF0A0A14);
  static const darkPageAlt = Color(0xFF0D0D1A);
  static const darkCard = Color(0xFF12121F);
  static const darkSurface = Color(0xFF1A1A2E);
  static const darkBorder = Color(0xFF2A2A4A);
  static const darkTextPrimary = Color(0xFFE8E8F0);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkTextMuted = Color(0xFF4A5568);
  static const darkReceivedBg = Color(0xFF1A1830);
  static const darkReceivedBorder = Color(0xFF2D2A6E);
}

// ─────────────────────────────────────────────
// NexChat ThemeData Factory
// ─────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Resolved semantic colors
    final colorScheme = isDark ? _darkColorScheme : _lightColorScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: 'SF Pro Display',

      // ── Scaffold ──────────────────────────
      scaffoldBackgroundColor:
      isDark ? NexColors.darkPage : NexColors.lightPageDark,

      // ── AppBar ────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:
        isDark ? NexColors.darkCard : NexColors.lightPageLight,
        foregroundColor:
        isDark ? NexColors.darkTextPrimary : NexColors.lightSlateDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: isDark ? NexColors.darkTextPrimary : NexColors.lightSlateDark,
        ),
        shape: Border(
          bottom: BorderSide(
            color: isDark ? NexColors.darkBorder : NexColors.indigo200,
            width: 1,
          ),
        ),
      ),

      // ── Card ──────────────────────────────
      cardTheme: CardThemeData(
        color:
        isDark ? NexColors.darkCard : NexColors.lightCardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? NexColors.darkBorder : NexColors.indigo200,
            width: 1,
          ),
        ),
        shadowColor: NexColors.indigo.withOpacity(isDark ? 0.3 : 0.12),
      ),

      // ── Input Decoration ──────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? NexColors.darkSurface : NexColors.lightCardSurface,
        hintStyle: TextStyle(
          color: isDark ? NexColors.darkTextMuted : NexColors.lightSlateMuted,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? NexColors.darkBorder : NexColors.indigo200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? NexColors.darkBorder : NexColors.indigo200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NexColors.indigo, width: 1.5),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // ── Bottom Navigation ─────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
        isDark ? NexColors.darkCard : NexColors.lightCardSurface,
        indicatorColor: NexColors.indigo.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active
                ? NexColors.indigo
                : (isDark
                ? NexColors.darkTextMuted
                : NexColors.lightSlateMuted),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(
            color: active
                ? NexColors.indigo
                : (isDark
                ? NexColors.darkTextMuted
                : NexColors.lightSlateMuted),
            size: 22,
          );
        }),
      ),

      // ── Divider ───────────────────────────
      dividerTheme: DividerThemeData(
        color: isDark ? NexColors.darkBorder : NexColors.indigo200,
        thickness: 1,
        space: 1,
      ),

      // ── Icon ──────────────────────────────
      iconTheme: IconThemeData(
        color: isDark ? NexColors.darkTextSecondary : NexColors.lightSlateMid,
        size: 22,
      ),

      // ── Text ──────────────────────────────
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: isDark ? NexColors.darkTextPrimary : NexColors.lightSlateDark,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDark ? NexColors.darkTextPrimary : NexColors.lightSlateDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? NexColors.darkTextPrimary : NexColors.lightSlateDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: isDark ? NexColors.darkTextPrimary : NexColors.lightSlateDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: isDark
              ? NexColors.darkTextSecondary
              : NexColors.lightSlateMid,
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color:
          isDark ? NexColors.darkTextMuted : NexColors.lightSlateMuted,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color:
          isDark ? NexColors.darkTextSecondary : NexColors.lightSlateMid,
        ),
      ),

      // ── Drawer ────────────────────────────
      drawerTheme: DrawerThemeData(
        backgroundColor:
        isDark ? NexColors.darkCard : NexColors.lightCardSurface,
        scrimColor: Colors.black54,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),

      // ── Bottom Sheet ──────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
        isDark ? NexColors.darkCard : NexColors.lightCardSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 0,
      ),

      // ── Switch ────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? Colors.white
            : (isDark ? NexColors.darkTextMuted : NexColors.lightSlateMuted)),
        trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? NexColors.indigo
            : (isDark ? NexColors.darkBorder : NexColors.indigo200)),
      ),

      // ── ListTile ──────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor:
        isDark ? NexColors.darkTextSecondary : NexColors.lightSlateMid,
        textColor:
        isDark ? NexColors.darkTextPrimary : NexColors.lightSlateDark,
      ),
    );
  }

  // ── Color Schemes ─────────────────────────

  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: NexColors.indigo,
    onPrimary: Colors.white,
    primaryContainer: NexColors.indigo100,
    onPrimaryContainer: NexColors.lightSlateDark,
    secondary: NexColors.violet,
    onSecondary: Colors.white,
    secondaryContainer: NexColors.indigo200,
    onSecondaryContainer: NexColors.lightSlateDark,
    surface: NexColors.lightCardSurface,
    onSurface: NexColors.lightSlateDark,
    onSurfaceVariant: NexColors.lightSlateMid,
    outline: NexColors.indigo200,
    outlineVariant: NexColors.indigo100,
    error: Color(0xFFDC2626),
    onError: Colors.white,
    errorContainer: Color(0xFFFFE4E4),
    onErrorContainer: Color(0xFF7F1D1D),
    scrim: Colors.black54,
    inverseSurface: NexColors.lightSlateDark,
    onInverseSurface: Colors.white,
    inversePrimary: NexColors.indigo200,
  );

  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: NexColors.indigo,
    onPrimary: Colors.white,
    primaryContainer: NexColors.indigoDark100,
    onPrimaryContainer: NexColors.darkTextPrimary,
    secondary: NexColors.violet,
    onSecondary: Colors.white,
    secondaryContainer: NexColors.indigoDark200,
    onSecondaryContainer: NexColors.darkTextPrimary,
    surface: NexColors.darkCard,
    onSurface: NexColors.darkTextPrimary,
    onSurfaceVariant: NexColors.darkTextSecondary,
    outline: NexColors.darkBorder,
    outlineVariant: NexColors.darkSurface,
    error: Color(0xFFF87171),
    onError: Colors.white,
    errorContainer: Color(0xFF3B0000),
    onErrorContainer: Color(0xFFFCA5A5),
    scrim: Colors.black87,
    inverseSurface: NexColors.darkTextPrimary,
    onInverseSurface: NexColors.darkCard,
    inversePrimary: NexColors.indigo200,
  );
}

// ─────────────────────────────────────────────
// Convenience extensions for BuildContext
// ─────────────────────────────────────────────

extension NexThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;

  // Page background gradient
  Gradient get pageGradient => isDark
      ? const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [NexColors.darkPage, NexColors.darkPageAlt],
  )
      : const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [NexColors.lightPageDark, NexColors.lightPageLight],
  );

  // Sent bubble gradient
  Gradient get sentBubbleGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [NexColors.indigo, NexColors.violet],
  );

  // Received bubble style
  Color get receivedBubbleBg =>
      isDark ? NexColors.darkReceivedBg : NexColors.indigo100;
  Color get receivedBubbleBorder =>
      isDark ? NexColors.darkReceivedBorder : NexColors.indigo200;

  // Card surface
  Color get cardSurface =>
      isDark ? NexColors.darkCard : NexColors.lightCardSurface;
  Color get cardBorder =>
      isDark ? NexColors.darkBorder : NexColors.indigo200;

  // Text colors
  Color get textPrimary =>
      isDark ? NexColors.darkTextPrimary : NexColors.lightSlateDark;
  Color get textSecondary =>
      isDark ? NexColors.darkTextSecondary : NexColors.lightSlateMid;
  Color get textMuted =>
      isDark ? NexColors.darkTextMuted : NexColors.lightSlateMuted;
}