# JARVIS plan

Phase 0 planning completed and committed. Earlier missing-repository/SDK blockers were resolved in the actual checkout at /home/dev/projects/jarvis-ai. Phase 1a and its test closeout are committed/pushed (4a0e066, df45f55). Phase 1b core is delivered at b6a6030. The current authorization is Phase 1b.2 UI polish and Developer frame diagnostics only. Stop after 1b.2; the next user next authorizes 1b.3 below, not 1c or Phase 2.

## Structure and decisions

One Flutter/Dart app: lib/app for bootstrap, navigation, theme and composition; lib/core for contracts, policy, errors, capabilities and tokens; lib/features/<feature>/{presentation,domain,data}; test, integration_test, docs and Android/iOS/Linux/Windows runners. Riverpod, Drift/SQLite and flutter_secure_storage are proposed as required by the mission; proposal is not dependency approval. Domain remains pure Dart. Use SDK widgets, system fonts and a CustomPainter orb initially; omit optional scaffold icons and generators unless approved. No cloud, telemetry or sync.

Reference hardware: Ubuntu 26.04, Intel i5-6300U (2 cores/4 threads), 8 GB RAM, Intel HD 520, no dedicated GPU, 256 GB disk. This is the acceptance target, not evidence that this execution container matches it. Linux desktop and physical Android over USB are primary test paths; no emulator required. Windows builds use GitHub Actions on explicit triggers, subject to quota; iOS validation requires macOS.

CPU-only Ollama defaults: llama3.2:1b fast and llama3.2:3b quality; never default larger. Start with 2,048 context tokens, one generation at a time and bounded output; tune only with measured memory/latency. Lazy-load features/models, unload idle models with supported keep_alive behavior, serialize embedding/vision work and pause indexing during chat. Do not run text, vision and speech models concurrently on this machine. Developer screen reports measured app/host CPU and memory where available and explicitly marks unavailable host metrics. Use cancellable streaming and immediate state feedback. Lightweight orb, reduced-motion preference and automatic simplified rendering after sustained poor frame timing.

## Zero-cost feasibility and risks

Local productivity can be fully offline. Desktop AI requires separately installed Ollama and downloaded licensed weights. Mobile AI uses a reachable user-owned LAN host; standalone mobile inference is an unapproved extension. No public exposure or automatic transport downgrade. Explain destination and transport before connection. Existing hardware, electricity, storage and initial connectivity are real costs, although baseline software/service charges are $0.

8 GB shared RAM is restrictive: 3b may be slow or compete with speech/vision. Model file size is not peak RAM. Benchmark on reference machine before claims. Text-only llama3.2 defaults do not provide image understanding; a separately approved small local vision model must pass hardware tests in phase 7. If it cannot, explain the constraint and propose a free local-host alternative before claiming feature completion. Ubuntu 26.04 support is not inferred from generic Linux badges. Piper redistribution obligations, model/voice licenses, mobile bindings, Wayland portals, notification reliability, offline OS voices and iOS scheduling remain release gates.

## Phases and acceptance

Execute one authorized phase per next. If a phase is too large, propose bounded subphases before implementation and obtain authorization; next never approves dependencies.

