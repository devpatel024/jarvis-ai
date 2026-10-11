# JARVIS plan

Phase 0 planning completed and committed. Earlier missing-repository/SDK blockers were resolved in the actual checkout at /home/dev/projects/jarvis-ai. Phase 1a and its test closeout are committed/pushed (4a0e066, df45f55). Phase 1b core is delivered at b6a6030. Phase 1b.2 is delivered at 8e6f557. Current authorization: accepted Slice A follow-up in three ordered parts, each committed locally for the user to push: (1) small UI fixes, (2) Phase 2 real local Ollama chat and approved persistence, (3) GitHub README redesign. Latest authorization adds bounded Linux/Windows runner sizing to Part 3, followed by Phase 1b.3 Step 1 research only; voice downloads/integration require approval, and 1c remains excluded. Stop at a clean completed part if context/credits are low and record the exact resume point in HANDOFF.

## Structure and decisions

One Flutter/Dart app: lib/app for bootstrap, navigation, theme and composition; lib/core for contracts, policy, errors, capabilities and tokens; lib/features/<feature>/{presentation,domain,data}; test, integration_test, docs and Android/iOS/Linux/Windows runners. Riverpod, Drift/SQLite and flutter_secure_storage are proposed as required by the mission; proposal is not dependency approval. Domain remains pure Dart. Use SDK widgets, system fonts and a CustomPainter orb initially; omit optional scaffold icons and generators unless approved. No cloud, telemetry or sync.

Reference hardware: Ubuntu 26.04, Intel i5-6300U (2 cores/4 threads), 8 GB RAM, Intel HD 520, no dedicated GPU, 256 GB disk. Native Linux runs and Ollama benchmarks have now been measured on this matching reference machine; other desktop load remains uncontrolled. Linux desktop and physical Android over USB are primary test paths; no emulator required. Windows builds use GitHub Actions on explicit triggers, subject to quota; iOS validation requires macOS.

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
| Slice A | Five dark/light palettes, lightweight premium UI, in-memory chats/actions/shortcuts, three measured quality tiers, approved fonts, screenshots; stop for feedback. |
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
| 13 | Only explicitly requested optional cloud adapters, including planned Gujarati cloud smart mode: off by default, explicit destination/data consent and cost/account/key approval, local embeddings stay local; no silent fallback. |

All implementation gates: format, flutter analyze, flutter test, relevant integration/build checks, resolve failures, review diff/secret exposure, update records, local focused commit, stop. No fake successes or unfinished controls in delivered features.

## Dependency approvals

Standing approval from user (2026-10-10): Flutter/Dart SDK, pub.dev packages verified MIT/BSD/Apache-2.0, Ollama and llama3.2:1b/3b. Always ask before GPL/LGPL/AGPL/noncommercial, unknown/paid terms, account/API key, single download >1 GB, or new sudo-requiring native/system tool. Exceptions override standing approval. No splitting downloads to evade limit. Record exact versions/licenses/source/date and review transitives/lockfiles before addition. No unchanged approval re-requests.

English is the baseline including voice. Gujarati text is required from Phase 1: font coverage, Unicode input/rendering and lossless note/task storage when Phase 3 ships; UI localization later. No Gujarati voice claim before real reference-hardware audio tests. Phase 5 compares licensed Whisper sizes, Vosk Gujarati if available, Piper/espeak-ng/OS voices, reports accuracy/latency and labels unsatisfactory voice experimental. Phase 2 compares 1b/3b with one or two small local alternatives on matched English/Gujarati prompts before final defaults. No silent cloud fallback; any optional cloud setting off by default with explicit consent.

Current status: Phase 1a checks re-run and passed; already-completed closeout skipped. Phase 1b delivers domain streaming/cancellation/typed events, local scripted English/Gujarati MockProvider, Riverpod session chat with Stop/error/Retry, adaptive Chat destination, dark default/light/system themes, lightweight five-state orb, visual debug controls, reduced motion (app + OS), measured rolling-window static fallback, and phase-specific tests. This historical 1b state was session-only; Part 2 now persists chat/settings. Microphone and audio remain off. No Phase 1c CI work. Native Linux Gujarati dark/light captures visually checked using installed system font fallback; other-platform glyph checks remain manual.

Performance: the 60fps goal remains OPEN. Native profile runs on i5-6300U/Ubuntu 26.04/i915 do not meet the 16.67 ms raster target. Automatic fallback works; do not advertise 60fps. See docs/PERFORMANCE.md for measurements and the repeatable profile harness. Low-memory target requires further benchmarking/tuning through Phase 12.

## Costs

Planning sources reviewed 2026-10-10; installed SDK/package versions verified 2026-10-11. Unselected candidate versions remain discovery snapshots, not installed dependencies. $0 below means no required software/service charge for eligible personal use; this Phase 1b session added no downloads or assets. Unselected entries must acquire exact versions, sizes and license evidence before approval. Runtime quotas are none for local code unless stated; hardware capacity still limits use.

