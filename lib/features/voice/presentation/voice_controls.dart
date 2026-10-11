import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_theme.dart';
import '../../chat/presentation/chat_controller.dart';
import '../domain/voice_contracts.dart';
import 'voice_providers.dart';

class VoiceKeyboard extends ConsumerStatefulWidget {
  const VoiceKeyboard({
    super.key,
    required this.child,
    required this.isEditing,
  });
  final Widget child;
  final bool Function() isEditing;
  @override
  ConsumerState<VoiceKeyboard> createState() => _VoiceKeyboardState();
}

class _VoiceKeyboardState extends ConsumerState<VoiceKeyboard> {
  bool _held = false;
  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    onKeyEvent: (_, event) {
      if (event.logicalKey != LogicalKeyboardKey.space ||
          widget.isEditing() ||
          !ref.read(voiceSettingsProvider).enabled) {
        return KeyEventResult.ignored;
      }
      final controller = ref.read(voiceSessionProvider.notifier);
      if (event is KeyDownEvent) {
        _held = true;
        if (ref.read(chatProvider).busy &&
            !ref.read(voiceSessionProvider).active) {
          ref.read(chatProvider.notifier).stop();
        }
        unawaited(
          controller.start().then((_) {
            if (!_held) unawaited(controller.finish());
          }),
        );
      } else if (event is KeyUpEvent) {
        _held = false;
        unawaited(controller.finish());
      }
      return KeyEventResult.handled;
    },
    child: widget.child,
  );
}

class VoiceControls extends ConsumerStatefulWidget {
  const VoiceControls({super.key});
  @override
  ConsumerState<VoiceControls> createState() => _VoiceControlsState();
}

