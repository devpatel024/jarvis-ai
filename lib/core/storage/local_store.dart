import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

class SavedMessage {
  const SavedMessage(
    this.role,
    this.text,
    this.timestamp,
    this.stopped, [
    this.provider = 'Mock demo',
  ]);
  final String role, text, provider;
  final DateTime timestamp;
  final bool stopped;
}

class SavedChat {
  const SavedChat(this.id, this.title, this.messages);
  final String id, title;
  final List<SavedMessage> messages;
}

class LocalSnapshot {
  const LocalSnapshot({this.chats = const [], this.settings = const {}});
  final List<SavedChat> chats;
  final Map<String, String> settings;
}

class LocalStore {
  LocalStore(this.database);
  final AppDatabase database;
  Future<void> _pending = Future.value();
  Object? lastError;
  final issues = StreamController<String>.broadcast();
  Future<void> flush() => _pending;
  void enqueue(Future<void> Function() action) {
    _pending = _pending.then((_) => action()).catchError((Object error) {
      lastError = error;
      issues.add(
        "Local save failed. Check disk space and file permissions. Changes may be unsaved.",
      );
    });
  }

  Future<LocalSnapshot> load() async {
    final rooms = await database.select(database.conversationRows).get();
    final messages = await (database.select(
      database.messageRows,
    )..orderBy([(m) => OrderingTerm.asc(m.position)])).get();
    final settings = await database.select(database.settingRows).get();
    if (messages.any((m) => !['user', 'assistant'].contains(m.role))) {
      throw const FormatException('Invalid saved message role');
    }
    return LocalSnapshot(
      chats: rooms
          .map(
            (r) => SavedChat(
              r.id,
              r.title,
              messages
                  .where((m) => m.conversationId == r.id)
                  .map(
                    (m) => SavedMessage(
                      m.role,
                      m.content,
                      m.timestamp,
                      m.stopped,
                      m.provider,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
      settings: {for (final s in settings) s.key: s.value},
    );
  }

  Future<void> saveChats(List<SavedChat> chats) =>
      database.transaction(() async {
        await database.delete(database.messageRows).go();
        await database.delete(database.conversationRows).go();
        await database.batch((batch) {
          batch.insertAll(
            database.conversationRows,
            chats.map(
              (r) => ConversationRowsCompanion.insert(id: r.id, title: r.title),
            ),
          );
          for (final r in chats) {
            batch.insertAll(
              database.messageRows,
              r.messages.indexed.map(
                (e) => MessageRowsCompanion.insert(
                  conversationId: r.id,
                  position: e.$1,
                  role: e.$2.role,
                  content: e.$2.text,
                  timestamp: e.$2.timestamp,
                  stopped: Value(e.$2.stopped),
                  provider: Value(e.$2.provider),
                ),
              ),
            );
          }
        });
      });
  Future<void> setting(String key, String value) async {
    await database
        .into(database.settingRows)
        .insertOnConflictUpdate(
          SettingRowsCompanion.insert(key: key, value: value),
        );
  }
}

final localStoreProvider = Provider<LocalStore?>((ref) => null);
final initialSnapshotProvider = Provider((ref) => const LocalSnapshot());
void persistSetting(Ref ref, String key, String value) {
  final store = ref.read(localStoreProvider);
  store?.enqueue(() => store.setting(key, value));
}

T? savedEnum<T extends Enum>(Ref ref, String key, List<T> values) {
  final name = ref.read(initialSnapshotProvider).settings[key];
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

final storageIssueProvider = StreamProvider<String>(
  (ref) => ref.watch(localStoreProvider)?.issues.stream ?? const Stream.empty(),
);
