import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/core/design/app_theme.dart';
import 'package:jarvis/core/design/motion_settings.dart';
import 'package:jarvis/core/developer/performance_settings.dart';
import 'package:jarvis/features/chat/presentation/chat_screen.dart';
import 'widget_test.dart' show launch, destination, reveal;

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05));
}

void main() {
  test('Tier windows are isolated, bounded and resettable', () {
    final diagnostics = FrameDiagnostics();
    for (var i = 0; i < 130; i++) {
      diagnostics.record(OrbTier.ultra, 1000, 20000);
    }
    diagnostics.record(OrbTier.lite, 2000, 3000);
    final ultra = diagnostics.tiers[OrbTier.ultra]!;
    expect(ultra.count, 120);
    expect(ultra.mean(raster: false), 1);
    expect(ultra.p95(raster: true), 20);
    expect(ultra.budgetMisses, 120);
    expect(diagnostics.tiers[OrbTier.lite]!.count, 1);
    diagnostics.reset();
    expect(diagnostics.tiers.values.every((s) => s.count == 0), isTrue);
  });
  test('Every palette meets AA for body, muted and gradient-bubble text', () {
    for (final palette in AppPalette.values) {
      for (final brightness in Brightness.values) {
        final c = AppTheme.colors(palette, brightness);
        for (final surface in [
          c.surface,
          c.background,
          Color.alphaBlend(
            c.accents.first.withValues(alpha: c.dark ? .10 : .06),
            c.surface,
          ),
          Color.alphaBlend(
            c.accents.last.withValues(alpha: c.dark ? .08 : .04),
            c.surface,
          ),
          Color.alphaBlend(
            c.accents.first.withValues(alpha: .15),
            c.background,
          ),
          Color.alphaBlend(c.accents[1].withValues(alpha: .15), c.background),
          Color.alphaBlend(c.accents[2].withValues(alpha: .15), c.background),
        ]) {
          expect(
            contrast(c.ink, surface),
            greaterThanOrEqualTo(4.5),
            reason: '${palette.label} $brightness body',
          );
          expect(
            contrast(c.muted, surface),
            greaterThanOrEqualTo(4.5),
            reason: '${palette.label} $brightness muted',
          );
        }
        for (var step = 0; step <= 100; step++) {
          final color = Color.lerp(
            c.userStops.first,
            c.userStops.last,
            step / 100,
          )!;
          expect(
            contrast(c.userInk, color),
            greaterThanOrEqualTo(4.5),
            reason: '${palette.label} $brightness bubble $step',
          );
        }
      }
    }
  });
  testWidgets('Developer overlay toggles and all three readouts refresh/reset', (
    tester,
  ) async {
    final container = await launch(tester);
    await destination(tester, 'Settings');
    await reveal(tester, find.text('Developer'));
    await tester.tap(find.text('Developer'));
    await tester.pumpAndSettle();
    final overlay = find.widgetWithText(
      SwitchListTile,
      'Flutter performance overlay',
    );
    await reveal(tester, overlay);
    await tester.tap(overlay);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .showPerformanceOverlay,
      isTrue,
    );
    await tester.tap(overlay);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .showPerformanceOverlay,
      isFalse,
    );
    final diagnostics = container.read(frameDiagnosticsProvider);
    diagnostics.reset();
    for (final tier in OrbTier.values) {
      diagnostics.record(tier, 1000, 4000);
    }
    await reveal(tester, find.text('Refresh frame times'));
    await tester.tap(find.text('Refresh frame times'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Raster: 4.0 ms mean'), findsNWidgets(3));
    await tester.tap(find.text('Reset frame times'));
    await tester.pumpAndSettle();
    // Settings frames may be reported by native engines; widget engine reports none.
    expect(find.text('No measured frames yet.'), findsNWidgets(3));
  });
  testWidgets(
    'Manual tiers apply; measured auto fallback records without feedback',
    (tester) async {
      final container = await launch(tester, reduced: false);
      final quality = container.read(qualityProvider.notifier);
      for (final tier in OrbTier.values) {
        quality.select(tier);
        await tester.pump();
        expect(tester.widget<ChatScreen>(find.byType(ChatScreen)).tier, tier);
      }
      quality.select(null);
      await tester.pump();
      expect(container.read(qualityProvider).tier, OrbTier.lite);
      final healthy = List.generate(
        180,
        (i) => FrameTiming(
          vsyncStart: i * 40000,
          buildStart: i * 40000,
          buildFinish: i * 40000 + 1000,
          rasterStart: i * 40000 + 1000,
          rasterFinish: i * 40000 + 2000,
          rasterFinishWallTime: i * 40000 + 2000,
        ),
      );
      tester.binding.platformDispatcher.onReportTimings!(healthy);
      await tester.pump();
      expect(container.read(qualityProvider).tier, OrbTier.balanced);
      final slow = List.generate(
        60,
        (i) => FrameTiming(
          vsyncStart: i * 40000,
          buildStart: i * 40000,
          buildFinish: i * 40000 + 1000,
          rasterStart: i * 40000 + 1000,
          rasterFinish: i * 40000 + 39000,
          rasterFinishWallTime: i * 40000 + 39000,
        ),
      );
      tester.binding.platformDispatcher.onReportTimings!(slow);
      await tester.pump();
      expect(container.read(qualityProvider).tier, OrbTier.balanced);
      tester.binding.platformDispatcher.onReportTimings!(slow);
      await tester.pump();
      expect(container.read(qualityProvider).tier, OrbTier.lite);
      container.read(reduceMotionProvider.notifier).setReduced(true);
      await tester.pumpAndSettle();
      tester.binding.platformDispatcher.onReportTimings!(slow);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Settings quality dropdown selects each override and Automatic', (
    tester,
  ) async {
    final container = await launch(tester);
    await destination(tester, 'Settings');
    final dropdown = find.byType(DropdownButtonFormField<OrbTier?>);
    await reveal(tester, dropdown);
    for (final tier in OrbTier.values) {
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text(tier.label).last);
      await tester.pumpAndSettle();
      expect(container.read(qualityProvider).manual, tier);
    }
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automatic').last);
    await tester.pumpAndSettle();
    expect(container.read(qualityProvider).manual, isNull);
  });
}
