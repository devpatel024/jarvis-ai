// Actual application, forced quality tiers, no overlay/screenshots in timed run.
// flutter run -d linux --profile --no-pub -t tool/slice_a_benchmark.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/app/jarvis_app.dart';
import 'package:jarvis/core/developer/performance_settings.dart';
import 'package:jarvis/features/chat/presentation/chat_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  final frames = {for (final tier in OrbTier.values) tier: <FrameTiming>[]};
  final clock = Stopwatch()..start();
  OrbTier current = OrbTier.ultra;
  var warmup = true;
  void record(List<FrameTiming> samples) {
    if (!warmup) frames[current]!.addAll(samples);
  }

  SchedulerBinding.instance.addTimingsCallback(record);
  container.read(qualityProvider.notifier).select(current);
  runApp(
    UncontrolledProviderScope(container: container, child: const JarvisApp()),
  );
  unawaited(() async {
    for (final tier in OrbTier.values) {
      current = tier;
      warmup = true;
      container.read(qualityProvider.notifier).select(tier);
      container.read(chatProvider.notifier).newChat();
      await Future<void>.delayed(const Duration(seconds: 4));
      warmup = false;
      unawaited(container.read(chatProvider.notifier).send('નમસ્તે!'));
      await Future<void>.delayed(const Duration(seconds: 5));
      unawaited(
        container.read(chatProvider.notifier).send('Show a code example'),
      );
      await Future<void>.delayed(const Duration(seconds: 7));
      warmup = true;
    }
    Map<String, Object?> stats(List<int> values) {
      if (values.isEmpty) return {'count': 0};
      final sorted = [...values]..sort();
      return {
        'count': values.length,
        'mean_ms': values.reduce((a, b) => a + b) / values.length / 1000,
        'p95_ms': sorted[(values.length * .95).ceil() - 1] / 1000,
        'max_ms': sorted.last / 1000,
      };
    }

    final result = {
      'mode': 'profile',
      'duration_s': clock.elapsedMilliseconds / 1000,
      'per_tier_window_s': 12,
      'warmup_per_tier_s': 4,
      'overlay': false,
      'peak_app_rss_bytes': ProcessInfo.maxRss,
      'physical_viewport': {
        'width': WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .physicalSize
            .width,
        'height': WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .physicalSize
            .height,
      },
      'device_pixel_ratio': WidgetsBinding
          .instance
          .platformDispatcher
          .views
          .first
          .devicePixelRatio,
      'viewport': 'native runner default',
      'tiers': {
        for (final tier in OrbTier.values)
          tier.label: {
            'build': stats(
              frames[tier]!.map((f) => f.buildDuration.inMicroseconds).toList(),
            ),
            'raster': stats(
              frames[tier]!
                  .map((f) => f.rasterDuration.inMicroseconds)
                  .toList(),
            ),
            'total_span': stats(
              frames[tier]!.map((f) => f.totalSpan.inMicroseconds).toList(),
            ),
          },
      },
      'note':
          'Whole app, forced tiers, live scripted streams; desktop load uncontrolled. Timer animation caps are not FPS certification.',
    };
    stdout.writeln('JARVIS_SLICE_A_REPORT ${jsonEncode(result)}');
    SchedulerBinding.instance.removeTimingsCallback(record);
    container.dispose();
    exit(frames.values.any((f) => f.isEmpty) ? 1 : 0);
  }());
}