| Phase | Deliverable and acceptance gate |
|---|---|
| 0 | Supplied AGENTS, plan, costs, capabilities, risks, handoff; focused planning commit if Git available; stop. |
| 1a | Scaffold and adaptive accessible shell, dark/light tokens, English baseline and Gujarati Unicode input/rendering; stop. Native runners and executable verification require available approved SDK/toolchain. |
| 1b | Lightweight five-state orb and explicitly labeled Mock streaming chat with cancellation/error/retry; stop. |
| 1b.2 | UI polish; Settings > Developer performance overlay (off by default), bounded per-tier build/raster frame times; stop. |
| 1b.3 | User-requested offline voice conversation foundation described below, engine comparison and approval gates first; stop. |
| 1c | Expanded meaningful domain/widget/integration tests, local check scripts and quota-conscious Linux checks plus Windows build workflow; stop. |
| 2 | Tested SQLite migrations, persistent chat, secure settings, onboarding, Ollama discovery/connection/streaming/cancellation; unreachable host and context-limit recovery; explicit model download consent. |
| 3 | Persistent tasks/notes/calendar/focus/habits; CRUD/search/domain rules work without AI or internet. |
| 4 | Local reminders, recurrence, quiet hours and briefings; restart/timezone/DST reconciliation and denied-permission fallback tested. |
| 5 | Approved offline STT and TTS, push-to-talk transcript review and playback interruption; airplane-mode/network-denial test; wake word only separately requested and feasible. |
| 6 | Confirmed memory with provenance/correction/deletion, global extraction/retrieval switch, sensitive candidate rejection tests; credential-free export and complete confirmed app-data deletion. |
| 7 | Validated document/image intake, supported extraction/OCR/vision; local embedding/index lifecycle and actual citations; revoked permission/deletion propagation and insufficient-evidence tests. |
| 8 | Typed tools, eight-step/time/output budgets, cancellation, scoped policy, exact-argument confirmations, restart deduplication, redacted logs, real undo; personas/workflows/QA Assistant cannot bypass policy. |
| 9 | Desktop hotkey/tray/command bar, explicit clipboard/screenshot/scoped search; allowlisted system arguments, compositor fallbacks and confirmed execution tested. |
| 10 | Physical Android widget/share/camera/notifications; permission/lifecycle checks; iOS source/configuration review with builds pending without macOS. |
| 11 | Opt-in proactivity and automations with previews, cooldowns/dedup/quiet hours; local synthetic evaluation, feedback; optional external information only after terms approval and outage fallback. |
| 12 | No-key/account end-to-end offline test after setup; reference-hardware accessibility/performance and disk/RAM/latency report; runnable Linux/Windows bundles, APK/AAB; signing/store costs separated. |
| 13 | Only explicitly requested optional cloud adapters, disabled by default; consent and cost controls; local embeddings stay local; no fallback. |

All implementation gates: format, flutter analyze, flutter test, relevant integration/build checks, resolve failures, review diff/secret exposure, update records, local focused commit, stop. No fake successes or unfinished controls in delivered features.

## Dependency approvals

Standing approval from user (2026-10-10): Flutter/Dart SDK, pub.dev packages verified MIT/BSD/Apache-2.0, Ollama and llama3.2:1b/3b. Always ask before GPL/LGPL/AGPL/noncommercial, unknown/paid terms, account/API key, single download >1 GB, or new sudo-requiring native/system tool. Exceptions override standing approval. No splitting downloads to evade limit. Record exact versions/licenses/source/date and review transitives/lockfiles before addition. No unchanged approval re-requests.

English is the baseline including voice. Gujarati text is required from Phase 1: font coverage, Unicode input/rendering and lossless note/task storage when Phase 3 ships; UI localization later. No Gujarati voice claim before real reference-hardware audio tests. Phase 5 compares licensed Whisper sizes, Vosk Gujarati if available, Piper/espeak-ng/OS voices, reports accuracy/latency and labels unsatisfactory voice experimental. Phase 2 compares 1b/3b with one or two small local alternatives on matched English/Gujarati prompts before final defaults. No silent cloud fallback; any optional cloud setting off by default with explicit consent.

Current status: Phase 1a checks re-run and passed; already-completed closeout skipped. Phase 1b delivers domain streaming/cancellation/typed events, local scripted English/Gujarati MockProvider, Riverpod session chat with Stop/error/Retry, adaptive Chat destination, dark default/light/system themes, lightweight five-state orb, visual debug controls, reduced motion (app + OS), measured rolling-window static fallback, and phase-specific tests. Chat/appearance remain session-only; microphone and audio are off. No Phase 1c CI work. Native Linux Gujarati dark/light captures visually checked using installed system font fallback; other-platform glyph checks remain manual.

Performance: the 60fps goal remains OPEN. Native profile runs on i5-6300U/Ubuntu 26.04/i915 do not meet the 16.67 ms raster target. Automatic fallback works; do not advertise 60fps. See docs/PERFORMANCE.md for measurements and the repeatable profile harness. Low-memory target requires further benchmarking/tuning through Phase 12.

