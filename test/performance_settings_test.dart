import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/app/jarvis_app.dart';
import 'package:jarvis/core/developer/performance_settings.dart';

void main() {
  test('tier samples are isolated, bounded and resettable', () {
    final diagnostics = FrameDiagnostics();
    for (var i = 0; i < 130; i++) {
      diagnostics.record(OrbTier.animated, 1000, 20000);
    }
    diagnostics.record(OrbTier.simple, 2000, 3000);
    final animated = diagnostics.tiers[OrbTier.animated]!;
    expect(animated.count, 120);
    expect(animated.mean(raster: false), 1);
    expect(animated.p95(raster: true), 20);
    expect(animated.budgetMisses, 120);
    expect(diagnostics.tiers[OrbTier.simple]!.count, 1);
    expect(diagnostics.tiers[OrbTier.simple]!.budgetMisses, 0);
    diagnostics.reset();
    expect(diagnostics.tiers.values.every((s) => s.count == 0), isTrue);
    expect(diagnostics.tiers[OrbTier.simple]!.mean(raster: true), isNull);
  });

  testWidgets('Developer overlay and tier readouts refresh and reset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const JarvisApp()),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .showPerformanceOverlay,
      isFalse,
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    final overlay = find.widgetWithText(
      SwitchListTile,
      'Flutter performance overlay',
    );
    await tester.ensureVisible(overlay);
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
    container
        .read(frameDiagnosticsProvider)
        .record(OrbTier.animated, 2000, 4000);
    container.read(frameDiagnosticsProvider).record(OrbTier.simple, 1000, 3000);
    await tester.ensureVisible(find.text('Refresh frame times'));
    await tester.tap(find.text('Refresh frame times'));
    await tester.pump();
    expect(find.textContaining('Raster: 4.0 ms mean'), findsOneWidget);
    expect(find.textContaining('Raster: 3.0 ms mean'), findsOneWidget);
    await tester.tap(find.text('Reset frame times'));
    await tester.pump();
    expect(find.textContaining('No measured frames yet.'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Developer panel wraps at phone width and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const ProviderScope(child: JarvisApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Simple orb tier'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Simple orb tier'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
