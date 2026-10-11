import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/features/chat/presentation/chat_controller.dart';
import 'package:jarvis/features/chat/presentation/chat_screen.dart';
import 'package:jarvis/features/chat/data/mock_provider.dart';
import 'package:jarvis/features/orb/domain/orb_state.dart';
import 'package:jarvis/features/orb/presentation/core_orb.dart';
import '../../widget_test.dart' show launch, completeReply;

void main() {
  testWidgets('Gujarati streams with thinking and speaking then completes', (
    tester,
  ) async {
    final container = await launch(tester);
    await tester.enterText(find.byKey(const ValueKey('composer')), 'નમસ્તે');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    expect(find.text('Preparing a demo reply…'), findsOneWidget);
    expect(
      tester.widget<CoreOrb>(find.byType(CoreOrb).first).state,
      OrbState.thinking,
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<CoreOrb>(find.byType(CoreOrb).first).state,
      OrbState.speaking,
    );
    await completeReply(tester);
    expect(
      container.read(chatProvider).entries.last.text,
      MockProvider.gujaratiReply,
    );
    expect(find.textContaining('નમસ્તે! આ માત્ર'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Stop retains partial reply and next send works', (tester) async {
    final container = await launch(tester, size: const Size(390, 1000));
    await tester.enterText(find.byKey(const ValueKey('composer')), 'Hello');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byTooltip('Stop'));
    await tester.pump();
    final partial = container.read(chatProvider).entries.last.text;
    await completeReply(tester);
    expect(container.read(chatProvider).entries.last.text, partial);
    expect(container.read(chatProvider).entries.last.stopped, isTrue);
    await tester.enterText(find.byKey(const ValueKey('composer')), 'Again');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    await completeReply(tester);
    expect(
      container.read(chatProvider).entries.last.text,
      MockProvider.englishReply,
    );
  });
  testWidgets('Failure retry does not duplicate the user message', (
    tester,
  ) async {
    final container = await launch(tester);
    container.read(demoFailureProvider.notifier).select(true);
    await tester.enterText(find.byKey(const ValueKey('composer')), 'Hello');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(find.text('Retry reply'), findsOneWidget);
    await tester.tap(find.text('Retry reply'));
    await tester.pump();
    await completeReply(tester);
    expect(container.read(chatProvider).entries, hasLength(2));
    expect(container.read(chatProvider).failure, isNull);
  });
  testWidgets('Message menu copy, edit last and regenerate', (tester) async {
    final container = await launch(tester);
    await tester.enterText(find.byKey(const ValueKey('composer')), 'Hello');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    await completeReply(tester);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.tap(find.byTooltip('Message actions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy message'));
    await tester.pumpAndSettle();
    expect(copied, 'Hello');
    await tester.tap(find.byTooltip('Message actions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit last message'));
    await tester.pumpAndSettle();
    expect(find.text('Editing your last message'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('composer')), 'નમસ્તે');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    await completeReply(tester);
    expect(container.read(chatProvider).entries.first.text, 'નમસ્તે');
    await tester.tap(find.byTooltip('Message actions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Regenerate reply'));
    await tester.pump();
    await completeReply(tester);
    expect(container.read(chatProvider).entries, hasLength(2));
  });
  testWidgets('Code suggestion renders fenced code with copy action', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.text('Show a code example'));
    await tester.pump();
    await completeReply(tester);
    expect(find.byTooltip('Copy code'), findsOneWidget);
    expect(find.textContaining('print("Hello / નમસ્તે")'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
