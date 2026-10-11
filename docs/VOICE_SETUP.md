# Offline English voice setup (personal, non-distributed builds)

English voice is opt-in and off by default. It does not download engines or record audio files. The microphone opens only on a mic tap/hold or Space press outside the composer, closes before STT, stays closed during generation/playback, and closes on End voice/disable/window disposal. Raw PCM lives in bounded memory (20-second utterance, maximum 640,000 bytes) then is discarded. Recognized text and answers are saved as normal unencrypted local chat history. Speech recognition is final-utterance transcription, not a live partial-word transcript.

These approved engines cost $0 and run offline after setup. eSpeak NG and native dependencies have GPL obligations: approved for personal, non-distributed use only. A separate process avoids in-app linking but does not grant distribution permission. Do not distribute engine/application bundles until licences/notices/source obligations are resolved. See [artifact evidence](dependencies/voice-artifacts.json) and [comparison](VOICE_ENGINE_COMPARISON.md).

## This laptop

User installed `espeak-ng=1.52.0+dfsg-5build1` through apt; no agent sudo. Existing `arecord`, `aplay`, compiler and CMake used. English playback was confirmed by the user. All voice downloads stay in `/home/dev/Documents/Codex/jarvis-voice-scratch`, outside both repositories.

In Settings > Offline English voice, enter the following folder and **press Enter** to save it:

```text
/home/dev/Documents/Codex/jarvis-voice-scratch
```

Select Whisper tiny.en (measured provisional Linux default), enable voice, and select local Ollama/llama3.2:1b in provider settings. Nothing is fetched from the network by this setup UI. The selected directory must contain the approved native binaries/models; only developer setup creates them.

Repeatable native build with already approved/extracted sources:

```bash
cmake -S /home/dev/Documents/Codex/jarvis-voice-scratch/whisper.cpp-d1be6fde11ac6e0407606b4e42fe72d34add8037 \
  -B /home/dev/Documents/Codex/jarvis-voice-scratch/whisper-build \
  -DCMAKE_BUILD_TYPE=Release -DGGML_CUDA=OFF -DGGML_VULKAN=OFF \
  -DWHISPER_BUILD_TESTS=OFF -DWHISPER_BUILD_EXAMPLES=ON
cmake --build /home/dev/Documents/Codex/jarvis-voice-scratch/whisper-build --target whisper-cli -j2
cc -O2 tool/native/voice_vosk.c \
  -I/home/dev/Documents/Codex/jarvis-voice-scratch/vosk-linux-x86_64-0.3.45 \
  -L/home/dev/Documents/Codex/jarvis-voice-scratch/vosk-linux-x86_64-0.3.45 -lvosk \
  -Wl,-rpath,/home/dev/Documents/Codex/jarvis-voice-scratch/vosk-linux-x86_64-0.3.45 \
  -o /home/dev/Documents/Codex/jarvis-voice-scratch/voice-vosk
```

No builds during Ollama generation. Compiler memory/time evidence in the comparison. The Vosk helper's rpath references this scratch directory; rebuilding is required after relocation. Whisper shared libraries remain alongside its executable in whisper-build/bin. Do not commit binaries/models/fixtures.

Linux has no uniform runtime microphone prompt for ordinary unsandboxed desktop processes. The app explains consent before enabling; actual OS/audio access errors show permission recovery. Sandboxed Flatpak/Snap packaging needs separate platform permission integration, currently unverified. `arecord`/`aplay` use the ALSA `default` device, which may be routed by PulseAudio/PipeWire; select devices in OS sound settings. No hardcoded hardware device bypasses that routing.

## Other platforms

Windows engine files exist upstream but Windows execution is **unverified**. Build `tool/native/voice_audio_windows.cpp` using an already configured Visual Studio Developer Command Prompt:

```bat
cl /EHsc /O2 tool\native\voice_audio_windows.cpp winmm.lib /Fe:VOICE_ROOT\voice-audio.exe
cl /O2 /I VOICE_ROOT\vosk-win64-0.3.45 tool\native\voice_vosk.c VOICE_ROOT\vosk-win64-0.3.45\libvosk.lib /Fe:VOICE_ROOT\voice-vosk.exe
```

Place Vosk's native DLLs alongside voice-vosk.exe, the small-en-us-0.15 model folder below VOICE_ROOT, and independently install the pinned eSpeak NG release using its reviewed official installer (installation/download approval rules still apply). eSpeak must be on PATH. This source adapter uses WinMM capture/playback in a separate process, memory-only; Windows microphone privacy access is controlled in OS Settings. Do not infer a verified Windows build from provided commands. Native runtime licences, complete notices and redistribution remain open. No workflow changes or Phase 1c work were added.

The pinned Whisper CLI's stdout implementation opens `CON` on Windows, so pipe-only transcription through that CLI is unavailable there. The app explains this and defaults Windows to Vosk. A future MIT Whisper API helper could remove that limit; it is not claimed implemented.

Android/iOS voice adapters are unavailable in this step; text chat remains usable. Domain interfaces allow a later native worker adapter. Android would require contextual RECORD_AUDIO permission and a capture implementation; iOS requires microphone usage description and real platform validation. No mobile runner/permission changes or silent network speech. Mobile LLM transport still follows existing local-host limitations. Gujarati voice is disabled and labeled experimental/limited accuracy pending Phase 5 real sample evaluation. Wake-word interface exists with a disabled setting; there is no background listener.

## Manual acceptance checks

1. With headphones: tap mic, say “Hello”, wait for a spoken brief answer; answer again and confirm automatic re-listening. Say “stop”/“goodbye” alone; confirm mic indicator turns off. Repeat with laptop speakers; Jarvis must not transcribe its own answer.
2. Hold the mic button, speak, release; repeat with Space outside the composer. Space while typing must remain text input. Silence in conversation mode should close the mic after ten seconds; speech followed by about 800 ms quiet should finish the utterance.
3. While speaking, press Space or tap mic; speech should stop, microphone should arm, and the interrupted turn must not restart speech. Press End voice while transcribing, thinking, speaking and listening. Disable voice in Settings while active. Close the app while active. Confirm no orphan arecord/aplay/espeak/whisper processes and no background mic use.
4. Deny/disable mic access or unplug input; verify a useful error and retry. Unplug speakers/select a wrong output and test playback recovery. Wrong/missing engine directory must explain setup without downloading anything.
5. Developer: record STT latency/RTF, first audio queued (not acoustic onset), end-capture-to-first audio, total end-capture-to-playback-finish and RSS. Test the three benchmark sentences with your own accent and report the actual transcripts. Synthetic fixture accuracy does not predict mic noise/accent performance.
6. Check orb mic-level response/listening, Lite during STT, speaking during queued playback, reduce motion and OS animation settings. Check dark/light and 360-pixel width. Airplane/disconnected mode must retain speech; Ollama unavailable must recover visibly without any cloud fallback.

Default ALSA device verification (2026-10-11): `arecord -q -D default -t raw -f S16_LE -r 16000 -c 1` opened successfully on this laptop, streamed 8,000 PCM bytes into memory during a 0.5-second check, and was killed immediately (SIGKILL, exit -9). No stderr and no audio file. This confirms device access, not microphone intelligibility. No device override was guessed. If default access fails, the app reports the engine failure; inspect the exact native error with that command and enumerate devices with `arecord -l`. The app closes capture before transcription/playback and stops on app inactivity, hiding, conversation changes or disabling voice. A 350 ms pause follows playback before automatic listening resumes.
