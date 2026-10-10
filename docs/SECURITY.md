# Security and privacy plan

Threat boundaries: models, files, OCR, clipboard, retrieved text and tool output are untrusted and never authorize actions. OS permission does not confer action approval. Policy validates typed schemas, grants and exact arguments before execution; destructive/system confirmations are fresh and bound to those arguments. No arbitrary model shell text, silent cloud fallback or credential logging.

Data destinations: app-owned local SQLite/attachments/cache; user-selected original documents read only; explicitly configured user-owned Ollama localhost/LAN host; optional external information only if activated; optional paid provider only with distinct data consent. No telemetry/backend/sync. Disable Android/iOS backup of app data where configuration permits to honor no-cloud intent, and verify actual platform behavior.

SQLite is not automatically encrypted. Document filesystem permissions, OS disk encryption and actual secure-store behavior without claiming database encryption. Secure-store failure disables optional credentials safely. Never request secrets in chat or fixtures.

Memory confirmation and candidate redaction/rejection cover passwords, payment cards and ID numbers with adversarial tests; detection is imperfect and described honestly. Memory off disables extraction and retrieval while history remains independently controlled.

Export excludes credentials. Confirmed delete cancels jobs, reminders and queues then clears only app-owned database, attachments/index/cache/credentials; leaves original documents intact. Report exported copies and optional provider retention separately. Restart-safe deletion and action deduplication need tests.

Required tests: injection cannot grant permission; exact-argument mismatch; sensitive-memory rejection; revoked file grant; cloud excerpt consent; redacted logs; duplicate prevention; compensating undo; cancellation; full app-data deletion.
