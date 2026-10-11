import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design/app_theme.dart';
import '../core/storage/local_store.dart';
import '../core/developer/performance_settings.dart';
import '../features/shell/presentation/assistant_shell.dart';

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() =>
      savedEnum(ref, 'theme', ThemeMode.values) ?? ThemeMode.dark;
  void select(ThemeMode mode) {
    state = mode;
    persistSetting(ref, 'theme', mode.name);
  }
}

final themeProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);

class PaletteController extends Notifier<AppPalette> {
  @override
  AppPalette build() =>
      savedEnum(ref, 'palette', AppPalette.values) ?? AppPalette.aurora;
  void select(AppPalette palette) {
    state = palette;
    persistSetting(ref, 'palette', palette.name);
  }
}

final paletteProvider = NotifierProvider<PaletteController, AppPalette>(
  PaletteController.new,
);

class JarvisApp extends ConsumerWidget {
  const JarvisApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'JARVIS',
    debugShowCheckedModeBanner: false,
    showPerformanceOverlay: ref.watch(performanceOverlayProvider),
    theme: AppTheme.build(Brightness.light, ref.watch(paletteProvider)),
    darkTheme: AppTheme.build(Brightness.dark, ref.watch(paletteProvider)),
    themeMode: ref.watch(themeProvider),
    home: const AssistantShell(),
  );
}
