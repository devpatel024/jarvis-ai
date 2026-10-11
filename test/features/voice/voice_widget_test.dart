import 'package:jarvis/core/design/app_theme.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/features/voice/presentation/voice_controls.dart';
import 'package:jarvis/features/voice/presentation/voice_providers.dart';
import 'package:jarvis/features/voice/domain/voice_contracts.dart';
import 'package:jarvis/features/chat/presentation/chat_screen.dart';
import 'package:jarvis/features/orb/presentation/core_orb.dart';
import 'package:jarvis/features/orb/domain/orb_state.dart';
import 'package:jarvis/core/developer/performance_settings.dart';
import 'voice_session_test.dart' show FakeAudio, FakeStt, FakeTts;

class EnabledVoice extends VoiceSettings {
  @override
  VoiceSettingsState build() => const VoiceSettingsState(enabled: true);
}

void main() {
  testWidgets(
    'tap mic shows listening, mic level, STT tier and End closes capture',
    (tester) async {
      final audio = FakeAudio(), stt = FakeStt(), tts = FakeTts();
      stt.pending = Completer();
      final container = ProviderContainer(
        overrides: [
          voiceSettingsProvider.overrideWith(EnabledVoice.new),
          audioInputProvider.overrideWithValue(audio),
          speechToTextProvider.overrideWithValue(stt),
          textToSpeechProvider.overrideWithValue(tts),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.build(Brightness.dark),
            home: Scaffold(body: ChatScreen(reduced: true)),
          ),
        ),
      );
      expect(audio.starts, 0);
      await tester.tap(find.byKey(const ValueKey('voice-mic')));
      await tester.pump();
      expect(find.text('Listening · microphone active'), findsOneWidget);
      audio.speech();
      await tester.pump();
      expect(
        tester.widget<CoreOrb>(find.byType(CoreOrb).first).state,
        OrbState.listening,
      );
      expect(
        tester.widget<CoreOrb>(find.byType(CoreOrb).first).microphoneLevel,
        .2,
      );
      audio.silence();
      await tester.pump();
      await tester.pump();
      expect(
        container.read(voiceSessionProvider).phase,
        VoicePhase.transcribing,
      );
      expect(
        tester.widget<CoreOrb>(find.byType(CoreOrb).first).tier,
        OrbTier.lite,
      );
      await tester.tap(find.text('End voice'));
      await tester.pump();
      stt.pending!.complete(const SpeechResult('Hello'));
      await tester.pumpAndSettle();
      expect(find.text('Microphone off · tap or hold to talk'), findsOneWidget);
      expect(audio.frames, isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets(
    'Space holds PTT, release ends capture, text editing keeps Space',
    (tester) async {
      final audio = FakeAudio(), stt = FakeStt();
      stt.pending = Completer();
      final container = ProviderContainer(
        overrides: [
          voiceSettingsProvider.overrideWith(EnabledVoice.new),
          audioInputProvider.overrideWithValue(audio),
          speechToTextProvider.overrideWithValue(stt),
          textToSpeechProvider.overrideWithValue(FakeTts()),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.build(Brightness.dark),
            home: const Scaffold(body: ChatScreen(reduced: true)),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(audio.starts, 1);
      audio.speech();
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(audio.frames, isNull);
      await container.read(voiceSessionProvider.notifier).stop();
      stt.pending!.complete(const SpeechResult('Hello'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('composer')));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(audio.starts, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets('disabled mic explains privacy; cancel never captures', (
    tester,
  ) async {
    final audio = FakeAudio();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [audioInputProvider.overrideWithValue(audio)],
        child: MaterialApp(
          theme: AppTheme.build(Brightness.dark),
          home: Scaffold(body: VoiceControls()),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('voice-mic')));
    await tester.pumpAndSettle();
    expect(find.text('Enable offline English voice?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(audio.starts, 0);
  });
  testWidgets(
    'voice settings and developer readout state experimental limitations',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [VoiceSettingsPanel(), VoiceDeveloperReadout()],
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        find.text('Gujarati voice · experimental · limited accuracy'),
        findsOneWidget,
      );
      expect(find.text('Wake word · unavailable'), findsOneWidget);
      expect(find.textContaining('TTS first audio queued:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
