import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/features/chat/data/mock_provider.dart';
import 'package:jarvis/features/chat/domain/llm_provider.dart';

void main() {
  const provider = MockProvider(
    firstTokenDelay: Duration.zero,
    tokenDelay: Duration.zero,
  );
  for (final sample in [
    ('Hello', MockProvider.englishReply),
    ('નમસ્તે', MockProvider.gujaratiReply),
  ]) {
    test('Mock streams lossless sample: ${sample.$1}', () async {
      final events = await provider.respond([
        LlmMessage(MessageRole.user, sample.$1),
      ], cancellation: CancellationToken()).toList();
      expect(events.whereType<TextDelta>().length, greaterThan(5));
      expect(
        events.whereType<TextDelta>().map((e) => e.text).join(),
        sample.$2,
      );
      expect(events.last, isA<LlmCompleted>());
      expect(events.whereType<LlmFailed>(), isEmpty);
      expect(provider.isDemo, isTrue);
    });
  }
  test('Pre-cancelled request generates no text or success', () async {
    final token = CancellationToken()..cancel();
    final events = await provider.respond([
      const LlmMessage(MessageRole.user, 'Hi'),
    ], cancellation: token).toList();
    expect(events, hasLength(1));
    expect((events.single as LlmFailed).failure.code, LlmErrorCode.cancelled);
  });
  test('Cancellation interrupts a pending long delay promptly', () async {
    final token = CancellationToken();
    const slow = MockProvider(firstTokenDelay: Duration(seconds: 30));
    final response = slow.respond([
      const LlmMessage(MessageRole.user, 'Hi'),
    ], cancellation: token).toList();
    token.cancel();
    final events = await response.timeout(const Duration(seconds: 1));
    expect((events.single as LlmFailed).failure.code, LlmErrorCode.cancelled);
  });
  test('Cancelling after first delta retains only partial output', () async {
    final token = CancellationToken();
    final events = <LlmEvent>[];
    await for (final event in provider.respond([
      const LlmMessage(MessageRole.user, 'Hi'),
    ], cancellation: token)) {
      events.add(event);
      if (event is TextDelta) token.cancel();
    }
    expect(events.whereType<TextDelta>(), hasLength(1));
    expect(events.whereType<LlmCompleted>(), isEmpty);
    expect((events.last as LlmFailed).failure.code, LlmErrorCode.cancelled);
  });
  test('Failure is typed and never emits completion', () async {
    const failed = MockProvider(
      firstTokenDelay: Duration.zero,
      simulateFailure: true,
    );
    final events = await failed.respond([
      const LlmMessage(MessageRole.user, 'Hi'),
    ], cancellation: CancellationToken()).toList();
    expect((events.single as LlmFailed).failure.code, LlmErrorCode.unavailable);
  });
  test('Empty requests fail validation', () async {
    final events = await provider
        .respond([], cancellation: CancellationToken())
        .toList();
    expect(
      (events.single as LlmFailed).failure.code,
      LlmErrorCode.invalidRequest,
    );
  });
}
