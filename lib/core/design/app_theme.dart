import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const accent = Color(0xFF007F86);
  static const spacing = 24.0;
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
