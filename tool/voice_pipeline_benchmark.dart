// Existing prerecorded synthetic clip -> real STT -> real Ollama -> speakers.
// Never opens the microphone or saves recording. Usage: dart run ... ROOT CLIP OUTPUT
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:jarvis/features/chat/data/ollama_provider.dart';
import 'package:jarvis/features/chat/domain/llm_provider.dart';
import 'package:jarvis/features/chat/domain/llm_settings.dart';
import 'package:jarvis/features/voice/data/process_voice_engines.dart';
import 'package:jarvis/features/voice/domain/voice_contracts.dart';
import 'package:jarvis/features/voice/domain/voice_session_controller.dart';

class FixtureAudio implements AudioInput {
  StreamController<AudioFrame>? frames;
  @override
  Stream<AudioFrame> capture(CancellationToken cancellation) =>
      (frames = StreamController<AudioFrame>()).stream;
  @override
  Future<void> stop() async {
    if (frames != null && !frames!.isClosed) await frames!.close();
  }
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 3) throw ArgumentError('ROOT CLIP OUTPUT required');
  final directory = EngineDirectory(arguments[0], useWhisper: true);
  final clip = (await File(arguments[1]).readAsBytes()).sublist(44);
  final audio = FixtureAudio(), service = OllamaService();
  final states = <String>[];
  final controller = VoiceSessionController(
    audio: audio,
    stt: ProcessSpeechToText(directory),
    tts: ProcessTextToSpeech(directory),
    vad: const EnergyVoiceActivityDetector(),
    llm: OllamaProvider(
      service,
      const LlmSettings(spoken: true, language: ReplyLanguage.english),
    ),
    residentLlmRss: residentOllamaRss,
    onState: (state) {
      states.add(state.phase.name);
    },
  );
  try {
    await controller.start();
    audio.frames!.add(
      AudioFrame(
        clip,
        .1,
        Duration(microseconds: clip.length * 1000000 ~/ 32000),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await controller.finishUtterance();
    final s = controller.state, m = s.metrics;
    final result = {
      'date': DateTime.now().toUtc().toIso8601String(),
      'fixture': 'eSpeak synthetic greeting; no live mic',
      'transcript': s.transcript,
      'reply': s.reply,
      'failure': s.failure?.message,
      'states': states,
      'stt_ms': m.sttLatency?.inMilliseconds,
      'stt_rtf': m.realTimeFactor,
      'tts_first_audio_queued_ms': m.firstAudio?.inMilliseconds,
      'end_capture_to_first_queued_audio_ms':
          m.responseFirstAudio?.inMilliseconds,
      'round_trip_ms': m.roundTrip?.inMilliseconds,
      'stt_peak_rss_bytes': m.sttRss,
      'tts_player_peak_rss_bytes': m.ttsRss,
      'ollama_rss_snapshot_bytes': m.llmRss,
      'note':
          'Actual Linux player process; time is first PCM queued, not acoustically measured speaker onset. Cold Ollama if /api/ps empty beforehand; uncontrolled desktop load.',
    };
    await File(
      arguments[2],
    ).writeAsString('${const JsonEncoder.withIndent('  ').convert(result)}\n');
    stdout.writeln(jsonEncode(result));
    if (s.failure != null) exitCode = 1;
  } finally {
    await controller.dispose();
    await service.unload('llama3.2:1b');
    service.close();
  }
}
