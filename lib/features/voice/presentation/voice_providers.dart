import 'dart:io';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

import '../../../core/storage/local_store.dart';
import '../../chat/domain/llm_provider.dart';
import '../../chat/presentation/chat_controller.dart';
import '../../chat/presentation/provider_settings.dart';
import '../domain/voice_contracts.dart';
import '../domain/voice_session_controller.dart';
import '../data/process_voice_engines.dart';

class VoiceSettingsState {
  const VoiceSettingsState({
    this.enabled = false,
    this.directory = const String.fromEnvironment('JARVIS_VOICE_ENGINE_DIR'),
    this.whisper = true,
  });
  final bool enabled, whisper;
  final String directory;
}

class VoiceSettings extends Notifier<VoiceSettingsState> {
  @override
  VoiceSettingsState build() {
    final saved = ref.read(initialSnapshotProvider).settings;
    return VoiceSettingsState(
      enabled: saved['voiceEnabled'] == 'true',
      directory:
          saved['voiceDirectory'] ??
          const String.fromEnvironment('JARVIS_VOICE_ENGINE_DIR'),
      whisper: saved['voiceWhisper'] == null
          ? !Platform.isWindows
          : saved['voiceWhisper'] == 'true',
    );
  }

  void update({bool? enabled, String? directory, bool? whisper}) {
    // Stop active capture/playback before changing capabilities or paths.
    unawaited(ref.read(voiceSessionProvider.notifier).stop());
    state = VoiceSettingsState(
      enabled: enabled ?? state.enabled,
      directory: directory ?? state.directory,
      whisper: whisper ?? state.whisper,
    );
    persistSetting(ref, 'voiceEnabled', '${state.enabled}');
    persistSetting(ref, 'voiceDirectory', state.directory);
    persistSetting(ref, 'voiceWhisper', '${state.whisper}');
  }
}

final voiceSettingsProvider =
    NotifierProvider<VoiceSettings, VoiceSettingsState>(VoiceSettings.new);
final engineDirectoryProvider = Provider((ref) {
  final settings = ref.watch(voiceSettingsProvider);
  return EngineDirectory(settings.directory, useWhisper: settings.whisper);
});
final audioInputProvider = Provider<AudioInput>(
  (ref) => ProcessAudioInput(ref.watch(engineDirectoryProvider)),
);
final speechToTextProvider = Provider<SpeechToText>(
  (ref) => ProcessSpeechToText(ref.watch(engineDirectoryProvider)),
);
final textToSpeechProvider = Provider<TextToSpeech>(
  (ref) => ProcessTextToSpeech(ref.watch(engineDirectoryProvider)),
);
final voiceActivityDetectorProvider = Provider<VoiceActivityDetector>(
  (ref) => const EnergyVoiceActivityDetector(),
);

class ChatVoiceProvider implements LlmProvider {
  ChatVoiceProvider(this.controller);
  final ChatController controller;
  @override
  bool get isDemo => false;
  @override
  String get label => 'Selected chat provider (voice)';
  @override
  Stream<LlmEvent> respond(
    List<LlmMessage> messages, {
    required CancellationToken cancellation,
  }) => controller.respondForVoice(messages.last.text, cancellation);
}

class VoiceSession extends Notifier<VoiceSnapshot> {
  VoiceSessionController? _controller;
  @override
  VoiceSnapshot build() {
    ref.watch(voiceSettingsProvider);
    var alive = true;
    final controller = VoiceSessionController(
      audio: ref.watch(audioInputProvider),
      stt: ref.watch(speechToTextProvider),
      tts: ref.watch(textToSpeechProvider),
      vad: ref.watch(voiceActivityDetectorProvider),
      llm: ChatVoiceProvider(ref.read(chatProvider.notifier)),
      residentLlmRss: residentOllamaRss,
      onState: (next) {
        if (alive && ref.mounted) state = next;
      },
    );
    _controller = controller;
    final lifecycle = AppLifecycleListener(
      onInactive: () => unawaited(controller.stop()),
      onHide: () => unawaited(controller.stop()),
      onDetach: () => unawaited(controller.stop()),
    );
    ref.onDispose(() {
      alive = false;
      lifecycle.dispose();
      unawaited(controller.dispose());
    });
    // Default is disabled. Building this provider never starts a microphone.
    ref.listen(providerSettingsProvider, (_, next) {
      unawaited(controller.stop());
    });
    ref.listen(chatProvider.select((chat) => chat.activeId), (_, next) {
      unawaited(controller.stop());
    });
    ref.listen(voiceSettingsProvider, (_, next) {
      if (!next.enabled) unawaited(controller.stop());
    });
    return const VoiceSnapshot();
  }

  Future<void> start({bool conversation = false}) async {
    if (ref.read(voiceSettingsProvider).enabled) {
      await _controller?.start(conversation: conversation);
    }
  }

  Future<void> finish() async => _controller?.finishUtterance();
  Future<void> stop() async => _controller?.stop();
}

final voiceSessionProvider = NotifierProvider<VoiceSession, VoiceSnapshot>(
  VoiceSession.new,
);