| Component / version | Role/status/platform | License and distribution obligations | Personal cost, needs/limits | Source / verification |
|---|---|---|---|---|
| Flutter 3.47.7 / Dart 3.13.5 | Required SDK/build tooling; W/L/A/iOS | Flutter BSD-3; retain notices; Dart and engine third-party notices reviewed at pin | $0; SDK download/disk size pending exact archive; target native tools separate | https://docs.flutter.dev/install/archive ; https://docs.flutter.dev/resources/faq |
| flutter_riverpod 3.4.3 | Required installed state/composition; W/L/A/iOS | MIT; retain copyright/license | $0 personal use, no account/key or service quota; existing local package, no new download | https://pub.dev/packages/flutter_riverpod/versions/3.4.3 ; lockfile and installed LICENSE verified 2026-10-11 |
| flutter_lints 6.0.0 | Required installed dev-only analysis; all Dart/Flutter targets | BSD-3-Clause; retain copyright/license/disclaimer, no endorsement | $0 personal use; existing local package; no runtime service or model asset; transitive lints 6.1.0 BSD-3-Clause | https://pub.dev/packages/flutter_lints/versions/6.0.0 ; lockfile and installed LICENSE verified 2026-10-11 |
| drift 2.35.2 | Required installed persistence; W/L/A/iOS | MIT; retain notices; SQLite native dependency review separate | $0; exact generators and native runtime audited below | https://pub.dev/packages/drift |
| flutter_secure_storage 11.2.0 | Required proposed secure settings; W/L/A/iOS | BSD-3; retain notices; federated packages separate audit | $0; Android API 23+ per docs; Linux keyring/native prerequisites pending | https://pub.dev/packages/flutter_secure_storage |
| Future generators/native packages: unselected; existing scaffold/test/lint packages locked | Required only when introduced | Every resolved artifact/license pending; standing permissive-package approval; exception gates apply | $0 baseline requirement; sizes pending lockfile; no downloads now | package manifests/lockfile audit required |
| SQLite 3.53.4 via sqlite3 3.7.0 / vector extension unselected | Required installed SQLite; vector extension future optional | Public domain explicitly approved; native artifacts below; vector review deferred | $0 baseline requirement; bounded exact cosine search over SQLite vectors planned | https://drift.simonbinder.eu/ |
| Ollama 0.40.3 | Required real desktop brain, mobile via LAN | MIT engine; models have independent terms; retain engine notice | $0 local; CPU RAM/disk/download needs; no account; cloud capabilities excluded | https://github.com/ollama/ollama/blob/main/LICENSE ; https://docs.ollama.com/faq |
| llama3.2:1b / :3b, observed full digests in performance/ollama-comparison.json | User-selected unchanged fast/quality CPU text defaults; installed desktop Ollama, not bundled | Llama 3.2 Community License + AUP (2024-09-25), explicitly pre-approved; redistribution requires agreement/notice and Built with Llama attribution, derivative model naming obligations; >700M-user commercial gate | $0 eligible local use subject to terms; 1b Q8_0 1,321,098,329 bytes; 3b Q4_K_M 2,019,393,189 bytes already installed, NEVER re-pulled. Peak process RSS measured in PERFORMANCE | https://ollama.com/library/llama3.2:1b ; https://ollama.com/library/llama3.2:3b ; installed /api/show license/details snapshot docs/dependencies/llama-models.json, verified 2026-10-11 |
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

### Slice A approved bundled assets — 2026-10-11

Explicit font approval received in this session. Font files and notices total 1,010,066 bytes (about 0.96 MiB), plus source metadata. No runtime download, new account, native tool or package dependency. Immutable source URLs/hashes in assets/fonts/SOURCES.json.

| Slice A asset/version | License / distribution obligations | Required/platform/cost/download | Verified source/date |
|---|---|---|---|
| Space Grotesk 2.000 | SIL OFL 1.1, preserve copyright/license; font cannot be sold alone; derivative naming requirements apply | Bundled UI font W/L/A/iOS, $0; 136,676 bytes + 4,495-byte notice | Google fonts commit bd8f81ddb5c74d5c8897b36ad88b440266245103; embedded name version and OFL reviewed 2026-10-11 |
| Noto Sans Gujarati 2.106 | SIL OFL 1.1, same notice/standalone sale/derivative obligations | Bundled Gujarati fallback W/L/A/iOS, $0; 672,904 bytes + 4,384-byte notice | Same pinned repository; embedded version and OFL reviewed 2026-10-11 |
| JetBrains Mono 2.211 | SIL OFL 1.1, same notice/standalone sale/derivative obligations | Bundled code font W/L/A/iOS, $0; 187,208 bytes + 4,399-byte notice | Same pinned repository; embedded version and OFL reviewed 2026-10-11 |
| Palettes, gradient glass, orb, Markdown renderer, captures/bench harness | Original app code/assets; no additional library/service | Required Slice A W/L/A/iOS source; $0; no network/native runtime dependency | Repository source; uses existing Flutter 3.47.7/Dart 3.13.5 and Riverpod 3.4.3 |

### Disabled optional paid integrations

Gemini, OpenAI and Anthropic: no versions/SDKs selected, no approvals, disabled and excluded from release dependency graph. External variable charges, accounts/keys and retention terms require explicit request and fresh official verification. Never describe them as baseline free; secure UI entry only. No remote embeddings even with cloud chat.

### Part 2 approved native SQLite Costs — 2026-10-11

