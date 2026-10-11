import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_provider.dart';
import '../domain/llm_provider.dart';

enum ChatPhase { idle, thinking, streaming, error }

class ChatEntry {
  ChatEntry(this.role, this.text, {this.stopped = false, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
  final MessageRole role;
  final String text;
  final bool stopped;
  final DateTime timestamp;
}

class ChatSummary {
  const ChatSummary(this.id, this.title);
  final String id, title;
}

class ChatState {
  const ChatState({
    this.entries = const [],
    this.phase = ChatPhase.idle,
    this.failure,
    this.activeId = '1',
    this.sessions = const [ChatSummary('1', 'New conversation')],
  });
  final List<ChatEntry> entries;
  final ChatPhase phase;
  final LlmFailure? failure;
  final String activeId;
  final List<ChatSummary> sessions;
  bool get busy => phase == ChatPhase.thinking || phase == ChatPhase.streaming;
}

final llmProvider = Provider<LlmProvider>((ref) => const MockProvider());
final chatProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);

class ChatController extends Notifier<ChatState> {
  CancellationToken? _token;
  int _generation = 0, _nextId = 1;
  String _id = '1';
  final _chats = <String, ChatState>{'1': const ChatState()};
  final _titles = <String, String>{'1': 'New conversation'};
  @override
  ChatState build() {
    ref.onDispose(() {
      _generation++;
      _token?.cancel();
    });
    return const ChatState();
  }

  void _emit(ChatState value) {
    _chats[_id] = value;
    state = ChatState(
      entries: value.entries,
      phase: value.phase,
      failure: value.failure,
      activeId: _id,
      sessions:
          state.sessions.length == _titles.length &&
              state.sessions.every((s) => _titles[s.id] == s.title)
          ? state.sessions
          : List.unmodifiable(
              _titles.entries.map((e) => ChatSummary(e.key, e.value)),
            ),
    );
  }

  void newChat() {
    stop();
    _id = '${++_nextId}';
    _titles[_id] = 'New conversation';
    _emit(const ChatState());
  }

  void selectChat(String id) {
    if (id == _id || !_chats.containsKey(id)) return;
    stop();
    _id = id;
    _emit(_chats[id]!);
  }

  void renameChat(String id, String title) {
    if (!_titles.containsKey(id) || title.trim().isEmpty) return;
    // UI bounds graphemes; retain complete Gujarati clusters without rune slicing.
    _titles[id] = title.trim();
    _emit(state);
  }

  /// Caller confirms the exact chat before deletion; active streaming is stopped.
  void deleteChat(String id) {
    if (!_titles.containsKey(id)) return;
    if (id == _id) stop();
    _titles.remove(id);
    _chats.remove(id);
    if (_titles.isEmpty) {
      _id = '${++_nextId}';
      _titles[_id] = 'New conversation';
      _emit(const ChatState());
    } else {
      if (id == _id) _id = _titles.keys.last;
      _emit(_chats[_id]!);
    }
  }

  Future<void> send(String prompt, {bool simulateFailure = false}) async {
    if (state.busy || prompt.trim().isEmpty) return;
    if (state.entries.isEmpty && _titles[_id] == 'New conversation') {
      final text = prompt.trim();
      _titles[_id] = text.length > 36
          ? '${String.fromCharCodes(text.runes.take(36))}…'
          : text;
    }
    await _run(prompt.trim(), retry: false, simulateFailure: simulateFailure);
  }

  Future<void> retry() async {
    if (state.failure != null) await regenerate();
  }

  Future<void> regenerate() async {
    if (state.busy ||
        state.entries.isEmpty ||
        state.entries.last.role != MessageRole.assistant) {
      return;
    }
    final users = state.entries.where((e) => e.role == MessageRole.user);
    if (users.isEmpty) return;
    await _run(users.last.text, retry: true);
  }

  Future<void> editLast(String prompt) async {
    if (state.busy || prompt.trim().isEmpty) return;
    final index = state.entries.lastIndexWhere(
      (e) => e.role == MessageRole.user,
    );
    if (index < 0) return;
    _emit(ChatState(entries: List.unmodifiable(state.entries.take(index))));
    await send(prompt);
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
    entries.add(ChatEntry(MessageRole.assistant, ''));
    _emit(
      ChatState(entries: List.unmodifiable(entries), phase: ChatPhase.thinking),
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
            entries.add(
              ChatEntry(
                MessageRole.assistant,
                previous.text + text,
                timestamp: previous.timestamp,
              ),
            );
            _emit(
              ChatState(
                entries: List.unmodifiable(entries),
                phase: ChatPhase.streaming,
              ),
            );
          case LlmCompleted():
            _emit(ChatState(entries: List.unmodifiable(entries)));
            return;
          case LlmFailed(:final failure):
            _emit(
              ChatState(
                entries: List.unmodifiable(entries),
                phase: ChatPhase.error,
                failure: failure,
              ),
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

  void _fail(LlmFailure failure) => _emit(
    ChatState(entries: state.entries, phase: ChatPhase.error, failure: failure),
  );
  void stop() {
    if (!state.busy) return;
    _generation++;
    _token?.cancel();
    final entries = [...state.entries];
    final last = entries.removeLast();
    entries.add(
      ChatEntry(last.role, last.text, stopped: true, timestamp: last.timestamp),
    );
    _emit(ChatState(entries: List.unmodifiable(entries)));
  }
}
