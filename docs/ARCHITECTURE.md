# Architecture decisions — Phase 0

Feature-first clean layers; app composes Riverpod repositories, domain is pure Dart and data adapters own storage/providers. Typed Result and injectable Clock; deterministic fakes.

LlmProvider exposes neutral messages/attachments, capabilities, cancellable event streams (text/tool/usage/completion/error), deadlines, context limits and bounded idempotent retries. Mock is labeled demo; Ollama default real provider. Tool planning uses schema validation where native tools unavailable. Non-idempotent actions never auto-retry.

Capability interfaces cover speech, wake word, notifications/scheduler, scoped files, camera, screenshots, clipboard, hotkeys, tray, widgets and share. Available/denied/unsupported/disconnected states include usable alternatives.

Drift migrations preserve relational entities and history. SQLite vector rows store source hash, chunk/page provenance, model digest/dimensions and grant scope. Bounded exact search first; native extension only after platform approval. Index workers yield to chat; deletion/revocation removes chunks and cancels work.

Memory candidates require accept/edit/reject before durable writes; provenance, scope, timestamps, correction and deletion retained. Global memory switch stops extraction/retrieval separately from chat history.

Tool registry validates schemas and policy outside model code. Eight-step loop with deadline/output limits, fresh exact-argument confirmation for destructive/system actions, durable action IDs, allowlisted executable/argument arrays and redacted log. Undo only for verified compensating operations. Personas and workflows carry declared inputs/permissions and cannot grant themselves authority.

No background inference promise. Opt-in automation uses quiet hours/cooldowns/deduplication and narrow grants. CPU-only single-model execution on reference hardware. Optional cloud routing cannot replace local retrieval or bypass destination consent.

## Phase 1b implementation

LlmProvider is pure Dart and emits TextDelta/LlmCompleted/LlmFailed with typed failure codes and a cooperative CancellationToken that interrupts pending delays. MockProvider is a local scripted data adapter; the app composition uses a Riverpod provider, overridable in tests. ChatController owns immutable state, generation fences against stale output, disposal/Stop cancellation, 20-second inter-event timeout and explicit retry without duplicating the user entry. No action execution, persistence, audio or network inference exists in this phase. Rich provider attachments/capabilities/usage and real Ollama transport belong to Phase 2.

CoreOrb owns and disposes its painter ticker and engine-timing callback. RepaintBoundary isolates paint animation; a 60-sample bounded window of max(build,raster) switches to a static orb when 12 or more samples exceed 16.667 ms. Static/reduced-motion modes pause the ticker; 1b.2 diagnostic collection records bounded samples without scheduling frames. Timing labels live in Settings > Developer and refresh explicitly. The orb rebuilds from timing reports only when entering fallback. Fallback latches for the current orb mount; leaving/re-entering Chat starts a new measurement window. OS animation preference cannot be overridden by the app setting. Listening/speaking labels are explicit visual previews with microphone off; no speech availability claim.

## Slice A redesign

Shell is the sole engine-timing observer, removing its callback on disposal. Pure-Dart frame_metrics contains bounded statistics and the hysteresis governor; Riverpod quality/overlay settings own composition. Render-only MotionClock drives painter repaint signals with tier-specific intervals, without rebuilding chat for each animation tick. Repaint boundaries isolate background, orb and message/composer surfaces. No blur, saveLayer, custom fragment shader, animated whole-screen opacity or remote image loading.

ChatController archives each in-memory room and fences late streaming events across Stop/new/select/delete. Timestamp is created once per entry and retained during deltas/Stop. Session summaries are reused while only message text streams, avoiding sidebar rebuilds per token. Lazy ListView.builder renders messages with maximum reading width; message entry movement, glass surfaces and palette-driven tokens are presentation only. LocalMarkdown is a documented offline subset, never an executable/HTML/network renderer.

Linux runner explicitly selects the installed SDK's Skia backend via fl_dart_project_set_enable_impeller(project, FALSE), after measured Impeller OpenGLESSDF stalls on HD 520. Windows/Android/iOS runners are unchanged and unverified. Lite breathes by a small transform around a cached static orb painting, rather than rebuilding gradient geometry each tick. Automatic quality starts Lite and only promotes after measured healthy windows; app/OS reduced motion disables the transform too.

## Part 2 implemented local provider and storage

Domain `LlmProvider`, `LlmSettings`, messages, cancellation and failures remain pure Dart. OllamaService owns dart:io loopback-only transport: proxies/redirects disabled, NDJSON streamed with byte/line limits, UTF-8 decoding, typed failures, connection/response deadlines and actual connection abortion. No package HTTP adapter, credentials, cloud routing or model pull endpoint. Model switching cancels and waits before unloading the previously selected model; another resident model produces a recovery message instead of loading a second. External Ollama clients can race the daemon and are outside this app's control.

Match-input mode resolves the latest input's Gujarati Unicode block versus English before creating a single explicit language instruction. This avoids a general Gujarati instruction dominating English replies in the small models. Transliteration is not language detection; mixed text containing Gujarati selects Gujarati. The forced language setting overrides this heuristic. Instructions cannot guarantee correct or fluent replies.

Riverpod composes the selected real provider or labeled Mock demo. ChatController still fences stale output, bounds inter-event wait to 95 seconds, and saves immutable snapshots through LocalStore's serialized queue. Streaming checkpoints are at most once per second, marked interrupted until a completed reply is saved. NativeDatabase.createInBackground runs database I/O in an isolate. Drift schema v2 contains conversation, ordered message and non-secret setting rows; migration v1→v2 adds the stopped flag and per-message provider label, keeping older scripted replies honestly labeled. Referential integrity/cascade, file reopen, Gujarati fidelity, setting restore, search and deletion are tested. Search scans loaded title/message strings; history is currently loaded in full, so very large histories need future pagination and incremental writes before scale claims.

Bootstrap resolves the platform application-support directory, opens jarvis.sqlite, loads the snapshot and overrides Riverpod dependencies before displaying the shell. Failure offers retry and never recreates/deletes the database automatically. Runtime save failure is visible in Chat/Settings. Plain SQLite is unencrypted; account/file permissions provide protection. Logical deletion is not forensic erasure of filesystem/database journal remnants. There is no credential UI or stored secret. Optional credential storage will be implemented only with an authorized optional provider.

The pinned sqlite3 3.7.0 hook bundles a hash-verified native asset; no system SQLite install or JVM is needed for desktop. Android JNI remains an audited path_provider transitive, with optional desktop JVM discovery disabled. Android/iOS runner configuration is unchanged. The manual Windows workflow tests SQLite migration/CRUD and builds an unsigned bundle, pending actual GitHub execution. Onboarding currently consists of honest empty-state labeling, Settings endpoint/model diagnostics and exact recovery instructions; LAN/mobile configuration and fuller onboarding remain unimplemented acceptance gates.