User explicitly approved public-domain native SQLite and pinned/hash-verified sqlite3 3.7.0 prebuilt artifacts. Every artifact below costs $0, requires no account/key/sudo, and is public domain. The Dart wrapper is MIT. Linux x64 engine version **SQLite 3.53.4** was read from the downloaded library. Other platform versions and builds have not been executed. Source release: https://github.com/simolus3/sqlite3.dart/releases/tag/sqlite3-3.7.0 . Exact source URLs, bytes and hook hashes are also in [artifact metadata](dependencies/sqlite3-3.7.0-artifacts.json). Only Linux x64 has been downloaded here.

| Native artifact (platform/architecture) | Exact bytes | SHA-256 (pinned hook expectation) | Source release URL |
|---|---:|---|---|
| libsqlite3.arm.android.so | 1,872,620 | `a42fa9d0f5c006d30b000d4904bc497705191c5d7330b178618546004295bb49` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/libsqlite3.arm.android.so |
| libsqlite3.arm.linux.so | 1,171,128 | `f076c2399d68ac9eb849841088029397948ffc97c461040f2a3ca1d1491355fe` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/libsqlite3.arm.linux.so |
| libsqlite3.arm64.android.so | 1,831,784 | `0c2d3bfc8c87abceb21ed72a4bb49964121c5fe1a8ef3848d83ba907d01b6161` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/libsqlite3.arm64.android.so |
| libsqlite3.arm64.ios.dylib | 1,668,776 | `1cd28d9f4f2be1d855945d44b68229d2fc7a6a0db4a3fd8e88d7d7f719cd3de0` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/libsqlite3.arm64.ios.dylib |
| libsqlite3.arm64.ios_sim.dylib | 1,714,976 | `1218e774869d673134b8d901dc6654bb1879f4a3682e9bdd4899e20599d21a1b` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/libsqlite3.arm64.ios_sim.dylib |
| libsqlite3.arm64.linux.so | 1,802,328 | `037539c68603ce1dbff411c276945e092b808d48d515e5e15d5266a602d39711` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/libsqlite3.arm64.linux.so |
| libsqlite3.arm64.macos.dylib | 1,713,824 | `649fdf22050829816ebec7dbeab5e7b974bd72487f84cbcf3529f3bd7b756430` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/libsqlite3.arm64.macos.dylib |
| libsqlite3.ia32.android.so | 1,751,624 | `3888ba23a79904b968ad7f7cd3b3f59e856a25dcc90953b5a69ea6a4f9961f59` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/libsqlite3.ia32.android.so |
| libsqlite3.ia32.linux.so | 1,955,688 | `5df89bac8f446cebef1c0276f470d5c3ac553dba9c2b115d4b4df76a5d4d97b1` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/libsqlite3.ia32.linux.so |
| libsqlite3.riscv64.linux.so | 1,289,928 | `91b3a9e42b922424c770cf82b27f05772b85d056a4222aa527c5f9170f59d56b` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/libsqlite3.riscv64.linux.so |
| libsqlite3.x64.android.so | 1,808,568 | `949965f0eba976f707ae364cdcb42c342b5f0626081f8d7f0378fb7b52848772` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/libsqlite3.x64.android.so |
| libsqlite3.x64.ios_sim.dylib | 1,719,720 | `c41f725b587170f6f899d97710e531af7ff2f49eb757d5246b5af0b8371ced9f` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/libsqlite3.x64.ios_sim.dylib |
| libsqlite3.x64.linux.so | 1,788,664 | `0f947ebe629e8d9d02d7f408bef36e056bfc63ea47e02e0d45a7bae454f04ace` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/libsqlite3.x64.linux.so |
| libsqlite3.x64.macos.dylib | 1,718,616 | `5b95619427b111ad23725ec42b48f84e707712d367cf35180e65ff486c4a8ba8` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/libsqlite3.x64.macos.dylib |
| sqlite3.arm64.windows.dll | 1,601,024 | `8b672eefe9d595b3788548998558f87768ec7373b282bd8c822d2116c5a30c95` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/sqlite3.arm64.windows.dll |
| sqlite3.debug.wasm | 3,405,586 | `ccc33e306e9ac69c94785e551e8e1c44e3addf6b930e2e463b262de3e304da3c` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/sqlite3.debug.wasm |
| sqlite3.ia32.windows.dll | 1,327,104 | `6f708e62df110fc0a5fd81124be9e6c89e2c39b8364327e94f6ec3f3ea1cf457` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/sqlite3.ia32.windows.dll |
| sqlite3.x64.windows.dll | 1,709,056 | `98b4be674137b85ec111a7a29223e87aa41c3e964d61f73602471ddd7b9c56ce` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.0/sqlite3.x64.windows.dll |

Linux x64 downloaded bytes and SHA-256 match the table; tests execute that library. The default package hook downloads and caches the target library, verifies its pinned SHA-256, and bundles it. It does **not** compile SQLite or require a system SQLite package. The hook and release tag/hash map are inside exact sqlite3 **3.7.0**, with the package archive SHA-256 in pubspec.lock; no separate floating hook or latest-release lookup. Preserve pubspec.lock and use `flutter pub get --enforce-lockfile` (or `--offline --enforce-lockfile` after setup). No encrypted SQLCipher/sqlite3mc or vector extension selected.

