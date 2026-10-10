# Architecture decisions — Phase 0

Feature-first clean layers; app composes Riverpod repositories, domain is pure Dart and data adapters own storage/providers. Typed Result and injectable Clock; deterministic fakes.

LlmProvider exposes neutral messages/attachments, capabilities, cancellable event streams (text/tool/usage/completion/error), deadlines, context limits and bounded idempotent retries. Mock is labeled demo; Ollama default real provider. Tool planning uses schema validation where native tools unavailable. Non-idempotent actions never auto-retry.

Capability interfaces cover speech, wake word, notifications/scheduler, scoped files, camera, screenshots, clipboard, hotkeys, tray, widgets and share. Available/denied/unsupported/disconnected states include usable alternatives.

Drift migrations preserve relational entities and history. SQLite vector rows store source hash, chunk/page provenance, model digest/dimensions and grant scope. Bounded exact search first; native extension only after platform approval. Index workers yield to chat; deletion/revocation removes chunks and cancels work.

Memory candidates require accept/edit/reject before durable writes; provenance, scope, timestamps, correction and deletion retained. Global memory switch stops extraction/retrieval separately from chat history.

Tool registry validates schemas and policy outside model code. Eight-step loop with deadline/output limits, fresh exact-argument confirmation for destructive/system actions, durable action IDs, allowlisted executable/argument arrays and redacted log. Undo only for verified compensating operations. Personas and workflows carry declared inputs/permissions and cannot grant themselves authority.

No background inference promise. Opt-in automation uses quiet hours/cooldowns/deduplication and narrow grants. CPU-only single-model execution on reference hardware. Optional cloud routing cannot replace local retrieval or bypass destination consent.
