import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../chat/domain/llm_provider.dart';
import '../domain/voice_contracts.dart';

/// External processes only. No network, shell evaluation, automatic downloads,
/// audio files, or in-app GPL linkage. PCM is bounded and held in memory.
class EngineDirectory {
  const EngineDirectory(this.path, {this.useWhisper = false});
  final String path;
  final bool useWhisper;
  String get vosk => '$path/voice-vosk${Platform.isWindows ? '.exe' : ''}';
  String get voskModel => '$path/vosk-model-small-en-us-0.15';
  String get whisper =>
      '$path/whisper-build/bin/whisper-cli${Platform.isWindows ? '.exe' : ''}';
  String get whisperModel => '$path/ggml-tiny.en.bin';
  String get windowsAudio => '$path/voice-audio.exe';
  Future<void> verify() async {
    if (!Platform.isLinux && !Platform.isWindows) {
      throw const VoiceFailure(
        VoiceError.unavailable,
        'Offline voice is currently desktop only. Use English or Gujarati text on this platform.',
      );
    }
    if (Platform.isWindows && useWhisper) {
      throw const VoiceFailure(
        VoiceError.unavailable,
        'This pinned Whisper CLI writes CON on Windows rather than the redirected pipe. Select Vosk for memory-only Windows voice, or use text.',
      );
    }
    final engine = useWhisper ? whisper : vosk;
    if (path.isEmpty ||
        !await File(engine).exists() ||
        !(useWhisper
            ? await File(whisperModel).exists()
            : await Directory(voskModel).exists())) {
      throw const VoiceFailure(
        VoiceError.unavailable,
        'Configure the approved voice engines folder in Settings. See docs/VOICE_SETUP.md; nothing is downloaded automatically.',
      );
    }
    if (Platform.isWindows && !await File(windowsAudio).exists()) {
      throw const VoiceFailure(
        VoiceError.unavailable,
        'Windows needs the voice-audio.exe process adapter. See docs/VOICE_SETUP.md. Windows hardware validation is pending.',
      );
    }
  }
}

class ProcessMemory {
  final _peaks = <int, int>{};
  Timer? _timer;
  void watch(Iterable<Process> processes) {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!Platform.isLinux) return;
      for (final process in processes) {
        try {
          final match = RegExp(
            r'VmRSS:\s+(\d+)',
          ).firstMatch(File('/proc/${process.pid}/status').readAsStringSync());
          if (match != null) {
            _peaks[process.pid] = math.max(
              _peaks[process.pid] ?? 0,
              int.parse(match[1]!) * 1024,
            );
          }
        } on FileSystemException {
          /* Process may have just exited. */
        }
      }
    });
  }

  int? get peak =>
      _peaks.isEmpty ? null : _peaks.values.fold<int>(0, (a, b) => a + b);
  void close() => _timer?.cancel();
}

Future<Process> _start(String executable, List<String> arguments) async {
  try {
    return await Process.start(
      executable,
      arguments,
      environment: const {
        'OPENBLAS_NUM_THREADS': '2',
        'OMP_NUM_THREADS': '2',
        'MKL_NUM_THREADS': '2',
      },
    );
  } on ProcessException {
    throw const VoiceFailure(
      VoiceError.unavailable,
      'Voice executable is missing or cannot start. Check voice setup and microphone permissions.',
    );
  }
}

void _cancelProcess(Process process, CancellationToken token) {
  unawaited(
    token.whenCancelled.then((_) {
      process.kill(
        Platform.isWindows ? ProcessSignal.sigterm : ProcessSignal.sigkill,
      );
    }),
  );
}

void _checkCancelled(CancellationToken token) {
  if (token.isCancelled) {
    throw const VoiceFailure(VoiceError.cancelled, 'Voice stopped.');
  }
}