First build per target requires internet for the native artifact, plus initial SDK/pub dependencies. Later Linux cached-build verification is recorded in HANDOFF; cleaning hook caches, changing targets/pins, or missing SDK artifacts can require internet again. App runtime does not download SQLite. Windows CI builds/tests the same dependency with the ordinary hosted Windows C++ toolchain; it is **UNVERIFIED until GitHub runs it**. Manual dispatch only, 25-minute timeout, cancellation, one-day artifact retention, no model downloads. Check remaining private-repository Actions quota before dispatch; no automatic paid overages authorized. Pinned SDK archive size/hash is checked before download; an archive over 1 GB requires the explicit workflow approval checkbox after reviewing the printed size. Catalog lookup failed from this environment; no Windows SDK archive or CI run was performed.

Android arm/arm64/x86/x64 and iOS arm64 device/arm64+x64 simulator native artifacts are provided by sqlite3 3.7.0. Drift NativeDatabase uses these hook-bundled libraries on those targets; no sqflite or system-SQLite fallback is needed. Android/iOS runners remain unchanged and builds/device behavior are unverified.

| Other native/build component | Pin/licence/obligations | Role, platform and cost |
|---|---|---|
| JNI native headers/wrappers from jni 1.1.0 | Android Open Source Project 2006; Apache-2.0 for jni.h/global_jni_env, BSD-3 for Dart API and JNI package. Preserve notices; bundled assets/licenses/JNI-NATIVE.txt plus Flutter generated licences | Android path_provider transitive; optional desktop JVM lookup explicitly disabled in Linux/Windows CMake. No Java installation or JVM bundling; $0 |
| actions/checkout v4 | 11d5960a326750d5838078e36cf38b85af677262; MIT, preserve notices; https://github.com/actions/checkout | Manual Windows workflow tooling; $0 within user account quota |
| actions/upload-artifact v4 | ea165f8d65b6e75b540449e92b4886f43607fa02; MIT, preserve notices; https://github.com/actions/upload-artifact | Optional unsigned Windows artifact, one-day retention; $0 within user account quota |

Direct generator versions: drift_dev **2.35.1** (there is no published 2.35.2 at verification), build_runner **2.16.2**. Both are pinned; approved under the user’s permissive dev-package approval. Native package/version/source/licence audit completed with installed source on 2026-10-11. No new native/system tool installed.

### Part 2 installed package Costs — 2026-10-11

User explicitly approves public-domain native SQLite, pinned sqlite3 3.7.0 prebuilt/hash-verified artifacts. Public domain is acceptable alongside MIT/BSD/Apache. Source and native artifact rows above are verified; Linux download bytes/hash match the pin. Direct dependencies pinned; complete resolved graph locked in pubspec.lock. All hosted packages below cost $0, no account/key or service quota. MIT/BSD require retained copyright/licence notices; Apache includes licence/NOTICE obligations. SDK package licences are listed separately (Flutter BSD, sky_engine Apache). Versions/licence texts audited from installed package LICENSE files; pub.dev version URL is the source for each hosted row. Native platform toolchain/transitive notices must also be preserved.

