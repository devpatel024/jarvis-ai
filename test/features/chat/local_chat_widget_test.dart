import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/app/jarvis_app.dart';
import 'package:jarvis/core/design/motion_settings.dart';
import 'package:jarvis/core/storage/local_store.dart';
import 'package:jarvis/features/chat/domain/llm_provider.dart';
import 'package:jarvis/features/chat/data/ollama_provider.dart';
import 'package:jarvis/features/chat/presentation/chat_controller.dart';
import 'package:jarvis/features/chat/presentation/provider_settings.dart';

class FailedLocalProvider implements LlmProvider {
  const FailedLocalProvider(this.failure);
  final LlmFailure failure;
  @override
  bool get isDemo => false;
  @override
  String get label => 'llama3.2:1b';
  @override
  Stream<LlmEvent> respond(
    List<LlmMessage> messages, {
    required CancellationToken cancellation,
  }) async* {
    yield LlmFailed(failure);
  }
}

class FakeOllamaService extends OllamaService {
  final unloaded = <String>[];
  @override
  Future<Map<String, dynamic>> json(
    String path, {
    Map<String, Object?>? body,
  }) async => {
    'models': [
      {'name': 'llama3.2:1b'},
    ],
  };
  @override
  Future<void> unload(String model) async {
    unloaded.add(model);
  }
}

void main() {
  testWidgets(
    'Top-bar model switch unloads old model before selection and retains demo choice',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakeOllamaService();
      final scope = ProviderContainer(
        overrides: [
          initialSnapshotProvider.overrideWithValue(
            const LocalSnapshot(settings: {'model': 'llama3.2:1b'}),
          ),
          ollamaServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(scope.dispose);
      scope.read(reduceMotionProvider.notifier).setReduced(true);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: scope, child: const JarvisApp()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Choose local model'));
      await tester.pumpAndSettle();
      expect(find.text('Mock demo · scripted'), findsOneWidget);
      await tester.tap(find.text('llama3.2:3b · quality'));
      await tester.pumpAndSettle();
      expect(service.unloaded, ['llama3.2:1b']);
      expect(scope.read(providerSettingsProvider).model, 'llama3.2:3b');
      expect(find.text('llama3.2:3b'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final failure in [
    const LlmFailure(
      LlmErrorCode.unavailable,
      'Ollama is not running. Run: ollama serve.',
    ),
    const LlmFailure(
      LlmErrorCode.modelMissing,
      'Model not pulled. Run: ollama pull llama3.2:1b.',
    ),
    const LlmFailure(
      LlmErrorCode.contextLimit,
      'Shorten this message or increase context in Settings.',
    ),
  ]) {
    testWidgets('Local ${failure.code.name} shows recovery and retry', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final scope = ProviderContainer(
        overrides: [
          initialSnapshotProvider.overrideWithValue(
            const LocalSnapshot(settings: {'model': 'llama3.2:1b'}),
          ),
          llmProvider.overrideWithValue(FailedLocalProvider(failure)),
        ],
      );
      addTearDown(scope.dispose);
      scope.read(reduceMotionProvider.notifier).setReduced(true);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: scope, child: const JarvisApp()),
      );
      await tester.pumpAndSettle();
      expect(scope.read(providerSettingsProvider).model, 'llama3.2:1b');
      expect(find.text('llama3.2:1b'), findsWidgets);
      await scope.read(chatProvider.notifier).send('ગુજરાતી પ્રશ્ન');
      await tester.pumpAndSettle();
      expect(find.text(failure.message), findsOneWidget);
      expect(find.text('Jarvis · llama3.2:1b'), findsOneWidget);
      expect(find.text('Jarvis · scripted demo'), findsNothing);
      expect(find.text('Retry reply'), findsOneWidget);
      expect(find.text('ગુજરાતી પ્રશ્ન'), findsWidgets);
      await tester.tap(find.text('Retry reply'));
      await tester.pumpAndSettle();
      expect(scope.read(chatProvider).entries, hasLength(2));
      expect(tester.takeException(), isNull);
    });
  }
}
