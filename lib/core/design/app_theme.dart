import 'package:flutter/material.dart';

enum AppPalette { aurora, neonCyber, sunset, emerald, monoGlow }

extension PaletteName on AppPalette {
  String get label => switch (this) {
    AppPalette.aurora => 'Aurora',
    AppPalette.neonCyber => 'Neon Cyber',
    AppPalette.sunset => 'Sunset',
    AppPalette.emerald => 'Emerald',
    AppPalette.monoGlow => 'Mono Glow',
  };
}

@immutable
class JarvisColors extends ThemeExtension<JarvisColors> {
  const JarvisColors(
    this.background,
    this.surface,
    this.ink,
    this.muted,
    this.accents,
    this.userStops,
    this.userInk,
  );
  final Color background, surface, ink, muted, userInk;
  final List<Color> accents, userStops;
  bool get dark => background.computeLuminance() < .1;
  LinearGradient get accentGradient => LinearGradient(colors: accents);
  LinearGradient get bubbleGradient => LinearGradient(colors: userStops);
  LinearGradient get glassGradient => LinearGradient(
    colors: [
      Color.alphaBlend(
        accents.first.withValues(alpha: dark ? .10 : .06),
        surface,
      ),
      Color.alphaBlend(
        accents.last.withValues(alpha: dark ? .08 : .04),
        surface,
      ),
    ],
  );
  List<Color> stateColors(String state) => switch (state) {
    'listening' => AppTheme.listening,
    'thinking' => AppTheme.thinking,
    'speaking' => AppTheme.speaking,
    'error' => AppTheme.error,
    _ => [accents.first, accents[1]],
  };
  @override
  JarvisColors copyWith() => this;
  @override
  JarvisColors lerp(covariant JarvisColors? other, double t) =>
      t < .5 ? this : other ?? this;
  static JarvisColors of(BuildContext context) =>
      Theme.of(context).extension<JarvisColors>()!;
}

abstract final class AppTheme {
  static const mobileStatusHeight = 36.0;
  static const captionSize = 11.0, helperSize = 12.0, avatarSize = 36.0;
  static const swatchWidth = 100.0, swatchHeight = 24.0, brandTracking = 3.0;
  static const bubbleWidth = .90,
      statusTint = .12,
      chipTint = .15,
      focusWidth = 2.0;
  static const spacing = 24.0, smallSpacing = 8.0, messagePadding = 16.0;
  static const radius = 24.0, controlRadius = 16.0, pillRadius = 40.0;
  static const orbSize = 144.0,
      heroOrbSize = 260.0,
      phoneOrbSize = 190.0,
      compactOrbSize = 62.0;
  static const railWidth = 88.0, sidebarWidth = 224.0, readingWidth = 780.0;
  static const desktopBreakpoint = 1100.0, railBreakpoint = 700.0;
  static const hairline = 1.0, glowAlpha = .14, elevation = 0.0;
  static const orbCycle = Duration(seconds: 5);
  static const activeOrbCycle = Duration(milliseconds: 1800);
  static const errorFlicker = Duration(milliseconds: 450);
  static const messageEntry = Duration(milliseconds: 360);
  static const pageDrift = .025;
  static const transition = Duration(milliseconds: 220);
  static const auroraCycle = Duration(seconds: 45);
  static const amber = Color(0xFFFFC56A);
  static const listening = [Color(0xFF43F1AD), Color(0xFF42DCFF)];
  static const thinking = [Color(0xFFB895FF), Color(0xFFFF79CA)];
  static const speaking = [Color(0xFF61ADFF), Color(0xFF57E5FF), amber];
  static const error = [Color(0xFFFF777F), Color(0xFFFFAF70)];
  static const transparent = Colors.transparent;
  static const white = Colors.white;
  static const black = Colors.black;

  static JarvisColors colors(AppPalette palette, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final accents = switch (palette) {
      AppPalette.aurora => const [
        Color(0xFF67E8F9),
        Color(0xFFAD94FF),
        Color(0xFFFF88D3),
      ],
      AppPalette.neonCyber => const [
        Color(0xFF70B7FF),
        Color(0xFFD2F66E),
        Color(0xFFFF83C6),
      ],
      AppPalette.sunset => const [
        Color(0xFFFFBD7A),
        Color(0xFFFF9FA4),
        Color(0xFFBAA0FF),
      ],
      AppPalette.emerald => const [
        Color(0xFF72E5B3),
        Color(0xFF64D9DE),
        Color(0xFFFFD279),
      ],
      AppPalette.monoGlow => const [
        Color(0xFF84E8F6),
        Color(0xFFC9CDDF),
        Color(0xFFEDF0F8),
      ],
    };
    final backgrounds = switch (palette) {
      AppPalette.aurora => const [Color(0xFF0A0E27), Color(0xFFF3F2FC)],
      AppPalette.neonCyber => const [Color(0xFF071323), Color(0xFFF0F5FC)],
      AppPalette.sunset => const [Color(0xFF211123), Color(0xFFFFF4EF)],
      AppPalette.emerald => const [Color(0xFF071E20), Color(0xFFEDF7F1)],
      AppPalette.monoGlow => const [Color(0xFF121522), Color(0xFFF3F5F7)],
    };
    final userStops = dark
        ? accents.take(2).toList()
        : switch (palette) {
            AppPalette.aurora => const [Color(0xFF163D75), Color(0xFF573797)],
            AppPalette.neonCyber => const [
              Color(0xFF173B81),
              Color(0xFF344F40),
            ],
            AppPalette.sunset => const [Color(0xFF913B13), Color(0xFF733368)],
            AppPalette.emerald => const [Color(0xFF125342), Color(0xFF154D64)],
            AppPalette.monoGlow => const [Color(0xFF253E4B), Color(0xFF383C50)],
          };
    return JarvisColors(
      backgrounds[dark ? 0 : 1],
      dark ? const Color(0xFF171D35) : const Color(0xFFFFFFFF),
      dark ? const Color(0xFFF4F4FC) : const Color(0xFF171D35),
      dark ? const Color(0xFFC0C6DC) : const Color(0xFF4E566F),
      accents,
      userStops,
      dark ? const Color(0xFF102032) : const Color(0xFFFFFFFF),
    );
  }

  static ThemeData build(
    Brightness brightness, [
    AppPalette palette = AppPalette.aurora,
  ]) {
    final c = colors(palette, brightness);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: c.userStops.first,
          brightness: brightness,
        ).copyWith(
          surface: c.surface,
          onSurface: c.ink,
          onSurfaceVariant: c.muted,
          primary: c.dark ? c.accents.first : c.userStops.first,
          onPrimary: c.dark ? c.userInk : white,
          outline: c.dark ? c.accents[1] : c.userStops[1],
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [c],
      fontFamily: 'SpaceGrotesk',
      fontFamilyFallback: const ['NotoSansGujarati'],
      scaffoldBackgroundColor: transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: transparent,
        foregroundColor: c.ink,
        elevation: elevation,
      ),
      cardTheme: const CardThemeData(elevation: elevation),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(backgroundColor: c.surface),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: transparent,
      ),
    );
  }
}