| Package | Locked version | Licence | Source |
|---|---|---|---|
| _fe_analyzer_shared | 109.0.0 | BSD-3-Clause | https://pub.dev/packages/_fe_analyzer_shared/versions/109.0.0 |
| analyzer | 14.5.0 | BSD-3-Clause | https://pub.dev/packages/analyzer/versions/14.5.0 |
| args | 2.7.0 | BSD-3-Clause | https://pub.dev/packages/args/versions/2.7.0 |
| async | 2.13.1 | BSD-3-Clause | https://pub.dev/packages/async/versions/2.13.1 |
| boolean_selector | 2.1.2 | BSD-3-Clause | https://pub.dev/packages/boolean_selector/versions/2.1.2 |
| build | 4.0.11 | BSD-3-Clause | https://pub.dev/packages/build/versions/4.0.11 |
| build_config | 1.3.3 | BSD-3-Clause | https://pub.dev/packages/build_config/versions/1.3.3 |
| build_daemon | 4.1.6 | BSD-3-Clause | https://pub.dev/packages/build_daemon/versions/4.1.6 |
| build_runner | 2.16.2 | BSD-3-Clause | https://pub.dev/packages/build_runner/versions/2.16.2 |
| built_collection | 5.1.2 | BSD-3-Clause | https://pub.dev/packages/built_collection/versions/5.1.2 |
| built_value | 8.13.0 | BSD-3-Clause | https://pub.dev/packages/built_value/versions/8.13.0 |
| characters | 1.4.1 | BSD-3-Clause | https://pub.dev/packages/characters/versions/1.4.1 |
| charcode | 1.4.0 | BSD-3-Clause | https://pub.dev/packages/charcode/versions/1.4.0 |
| checked_yaml | 2.0.4 | BSD-3-Clause | https://pub.dev/packages/checked_yaml/versions/2.0.4 |
| cli_util | 0.6.0 | BSD-3-Clause | https://pub.dev/packages/cli_util/versions/0.6.0 |
| clock | 1.1.3 | Apache-2.0 | https://pub.dev/packages/clock/versions/1.1.3 |
| code_assets | 2.1.0 | BSD-3-Clause | https://pub.dev/packages/code_assets/versions/2.1.0 |
| collection | 1.19.1 | BSD-3-Clause | https://pub.dev/packages/collection/versions/1.19.1 |
| convert | 3.1.2 | BSD-3-Clause | https://pub.dev/packages/convert/versions/3.1.2 |
| crypto | 3.0.7 | BSD-3-Clause | https://pub.dev/packages/crypto/versions/3.0.7 |
| dart_style | 3.1.13 | BSD-3-Clause | https://pub.dev/packages/dart_style/versions/3.1.13 |
| drift | 2.35.2 | MIT | https://pub.dev/packages/drift/versions/2.35.2 |
| drift_dev | 2.35.1 | MIT | https://pub.dev/packages/drift_dev/versions/2.35.1 |
| fake_async | 1.3.3 | Apache-2.0 | https://pub.dev/packages/fake_async/versions/1.3.3 |
| ffi | 2.2.0 | BSD-3-Clause | https://pub.dev/packages/ffi/versions/2.2.0 |
| file | 7.0.1 | BSD-3-Clause | https://pub.dev/packages/file/versions/7.0.1 |
| fixnum | 1.1.1 | BSD-3-Clause | https://pub.dev/packages/fixnum/versions/1.1.1 |
| flutter | 0.0.0 | BSD-3-Clause (Flutter SDK 3.47.7) | Installed Flutter SDK LICENSE |
| flutter_lints | 6.0.0 | BSD-3-Clause | https://pub.dev/packages/flutter_lints/versions/6.0.0 |
| flutter_riverpod | 3.4.3 | MIT | https://pub.dev/packages/flutter_riverpod/versions/3.4.3 |
| flutter_test | 0.0.0 | BSD-3-Clause (Flutter SDK 3.47.7) | Installed Flutter SDK LICENSE |
| glob | 2.2.0 | BSD-3-Clause | https://pub.dev/packages/glob/versions/2.2.0 |
| graphs | 2.3.2 | BSD-3-Clause | https://pub.dev/packages/graphs/versions/2.3.2 |
| hooks | 2.2.0 | BSD-3-Clause | https://pub.dev/packages/hooks/versions/2.2.0 |
| http_multi_server | 3.2.2 | BSD-3-Clause | https://pub.dev/packages/http_multi_server/versions/3.2.2 |
| http_parser | 4.1.2 | BSD-3-Clause | https://pub.dev/packages/http_parser/versions/4.1.2 |
| io | 1.1.0 | BSD-3-Clause | https://pub.dev/packages/io/versions/1.1.0 |
| jni | 1.1.0 | BSD-3-Clause | https://pub.dev/packages/jni/versions/1.1.0 |
| jni_flutter | 1.0.4+1 | BSD-3-Clause | https://pub.dev/packages/jni_flutter/versions/1.0.4+1 |
| jni_util | 1.0.0 | BSD-3-Clause | https://pub.dev/packages/jni_util/versions/1.0.0 |
| json_annotation | 4.12.0 | BSD-3-Clause | https://pub.dev/packages/json_annotation/versions/4.12.0 |
| leak_tracker | 11.0.2 | BSD-3-Clause | https://pub.dev/packages/leak_tracker/versions/11.0.2 |
| leak_tracker_flutter_testing | 3.0.10 | BSD-3-Clause | https://pub.dev/packages/leak_tracker_flutter_testing/versions/3.0.10 |
| leak_tracker_testing | 3.0.2 | BSD-3-Clause | https://pub.dev/packages/leak_tracker_testing/versions/3.0.2 |
| lints | 6.1.0 | BSD-3-Clause | https://pub.dev/packages/lints/versions/6.1.0 |
| listen | 1.0.1 | BSD-3-Clause | https://pub.dev/packages/listen/versions/1.0.1 |
| logging | 1.3.0 | BSD-3-Clause | https://pub.dev/packages/logging/versions/1.3.0 |
| matcher | 0.12.20 | BSD-3-Clause | https://pub.dev/packages/matcher/versions/0.12.20 |
| material_color_utilities | 0.13.0 | Apache-2.0 | https://pub.dev/packages/material_color_utilities/versions/0.13.0 |
| meta | 1.19.0 | BSD-3-Clause | https://pub.dev/packages/meta/versions/1.19.0 |
| mime | 2.1.0 | BSD-3-Clause | https://pub.dev/packages/mime/versions/2.1.0 |
| native_toolchain_c | 0.19.5 | BSD-3-Clause | https://pub.dev/packages/native_toolchain_c/versions/0.19.5 |
| objective_c | 9.6.2 | BSD-3-Clause | https://pub.dev/packages/objective_c/versions/9.6.2 |
| package_config | 3.0.0 | BSD-3-Clause | https://pub.dev/packages/package_config/versions/3.0.0 |
| path | 1.9.1 | BSD-3-Clause | https://pub.dev/packages/path/versions/1.9.1 |
| path_provider | 2.1.6 | BSD-3-Clause | https://pub.dev/packages/path_provider/versions/2.1.6 |
| path_provider_android | 2.3.1 | BSD-3-Clause | https://pub.dev/packages/path_provider_android/versions/2.3.1 |
| path_provider_foundation | 2.6.0 | BSD-3-Clause | https://pub.dev/packages/path_provider_foundation/versions/2.6.0 |
| path_provider_linux | 2.2.2 | BSD-3-Clause | https://pub.dev/packages/path_provider_linux/versions/2.2.2 |
| path_provider_platform_interface | 2.1.3 | BSD-3-Clause | https://pub.dev/packages/path_provider_platform_interface/versions/2.1.3 |
| path_provider_windows | 2.3.0 | BSD-3-Clause | https://pub.dev/packages/path_provider_windows/versions/2.3.0 |
| platform | 3.2.0 | BSD-3-Clause | https://pub.dev/packages/platform/versions/3.2.0 |
| plugin_platform_interface | 2.1.8 | BSD-3-Clause | https://pub.dev/packages/plugin_platform_interface/versions/2.1.8 |
| pool | 1.5.3 | BSD-3-Clause | https://pub.dev/packages/pool/versions/1.5.3 |
| process | 5.0.6 | BSD-3-Clause | https://pub.dev/packages/process/versions/5.0.6 |
| pub_semver | 2.2.1 | BSD-3-Clause | https://pub.dev/packages/pub_semver/versions/2.2.1 |
| pubspec_parse | 1.6.0 | BSD-3-Clause | https://pub.dev/packages/pubspec_parse/versions/1.6.0 |
| recase | 4.1.0 | BSD-2-Clause | https://pub.dev/packages/recase/versions/4.1.0 |
| record_use | 1.1.1 | BSD-3-Clause | https://pub.dev/packages/record_use/versions/1.1.1 |
| riverpod | 3.4.3 | MIT | https://pub.dev/packages/riverpod/versions/3.4.3 |
| shelf | 1.4.2 | BSD-3-Clause | https://pub.dev/packages/shelf/versions/1.4.2 |
| shelf_web_socket | 3.0.0 | BSD-3-Clause | https://pub.dev/packages/shelf_web_socket/versions/3.0.0 |
| sky_engine | 0.0.0 (Flutter SDK 3.47.7 engine) | Apache-2.0 | Installed Flutter engine sky_engine LICENSE |
| source_gen | 4.3.0 | BSD-3-Clause | https://pub.dev/packages/source_gen/versions/4.3.0 |
| source_span | 1.10.2 | BSD-3-Clause | https://pub.dev/packages/source_span/versions/1.10.2 |
| sqlite3 | 3.7.0 | MIT | https://pub.dev/packages/sqlite3/versions/3.7.0 |
| sqlparser | 0.45.0 | MIT | https://pub.dev/packages/sqlparser/versions/0.45.0 |
| stack_trace | 1.12.2 | BSD-3-Clause | https://pub.dev/packages/stack_trace/versions/1.12.2 |
| state_notifier | 1.0.0 | MIT | https://pub.dev/packages/state_notifier/versions/1.0.0 |
| stream_channel | 2.1.4 | BSD-3-Clause | https://pub.dev/packages/stream_channel/versions/2.1.4 |
| stream_transform | 2.1.2 | BSD-3-Clause | https://pub.dev/packages/stream_transform/versions/2.1.2 |
| string_scanner | 1.4.1 | BSD-3-Clause | https://pub.dev/packages/string_scanner/versions/1.4.1 |
| term_glyph | 1.2.2 | BSD-3-Clause | https://pub.dev/packages/term_glyph/versions/1.2.2 |
| test_api | 0.7.12 | BSD-3-Clause | https://pub.dev/packages/test_api/versions/0.7.12 |
| typed_data | 1.4.0 | BSD-3-Clause | https://pub.dev/packages/typed_data/versions/1.4.0 |
| uuid | 4.6.0 | MIT | https://pub.dev/packages/uuid/versions/4.6.0 |
| vector_math | 2.4.0 | BSD-3-Clause | https://pub.dev/packages/vector_math/versions/2.4.0 |
| vm_service | 15.3.0 | BSD-3-Clause | https://pub.dev/packages/vm_service/versions/15.3.0 |
| watcher | 1.2.1 | BSD-3-Clause | https://pub.dev/packages/watcher/versions/1.2.1 |
| web | 1.1.1 | BSD-3-Clause | https://pub.dev/packages/web/versions/1.1.1 |
| web_socket | 1.0.1 | BSD-3-Clause | https://pub.dev/packages/web_socket/versions/1.0.1 |
| web_socket_channel | 3.0.3 | BSD-3-Clause | https://pub.dev/packages/web_socket_channel/versions/3.0.3 |
| xdg_directories | 1.1.0 | BSD-3-Clause | https://pub.dev/packages/xdg_directories/versions/1.1.0 |
| yaml | 3.1.4 | MIT | https://pub.dev/packages/yaml/versions/3.1.4 |
| yaml_edit | 2.2.4 | BSD-3-Clause | https://pub.dev/packages/yaml_edit/versions/2.2.4 |

