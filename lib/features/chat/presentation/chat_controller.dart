import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_provider.dart';
import '../domain/llm_provider.dart';

enum ChatPhase { idle, thinking, streaming, error }

class ChatEntry {
  const ChatEntry(this.role, this.text, {this.stopped = false});
  final MessageRole role;
  final String text;
  final bool stopped;
}

class ChatState {
  const ChatState({
    this.entries = const [],
    this.phase = ChatPhase.idle,
    this.failure,
  });
  final List<ChatEntry> entries;
  final ChatPhase phase;
  final LlmFailure? failure;
  bool get busy => phase == ChatPhase.thinking || phase == ChatPhase.streaming;
}

final llmProvider = Provider<LlmProvider>((ref) => const MockProvider());
final chatProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);

class ChatController extends Notifier<ChatState> {
  CancellationToken? _token;
  int _generation = 0;
  String? _lastPrompt;

  @override
  ChatState build() {
    ref.onDispose(() {
      _generation++;
      _token?.cancel();
    });
    return const ChatState();
  }

  Future<void> send(String prompt, {bool simulateFailure = false}) async {
    if (state.busy || prompt.trim().isEmpty) return;
    _lastPrompt = prompt.trim();
    await _run(_lastPrompt!, retry: false, simulateFailure: simulateFailure);
  }

  Future<void> retry() async {
    if (state.busy || _lastPrompt == null || state.failure == null) return;
    await _run(_lastPrompt!, retry: true);
  }

  Future<void> _run(
    String prompt, {
    required bool retry,
    bool simulateFailure = false,
  }) async {
    final generation = ++_generation;
    final token = CancellationToken();
    _token = token;
    final entries = [...state.entries];
    if (retry) {
      if (entries.isNotEmpty && entries.last.role == MessageRole.assistant) {
        entries.removeLast();
      }
    } else {
      entries.add(ChatEntry(MessageRole.user, prompt));
    }
    final request = entries.map((e) => LlmMessage(e.role, e.text)).toList();
    entries.add(const ChatEntry(MessageRole.assistant, ''));
    state = ChatState(
      entries: List.unmodifiable(entries),
      phase: ChatPhase.thinking,
    );
    final provider = simulateFailure
        ? const MockProvider(simulateFailure: true)
        : ref.read(llmProvider);
    try {
      await for (final event
          in provider
              .respond(request, cancellation: token)
              .timeout(const Duration(seconds: 20))) {
        if (!ref.mounted || generation != _generation) return;
        switch (event) {
          case TextDelta(:final text):
            final previous = entries.removeLast();
            entries.add(ChatEntry(MessageRole.assistant, previous.text + text));
            state = ChatState(
              entries: List.unmodifiable(entries),
              phase: ChatPhase.streaming,
            );
          case LlmCompleted():
            state = ChatState(entries: List.unmodifiable(entries));
            return;
          case LlmFailed(:final failure):
            state = ChatState(
              entries: List.unmodifiable(entries),
              phase: ChatPhase.error,
              failure: failure,
            );
            return;
        }
      }
      if (ref.mounted && generation == _generation) {
        _fail(
          const LlmFailure(
            LlmErrorCode.unavailable,
            'Provider ended without completion. Retry the reply.',
          ),
        );
      }
    } on TimeoutException {
      if (ref.mounted && generation == _generation) {
        _fail(
          const LlmFailure(
            LlmErrorCode.timeout,
            'Reply timed out. Retry the reply.',
          ),
        );
      }
    } catch (_) {
      if (ref.mounted && generation == _generation) {
        _fail(
          const LlmFailure(
            LlmErrorCode.unavailable,
            'Reply interrupted. Retry the reply.',
          ),
        );
      }
    } finally {
      token.cancel();
    }
  }

  void _fail(LlmFailure failure) => state = ChatState(
    entries: state.entries,
    phase: ChatPhase.error,
    failure: failure,
  );

  void stop() {
    if (!state.busy) return;
    _generation++;
    _token?.cancel();
    final entries = [...state.entries];
    final last = entries.removeLast();
    entries.add(ChatEntry(last.role, last.text, stopped: true));
    state = ChatState(entries: List.unmodifiable(entries));
  }
}
