# JARVIS plan

Phase 0 planning record — 2026-10-10. No implementation or dependency installation authorized in this phase. Planning documents complete; required planning commit blocked by an unusable read-only .git directory and absent Git identity. No dependencies approved.

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
| 1 | Approved scaffold, adaptive accessible shell, tokens, lightweight five-state orb, explicitly labeled Mock streaming chat with cancel/error/retry; meaningful domain/widget tests; local checks and quota-conscious Linux checks plus Windows build workflow. |
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

Approved: none. Installed by this phase: none. Before phase 1, prepare one exact-version batch covering Flutter/Dart SDK, flutter/flutter_test/integration_test SDK packages, flutter_riverpod, chosen lint package if any, scaffold/build tools and native prerequisites. Avoid automatic flutter create/pub get until approvals. Later batches include Drift/native SQLite/generation tools, secure storage, speech/voices, embeddings/vision, plugins and CI action revisions. Verify archives, compatibility, exact licenses, download sizes and transitive graph before requesting approval. Unknown fields block approval, not just integration. Record approval text/date/version and lockfile diff in LICENSES.md. Do not ask for unchanged approvals again.

## Costs

Official sources reviewed 2026-10-10. Candidate versions are discovery snapshots, not approved pins. $0 below means no required software/service charge for eligible personal use; no asset has been downloaded. Unselected entries must acquire exact versions, sizes and license evidence before approval. Runtime quotas are none for local code unless stated; hardware capacity still limits use.

| Component / version | Role/status/platform | License and distribution obligations | Personal cost, needs/limits | Source / verification |
|---|---|---|---|---|
| Flutter/Dart, version unselected | Required SDK/build tooling; W/L/A/iOS | Flutter BSD-3; retain notices; Dart and engine third-party notices reviewed at pin | $0; SDK download/disk size pending exact archive; target native tools separate | https://docs.flutter.dev/install/archive ; https://docs.flutter.dev/resources/faq |
| flutter_riverpod 3.4.3 | Required proposed state/composition; W/L/A/iOS | MIT; retain copyright/license | $0; package and transitives sizes pending | https://pub.dev/packages/flutter_riverpod |
| drift 2.35.2 | Required proposed persistence; W/L/A/iOS | MIT; retain notices; SQLite native dependency review separate | $0; generators/native runtime unselected | https://pub.dev/packages/drift |
| flutter_secure_storage 11.2.0 | Required proposed secure settings; W/L/A/iOS | BSD-3; retain notices; federated packages separate audit | $0; Android API 23+ per docs; Linux keyring/native prerequisites pending | https://pub.dev/packages/flutter_secure_storage |
| SDK scaffold/test/lint, generators and transitive packages: unselected | Required only when introduced | Every resolved artifact/license pending; no blanket approval | $0 baseline requirement; sizes pending lockfile; no downloads now | package manifests/lockfile audit required |
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
