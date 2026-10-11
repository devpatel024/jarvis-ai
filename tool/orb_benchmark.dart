// Manual native benchmark: flutter run -d linux --profile -t tool/orb_benchmark.dart
// Runs the actual demo chat for 20 seconds; reports frame timings, then exits.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/design/app_theme.dart';
import 'package:jarvis/features/chat/presentation/chat_controller.dart';
import 'package:jarvis/features/chat/presentation/chat_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  final captureKey = GlobalKey();
  const screenshotPath = String.fromEnvironment('JARVIS_BENCHMARK_SCREENSHOT');
  final clock = Stopwatch()..start();
  final build = <int>[];
  final raster = <int>[];
  final span = <int>[];
  void record(List<FrameTiming> frames) {
    if (clock.elapsed < const Duration(seconds: 2)) return;
    for (final frame in frames) {
      build.add(frame.buildDuration.inMicroseconds);
      raster.add(frame.rasterDuration.inMicroseconds);
      span.add(frame.totalSpan.inMicroseconds);
    }
  }

  SchedulerBinding.instance.addTimingsCallback(record);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.build(
          const bool.fromEnvironment('JARVIS_BENCHMARK_LIGHT')
              ? Brightness.light
              : Brightness.dark,
        ),
        home: RepaintBoundary(
          key: captureKey,
          child: const Scaffold(body: SafeArea(child: ChatScreen())),
        ),
      ),
    ),
  );
  Timer(
    const Duration(seconds: 3),
    () => container.read(chatProvider.notifier).send('નમસ્તે'),
  );
  Timer(
    const Duration(seconds: 10),
    () => container.read(chatProvider.notifier).send('Hello'),
  );
  if (screenshotPath.isNotEmpty) {
    Timer(const Duration(seconds: 8), () async {
      final boundary =
          captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes != null) {
        await File(screenshotPath).writeAsBytes(bytes.buffer.asUint8List());
      }
      image.dispose();
    });
  }
  Timer(const Duration(seconds: 20), () {
    Map<String, Object?> stats(List<int> values) {
      if (values.isEmpty) return {'count': 0};
      final sorted = [...values]..sort();
      return {
        'count': values.length,
        'mean_ms': values.reduce((a, b) => a + b) / values.length / 1000,
        'p95_ms': sorted[(values.length * .95).ceil() - 1] / 1000,
        'max_ms': sorted.last / 1000,
        'over_16_67_ms': values.where((v) => v > 16667).length,
      };
    }

    final result = {
      'mode': 'profile',
      'duration_s': 20,
      'warmup_s': 2,
      'build': stats(build),
      'raster': stats(raster),
      'total_span': stats(span),
      'note':
          'Actual demo chat; system/compositor load affects results. No 60fps guarantee.',
    };
    // Benchmark output contains timings only, never user conversation data.
    stdout.writeln('JARVIS_FRAME_REPORT ${jsonEncode(result)}');
    SchedulerBinding.instance.removeTimingsCallback(record);
    container.dispose();
    exit(build.isEmpty ? 1 : 0);
  });
}
