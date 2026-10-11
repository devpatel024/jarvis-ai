import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_store.dart';
import '../domain/llm_settings.dart';
import '../data/ollama_provider.dart';

final ollamaServiceProvider = Provider((ref) {
  final service = OllamaService();
  ref.onDispose(service.close);
  return service;
});

class ProviderSettings extends Notifier<LlmSettings> {
  @override
  LlmSettings build() {
    final saved = ref.read(initialSnapshotProvider).settings;
    final model = saved['model'];
    return LlmSettings(
      model: ['llama3.2:1b', 'llama3.2:3b', 'Mock demo'].contains(model)
          ? model!
          : ref.read(localStoreProvider) == null
          ? 'Mock demo'
          : 'llama3.2:1b',
      contextLength:
          [1024, 2048, 4096].contains(int.tryParse(saved['context'] ?? ''))
          ? int.parse(saved['context']!)
          : 2048,
      language:
          savedEnum(ref, 'language', ReplyLanguage.values) ??
          ReplyLanguage.matchInput,
      keepAliveSeconds:
          [0, 30, 60].contains(int.tryParse(saved['keepAlive'] ?? ''))
          ? int.parse(saved['keepAlive']!)
          : 30,
    );
  }

  void update({
    String? model,
    int? context,
    ReplyLanguage? language,
    int? keepAlive,
  }) {
    if (model != null &&
        !['llama3.2:1b', 'llama3.2:3b', 'Mock demo'].contains(model)) {
      throw ArgumentError.value(model);
    }
    if (context != null && ![1024, 2048, 4096].contains(context)) {
      throw ArgumentError.value(context);
    }
    if (keepAlive != null && ![0, 30, 60].contains(keepAlive)) {
      throw ArgumentError.value(keepAlive);
    }
    state = LlmSettings(
      model: model ?? state.model,
      contextLength: context ?? state.contextLength,
      language: language ?? state.language,
      keepAliveSeconds: keepAlive ?? state.keepAliveSeconds,
    );
    persistSetting(ref, 'model', state.model);
    persistSetting(ref, 'context', '${state.contextLength}');
    persistSetting(ref, 'language', state.language.name);
    persistSetting(ref, 'keepAlive', '${state.keepAliveSeconds}');
  }
}

final providerSettingsProvider =
    NotifierProvider<ProviderSettings, LlmSettings>(ProviderSettings.new);
