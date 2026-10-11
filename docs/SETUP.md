# Setup — Phase 1b

Repository: /home/dev/projects/jarvis-ai. Existing Flutter 3.47.7/Dart 3.13.5 at /home/dev/development/flutter/bin; Linux toolchain is available. No SDK, package, model or native tool installation was performed in Phase 1b.

Run locally from the repository root:

```sh
/home/dev/development/flutter/bin/flutter run -d linux --no-pub
```

Home retains a session-only English/Gujarati scratchpad. Open Chat for a visibly labeled local scripted demo, with Stop and explicit Retry. Expand Demo controls to preview all orb states or simulate a failed reply. Microphone/audio are off. Dark is the default; Settings offers Light/System and Reduce motion. OS animation accessibility preferences take precedence. All data remains in memory and is lost on app exit; no accounts, keys, model files or internet are needed for the demo once existing dependencies are installed.

Actual Ollama setup remains Phase 2. Existing llama3.2:1b/3b downloads exceed the 1 GB approval threshold and must not be pulled silently. Text/embedding/vision capabilities need licensed models and hardware checks. Phones require an explicitly configured trusted user-owned LAN host for AI; local productivity must remain usable disconnected. No emulator prerequisite; physical Android over USB is the planned testing route. Gujarati voice remains unverified until Phase 5 measurements; there is no cloud fallback.

Read PLAN/HANDOFF at the next session. Phase 1c begins only on user next. PERFORMANCE describes native benchmark reproduction and current unmet 60fps goal.