## Part 2 status — 2026-10-11

Implemented local-only Ollama adapter with streaming, aborting Stop, typed failures/deadlines, conservative UTF-8 byte bounds (system/output/framing reserves) and recoverable commands; explicit model discovery/check and fast/quality/demo selectors. CPU-only, context 2048 default, 256 generated-token cap, configurable idle unload (0/30/60 seconds), single active app generation, refusal to load alongside a different resident model, Linux low-memory warning. Model switch waits for cancellation and unloads the previously selected resident model before updating configuration. Other clients can race the localhost daemon; JARVIS cannot control external clients.

Drift v2 persists chats/messages/model/language/context/idle/theme/palette/reduced-motion/manual-quality settings through a background SQLite isolate. Native CRUD, delete/reopen, v1→v2 migration and Riverpod controller restart/search tested. History has exact-chat confirmed deletion, rename and English/Gujarati title/message search. Scratchpad and Developer overlay remain temporary. Periodic streaming checkpoints are marked stopped until a completed reply is saved. Database is unencrypted; filesystem/account protection applies. No credentials are accepted or stored, so optional secure-credential storage is deferred until an optional provider is authorized.

Scope: export/complete deletion remain Phase 6 per PLAN (conflict reported before implementation); no dead placeholder controls. LAN/mobile connection configuration and richer onboarding remain open acceptance items rather than unsupported success claims. Approved Gujarati-only Qwen comparison completed (latest user instruction limits candidate testing to Gujarati, overriding the earlier English comparison gate); both script-correct but fail the tasks. Existing 1b fast/3b quality defaults unchanged, and any change requires asking the user. Candidate models are testing-only, not app picker additions. This Part 2 adds only the explicitly authorized Windows SQLite workflow; wider Phase 1c work, voice, Android/iOS runner changes and Part 3 README edits are not started. Agent never pushes; user pushes the reported local commit. Final verification/model evidence is in HANDOFF and PERFORMANCE.