class _VoiceControlsState extends ConsumerState<VoiceControls> {
  bool _held = false;
  Future<bool> _permission() async {
    if (ref.read(voiceSettingsProvider).enabled) return true;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable offline English voice?'),
        content: const Text(
          'The microphone opens only when you start it. Audio stays in memory and is discarded after transcription. It is not recorded or uploaded. Offline speech engines and speakers must be configured in Settings. Your transcript and reply are saved as ordinary local chat history. You can disable voice at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable voice'),
          ),
        ],
      ),
    );
    if (!mounted || yes != true) return false;
    ref.read(voiceSettingsProvider.notifier).update(enabled: true);
    return true;
  }

  Future<void> _start(bool conversation) async {
    if (!await _permission() || !mounted) return;
    if (ref.read(chatProvider).busy && !ref.read(voiceSessionProvider).active) {
      ref.read(chatProvider.notifier).stop();
    }
    await ref
        .read(voiceSessionProvider.notifier)
        .start(conversation: conversation);
    if (!conversation && !_held && mounted) {
      await ref.read(voiceSessionProvider.notifier).finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final voice = ref.watch(voiceSessionProvider);
    final controller = ref.read(voiceSessionProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Semantics(
              button: true,
              label: 'Microphone: tap conversation, hold push to talk',
              child: GestureDetector(
                key: const ValueKey('voice-mic'),
                onTap: () {
                  if (voice.phase == VoicePhase.listening) {
                    unawaited(controller.stop());
                  } else {
                    unawaited(_start(true));
                  }
                },
                onLongPressStart: (_) {
                  _held = true;
                  unawaited(_start(false));
                },
                onLongPressEnd: (_) {
                  _held = false;
                  unawaited(controller.finish());
                },
                child: Tooltip(
                  message:
                      'Tap for conversation; hold to talk. Hold Space outside the text field.',
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.smallSpacing),
                    child: Icon(
                      voice.phase == VoicePhase.listening
                          ? Icons.mic
                          : Icons.mic_none,
                      color: voice.phase == VoicePhase.listening
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  voice.phase == VoicePhase.listening
                      ? 'Listening · microphone active'
                      : voice.phase == VoicePhase.transcribing
                      ? 'Transcribing locally · microphone off'
                      : voice.phase == VoicePhase.thinking
                      ? 'Thinking · microphone off'
                      : voice.phase == VoicePhase.speaking
                      ? 'Speaking · microphone off'
                      : 'Microphone off · tap or hold to talk',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            if (voice.active || voice.conversation)
              TextButton(
                onPressed: controller.stop,
                child: const Text('End voice'),
              ),
          ],
        ),
        if (voice.transcript.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'You said: ${voice.transcript}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (voice.failure != null)
          Text(
            voice.failure!.message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}

class VoiceSettingsPanel extends ConsumerStatefulWidget {
  const VoiceSettingsPanel({super.key});
  @override
  ConsumerState<VoiceSettingsPanel> createState() => _VoiceSettingsPanelState();
}

class _VoiceSettingsPanelState extends ConsumerState<VoiceSettingsPanel> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(voiceSettingsProvider);
    final notifier = ref.read(voiceSettingsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Offline English voice',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SwitchListTile(
          title: const Text('Enable voice'),
          value: settings.enabled,
          subtitle: const Text(
            'Microphone off until started. No audio files. Transcripts use local chat history.',
          ),
          onChanged: (value) => notifier.update(enabled: value),
        ),
        TextFormField(
          key: ValueKey(settings.directory),
          initialValue: settings.directory,
          decoration: const InputDecoration(
            labelText: 'Voice engines folder',
            helperText: 'Approved local files only. Setup: docs/VOICE_SETUP.md',
            helperMaxLines: 4,
          ),
          onFieldSubmitted: (value) => notifier.update(directory: value.trim()),
        ),
        DropdownButtonFormField<bool>(
          isExpanded: true,
          initialValue: settings.whisper,
          key: ValueKey(settings.whisper),
          decoration: const InputDecoration(
            labelText: 'English speech recognition',
          ),
          items: const [
            DropdownMenuItem(value: false, child: Text('Vosk small English')),
            DropdownMenuItem(value: true, child: Text('Whisper tiny.en')),
          ],
          onChanged: (value) {
            if (value != null) notifier.update(whisper: value);
          },
        ),
        const SwitchListTile(
          title: Text('Gujarati voice · experimental · limited accuracy'),
          value: false,
          subtitle: Text(
            'Disabled: not evaluated with real Gujarati samples. Gujarati text remains available.',
          ),
          onChanged: null,
        ),
        const SwitchListTile(
          title: Text('Wake word · unavailable'),
          value: false,
          subtitle: Text('No background listening. Use the mic or Space.'),
          onChanged: null,
        ),
        const Text(
          'English only. Separate eSpeak NG process uses GPL components for approved personal, non-distributed use. Distribution review is pending. Linux capture/playback uses existing ALSA tools. Windows adapter/runtime verification is pending; mobile voice is unavailable—use text.',
        ),
      ],
    );
  }
}

class VoiceDeveloperReadout extends ConsumerWidget {
  const VoiceDeveloperReadout({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(voiceSessionProvider).metrics;
    String ms(Duration? value) =>
        value == null ? 'not measured' : '${value.inMilliseconds} ms';
    String ram(int? value) => value == null
        ? 'unavailable/not sampled'
        : '${(value / 1048576).toStringAsFixed(1)} MiB';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STT latency: ${ms(metrics.sttLatency)} · RTF: ${metrics.realTimeFactor?.toStringAsFixed(2) ?? 'not measured'}',
        ),
        Text(
          'TTS first audio queued: ${ms(metrics.firstAudio)} (acoustic start unmeasured)',
        ),
        Text(
          'End capture to first audio queued: ${ms(metrics.responseFirstAudio)}',
        ),
        Text('Ollama RSS snapshot: ${ram(metrics.llmRss)} (not peak)'),
        Text(
          'Round trip, end of capture to end of playback: ${ms(metrics.roundTrip)}',
        ),
        Text(
          'Peak STT process RSS: ${ram(metrics.sttRss)} · TTS/player RSS: ${ram(metrics.ttsRss)}',
        ),
        const Text(
          'Linux RSS sampled every 50 ms; excludes app/Ollama. Windows RSS is unavailable. Only one STT process; mic closed during speech.',
        ),
      ],
    );
  }
}

class GlobalVoiceIndicator extends ConsumerWidget {
  const GlobalVoiceIndicator({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      voiceSessionProvider.select((s) => (s.phase, s.conversation)),
    );
    if (status.$1 == VoicePhase.idle && !status.$2) {
      return const SizedBox.shrink();
    }
    return Semantics(
      liveRegion: true,
      label:
          'Voice ${status.$1.name}; microphone ${status.$1 == VoicePhase.listening ? 'active' : 'off'}',
      child: IconButton(
        tooltip: 'Voice ${status.$1.name} · End voice',
        onPressed: () =>
            unawaited(ref.read(voiceSessionProvider.notifier).stop()),
        icon: Icon(
          status.$1 == VoicePhase.listening ? Icons.mic : Icons.mic_off,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