class ProcessAudioInput implements AudioInput {
  ProcessAudioInput(this.directory);
  final EngineDirectory directory;
  Process? _process;
  @override
  Stream<AudioFrame> capture(CancellationToken cancellation) async* {
    await directory.verify();
    _checkCancelled(cancellation);
    final process = await _start(
      Platform.isLinux ? 'arecord' : directory.windowsAudio,
      Platform.isLinux
          ? [
              '-q',
              '-D',
              'default',
              '-t',
              'raw',
              '-f',
              'S16_LE',
              '-r',
              '16000',
              '-c',
              '1',
            ]
          : ['capture'],
    );
    _process = process;
    _cancelProcess(process, cancellation);
    // Keep bounded native diagnostics in memory for explicit recovery only.
    final diagnostics = StringBuffer();
    final errors = process.stderr.transform(utf8.decoder).listen((text) {
      if (diagnostics.length < 2048) {
        diagnostics.write(
          text.substring(0, math.min(text.length, 2048 - diagnostics.length)),
        );
      }
    });
    final errorsDone = errors.asFuture<void>();
    var leftover = <int>[];
    try {
      await for (final chunk in process.stdout) {
        if (cancellation.isCancelled) break;
        final bytes = [...leftover, ...chunk];
        final even = bytes.length - bytes.length % 2;
        leftover = bytes.sublist(even);
        if (even == 0) continue;
        final data = Uint8List.fromList(bytes.sublist(0, even));
        final view = ByteData.sublistView(data);
        var squared = 0.0;
        for (var i = 0; i < even; i += 2) {
          final sample = view.getInt16(i, Endian.little) / 32768;
          squared += sample * sample;
        }
        yield AudioFrame(
          data,
          math.sqrt(squared / (even / 2)).clamp(0, 1),
          Duration(microseconds: even * 1000000 ~/ 32000),
        );
      }
      if (!cancellation.isCancelled && await process.exitCode != 0) {
        await errorsDone;
        throw VoiceFailure(
          VoiceError.permissionDenied,
          'Default microphone unavailable. ${diagnostics.toString().trim()}${Platform.isLinux ? ' Device list: arecord -l' : ' Check OS microphone permissions.'}',
        );
      }
    } finally {
      await stop();
      await errors.cancel();
    }
  }

  @override
  Future<void> stop() async {
    final process = _process;
    _process = null;
    if (process != null) {
      process.kill(
        Platform.isWindows ? ProcessSignal.sigterm : ProcessSignal.sigkill,
      );
      await process.exitCode;
    }
  }
}

class ProcessSpeechToText implements SpeechToText {
  const ProcessSpeechToText(this.directory);
  final EngineDirectory directory;
  @override
  Future<SpeechResult> transcribe(
    List<int> pcm,
    CancellationToken cancellation,
  ) async {
    await directory.verify();
    _checkCancelled(cancellation);
    final whisper = directory.useWhisper;
    final process = await _start(
      whisper ? directory.whisper : directory.vosk,
      whisper
          ? [
              '-m',
              directory.whisperModel,
              '-f',
              '-',
              '-t',
              '2',
              '-l',
              'en',
              '-ng',
              '-nt',
              '-otxt',
              '-of',
              '-',
            ]
          : [directory.voskModel],
    );
    _cancelProcess(process, cancellation);
    final memory = ProcessMemory()..watch([process]);
    final output = utf8.decoder.bind(process.stdout).join();
    unawaited(process.stderr.drain<void>());
    try {
      process.stdin.add(whisper ? _wav(pcm) : pcm);
      await process.stdin.close();
      if (await process.exitCode.timeout(const Duration(seconds: 90)) != 0) {
        _checkCancelled(cancellation);
        throw const VoiceFailure(
          VoiceError.engine,
          'Speech recognition failed. Check the pinned model and retry.',
        );
      }
      _checkCancelled(cancellation);
      final text = await output;
      return SpeechResult(
        whisper
            ? text.trim()
            : (jsonDecode(text) as Map<String, dynamic>)['text'] as String,
        peakRssBytes: memory.peak,
      );
    } on TimeoutException {
      throw const VoiceFailure(
        VoiceError.timeout,
        'Speech recognition timed out. Try a shorter utterance.',
      );
    } finally {
      memory.close();
      process.kill();
    }
  }
}

