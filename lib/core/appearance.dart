import 'package:flutter/material.dart';

/// Five genuinely different palettes; every dark variant has a #000000 canvas.
class KaryaPalette extends ThemeExtension<KaryaPalette> {
  const KaryaPalette({
    required this.canvas,
    required this.paper,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.ink,
    required this.outline,
    required this.muted,
  });
  final Color canvas, paper, primary, secondary, tertiary, ink, outline, muted;
  @override
  KaryaPalette copyWith({
    Color? canvas,
    Color? paper,
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? ink,
    Color? outline,
    Color? muted,
  }) => KaryaPalette(
    canvas: canvas ?? this.canvas,
    paper: paper ?? this.paper,
    primary: primary ?? this.primary,
    secondary: secondary ?? this.secondary,
    tertiary: tertiary ?? this.tertiary,
    ink: ink ?? this.ink,
    outline: outline ?? this.outline,
    muted: muted ?? this.muted,
  );
  @override
  KaryaPalette lerp(ThemeExtension<KaryaPalette>? other, double t) {
    if (other is! KaryaPalette) return this;
    return KaryaPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}

const themeNames = [
  'Classic',
  'Soft Pop',
  'Monochrome',
  'Forest',
  'Lavender Haze',
];
const _black = Color(0xFF000000),
    _white = Color(0xFFFFFCF7),
    _ink = Color(0xFF111111);
KaryaPalette paletteFor(int index, bool dark) {
  final i = index.clamp(0, 4);
  if (dark) {
    // Pure black is intentionally shared by all dark themes.
    return switch (i) {
      1 => const KaryaPalette(
        canvas: _black,
        paper: Color(0xFF181519),
        primary: Color(0xFFDDA3BF),
        secondary: Color(0xFF9BCCAD),
        tertiary: Color(0xFFC6B2E7),
        ink: Colors.white,
        outline: Color(0xFFECD9E6),
        muted: Color(0xFFB9ADBB),
      ),
      2 => const KaryaPalette(
        canvas: _black,
        paper: Color(0xFF151515),
        primary: Color(0xFFEAEAEA),
        secondary: Color(0xFF9F9F9F),
        tertiary: Color(0xFFC9C9C9),
        ink: Colors.white,
        outline: Color(0xFFEAEAEA),
        muted: Color(0xFFB6B6B6),
      ),
      3 => const KaryaPalette(
        canvas: _black,
        paper: Color(0xFF102019),
        primary: Color(0xFF90C5A1),
        secondary: Color(0xFFD6B578),
        tertiary: Color(0xFF9BAE72),
        ink: Colors.white,
        outline: Color(0xFFC1D6C5),
        muted: Color(0xFFABBFAF),
      ),
      4 => const KaryaPalette(
        canvas: _black,
        paper: Color(0xFF1E1728),
        primary: Color(0xFFC2A6FF),
        secondary: Color(0xFFFFB4D3),
        tertiary: Color(0xFFA5D6F4),
        ink: Colors.white,
        outline: Color(0xFFE2D1FF),
        muted: Color(0xFFC4B8D6),
      ),
      _ => const KaryaPalette(
        canvas: _black,
        paper: Color(0xFF171717),
        primary: Color(0xFFFFD51D),
        secondary: Color(0xFFFF4C89),
        tertiary: Color(0xFFA6E529),
        ink: Colors.white,
        outline: Color(0xFFF4F1E7),
        muted: Color(0xFFBDBDBD),
      ),
    };
  }
  return switch (i) {
    1 => const KaryaPalette(
      canvas: Color(0xFFF7EDD9),
      paper: Color(0xFFFFFDF9),
      primary: Color(0xFFE7ABC8),
      secondary: Color(0xFFBBDCB8),
      tertiary: Color(0xFFBEAFF1),
      ink: _ink,
      outline: _ink,
      muted: Color(0xFF645D5D),
    ),
    2 => const KaryaPalette(
      canvas: Color(0xFFF3F3F0),
      paper: Colors.white,
      primary: Color(0xFFCECECE),
      secondary: Color(0xFFEAEAEA),
      tertiary: Color(0xFFAEAEAE),
      ink: _ink,
      outline: _ink,
      muted: Color(0xFF5D5D5D),
    ),
    3 => const KaryaPalette(
      canvas: Color(0xFFE8ECD9),
      paper: Color(0xFFF9F7EA),
      primary: Color(0xFF86B68B),
      secondary: Color(0xFFD5B683),
      tertiary: Color(0xFFA5C2A5),
      ink: _ink,
      outline: _ink,
      muted: Color(0xFF4E5F4E),
    ),
    4 => const KaryaPalette(
      canvas: Color(0xFFF0E9FC),
      paper: Color(0xFFFFFCFE),
      primary: Color(0xFFBA9AFF),
      secondary: Color(0xFFFFB3D1),
      tertiary: Color(0xFFA2D8F0),
      ink: _ink,
      outline: _ink,
      muted: Color(0xFF655A73),
    ),
    _ => const KaryaPalette(
      canvas: Color(0xFFFFD51D),
      paper: _white,
      primary: Color(0xFFFF4C89),
      secondary: Color(0xFFA6E529),
      tertiary: Color(0xFF9573F5),
      ink: _ink,
      outline: _ink,
      muted: Color(0xFF504A35),
    ),
  };
}

KaryaPalette look(BuildContext context) =>
    Theme.of(context).extension<KaryaPalette>() ??
    paletteFor(0, Theme.of(context).brightness == Brightness.dark);

ThemeData neoTheme(bool dark, int personality) {
  final c = paletteFor(personality, dark);
  final outline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c.outline, width: 2),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: c.canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: dark ? c.primary : c.ink,
      onPrimary: dark ? Colors.black : Colors.white,
      surface: c.paper,
      onSurface: c.ink,
      outline: c.outline,
    ),
    extensions: [c],
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: c.ink,
        letterSpacing: -1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        color: c.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: c.ink,
      ),
      bodyMedium: TextStyle(color: c.ink),
      bodyLarge: TextStyle(color: c.ink),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.canvas,
      foregroundColor: c.ink,
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.paper,
      border: outline,
      enabledBorder: outline,
      focusedBorder: outline.copyWith(
        borderSide: BorderSide(color: c.primary, width: 3),
      ),
      contentPadding: const EdgeInsets.all(15),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? const Color(0xFF292929) : _ink,
      contentTextStyle: const TextStyle(color: Colors.white),
    ),
    splashColor: c.primary.withValues(alpha: 0.18),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeUpwardsPageTransitionsBuilder()},
    ),
  );
}
