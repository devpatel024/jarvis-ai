import 'dart:async';

import '../../chat/domain/llm_provider.dart';
import 'voice_contracts.dart';

/// One bounded utterance at a time. Never opens audio until explicitly started.
class VoiceSessionController {
  VoiceSessionController({
    required this.audio,
    required this.stt,
    required this.tts,
    required this.vad,
    required this.llm,
    required this.onState,
    this.residentLlmRss,
    this.echoCooldown = const Duration(milliseconds: 350),
    this.silenceTimeout = const Duration(seconds: 10),
    this.endSilence = const Duration(milliseconds: 800),
    this.maximumUtterance = const Duration(seconds: 20),
  });
  final AudioInput audio;
  final SpeechToText stt;
  final TextToSpeech tts;
  final VoiceActivityDetector vad;
  final LlmProvider llm;
  final void Function(VoiceSnapshot) onState;
  final Future<int?> Function()? residentLlmRss;
  final Duration silenceTimeout, endSilence, maximumUtterance, echoCooldown;
  VoiceSnapshot state = const VoiceSnapshot();
  CancellationToken? _token;
  StreamSubscription<AudioFrame>? _capture;
  Timer? _timeout, _maximum;
  final _pcm = <int>[];
  Duration _duration = Duration.zero, _quiet = Duration.zero;
  bool _heard = false, _enabled = true, _disposed = false;
  int _generation = 0;
  Future<void> _cleanup = Future.value();
  void _emit(VoiceSnapshot next) {
    if (_disposed) return;
    state = next;
    onState(next);
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (!enabled) await stop();
  }

  Future<void> start({bool conversation = false}) async {
    if (!_enabled || _disposed) return;
    // Barge-in cancels synthesis, playback, inference and capture before rearming.
    final cleanup = stop();
    final generation = _generation;
    await cleanup;
    if (!_enabled || _disposed || generation != _generation) return;
    _listen(conversation);
  }

  void _listen(bool conversation) {
    final generation = ++_generation;
    final token = CancellationToken();
    _token = token;
    _pcm.clear();
    _duration = Duration.zero;
    _quiet = Duration.zero;
    _heard = false;
    _emit(
      VoiceSnapshot(
        phase: VoicePhase.listening,
        conversation: conversation,
        transcript: state.transcript,
        reply: state.reply,
        metrics: state.metrics,
      ),
    );
    _timeout = Timer(silenceTimeout, () {
      if (generation == _generation && !_heard) unawaited(stop());
    });
    _maximum = Timer(maximumUtterance, () {
      if (generation == _generation) unawaited(finishUtterance());
    });
    _capture = audio
        .capture(token)
        .listen(
          (frame) {
            if (generation != _generation ||
                state.phase != VoicePhase.listening) {
              return;
            }
            _duration += frame.duration;
            if (_pcm.length + frame.pcm.length > 640000) {
              unawaited(finishUtterance());
              return;
            }
            _pcm.addAll(frame.pcm);
            final speech = vad.isSpeech(frame);
            if (speech) {
              _heard = true;
              _quiet = Duration.zero;
              _timeout?.cancel();
            } else {
              _quiet += frame.duration;
            }
            _emit(
              VoiceSnapshot(
                phase: VoicePhase.listening,
                level: frame.level,
                conversation: conversation,
                transcript: state.transcript,
                reply: state.reply,
                metrics: state.metrics,
              ),
            );
            if (conversation && _heard && _quiet >= endSilence) {
              unawaited(finishUtterance());
            }
          },
          onError: (Object error) {
            if (generation == _generation) unawaited(_fail(error));
          },
          onDone: () {
            if (generation == _generation &&
                state.phase == VoicePhase.listening) {
              unawaited(
                _fail(
                  const VoiceFailure(
                    VoiceError.unavailable,
                    'Microphone capture ended. Check microphone access.',
                  ),
                ),
              );
            }
          },
        );
  }

