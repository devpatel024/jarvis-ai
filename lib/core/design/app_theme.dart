import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const accent = Color(0xFF007F86);
  static const spacing = 24.0;
  static const smallSpacing = 8.0;
  static const messagePadding = 16.0;
  static const orbSize = 144.0;
  static const orbCycle = Duration(seconds: 4);
  static const activeOrbCycle = Duration(milliseconds: 1800);
  static const errorFlicker = Duration(milliseconds: 350);
  static ThemeData build(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF0C171D)
          : const Color(0xFFF3F7F8),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
