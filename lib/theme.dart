import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The five score components are the "spectrum" the prism splits a student into.
/// These are the ONLY accent colours in the app, and each always means the same thing.
class PrismColors {
  static const fit = Color(0xFF7B61F0); // violet: how well the career fits
  static const market = Color(0xFF14B3A3); // teal: job demand
  static const feasibility = Color(0xFFE5A50F); // amber: affordability
  static const roi = Color(0xFF3D7BF5); // blue: financial return
  static const penalty = Color(0xFFE0507A); // rose: family gap
  static const spectrum = [fit, market, feasibility, roi, penalty];

  // Dark (default): deep navy, glass surfaces.
  static const bgDark = Color(0xFF0B1020);
  static const surfaceDark = Color(0xFF121A30);
  static const surfaceDarkHigh = Color(0xFF18223D);
  static const inkDark = Color(0xFFE8EBF5);

  // Light.
  static const bgLight = Color(0xFFF2F4FA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const inkLight = Color(0xFF151B33);

  // Kept for older call sites.
  static const surface = surfaceDark;
}

extension Fade on Color {
  /// Version-safe opacity helper (avoids deprecated withOpacity).
  Color fade(double opacity) => withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
}

/// One spacing rhythm for the whole app.
class Spacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

/// Radius follows hierarchy: primary surfaces are rounder than nested ones.
class Radii {
  static const nested = 10.0;
  static const primary = 16.0;
  static const pill = 999.0;
}

/// Content width caps.
class Layout {
  static const maxContent = 1200.0;
  static const maxReading = 760.0;
  static const railBreakpoint = 1000.0;
}

/// Headings and numbers use Space Grotesk; body text uses Manrope.
TextStyle displayFont(TextStyle base) => GoogleFonts.spaceGrotesk(textStyle: base);

/// Tabular figures so animated numbers don't jitter in width.
const tabularFigures = [FontFeature.tabularFigures()];

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final ink = dark ? PrismColors.inkDark : PrismColors.inkLight;
  final surface = dark ? PrismColors.surfaceDark : PrismColors.surfaceLight;
  final bg = dark ? PrismColors.bgDark : PrismColors.bgLight;

  final scheme = ColorScheme.fromSeed(seedColor: PrismColors.fit, brightness: brightness).copyWith(
    primary: PrismColors.fit,
    onPrimary: Colors.white,
    surface: surface,
    onSurface: ink,
    surfaceContainerHighest: dark ? PrismColors.surfaceDarkHigh : const Color(0xFFE8EBF4),
    outline: ink.fade(0.18),
    outlineVariant: ink.fade(0.08),
  );

  // Body styles (Manrope).
  final body = GoogleFonts.manropeTextTheme(TextTheme(
    bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.55, color: ink),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: ink.fade(0.86)),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.45, color: ink.fade(0.62)),
    labelLarge: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.2, color: ink),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.2, color: ink.fade(0.72)),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2, color: ink.fade(0.62)),
    titleMedium: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.35, color: ink),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.35, color: ink),
  ));

  // Heading styles (Space Grotesk). Scale: display 48/40, h1 32, h2 24, h3 18.
  TextStyle h(double size, FontWeight w, double height, double tracking) => displayFont(
      TextStyle(fontSize: size, fontWeight: w, height: height, letterSpacing: tracking, color: ink));
  final textTheme = body.copyWith(
    displayLarge: h(48, FontWeight.w700, 1.05, -1.2),
    displayMedium: h(40, FontWeight.w700, 1.08, -0.9),
    displaySmall: h(32, FontWeight.w700, 1.12, -0.6),
    headlineLarge: h(32, FontWeight.w700, 1.12, -0.6),
    headlineMedium: h(28, FontWeight.w700, 1.15, -0.4),
    headlineSmall: h(24, FontWeight.w700, 1.2, -0.3),
    titleLarge: h(18, FontWeight.w700, 1.3, -0.1),
  );

  final focusRing = PrismColors.fit.fade(dark ? 0.45 : 0.3);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    focusColor: focusRing,
    hoverColor: ink.fade(0.05),
    splashFactory: InkSparkle.splashFactory,
    dividerTheme: DividerThemeData(color: ink.fade(0.08), thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleLarge,
      foregroundColor: ink,
    ),
    chipTheme: ChipThemeData(
      side: BorderSide(color: ink.fade(0.12)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.pill)),
      labelStyle: textTheme.labelMedium?.copyWith(color: ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: PrismColors.fit,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl, vertical: Spacing.md),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.nested)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl, vertical: Spacing.md),
        side: BorderSide(color: ink.fade(0.22)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.nested)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: dark ? const Color(0xFFB3A5FF) : PrismColors.fit, textStyle: textTheme.labelLarge),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? PrismColors.surfaceDarkHigh : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.nested), borderSide: BorderSide(color: ink.fade(0.14))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.nested), borderSide: BorderSide(color: ink.fade(0.14))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.nested), borderSide: const BorderSide(color: PrismColors.fit, width: 2)),
    ),
    sliderTheme: SliderThemeData(inactiveTrackColor: ink.fade(0.12)),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: PrismColors.fit.fade(0.18),
      selectedIconTheme: const IconThemeData(color: PrismColors.fit),
      unselectedIconTheme: IconThemeData(color: ink.fade(0.6)),
      selectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: ink, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: textTheme.labelMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface, surfaceTintColor: Colors.transparent),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: dark ? PrismColors.surfaceDarkHigh : ink),
  );
}