## Costs

Planning sources reviewed 2026-10-10; installed SDK/package versions verified 2026-10-11. Unselected candidate versions remain discovery snapshots, not installed dependencies. $0 below means no required software/service charge for eligible personal use; this Phase 1b session added no downloads or assets. Unselected entries must acquire exact versions, sizes and license evidence before approval. Runtime quotas are none for local code unless stated; hardware capacity still limits use.

| Component / version | Role/status/platform | License and distribution obligations | Personal cost, needs/limits | Source / verification |
|---|---|---|---|---|
| Flutter 3.47.7 / Dart 3.13.5 | Required SDK/build tooling; W/L/A/iOS | Flutter BSD-3; retain notices; Dart and engine third-party notices reviewed at pin | $0; SDK download/disk size pending exact archive; target native tools separate | https://docs.flutter.dev/install/archive ; https://docs.flutter.dev/resources/faq |
| flutter_riverpod 3.4.3 | Required installed state/composition; W/L/A/iOS | MIT; retain copyright/license | $0 personal use, no account/key or service quota; existing local package, no new download | https://pub.dev/packages/flutter_riverpod/versions/3.4.3 ; lockfile and installed LICENSE verified 2026-10-11 |
| flutter_lints 6.0.0 | Required installed dev-only analysis; all Dart/Flutter targets | BSD-3-Clause; retain copyright/license/disclaimer, no endorsement | $0 personal use; existing local package; no runtime service or model asset; transitive lints 6.1.0 BSD-3-Clause | https://pub.dev/packages/flutter_lints/versions/6.0.0 ; lockfile and installed LICENSE verified 2026-10-11 |
| drift 2.35.2 | Required proposed persistence; W/L/A/iOS | MIT; retain notices; SQLite native dependency review separate | $0; generators/native runtime unselected | https://pub.dev/packages/drift |
| flutter_secure_storage 11.2.0 | Required proposed secure settings; W/L/A/iOS | BSD-3; retain notices; federated packages separate audit | $0; Android API 23+ per docs; Linux keyring/native prerequisites pending | https://pub.dev/packages/flutter_secure_storage |
| Future generators/native packages: unselected; existing scaffold/test/lint packages locked | Required only when introduced | Every resolved artifact/license pending; standing permissive-package approval; exception gates apply | $0 baseline requirement; sizes pending lockfile; no downloads now | package manifests/lockfile audit required |
| SQLite/native vector extension: unselected | Required SQLite; vector extension optional | Verify exact native source/license; exact-search Dart fallback avoids extension | $0 baseline requirement; bounded exact cosine search over SQLite vectors planned | https://drift.simonbinder.eu/ |
| Ollama, version unselected | Required real desktop brain, mobile via LAN | MIT engine; models have independent terms; retain engine notice | $0 local; CPU RAM/disk/download needs; no account; cloud capabilities excluded | https://github.com/ollama/ollama/blob/main/LICENSE ; https://docs.ollama.com/faq |
| llama3.2:1b / :3b, full digest pin pending | User-selected fast/quality CPU text defaults | Llama community terms, not MIT; exact model license/AUP/attribution and redistribution review required | $0 eligible local use subject to terms; Observed tags: 1b Q8_0, 1.3 GB, short digest baf6a787fdff; 3b Q4_K_M, 2.0 GB, short digest a80c4f17acd5; full manifests and peak RAM still need verification | https://ollama.com/library/llama3.2:1b ; https://ollama.com/library/llama3.2:3b |
| Embedding and vision weights, unselected | Required phase 7 local AI; desktop/LAN | Model-specific terms required; no inference from engine license | $0 eligible baseline requirement; small hardware-compatible candidates only; sizes pending | https://ollama.com/library |
| whisper.cpp + tiny/base weights, versions unselected | Proposed offline STT; native bindings tested per platform | MIT engine; upstream Whisper code/weights MIT; retain notices; pin converted weight provenance | $0; CPU-only; exact file sizes/performance pending | https://github.com/ggml-org/whisper.cpp ; https://github.com/openai/whisper |
| Vosk engine/models, unselected | Alternative offline STT | Exact engine release and per-model license audit required | $0 eligible candidate; language/model size pending; Linux/Android pathways documented | https://alphacephei.com/vosk/ |
| Piper engine/voice, unselected | User-selected TTS candidate | Current OHF engine GPL-3.0; redistribution needs GPL compliance/source; voices independently licensed; linkage/distribution decision pending | $0 eligible personal use; native/phonemizer/transitives and voice size pending | https://github.com/OHF-Voice/piper1-gpl |
| Offline OS TTS voices, unselected | Alternative after proving offline behavior | OS/voice-specific distribution terms; no network-backed speech | $0 only if installed/eligible; report unavailable offline voices | platform-specific verification deferred |
| openWakeWord, version/models unselected | Optional, only explicit wake-word request | Apache-2 code; bundled weights CC-BY-NC-SA-4.0; attribution/noncommercial/share-alike constraints | $0 eligible personal noncommercial candidate; mobile integration/reliability pending | https://github.com/dscripka/openWakeWord |
| Notifications/file/camera/hotkey/tray/widget/share/OCR plugins and native tools, unselected | Phase-specific candidates | Exact releases, native/transitive licenses pending approval | $0 baseline requirement; download/platform limits pending | verify official sources at respective phase |
| External weather/info, unselected | Optional nonessential | Terms, attribution, no-key eligibility and rate limits not verified; disabled | $0 eligible sources only; cached/manual fallback; no service dependency | source selection deferred phase 11 |
| Git / GitHub Actions / action revisions unselected | Git present; hosted CI optional developer account | Git/source and action licenses audited at pin; no app account | Local $0; GitHub Free private: 2,000 minutes/month, 500 MB artifact storage, 10 GB cache per repo per current docs; avoid overage; actual account quota unknown | https://docs.github.com/en/billing/concepts/product-billing/github-actions |
| Native SDKs/toolchains, versions unselected | Linux, Windows, Android, Xcode build requirements | Verify exact SDK licenses; Android SDK terms; Xcode host required | Baseline local tools must be $0 eligible; downloads several GB possible, exact sizes pending; no emulator | https://docs.flutter.dev/platform-integration |
| Signing/store publication, unselected | Optional distribution, outside baseline | Store/platform enrollment and signing terms pending | Do not assume $0; Linux bundle, unsigned Windows bundle and local Android APK installation are planned alternatives; iOS signing/local-install limits require separate verification | https://docs.flutter.dev/deployment |

