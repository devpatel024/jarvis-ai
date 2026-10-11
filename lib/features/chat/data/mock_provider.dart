import '../domain/llm_provider.dart';

/// Scripted local demo. Does not infer, call tools, or access the network.
class MockProvider implements LlmProvider {
  const MockProvider({
    this.firstTokenDelay = const Duration(milliseconds: 450),
    this.tokenDelay = const Duration(milliseconds: 90),
    this.simulateFailure = false,
    this.voiceStyle = false,
  });
  final Duration firstTokenDelay;
  final Duration tokenDelay;
  final bool simulateFailure, voiceStyle;
  static const englishReply =
      'This is a scripted demo reply, not AI. Your message stays in this session. '
      'Ollama setup arrives in Phase 2.';
  static const gujaratiReply =
      'નમસ્તે! આ માત્ર નમૂનાનો જવાબ છે, સાચી AI નથી. '
      'તમારો સંદેશ આ સત્રમાં જ રહે છે. હું ગુજરાતી લખાણ બતાવી શકું છું.';

  static const codeReply =
      '# A small spark\nThis is a **scripted** code sample, not AI.\n```dart\nvoid main() {\n  print("Hello / નમસ્તે");\n}\n```\n- Local and offline\n- No tools executed';

  @override
  String get label => 'MockProvider • scripted demo';
  @override
  bool get isDemo => true;

  @override
  Stream<LlmEvent> respond(
    List<LlmMessage> messages, {
    required CancellationToken cancellation,
  }) async* {
    if (messages.isEmpty ||
        messages.last.role != MessageRole.user ||
        messages.last.text.trim().isEmpty) {
      yield const LlmFailed(
        LlmFailure(
          LlmErrorCode.invalidRequest,
          'Enter a message to start the demo.',
        ),
      );
      return;
    }
    if (!await cancellation.wait(firstTokenDelay)) {
      yield const LlmFailed(
        LlmFailure(LlmErrorCode.cancelled, 'Reply stopped.'),
      );
      return;
    }
    if (simulateFailure) {
      yield const LlmFailed(
        LlmFailure(
          LlmErrorCode.unavailable,
          'Simulated demo failure. Retry is available.',
        ),
      );
      return;
    }
    final prompt = messages.last.text.toLowerCase();
    final smallTalk = RegExp(r'\b(hello|hi|hey)\b').hasMatch(prompt)
        ? 'Hello! How are you today?'
        : prompt.contains('how are you')
        ? 'I am ready to help. What would you like to do today?'
        : prompt.contains('good') || prompt.contains('fine')
        ? 'That is good to hear. What are you planning next?'
        : null;
    final gujarati = RegExp(r'[\u0A80-\u0AFF]').hasMatch(messages.last.text);
    // Whitespace tokens preserve combining marks and the complete sample text.
    final tokens = RegExp(r'\S+\s*').allMatches(
      gujarati
          ? gujaratiReply
          : messages.last.text.toLowerCase().contains('code')
          ? codeReply
          : voiceStyle
          ? smallTalk ?? 'What would you like help with today?'
          : englishReply,
    );
    for (final token in tokens) {
      if (!await cancellation.wait(tokenDelay)) {
        yield const LlmFailed(
          LlmFailure(LlmErrorCode.cancelled, 'Reply stopped.'),
        );
        return;
      }
      yield TextDelta(token.group(0)!);
    }
    yield const LlmCompleted();
  }
}
