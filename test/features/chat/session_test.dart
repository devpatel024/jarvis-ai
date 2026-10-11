import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/features/chat/presentation/chat_controller.dart';
import 'package:jarvis/features/chat/data/mock_provider.dart';
import 'package:jarvis/features/chat/domain/llm_provider.dart';

void main() {
  test(
    'Chats retain Unicode, selection cancels active generation, delete stops jobs',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(chatProvider.notifier);
      final pending = controller.send('નમસ્તે 🪷');
      controller.newChat();
      final second = container.read(chatProvider).activeId;
      controller.selectChat('1');
      expect(container.read(chatProvider).entries.first.text, 'નમસ્તે 🪷');
      expect(container.read(chatProvider).entries.last.stopped, isTrue);
      controller.renameChat('1', 'ક્ષિ' * 30);
      expect(container.read(chatProvider).sessions.first.title, 'ક્ષિ' * 30);
      controller.renameChat('1', 'મારી વાતચીત');
      controller.selectChat(second);
      controller.deleteChat('1');
      await pending;
      expect(container.read(chatProvider).sessions, hasLength(1));
      expect(container.read(chatProvider).entries, isEmpty);
    },
  );
  test('Regenerate and edit preserve request history and timestamps', () async {
    final container = ProviderContainer(
      overrides: [
        llmProvider.overrideWithValue(
          const MockProvider(
            firstTokenDelay: Duration.zero,
            tokenDelay: Duration.zero,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(chatProvider.notifier);
    await controller.send('Hello');
    final first = container.read(chatProvider).entries.first.timestamp;
    await controller.regenerate();
    expect(container.read(chatProvider).entries, hasLength(2));
    expect(container.read(chatProvider).entries.first.timestamp, first);
    await controller.editLast('નમસ્તે');
    expect(container.read(chatProvider).entries, hasLength(2));
    expect(
      container.read(chatProvider).entries.last.text,
      MockProvider.gujaratiReply,
    );
  });
  test('Code sample streams without executing anything', () async {
    const provider = MockProvider(
      firstTokenDelay: Duration.zero,
      tokenDelay: Duration.zero,
    );
    final events = await provider.respond([
      const LlmMessage(MessageRole.user, 'Show code'),
    ], cancellation: CancellationToken()).toList();
    expect(
      events.whereType<TextDelta>().map((e) => e.text).join(),
      MockProvider.codeReply,
    );
  });
}