### Approved Gujarati comparison assets — 2026-10-11

Comparison only; do not change app defaults without asking. Both licenses checked on the exact official model tags; no account/key/service charge, CPU offline use after setup, no usage quota beyond hardware. Weights are not bundled with the app. Largest files below 1 GB; exact manifests/layer hashes in docs/dependencies/model-candidates.json. Initial download needs internet; aggregate layer storage 1,508,714,682 bytes, plus manifests/cache overhead. Apache redistribution requires license/notice preservation and marking modifications where applicable.

| Asset | License/cost/status | Source, download bytes, immutable manifest SHA-256 |
|---|---|---|
| qwen2.5:1.5b Q4_K_M | Apache-2.0; $0; explicitly approved download/test only | https://ollama.com/library/qwen2.5:1.5b ; all layers 986,061,405; largest 986,048,512; 65ec06548149b04c096a120e4a6da9d4017ea809c91734ea5631e89f96ddc57b |
| qwen3:0.6b Q4_K_M | Apache-2.0; $0; explicitly approved download/test only; thinking disabled | https://ollama.com/library/qwen3:0.6b ; all layers 522,653,277; largest 522,640,096; 7df6b6e09427a769808717c0a93cadc4ae99ed4eb8bf5ca557c90846becea435 |
| Python 3.14.4 (existing) | PSF License; $0; existing developer-only benchmark interpreter, no download/adoption as app dependency | Host version verified; stdlib only benchmark tool; no pip packages or system installs |

## Part 3 status — 2026-10-11

Original Aurora SVG hero and palette strip, GitHub-supported README with explicit anchors, dark/light picture and optimized WebP gallery. Previews retain original captures and synthetic demo provenance, each under 40 KB. No real Ollama screenshot claim: native app capture unavailable in this restricted session. English 1b/3b TTFT/tokens-per-second/RSS evidence was already complete in PERFORMANCE and is reproduced in README; no unnecessary model rerun/download. Notes/tasks remain Phase 3 planned, despite latest shorthand asking to describe their Gujarati support as already built; lossless Gujarati chat/text is built, notes/tasks support is required when implemented. Optional cloud Gujarati smart mode is roadmap-only in Phase 13, off by default and consent/cost/account gated. Defaults unchanged.

Native runner exception explicitly authorized by user: about 1280×800 client request, about 360×640 minimum subject to smaller work area, capped to current usable monitor geometry. Linux uses logical GTK units and decoration margin; Windows uses monitor DPI/work area with normal/min/max tracking and DPI-change clamps. Window manager rules may override Linux hints; Windows runtime/multi-monitor checks pending. No new app dependency or project LICENSE. Part 3 prepared in a writable local clone because session filesystem policy denied writes to original checkout; user applies the commit bundle before pushing.

### Part 3 asset and tooling Costs

| Component / version | Terms, status and personal cost | Source / verification |
|---|---|---|
| Original README banner.svg / palettes.svg | Original code, project licence undecided; $0, required documentation assets, SVG under 60 KB; no external logos/fonts downloaded | Repo assets/readme, 2026-10-11; palette values from AppTheme |
| Six optimized WebP previews | Existing native scripted-demo screenshots; project licence undecided; $0, no remote media; 14.7–37.7 KB each; no UI content alteration | assets/readme/SOURCES.json hashes; originals retained in docs/screenshots |
| Pillow 12.1.1 (existing interpreter library) | Existing local developer-only optimization tool, no package added to app or download; MIT-CMU Pillow licence, $0 | Host PIL version / installed metadata; PNG→WebP resize/encoding only |
| Bundled sharp 0.35.5 (existing Codex runtime) | Apache-2.0 wrapper, bundled libvips LGPL-2.1-or-later and renderer notices; existing offline developer tooling only, not installed/adopted/distributed with JARVIS; $0 | Existing runtime package version/notices; local SVG raster QA only, no new binary/download |
| Static shields.io badge URLs | Optional README rendering only, no runtime app request or service dependency; $0, hosted availability not guaranteed | Explicit static labels; native GitHub display remains manual |