Uint8List _wav(List<int> pcm) {
  final bytes = Uint8List(44 + pcm.length), data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, ascii.encode('RIFF'));
  data.setUint32(4, pcm.length + 36, Endian.little);
  bytes.setRange(8, 16, ascii.encode('WAVEfmt '));
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 16000, Endian.little);
  data.setUint32(28, 32000, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  bytes.setRange(36, 40, ascii.encode('data'));
  data.setUint32(40, pcm.length, Endian.little);
  bytes.setRange(44, bytes.length, pcm);
  return bytes;
}

class ProcessTextToSpeech implements TextToSpeech {
  ProcessTextToSpeech(this.directory);
  final EngineDirectory directory;
  Process? _synth, _player;
  @override
  Future<PlaybackResult> speak(
    String text,
    CancellationToken cancellation, {
    required void Function() onPlayback,
  }) async {
    _checkCancelled(cancellation);
    final watch = Stopwatch()..start();
    final synth = await _start('espeak-ng', [
      '--stdout',
      '-v',
      'en-us',
      '-s',
      '170',
      '--stdin',
    ]);
    _synth = synth;
    _cancelProcess(synth, cancellation);
    final player = await _start(
      Platform.isLinux ? 'aplay' : directory.windowsAudio,
      Platform.isLinux ? ['-q'] : ['play'],
    );
    _player = player;
    _cancelProcess(player, cancellation);
    final memory = ProcessMemory()..watch([synth, player]);
    unawaited(synth.stderr.drain<void>());
    unawaited(player.stderr.drain<void>());
    Duration? firstAudio;
    try {
      synth.stdin.add(utf8.encode(text));
      await synth.stdin.close();
      await for (final chunk in synth.stdout) {
        _checkCancelled(cancellation);
        player.stdin.add(chunk);
        await player.stdin.flush();
        if (chunk.length > 44 && firstAudio == null) {
          firstAudio = watch.elapsed;
          onPlayback();
        }
      }
      await player.stdin.close();
      final codes = await Future.wait([
        synth.exitCode,
        player.exitCode,
      ]).timeout(const Duration(seconds: 45));
      _checkCancelled(cancellation);
      if (codes.any((c) => c != 0) || firstAudio == null) {
        throw const VoiceFailure(
          VoiceError.engine,
          'Speech playback failed. Check the selected speaker or headphones.',
        );
      }
      return PlaybackResult(firstAudio: firstAudio, peakRssBytes: memory.peak);
    } on TimeoutException {
      throw const VoiceFailure(
        VoiceError.timeout,
        'Speech playback timed out.',
      );
    } finally {
      memory.close();
      await stop();
    }
  }

  @override
  Future<void> stop() async {
    final processes = [_synth, _player];
    _synth = null;
    _player = null;
    for (final p in processes) {
      p?.kill(
        Platform.isWindows ? ProcessSignal.sigterm : ProcessSignal.sigkill,
      );
    }
    for (final p in processes) {
      if (p != null) await p.exitCode;
    }
  }
}

Future<int?> residentOllamaRss() async {
  if (!Platform.isLinux) return null;
  var total = 0;
  await for (final entry in Directory('/proc').list()) {
    if (!RegExp(r'/\d+$').hasMatch(entry.path)) continue;
    try {
      final name = (await File('${entry.path}/comm').readAsString()).trim();
      if (name != 'ollama' && name != 'llama-server') continue;
      final match = RegExp(
        r'VmRSS:\s+(\d+)',
      ).firstMatch(await File('${entry.path}/status').readAsString());
      if (match != null) total += int.parse(match[1]!) * 1024;
    } on FileSystemException {
      /* Processes can exit during the sample. */
    }
  }
  return total;
}
