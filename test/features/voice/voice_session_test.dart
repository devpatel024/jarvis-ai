import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/features/chat/domain/llm_provider.dart';
import 'package:jarvis/features/voice/domain/voice_contracts.dart';
import 'package:jarvis/features/voice/domain/voice_session_controller.dart';

class FakeAudio implements AudioInput {
  StreamController<AudioFrame>? frames;
  int starts = 0, stops = 0;
  @override
  Stream<AudioFrame> capture(CancellationToken cancellation) {
    starts++;
    frames = StreamController<AudioFrame>();
    return frames!.stream;
  }

  void speech() =>
      frames!.add(const AudioFrame([0, 1], .2, Duration(milliseconds: 100)));
  void silence() =>
      frames!.add(const AudioFrame([0, 0], 0, Duration(seconds: 1)));
  @override
  Future<void> stop() async {
    stops++;
    final previous = frames;
    frames = null;
    await previous?.close();
  }
}

class FakeStt implements SpeechToText {
  String text = 'Hello';
  VoiceFailure? failure;
  Completer<SpeechResult>? pending;
  @override
  Future<SpeechResult> transcribe(
    List<int> pcm,
    CancellationToken cancellation,
  ) async {
    if (failure != null) throw failure!;
    return pending == null ? SpeechResult(text) : pending!.future;
  }
}

class FakeTts implements TextToSpeech {
  final sentences = <String>[];
  bool playing = false, hold = false;
  VoiceFailure? failure;
  int stops = 0;
  @override
  Future<PlaybackResult> speak(
    String text,
    CancellationToken cancellation, {
    required void Function() onPlayback,
  }) async {
    if (failure != null) throw failure!;
    sentences.add(text);
    playing = true;
    onPlayback();
    if (hold) await cancellation.whenCancelled;
    playing = false;
    if (cancellation.isCancelled) {
      throw const VoiceFailure(VoiceError.cancelled, 'Stopped');
    }
    return const PlaybackResult(firstAudio: Duration(milliseconds: 5));
  }

  @override
  Future<void> stop() async {
    playing = false;
    stops++;
  }
}

class FakeLlm implements LlmProvider {
  Completer<void>? pause;
  @override
  bool get isDemo => true;
  @override
  String get label => 'Fake';
  @override
  Stream<LlmEvent> respond(
    List<LlmMessage> messages, {
    required CancellationToken cancellation,
  }) async* {
    yield const TextDelta('Hello! ');
    if (pause != null) {
      await Future.any([pause!.future, cancellation.whenCancelled]);
    }
    if (cancellation.isCancelled) return;
    yield const TextDelta('How are you today?');
    yield const LlmCompleted();
  }
}

Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 10));
void main() {
  late FakeAudio audio;
  late FakeStt stt;
  late FakeTts tts;
  late FakeLlm llm;
  late VoiceSessionController controller;
  late List<VoicePhase> phases;
  setUp(() {
    audio = FakeAudio();
    stt = FakeStt();
    tts = FakeTts();
    llm = FakeLlm();
    phases = [];
    controller = VoiceSessionController(
      audio: audio,
      stt: stt,
      tts: tts,
      vad: const EnergyVoiceActivityDetector(),
      llm: llm,
      onState: (s) => phases.add(s.phase),
      silenceTimeout: const Duration(milliseconds: 40),
      echoCooldown: Duration.zero,
    );
  });
  tearDown(() async {
    await controller.dispose();
  });
  test(
    'default never captures; PTT transcribes and speaks complete sentences',
    () async {
      expect(audio.starts, 0);
      await controller.start();
      audio.speech();
      await tick();
      await controller.finishUtterance();
      expect(tts.sentences, ['Hello!', 'How are you today?']);
      expect(
        phases,
        containsAllInOrder([
          VoicePhase.listening,
          VoicePhase.transcribing,
          VoicePhase.thinking,
          VoicePhase.speaking,
          VoicePhase.idle,
        ]),
      );
      expect(controller.state.transcript, 'Hello');
      expect(controller.state.metrics.realTimeFactor, isNotNull);
      expect(audio.frames, isNull);
    },
  );
  test(
    'first sentence plays before final LLM token; mic stays closed',
    () async {
      llm.pause = Completer();
      await controller.start();
      audio.speech();
      await tick();
      final turn = controller.finishUtterance();
      await tick();
      expect(tts.sentences, ['Hello!']);
      expect(audio.frames, isNull);
      llm.pause!.complete();
      await turn;
    },
  );
  test(
    'conversation VAD re-listens after playback and goodbye ends it',
    () async {
      await controller.start(conversation: true);
      audio.speech();
      audio.silence();
      await tick();
      await tick();
      expect(audio.starts, 2);
      expect(controller.state.phase, VoicePhase.listening);
      stt.text = 'Goodbye.';
      audio.speech();
      audio.silence();
      await tick();
      await tick();
      expect(controller.state.phase, VoicePhase.idle);
      expect(audio.starts, 2);
    },
  );
  test('silence timeout closes microphone', () async {
    await controller.start(conversation: true);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(controller.state.phase, VoicePhase.idle);
    expect(audio.frames, isNull);
  });
  test('barge-in cancels speech before opening another mic', () async {
    tts.hold = true;
    await controller.start();
    audio.speech();
    await tick();
    final turn = controller.finishUtterance();
    await tick();
    expect(tts.playing, isTrue);
    await controller.start();
    await turn;
    expect(tts.playing, isFalse);
    expect(controller.state.phase, VoicePhase.listening);
    expect(audio.starts, 2);
  });
  test('cancel mid-speech stays idle without replay or auto-listen', () async {
    tts.hold = true;
    await controller.start(conversation: true);
    audio.speech();
    await tick();
    final turn = controller.finishUtterance();
    await tick();
    await controller.stop();
    await turn;
    expect(controller.state.phase, VoicePhase.idle);
    expect(audio.starts, 1);
    expect(tts.playing, isFalse);
  });
  test('typed STT failure closes mic and exposes recovery', () async {
    stt.failure = const VoiceFailure(VoiceError.engine, 'Recognition failed');
    await controller.start();
    audio.speech();
    await tick();
    await controller.finishUtterance();
    expect(controller.state.phase, VoicePhase.error);
    expect(controller.state.failure!.message, 'Recognition failed');
    expect(audio.frames, isNull);
  });
  test('permission denial and playback errors become typed states', () async {
    await controller.start();
    audio.frames!.addError(
      const VoiceFailure(VoiceError.permissionDenied, 'Denied'),
    );
    await tick();
    expect(controller.state.failure!.code, VoiceError.permissionDenied);
    tts.failure = const VoiceFailure(VoiceError.engine, 'Playback failed');
    await controller.start();
    audio.speech();
    await tick();
    await controller.finishUtterance();
    expect(controller.state.failure!.message, 'Playback failed');
  });
  test('disable during transcription discards stale result', () async {
    stt.pending = Completer();
    await controller.start();
    audio.speech();
    await tick();
    final turn = controller.finishUtterance();
    await tick();
    await controller.setEnabled(false);
    stt.pending!.complete(const SpeechResult('Hello'));
    await turn;
    await controller.start();
    expect(controller.state.phase, VoicePhase.idle);
    expect(audio.starts, 1);
    expect(tts.sentences, isEmpty);
  });
}
