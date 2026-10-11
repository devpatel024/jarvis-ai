import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'app/jarvis_app.dart';
import 'core/storage/app_database.dart';
import 'core/storage/local_store.dart';

bool _licensesRegistered = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!_licensesRegistered) {
    _licensesRegistered = true;
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks([
        'jni native sources',
      ], await rootBundle.loadString('assets/licenses/JNI-NATIVE.txt'));
    });
  }
  AppDatabase? database;
  try {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    database = AppDatabase.file(File('${directory.path}/jarvis.sqlite'));
    final store = LocalStore(database);
    final snapshot = await store.load();
    runApp(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          initialSnapshotProvider.overrideWithValue(snapshot),
        ],
        child: const JarvisApp(),
      ),
    );
  } catch (_) {
    await database?.close();
    runApp(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Local data could not be opened. Check disk space and application data permissions, then restart. No history has been deleted.',
                  ),
                  TextButton(
                    onPressed: main,
                    child: const Text('Retry opening local data'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
