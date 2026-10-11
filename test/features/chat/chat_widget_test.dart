import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/app/jarvis_app.dart';
import 'package:jarvis/features/chat/data/mock_provider.dart';
import 'package:jarvis/features/chat/presentation/chat_controller.dart';
import 'package:jarvis/features/orb/presentation/core_orb.dart';
import 'package:jarvis/features/orb/domain/orb_state.dart';

Future<void> startChat(
  WidgetTester tester, {
  Size size = const Size(1100, 1000),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(const ProviderScope(child: JarvisApp()));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Chat'));
  await tester.pump();
}

Future<void> send(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.text('Send'));
  await tester.pump();
}

Future<void> finishReply(WidgetTester tester) async {
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('Gujarati chat streams, finishes and updates orb', (
    tester,
  ) async {
    await startChat(tester);
    expect(
      find.text(
        'Start a demo conversation in English or Gujarati. Nothing is saved.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await send(tester, 'નમસ્તે');
    expect(
      tester.widget<CoreOrb>(find.byType(CoreOrb)).state,
      OrbState.thinking,
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<CoreOrb>(find.byType(CoreOrb)).state,
      OrbState.speaking,
    );
    expect(find.text('Stop'), findsOneWidget);
    await finishReply(tester);
    expect(find.text(MockProvider.gujaratiReply), findsOneWidget);
    expect(tester.widget<CoreOrb>(find.byType(CoreOrb)).state, OrbState.idle);
    expect(find.text('Send'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Stop freezes partial reply and a new send works', (
    tester,
  ) async {
    await startChat(tester, size: const Size(390, 900));
    await send(tester, 'Hello');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Stop'));
    await tester.pump();
    final context = tester.element(find.byType(CoreOrb));
    final container = ProviderScope.containerOf(context);
    final partial = container.read(chatProvider).entries.last.text;
    await finishReply(tester);
    expect(container.read(chatProvider).entries.last.text, partial);
    expect(container.read(chatProvider).entries.last.stopped, isTrue);
    expect(container.read(chatProvider).busy, isFalse);
    await send(tester, 'Try again');
    await finishReply(tester);
    expect(find.text(MockProvider.englishReply), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Demo error displays retry without duplicating user message', (
    tester,
  ) async {
    await startChat(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CoreOrb)),
    );
    await tester.tap(find.text('Demo controls'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await send(tester, 'Hello');
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widget<CoreOrb>(find.byType(CoreOrb)).state, OrbState.error);
    await tester.ensureVisible(find.text('Retry reply'));
    await tester.tap(find.text('Retry reply'));
    await tester.pump();
    await finishReply(tester);
    expect(container.read(chatProvider).entries.length, 2);
    expect(container.read(chatProvider).failure, isNull);
    expect(find.text(MockProvider.englishReply), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('OS reduced motion and all visual orb states', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await startChat(tester);
    expect(find.text('Simple orb: motion disabled'), findsOneWidget);
    await tester.tap(find.text('Demo controls'));
    await tester.pumpAndSettle();
    for (final state in OrbState.values) {
      await tester.ensureVisible(
        find.byType(DropdownButtonFormField<OrbState?>),
      );
      await tester.tap(find.byType(DropdownButtonFormField<OrbState?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(state.name).last);
      await tester.pumpAndSettle();
      expect(tester.widget<CoreOrb>(find.byType(CoreOrb)).state, state);
      expect(find.text('Simple orb: motion disabled'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Settings reduced motion disables animation on return to chat', (
    tester,
  ) async {
    await startChat(tester);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reduce motion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Simple orb: motion disabled'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Measured slow frames switch the actual orb to static mode', (
    tester,
  ) async {
    await startChat(tester);
    final slow = List.generate(
      60,
      (i) => FrameTiming(
        vsyncStart: i * 40000,
        buildStart: i * 40000,
        buildFinish: i * 40000 + 1000,
        rasterStart: i * 40000 + 1000,
        rasterFinish: i * 40000 + 25000,
        rasterFinishWallTime: i * 40000 + 25000,
      ),
    );
    tester.binding.platformDispatcher.onReportTimings!(slow);
    await tester.pump();
    expect(find.text('Simple orb: frame budget exceeded'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    tester.binding.platformDispatcher.onReportTimings!(slow);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Light chat supports phone width and doubled text size', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await startChat(tester, size: const Size(390, 900));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(JarvisApp)),
    );
    container.read(themeProvider.notifier).select(ThemeMode.light);
    await tester.pumpAndSettle();
    await send(tester, 'નમસ્તે');
    await finishReply(tester);
    expect(find.text(MockProvider.gujaratiReply), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