Verification: Dart formatting unchanged, analyzer clean, Linux release build passed using copies of existing SDK/pub/native caches. Flutter tests attempted but all harnesses blocked before execution by EPERM binding 127.0.0.1; not a passing test run. Prior Part 2 61-test result remains historical. README paths/anchors/image metadata/SVG XML reviewed, raster assets inspected locally. Windows build/runtime, actual native window fit and live Ollama capture NOT RUN under current platform/access limits. GitHub banner/badges/Mermaid/theme switching/manual TOC checks pending after user push.


## Phase 1b.3 Step 1 — engine research / approval pending

Authorized immediately after Part 3, research only. [Comparison](VOICE_ENGINE_COMPARISON.md) covers whisper.cpp tiny.en/base.en, Vosk small English, eSpeak NG, Piper and OS-dispatch alternatives, published sizes/terms, expected hardware constraints and platform adapter paths. No engine/model/package downloads or installs; no voice code or mic access. Recommend evaluating tiny.en versus Vosk, with formant eSpeak NG TTS only after explicit GPL approval. Piper neural TTS during streamed LLM conflicts with no concurrent neural-engine policy; requires explicit exception or serial scheduling. English-only; Gujarati stays disabled/experimental until Phase 5 real samples. Step 2 remains approval-gated.

### Voice candidate Costs — proposed, not installed (2026-10-11)

| Candidate pin / status | Licence / distribution obligations | Software cost, size/platform/limits and source |
|---|---|---|
| whisper.cpp 1.9.5 + tiny.en / optional base.en | MIT engine and Whisper weights; notices; native/compiler/transitives preflight pending | $0/no key; CPU W/L/Android pathways; model ~75/142 MiB; source-only release, compiled helper size unknown until build. https://github.com/ggml-org/whisper.cpp/releases/tag/v1.9.5 |
| Vosk 0.3.45 + small-en-us-0.15 | Apache-2.0 engine/model; notices; bundled native terms preflight pending | $0/no key; W/L/Android paths; model ~40 MB, x64 native-containing wheels Linux7.2/Windows14.0 MB. https://pypi.org/project/vosk/0.3.45/ ; https://alphacephei.com/vosk/models |
| eSpeak NG 1.52.0 | GPL-3.0-or-later, NOT approved; preserve licence/copyright and applicable source obligations; no assumption about whole-app licence | $0/no key; W/L/Android; formant voices, Windows MSI12.2 MB / AndroidAPK9.96 MB; Linux compiled size unknown, no sudo authorized. https://github.com/espeak-ng/espeak-ng/releases/tag/1.52.0 |
| Piper 1.8.0 / en_US-ljspeech-medium candidate | GPL-3.0-or-later engine/phonemizer, NOT approved; repository MIT voice, public-domain dataset in exact card; pin/review voice and transitive notices before adoption | $0/no key; Linux/Windows wheels34.1 MB excluding Python/ONNX/runtime/transitives; voice63.5 MB +4.97 kB config; Android integration unverified. https://pypi.org/project/piper-tts/1.8.0/ ; https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_US/ljspeech/medium/MODEL_CARD |
| speech-dispatcher / OS voices, unselected | GPLv2 server/LGPL-2.1-or-later C client and independent voices/backend terms, NOT approved; OS voice redistribution/offline unknown | $0 only eligible installed offline voices; Linux dispatch, separate WindowsSAPI/AndroidOS paths; exact package/voice/binary sizes unselected and unverified. https://github.com/brailcom/speechd/blob/master/README.md |

Published rounded sizes are not verified archive bytes or deployed footprint. No account/key, sudo, new tool or >1 GB download is approved by this table. Source archives/bindings/native assets and hashes must pass preflight after explicit candidate approval, and new exceptions must be asked separately. Actual local STT/TTS speed, accuracy and RAM remain NOT MEASURED.


### Voice evaluation approval and preflight Costs update — 2026-10-11

Whisper tiny.en, Vosk small English, and eSpeak NG are explicitly approved for evaluation/integration; eSpeak GPL-3.0-or-later approval is personal, non-distributed only. All software charges $0, no account/key. GPL distribution obligations must be resolved before distributing builds; a separate process does not waive them. Exact available artifact sizes/hashes, unresolved source/model checksums and native dependencies are recorded in docs/VOICE_ENGINE_COMPARISON.md. No artifact downloaded or engine installed yet. Evaluation/build remains paused at the user's exact pre-download size/hash gate, pending an exception for missing official checksums/byte counts or a verifiable source. Unselected Piper/base.en remain unapproved. No 1c.


### Voice preflight artifact Costs — approved downloads completed

2026-10-11. Official pinned artifacts cost $0/no account/key; five downloads total 150,609,612 bytes, maximum 77,704,715, within 150 MB/file and 400 MB/total caps. Exact versions/URLs/bytes/full SHA-256/check status recorded in `docs/dependencies/voice-artifacts.json` and `docs/VOICE_ENGINE_COMPARISON.md` (Costs evidence incorporated here). Whisper tiny.en published hash MATCH; all four other hashes explicitly computed locally on 2026-10-11, not publisher-verified. No binaries/models committed. Whisper source MIT and weights MIT; Vosk engine/model Apache-2.0, native notice/distribution review open. Windows native runtimes unverified for redistribution. eSpeak apt CLI pending user install, installed library notices reviewed, GPL personal non-distributed approval retained. No sudo or push. Compilation measurement and speech benchmark still pending; no default chosen or voice feature claim.
