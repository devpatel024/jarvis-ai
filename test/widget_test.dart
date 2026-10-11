import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/app/jarvis_app.dart';
import 'package:jarvis/core/design/app_theme.dart';
import 'package:jarvis/core/design/motion_settings.dart';
import 'package:jarvis/core/developer/performance_settings.dart';
import 'package:jarvis/features/chat/presentation/chat_controller.dart';
import 'package:jarvis/features/chat/presentation/chat_screen.dart';
import 'package:jarvis/features/orb/domain/orb_state.dart';
import 'package:jarvis/features/orb/presentation/core_orb.dart';

Future<ProviderContainer> launch(
  WidgetTester tester, {
  Size size = const Size(1200, 1000),
  bool reduced = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(reduceMotionProvider.notifier).setReduced(reduced);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const JarvisApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> destination(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

Future<void> completeReply(WidgetTester tester) async {
  for (var i = 0; i < 70; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('Every phone suggestion can scroll above composer at $scale', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await launch(tester, size: const Size(390, 900));
      for (final prompt in [
        'Plan my day',
        'Show a code example',
        'નમસ્તે',
        'મારા દિવસનું આયોજન કરો',
      ]) {
        final chip = find.widgetWithText(OutlinedButton, prompt);
        if (scale == 1) {
          expect(
            tester.getRect(chip).bottom,
            lessThan(
              tester.getRect(find.byKey(const ValueKey('composer'))).top,
            ),
          );
        }
        final label = tester.widget<Text>(
          find.descendant(of: chip, matching: find.text(prompt)),
        );
        expect(label.maxLines, 4);
        expect(label.overflow, TextOverflow.visible);
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        final rect = tester.getRect(chip);
        final composer = tester.getRect(find.byKey(const ValueKey('composer')));
        expect(rect.bottom, lessThan(composer.top));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(390));
        expect(chip.hitTestable(), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
  test('Gujarati fallback and typography weights match across themes', () {
    final dark = AppTheme.build(Brightness.dark);
    final light = AppTheme.build(Brightness.light);
    for (final styles in [
      (dark.textTheme.bodyMedium, light.textTheme.bodyMedium),
      (dark.textTheme.titleLarge, light.textTheme.titleLarge),
      (dark.textTheme.headlineLarge, light.textTheme.headlineLarge),
    ]) {
      expect(styles.$1!.fontWeight, styles.$2!.fontWeight);
      expect(styles.$1!.fontFamilyFallback, contains('NotoSansGujarati'));
      expect(styles.$2!.fontFamilyFallback, contains('NotoSansGujarati'));
    }
  });

  for (final width in [390.0, 850.0, 1200.0]) {
    testWidgets('Chat History Settings navigation at $width', (tester) async {
      await launch(tester, size: Size(width, 1000));
      expect(find.text('Hello / નમસ્તે'), findsOneWidget);
      await destination(tester, 'History');
      expect(find.text('Your conversations'), findsOneWidget);
      await destination(tester, 'Settings');
      expect(find.text('Appearance'), findsOneWidget);
      await destination(tester, 'Chat');
      expect(find.byKey(const ValueKey('composer')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('All palettes instantly apply dark and light variants', (
    tester,
  ) async {
    final container = await launch(tester);
    await destination(tester, 'Settings');
    for (final p in AppPalette.values) {
      await tester.tap(find.byTooltip(p.label));
      await tester.pumpAndSettle();
      expect(container.read(paletteProvider), p);
      final dropdown = find.byType(DropdownButtonFormField<ThemeMode>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Light').last);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Appearance'))).brightness,
        Brightness.light,
      );
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Appearance'))).brightness,
        Brightness.dark,
      );
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('Gujarati scratchpad survives navigation and clears', (
    tester,
  ) async {
    await launch(tester);
    await destination(tester, 'History');
    await tester.tap(find.text('Unicode scratchpad'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'નમસ્તે! ગુજરાતી 🪷');
    await destination(tester, 'Settings');
    await destination(tester, 'History');
    await tester.tap(find.text('Unicode scratchpad'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'નમસ્તે! ગુજરાતી 🪷',
    );
    await tester.tap(find.text('Clear scratchpad'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });
  testWidgets(
    'Keyboard commands new chat, command palette and send/newline/stop',
    (tester) async {
      final container = await launch(tester);
      await tester.tap(find.byKey(const ValueKey('composer')));
      await tester.enterText(find.byKey(const ValueKey('composer')), 'Hello');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(container.read(chatProvider).entries, isEmpty);
      await tester.enterText(find.byKey(const ValueKey('composer')), 'Hello');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(container.read(chatProvider).busy, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(container.read(chatProvider).busy, isFalse);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(container.read(chatProvider).sessions, hasLength(2));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.text('Commands'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Find a command'),
        'History',
      );
      await tester.pump();
      await tester.tap(find.text('Open History'));
      await tester.pumpAndSettle();
      expect(find.text('Your conversations'), findsOneWidget);
    },
  );
  testWidgets('History rename and confirmed deletion', (tester) async {
    final container = await launch(tester, size: const Size(390, 1000));
    await destination(tester, 'History');
    await tester.tap(find.byTooltip('Conversation actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ગુજરાતી chat');
    await tester.tap(find.text('Rename').last);
    await tester.pumpAndSettle();
    expect(container.read(chatProvider).sessions.single.title, 'ગુજરાતી chat');
    await tester.tap(find.byTooltip('Conversation actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(container.read(chatProvider).sessions.single.title, 'ગુજરાતી chat');
    await tester.tap(find.byTooltip('Conversation actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(
      container.read(chatProvider).sessions.single.title,
      'New conversation',
    );
  });
  testWidgets('Phone large text settings and developer panel remain usable', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await launch(tester, size: const Size(390, 1000));
    await destination(tester, 'Settings');
    await reveal(tester, find.text('Developer'));
    await tester.tap(find.text('Developer'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Lite tier'));
    expect(tester.takeException(), isNull);
  });
  testWidgets('App and OS reduced motion override manual Ultra', (
    tester,
  ) async {
    final container = await launch(tester);
    container.read(qualityProvider.notifier).select(OrbTier.ultra);
    await tester.pumpAndSettle();
    expect(
      tester.widget<ChatScreen>(find.byType(ChatScreen)).tier,
      OrbTier.lite,
    );
    container.read(reduceMotionProvider.notifier).setReduced(false);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpAndSettle();
    expect(
      tester.widget<CoreOrb>(find.byType(CoreOrb).first).reduceMotion,
      isTrue,
    );
  });
  testWidgets('Five visual orb previews remain in Developer settings', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final container = await launch(tester);
    for (final state in OrbState.values) {
      container.read(orbPreviewProvider.notifier).select(state);
      await tester.pumpAndSettle();
      expect(tester.widget<CoreOrb>(find.byType(CoreOrb).first).state, state);
      expect(
        tester.getSemantics(find.byType(CoreOrb).first).label,
        'Core orb: ${state.name}',
      );
    }
    semantics.dispose();
    expect(find.text('Demo controls'), findsNothing);
  });
}
