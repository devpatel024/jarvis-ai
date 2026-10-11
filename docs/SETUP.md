# Setup — Phase 1b

Repository: /home/dev/projects/jarvis-ai. Existing Flutter 3.47.7/Dart 3.13.5 at /home/dev/development/flutter/bin; Linux toolchain is available. No SDK, package, model or native tool installation was performed in Phase 1b.

Run locally from the repository root:

```sh
/home/dev/development/flutter/bin/flutter run -d linux --no-pub
```

Home retains a session-only English/Gujarati scratchpad. Open Chat for a visibly labeled local scripted demo, with Stop and explicit Retry. Expand Demo controls to preview all orb states or simulate a failed reply. Microphone/audio are off. Dark is the default; Settings offers Light/System and Reduce motion. OS animation accessibility preferences take precedence. All data remains in memory and is lost on app exit; no accounts, keys, model files or internet are needed for the demo once existing dependencies are installed.

Actual Ollama setup remains Phase 2. Existing llama3.2:1b/3b downloads exceed the 1 GB approval threshold and must not be pulled silently. Text/embedding/vision capabilities need licensed models and hardware checks. Phones require an explicitly configured trusted user-owned LAN host for AI; local productivity must remain usable disconnected. No emulator prerequisite; physical Android over USB is the planned testing route. Gujarati voice remains unverified until real sample measurements (the user scheduled early voice evaluation in 1b.3; Phase 5 retains broader qualification); there is no cloud fallback.

Read PLAN/HANDOFF at the next session. The next user next begins 1b.3 engine comparison/approval, not 1c or Phase 2. The 1b.2 Developer panel is described in PERFORMANCE; use a profile build for measurements. PERFORMANCE describes native benchmark reproduction and current unmet 60fps goal.

Slice A starts on Chat. History holds session chats and the temporary Unicode scratchpad. Desktop list can collapse; tablet uses rail; phone uses bottom navigation. Ctrl+K commands, Ctrl+N new chat, Enter send, Shift+Enter newline, Esc Stop. Message menus are accessible by their button, hover controls or long press. History menus rename or confirm deletion. Settings > Appearance switches five palettes/light/dark and quality; Developer holds all demo controls and timing numbers. Attachments/voice are informational unavailable labels; paste text instead. All state resets on exit. No 1b.3/1c/Phase 2 authorization follows automatically from this redesign.

Linux uses Skia selected by its native runner on Flutter 3.47.7; reference-machine Impeller OpenGLESSDF measurements were unacceptable. Automatic quality starts Lite; manually select Balanced/Ultra only after checking Developer timings. Those tiers are not certified at 30/60 fps on this hardware. All motion stops with Reduce motion.

## Part 2 local setup and cached builds

Use the tested Flutter 3.47.7 / Dart 3.13.5 SDK. The resolved graph now needs Dart >=3.12 and Flutter >=3.38.4; other SDKs are not validated. Keep pubspec.lock committed. Direct packages and generators are exact pins; sqlite3 is exactly 3.7.0 and its build hook contains a fixed release tag/hash map.

```sh
flutter pub get --enforce-lockfile
dart run build_runner build
flutter analyze --no-pub
flutter test --no-pub
flutter build linux --release --no-pub
flutter run -d linux --no-pub
```

Generated Drift source is committed, so normal builds do not need regeneration. First setup requires pub.dev/SDK artifacts and GitHub's public sqlite3-3.7.0 native release. Linux x64 SQLite download is 1,788,664 bytes, SHA-256 verified by the hook; it is bundled into the app. Subsequent same-target builds can reuse the shared hook cache. `flutter pub get --offline --enforce-lockfile` resolves from the existing package cache. See HANDOFF for actual cache/network verification. Removing `.dart_tool`, changing target or package pin, or missing Flutter engine artifacts can require downloads again. Nothing installs SQLite with sudo; no runtime SQLite downloads.

Ollama is separately installed/running on this machine. This work never pulls the already installed models. On another desktop, the Ollama daemon must be reachable at `http://127.0.0.1:11434`; if installed but stopped, run `ollama serve` (or use its existing service). Settings > Local intelligence > Check Ollama / model reports installed-model availability. Missing models show the exact pull command but never execute it: each current 1b/3b download exceeds 1 GB and needs the user's size/license approval before a new download. Run `ollama ps` to see resident models and `ollama stop MODEL` to unload a conflicting one. Never expose the daemon publicly for this app.

Fast 1b is the provisional production default; quality 3b and scripted Mock demo are selectable in Settings/top bar. Default context 2048, CPU-only/two threads, generated output capped at 256 tokens, deterministic sampling, idle unload after 30 seconds. Cold starts can be slow; streaming and Stop remain available. Larger context uses more RAM. Low available-memory warning is Linux-only; Settings > Developer reports measured app RSS/available host RAM, with CPU/unavailable platform metrics labeled honestly. No background model/index work.

Chats and appearance/provider preferences now save to `jarvis.sqlite` under path_provider's application-support directory. The scratchpad and Developer overlay remain temporary. Rename/search and exact-chat confirmed delete are in History. Data is unencrypted, subject to OS account permissions/backups. No automatic cloud/sync/audio/telemetry, no stored credentials. Save/open failures are visible. Export/complete deletion are still Phase 6 per PLAN; Android/iOS/Windows storage paths and device rendering remain unverified.

Windows: after you push the local commit, manually dispatch `.github/workflows/windows-build.yml` on GitHub and review your remaining private-repo quota first. This narrow workflow tests native SQLite CRUD/reopen/migration and builds Windows, with concurrency cancellation, 25-minute timeout and one-day unsigned artifact retention. It never downloads models. It looks up the **exact** Flutter 3.47.7 stable Windows archive in the official catalog, checks size and SHA-256, and refuses archives over 1 GB without the explicit approval checkbox. Review the printed size in a failed run before approving. The catalog was unreachable from this environment, so SDK availability and Windows execution are unverified. No agent push or workflow dispatch was performed.

sqlite3 3.7.0 supplies Android arm/arm64/x86/x64 and iOS arm64 device/arm64+x64 simulator native libraries itself. Drift NativeDatabase uses those hook assets; there is no sqflite/system-library fallback to configure. Android/iOS runners were not edited or built; future mobile Ollama still requires separately authorized user-owned LAN connection support. This step accepts only desktop loopback.

Gujarati comparison candidates qwen2.5:1.5b and qwen3:0.6b are explicitly approved for testing only. Their exact downloaded manifest hashes are recorded in docs/dependencies/model-candidates.json. They are not app defaults or app picker additions. The benchmark sends think:false (Qwen3 thinking disabled), verifies one CPU resident model and unloads each in finally. No automatic pulls are performed by the benchmark.

```sh
python3 tool/ollama_benchmark.py --models qwen2.5:1.5b qwen3:0.6b --gujarati-only --output docs/performance/ollama-alternatives.json
```

Run only after explicitly approved setup/downloads, with other Ollama clients stopped and no model resident. RAM sampling requires access to the actual Ollama/runner process status files. Results are server+runner RSS, not whole-system or app memory.