  Future<void> finishUtterance() async {
    if (state.phase != VoicePhase.listening) return;
    final generation = _generation,
        token = _token!,
        conversation = state.conversation;
    final pcm = List<int>.of(_pcm), duration = _duration;
    _timeout?.cancel();
    _maximum?.cancel();
    _emit(
      VoiceSnapshot(phase: VoicePhase.transcribing, conversation: conversation),
    );
    final capture = _capture;
    _capture = null;
    await audio.stop();
    await capture?.cancel(); // Microphone stays closed throughout STT/LLM/TTS.
    if (!_valid(generation, token)) return;
    if (!_heard || pcm.isEmpty) {
      await stop();
      return;
    }
    final turn = Stopwatch()..start();
    final recognition = Stopwatch()..start();
    try {
      final result = await stt.transcribe(pcm, token);
      if (!_valid(generation, token)) return;
      recognition.stop();
      final transcript = result.text.trim();
      if (transcript.isEmpty) {
        throw const VoiceFailure(
          VoiceError.engine,
          'No speech recognized. Try again closer to the microphone.',
        );
      }
      if (RegExp(
        r'^(stop|goodbye|good bye)[.!?]*$',
        caseSensitive: false,
      ).hasMatch(transcript)) {
        await stop();
        return;
      }
      var reply = '', pending = '';
      var completed = false;
      Duration? firstAudio, responseFirstAudio;
      var llmRss = await residentLlmRss?.call();
      if (!_valid(generation, token)) return;
      int? ttsRss;
      var chain = Future<void>.value();
      Object? playbackError;
      VoiceMetrics metrics({bool complete = false}) => VoiceMetrics(
        sttLatency: recognition.elapsed,
        audioDuration: duration,
        firstAudio: firstAudio,
        roundTrip: complete ? turn.elapsed : null,
        sttRss: result.peakRssBytes,
        ttsRss: ttsRss,
        llmRss: llmRss,
        responseFirstAudio: responseFirstAudio,
      );
      void emit(VoicePhase phase) => _emit(
        VoiceSnapshot(
          phase: phase,
          conversation: conversation,
          transcript: transcript,
          reply: reply,
          metrics: metrics(),
        ),
      );
      void queue(String sentence) {
        final spoken = sentence.replaceAll(RegExp(r'[`*_#]'), '').trim();
        if (spoken.isEmpty) return;
        chain = chain
            .then((_) async {
              if (!_valid(generation, token)) return;
              final playback = await tts.speak(
                spoken,
                token,
                onPlayback: () {
                  if (_valid(generation, token)) {
                    responseFirstAudio ??= turn.elapsed;
                    emit(VoicePhase.speaking);
                  }
                },
              );
              firstAudio ??= playback.firstAudio;
              final rss = playback.peakRssBytes;
              if (rss != null && (ttsRss == null || rss > ttsRss!)) {
                ttsRss = rss;
              }
              if (_valid(generation, token)) emit(VoicePhase.thinking);
            })
            .catchError((Object error) {
              playbackError = error;
              token.cancel();
            });
      }

      emit(VoicePhase.thinking);
      await for (final event
          in llm
              .respond([
                LlmMessage(MessageRole.user, transcript),
              ], cancellation: token)
              .timeout(const Duration(seconds: 95))) {
        if (!_valid(generation, token)) break;
        if (event is LlmFailed) {
          throw VoiceFailure(VoiceError.engine, event.failure.message);
        }
        if (event is LlmCompleted) completed = true;
        if (event is TextDelta) {
          reply += event.text;
          pending += event.text;
          final boundary = RegExp(r'[.!?](?:\s|$)');
          while (true) {
            final match = boundary.firstMatch(pending);
            if (match == null) break;
            queue(pending.substring(0, match.end));
            pending = pending.substring(match.end);
          }
          emit(state.phase);
        }
      }
      if (_valid(generation, token) && !completed) {
        throw const VoiceFailure(
          VoiceError.engine,
          'The reply ended before completion. Try again.',
        );
      }
      if (_valid(generation, token)) queue(pending);
      llmRss = await residentLlmRss?.call() ?? llmRss;
      await chain;
      if (playbackError != null && generation == _generation) {
        throw playbackError!;
      }
      if (!_valid(generation, token)) return;
      turn.stop();
      _emit(
        VoiceSnapshot(
          transcript: transcript,
          reply: reply,
          conversation: conversation,
          metrics: metrics(complete: true),
        ),
      );
      token.cancel();
      if (conversation && _enabled) {
        final cooldown = CancellationToken();
        _token = cooldown;
        if (await cooldown.wait(echoCooldown) &&
            generation == _generation &&
            _enabled) {
          _listen(true);
        }
      }
    } catch (error) {
      if (generation == _generation) await _fail(error);
    } finally {
      if (token.isCancelled && generation == _generation && state.active) {
        await stop();
      }
    }
  }

  bool _valid(int generation, CancellationToken token) =>
      !_disposed && generation == _generation && !token.isCancelled;
  Future<void> _fail(Object error) async {
    final failure = error is VoiceFailure
        ? error
        : const VoiceFailure(
            VoiceError.engine,
            'Voice engine failed. Check the installed engines and retry.',
          );
    await stop();
    if (failure.code == VoiceError.cancelled) return;
    _emit(
      VoiceSnapshot(
        phase: VoicePhase.error,
        transcript: state.transcript,
        reply: state.reply,
        failure: failure,
        metrics: state.metrics,
      ),
    );
  }

  Future<void> stop() async {
    _generation++;
    _token?.cancel();
    _timeout?.cancel();
    _maximum?.cancel();
    final capture = _capture;
    _capture = null;
    _pcm.clear();
    _emit(
      VoiceSnapshot(
        transcript: state.transcript,
        reply: state.reply,
        metrics: state.metrics,
      ),
    );
    // Kill native capture/playback immediately, before waiting on stream cancel.
    // Cancelling an async generator first can wait forever for its next chunk.
    final micStop = audio.stop(), speechStop = tts.stop();
    _cleanup = _cleanup.then((_) async {
      await Future.wait([micStop, speechStop]);
      await capture?.cancel();
    });
    await _cleanup;
  }

  Future<void> dispose() async {
    await stop();
    _disposed = true;
  }
}
