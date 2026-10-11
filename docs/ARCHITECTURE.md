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