### Disabled optional paid integrations

Gemini, OpenAI and Anthropic: no versions/SDKs selected, no approvals, disabled and excluded from release dependency graph. External variable charges, accounts/keys and retention terms require explicit request and fresh official verification. Never describe them as baseline free; secure UI entry only. No remote embeddings even with cloud chat.

## Performance and release evidence

Proposed acceptance budgets, to validate rather than claim: UI input/state feedback under 100 ms; measure p50/p95 time-to-first-token and tokens/sec for 1b/3b, peak RSS and host available RAM; no swap thrashing or OOM in one-model workload. Target 60fps on reference hardware, simplify orb after sustained frame budget misses, document measured fallback performance. Initial disk budget allocation requires checking free space before downloads. Performance gate remains open until benchmark evidence exists.

Default CI synthetic tests only, no models or credentials. PR checks on Linux, explicit/manual Windows build and controlled release triggers; concurrency cancellation, one-day artifact retention, bounded cache, no paid runners or automatic macOS jobs. Every workflow has local command equivalents; Windows locally requires a Windows host. Halt hosted jobs when available free quota is insufficient.

### Phase 1a selected source dependencies

| Component/version | License/cost | Approval/status/obligations |
|---|---|---|
| flutter_riverpod 3.4.3 | MIT; $0 | Standing pre-approval; official https://pub.dev/packages/flutter_riverpod reviewed 2026-10-10; retain notice; installed package and existing lockfile verified 2026-10-11; no lockfile changes in this follow-up. |
| flutter/flutter_test SDK packages, Flutter 3.47.7 | BSD-3 plus bundled notices; $0 | Standing SDK approval; existing SDK version verified 2026-10-11; no download performed, download gate still applies to future installations. |

