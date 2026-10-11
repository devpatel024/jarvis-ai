import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as native;
import 'package:jarvis/core/storage/app_database.dart';
import 'package:jarvis/core/storage/local_store.dart';

void main() {
  test(
    'SQLite Unicode create/write/read/rename/delete and reopen settings',
    () async {
      final temp = await Directory.systemTemp.createTemp('jarvis-sqlite-test');
      final file = File('${temp.path}/data.sqlite');
      var database = AppDatabase(NativeDatabase(file));
      var store = LocalStore(database);
      final message = SavedMessage(
        'assistant',
        'નમસ્તે! મારા દિવસનું આયોજન કરો. 👋',
        DateTime.utc(2026, 10, 11),
        false,
        'llama3.2:3b',
      );
      await store.saveChats([
        SavedChat('1', 'ગુજરાતી નોંધ', [message]),
      ]);
      await store.setting('theme', 'light');
      await database.close();
      database = AppDatabase(NativeDatabase(file));
      store = LocalStore(database);
      var data = await store.load();
      expect(data.chats.single.messages.single.text, message.text);
      expect(data.chats.single.messages.single.provider, 'llama3.2:3b');
      expect(data.chats.single.title, 'ગુજરાતી નોંધ');
      expect(data.settings['theme'], 'light');
      await store.saveChats([
        SavedChat('1', 'બદલેલું નામ', [message]),
      ]);
      data = await store.load();
      expect(data.chats.single.title, 'બદલેલું નામ');
      await store.saveChats([]);
      expect((await store.load()).chats, isEmpty);
      expect(
        await database
            .customSelect('SELECT COUNT(*) AS n FROM message_rows')
            .getSingle()
            .then((r) => r.read<int>('n')),
        0,
      );
      await database.close();
      await temp.delete(recursive: true);
    },
  );
  test('Migration v1 to v2 retains Gujarati and defaults stopped to false', () async {
    final temp = await Directory.systemTemp.createTemp('jarvis-migration-test');
    final file = File('${temp.path}/v1.sqlite');
    final db = native.sqlite3.open(file.path);
    db.execute(
      'CREATE TABLE conversation_rows (id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL)',
    );
    db.execute(
      'CREATE TABLE message_rows (conversation_id TEXT NOT NULL REFERENCES conversation_rows(id) ON DELETE CASCADE, position INTEGER NOT NULL, role TEXT NOT NULL, content TEXT NOT NULL, timestamp INTEGER NOT NULL, PRIMARY KEY(conversation_id,position))',
    );
    db.execute(
      'CREATE TABLE setting_rows (key TEXT NOT NULL PRIMARY KEY,value TEXT NOT NULL)',
    );
    db.execute('INSERT INTO conversation_rows VALUES (?,?)', ['1', 'જૂની વાત']);
    db.execute('INSERT INTO message_rows VALUES (?,?,?,?,?)', [
      '1',
      0,
      'user',
      'ગુજરાતી સુરક્ષિત રહે',
      1791676800,
    ]);
    db.execute('PRAGMA user_version = 1');
    db.close();
    final migrated = AppDatabase(NativeDatabase(file));
    final snapshot = await LocalStore(migrated).load();
    expect(snapshot.chats.single.messages.single.text, 'ગુજરાતી સુરક્ષિત રહે');
    expect(snapshot.chats.single.messages.single.stopped, isFalse);
    expect(snapshot.chats.single.messages.single.provider, 'Mock demo');
    await LocalStore(migrated).saveChats([
      SavedChat('1', 'જૂની વાત', [
        SavedMessage('assistant', 'અધૂરો જવાબ', DateTime.utc(2026), true),
      ]),
    ]);
    expect(
      (await LocalStore(migrated).load()).chats.single.messages.single.stopped,
      isTrue,
    );
    expect(
      (await migrated.customSelect('PRAGMA user_version').getSingle())
          .data
          .values
          .single,
      2,
    );
    await migrated.close();
    await temp.delete(recursive: true);
  });
  test(
    'Queued writes serialize and report save errors without losing the queue',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final store = LocalStore(database);
      store.enqueue(() => store.setting('model', 'llama3.2:1b'));
      store.enqueue(() => store.setting('model', 'Mock demo'));
      await store.flush();
      expect((await store.load()).settings['model'], 'Mock demo');
      final error = store.issues.stream.first;
      store.enqueue(
        () => Future<void>.error(StateError('simulated disk failure')),
      );
      await store.flush();
      expect(await error, contains('Local save failed'));
      store.enqueue(() => store.setting('theme', 'dark'));
      await store.flush();
      expect((await store.load()).settings['theme'], 'dark');
      await database.close();
      await store.issues.close();
    },
  );
}
