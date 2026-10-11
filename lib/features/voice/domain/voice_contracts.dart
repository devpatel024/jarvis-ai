import '../../chat/domain/llm_provider.dart';

enum VoicePhase { idle, listening, transcribing, thinking, speaking, error }

enum VoiceError { permissionDenied, unavailable, timeout, cancelled, engine }

class VoiceFailure implements Exception {
  const VoiceFailure(this.code, this.message);
  final VoiceError code;
  final String message;
}

class AudioFrame {
  const AudioFrame(this.pcm, this.level, this.duration);
  final List<int> pcm;
  final double level;
  final Duration duration;
}

class SpeechResult {
  const SpeechResult(this.text, {this.peakRssBytes});
  final String text;
  final int? peakRssBytes;
}

class PlaybackResult {
  const PlaybackResult({required this.firstAudio, this.peakRssBytes});
  final Duration firstAudio;
  final int? peakRssBytes;
}

abstract interface class AudioInput {
  Stream<AudioFrame> capture(CancellationToken cancellation);
  Future<void> stop();
}

abstract interface class SpeechToText {
  Future<SpeechResult> transcribe(
    List<int> pcm,
    CancellationToken cancellation,
  );
}

abstract interface class TextToSpeech {
  Future<PlaybackResult> speak(
    String text,
    CancellationToken cancellation, {
    required void Function() onPlayback,
  });
  Future<void> stop();
}

abstract interface class VoiceActivityDetector {
  bool isSpeech(AudioFrame frame);
}

abstract interface class WakeWordDetector {
  Stream<bool> detect(Stream<AudioFrame> frames);
}

class EnergyVoiceActivityDetector implements VoiceActivityDetector {
  const EnergyVoiceActivityDetector({this.threshold = .015});
  final double threshold;
  @override
  bool isSpeech(AudioFrame frame) => frame.level >= threshold;
}

class VoiceMetrics {
  const VoiceMetrics({
    this.sttLatency,
    this.audioDuration,
    this.firstAudio,
    this.roundTrip,
    this.sttRss,
    this.ttsRss,
    this.llmRss,
    this.responseFirstAudio,
  });
  final Duration? sttLatency, audioDuration, firstAudio, roundTrip;
  final int? sttRss, ttsRss, llmRss;
  final Duration? responseFirstAudio;
  double? get realTimeFactor =>
      sttLatency == null ||
          audioDuration == null ||
          audioDuration!.inMicroseconds == 0
      ? null
      : sttLatency!.inMicroseconds / audioDuration!.inMicroseconds;
}

class VoiceSnapshot {
  const VoiceSnapshot({
    this.phase = VoicePhase.idle,
    this.transcript = '',
    this.reply = '',
    this.level = 0,
    this.conversation = false,
    this.failure,
    this.metrics = const VoiceMetrics(),
  });
  final VoicePhase phase;
  final String transcript, reply;
  final double level;
  final bool conversation;
  final VoiceFailure? failure;
  final VoiceMetrics metrics;
  bool get active => phase != VoicePhase.idle && phase != VoicePhase.error;
}
