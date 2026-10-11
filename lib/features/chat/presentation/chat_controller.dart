import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_provider.dart';
import '../domain/llm_provider.dart';
import '../data/ollama_provider.dart';
import 'provider_settings.dart';
import '../../../core/storage/local_store.dart';

enum ChatPhase { idle, thinking, streaming, error }

class ChatEntry {
  ChatEntry(
    this.role,
    this.text, {
    this.stopped = false,
    this.provider = 'Mock demo',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  final MessageRole role;
  final String text, provider;
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

final llmProvider = Provider<LlmProvider>((ref) {
  final settings = ref.watch(providerSettingsProvider);
  return settings.demo
      ? const MockProvider()
      : OllamaProvider(ref.read(ollamaServiceProvider), settings);
});
final chatProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);

class ChatController extends Notifier<ChatState> {
  CancellationToken? _token;
  Timer? _saveTimer;
  int _generation = 0, _nextId = 1;
  String _id = '1';
  final _chats = <String, ChatState>{'1': const ChatState()};
  final _titles = <String, String>{'1': 'New conversation'};
  @override
  ChatState build() {
    final snapshot = ref.read(initialSnapshotProvider);
    if (snapshot.chats.isNotEmpty) {
      _chats.clear();
      _titles.clear();
      for (final c in snapshot.chats) {
        _titles[c.id] = c.title;
        _nextId = (_nextId > (int.tryParse(c.id) ?? 0))
            ? _nextId
            : int.parse(c.id);
        _chats[c.id] = ChatState(
          entries: c.messages
              .map(
                (m) => ChatEntry(
                  MessageRole.values.byName(m.role),
                  m.text,
                  timestamp: m.timestamp,
                  stopped: m.stopped,
                  provider: m.provider,
                ),
              )
              .toList(),
        );
      }
      final saved = snapshot.settings['activeChat'];
      _id = _chats.containsKey(saved) ? saved! : _chats.keys.last;
    }
    ref.onDispose(() {
      _saveTimer?.cancel();
      _generation++;
      _token?.cancel();
    });
    return ChatState(
      entries: _chats[_id]!.entries,
      activeId: _id,
      sessions: _titles.entries
          .map((e) => ChatSummary(e.key, e.value))
          .toList(),
    );
  }

  void _persist() {
    _saveTimer?.cancel();
    _saveTimer = null;
    final store = ref.read(localStoreProvider);
    if (store == null) return;
    final rooms = _titles.entries
        .map(
          (t) => SavedChat(
            t.key,
            t.value,
            _chats[t.key]!.entries
                .map(
                  (e) => SavedMessage(
                    e.role.name,
                    e.text,
                    e.timestamp,
                    e.stopped ||
                        (_chats[t.key]!.busy &&
                            identical(e, _chats[t.key]!.entries.last)),
                    e.provider,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
    store.enqueue(() => store.saveChats(rooms));
    persistSetting(ref, 'activeChat', _id);
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
    if (state.phase == ChatPhase.streaming) {
      _saveTimer ??= Timer(const Duration(seconds: 1), () {
        _saveTimer = null;
        if (ref.mounted) _persist();
      });
    } else {
      _persist();
    }
  }

  List<ChatSummary> search(String query) {
    final needle = query.trim().toLowerCase();
    return [
      for (final room in _titles.entries)
        if (needle.isEmpty ||
            room.value.toLowerCase().contains(needle) ||
            _chats[room.key]!.entries.any(
              (e) => e.text.toLowerCase().contains(needle),
            ))
          ChatSummary(room.key, room.value),
    ];
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
    final provider = simulateFailure
        ? const MockProvider(simulateFailure: true)
        : ref.read(llmProvider);
    entries.add(
      ChatEntry(
        MessageRole.assistant,
        '',
        provider: provider.isDemo ? 'Mock demo' : provider.label,
      ),
    );
    _emit(
      ChatState(entries: List.unmodifiable(entries), phase: ChatPhase.thinking),
    );
    try {
      await for (final event
          in provider
              .respond(request, cancellation: token)
              .timeout(const Duration(seconds: 95))) {
        if (!ref.mounted || generation != _generation) return;
        switch (event) {
          case TextDelta(:final text):
            final previous = entries.removeLast();
            entries.add(
              ChatEntry(
                MessageRole.assistant,
                previous.text + text,
                timestamp: previous.timestamp,
                provider: previous.provider,
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
      ChatEntry(
        last.role,
        last.text,
        stopped: true,
        timestamp: last.timestamp,
        provider: last.provider,
      ),
    );
    _emit(ChatState(entries: List.unmodifiable(entries)));
  }
}