Existing llama3.2 tags observed at 1.3/2.0 GB still require explicit download approval despite model pre-approval. Gujarati font asset not selected: no assumption of bundled font coverage, no unapproved font download; Linux glyph QA completed via Phase 1b native captures; other-platform font/shaping verification remains pending. OFL fonts would need separate approval under the current policy.

### Phase 1b costs and approvals — 2026-10-11

No direct/development dependency, native component, model, voice or external tool was added. pubspec.yaml and pubspec.lock are unchanged from the committed 1a baseline. Existing Flutter 3.47.7/Dart 3.13.5 and Riverpod 3.4.3 (MIT), flutter_lints 6.0.0/lints 6.1.0 (BSD-3-Clause) are reused at $0. MockProvider, orb painter and benchmark harness are original application code, with no runtime service or download requirement. Native Gujarati rendering uses an already-installed system font (fc-match :lang=gu reports Noto Sans Gujarati); no font asset is bundled or redistributed. Future bundled fonts remain subject to approval, including OFL outside the standing package-license list.

Next phase requires user next: 1b.3 voice engine comparison and recommendation first. Do not begin 1b.3, 1c or Phase 2 in the 1b.2 session. Optional Ollama/model integration remains Phase 2; >1 GB downloads still require explicit approval.


### Phase 1b.2 status and costs — 2026-10-11

Delivered: themed chat message surfaces and composer separation; technical timing numbers moved to Settings > Developer. Session-only showPerformanceOverlay toggle defaults off. Developer readouts separate animated/simple tiers, last 120 frames each, build/raster mean and p95 plus 16.7 ms budget misses, Refresh and Reset. Engine recording does not publish per-frame UI changes; static orb does not schedule monitoring frames. Tier attribution uses the mode at engine report time and timings cover the whole app while Chat is mounted; no isolated orb/FPS claims. No new downloads/dependencies/lockfile changes; existing Flutter 3.47.7 BSD-3 and Riverpod 3.4.3 MIT reused at $0. Flutter overlay reference: https://api.flutter.dev/flutter/material/MaterialApp/showPerformanceOverlay.html (reviewed 2026-10-11).

### Next: Phase 1b.3 (not started; explicit user schedule change)

The user moved the initial voice foundation ahead of Phase 5. This changes the previous schedule, not dependency or privacy gates. Phase 5 retains broader platform qualification and Gujarati engine evaluation not completed in 1b.3. First research at least two STT and two TTS candidates, present a short license/model-size/RAM comparison and recommendation, obtain required engine/license approvals and explicit model download approval before downloading models. Real speed/RAM claims require execution on the reference machine; mark unavailable results honestly.

Implement pure-domain SpeechToText, TextToSpeech, AudioInput, VoiceActivityDetector and VoiceSessionController (idle/listening/transcribing/thinking/speaking/error), Riverpod composition and deterministic fakes. Mic → VAD → STT → existing streamed LlmProvider → sentence-by-sentence TTS; varied English Mock greetings/small talk. Push-to-talk via held Space/mic, tap conversation with automatic relisten, silence timeout and stop/goodbye. Barge-in interrupts playback; ignore/mute mic during speech to prevent echo. Real mic-level/playback orb states, live transcript and response, visible active-mic indication, contextual permission explanation including Android RECORD_AUDIO, voice-disable switch, no audio saving by default. Pipeline remains usable by Ollama later.

Native engine work off UI thread; lower orb tier during STT. Linux/Windows support and Android alternatives must be evidence-based. Gujarati voice experimental, off by default, labeled limited accuracy and tested with real samples before claims. No wake-word implementation; only capability interface and explicitly disabled entry per user request. No silent cloud. Developer metrics: STT real-time factor and latency, TTS time-to-first-audio, total round trip and per-stage RAM. Fake controller transition/barge-in/silence tests and widget voice tests; format, clean analyze, all tests and Linux release build; update HANDOFF/PLAN/Costs, commit/push, stop. Model audio samples or licenses unavailable are blockers to measurement, not permission to fabricate results.
