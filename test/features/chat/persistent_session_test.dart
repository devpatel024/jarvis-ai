import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/app/jarvis_app.dart';
import 'package:jarvis/core/storage/app_database.dart';
import 'package:jarvis/core/storage/local_store.dart';
import 'package:jarvis/features/chat/data/mock_provider.dart';
import 'package:jarvis/features/chat/domain/llm_settings.dart';
import 'package:jarvis/features/chat/presentation/chat_controller.dart';
import 'package:jarvis/features/chat/presentation/provider_settings.dart';

void main() {
  test(
    'Controller restores chat selection, Gujarati search, rename and settings after database restart',
    () async {
      final temp = await Directory.systemTemp.createTemp('jarvis-session-');
      final file = File('${temp.path}/session.sqlite');
      var db = AppDatabase.file(file);
      var store = LocalStore(db);
      ProviderContainer container(LocalSnapshot snapshot) => ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          initialSnapshotProvider.overrideWithValue(snapshot),
          llmProvider.overrideWithValue(
            const MockProvider(
              firstTokenDelay: Duration.zero,
              tokenDelay: Duration.zero,
            ),
          ),
        ],
      );
      var scope = container(await store.load());
      expect(scope.read(providerSettingsProvider).model, 'llama3.2:1b');
      final controller = scope.read(chatProvider.notifier);
      await controller.send('નમસ્તે 🪷');
      controller.renameChat('1', 'મારી વાત');
      controller.newChat();
      final second = scope.read(chatProvider).activeId;
      await controller.send('Hello');
      controller.selectChat('1');
      scope.read(themeProvider.notifier).select(ThemeMode.light);
      scope
          .read(providerSettingsProvider.notifier)
          .update(
            model: 'llama3.2:3b',
            context: 1024,
            language: ReplyLanguage.gujarati,
            keepAlive: 0,
          );
      await store.flush();
      scope.dispose();
      await db.close();
      await store.issues.close();
      db = AppDatabase.file(file);
      store = LocalStore(db);
      scope = container(await store.load());
      final restored = scope.read(chatProvider.notifier);
      expect(scope.read(chatProvider).activeId, '1');
      expect(scope.read(chatProvider).entries.first.text, 'નમસ્તે 🪷');
      expect(restored.search('નમસ્તે').single.title, 'મારી વાત');
      expect(restored.search('HELLO').single.id, second);
      expect(restored.search('absent'), isEmpty);
      expect(scope.read(themeProvider), ThemeMode.light);
      expect(scope.read(providerSettingsProvider).model, 'llama3.2:3b');
      expect(scope.read(providerSettingsProvider).contextLength, 1024);
      expect(
        scope.read(providerSettingsProvider).language,
        ReplyLanguage.gujarati,
      );
      expect(scope.read(providerSettingsProvider).keepAliveSeconds, 0);
      restored.deleteChat('1');
      await store.flush();
      expect((await store.load()).chats.single.id, second);
      scope.dispose();
      await db.close();
      await store.issues.close();
      await temp.delete(recursive: true);
    },
  );
}
