import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
part 'app_database.g.dart';

class ConversationRows extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MessageRows extends Table {
  TextColumn get conversationId =>
      text().references(ConversationRows, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get role => text()();
  TextColumn get content => text()();
  TextColumn get provider => text().withDefault(const Constant('Mock demo'))();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get stopped => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {conversationId, position};
}

class SettingRows extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [ConversationRows, MessageRows, SettingRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);
  factory AppDatabase.file(File file) =>
      AppDatabase(NativeDatabase.createInBackground(file));
  @override
  int get schemaVersion => 2;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from == 1) {
        await m.addColumn(messageRows, messageRows.stopped);
        await m.addColumn(messageRows, messageRows.provider);
      }
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
