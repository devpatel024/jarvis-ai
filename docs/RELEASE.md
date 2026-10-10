# Release gates

No builds produced. After approved setup: dart format --output=none --set-exit-if-changed lib test; flutter analyze; flutter test; relevant flutter test integration_test on real targets; flutter build linux --release; flutter build windows --release on Windows; flutter build apk --release; flutter build appbundle --release. flutter build ios --no-codesign requires macOS/Xcode and is pending.

Windows CI requested by user; implement in phase 1 after exact action/tool approvals with explicit triggers, concurrency cancellation, short retention and quota awareness. Local Linux tests remain independent of GitHub. No large model downloads, credentials or paid evaluator in CI.

Baseline gate: offline without keys/accounts after setup, reference-hardware RAM/latency/frame tests, physical Android disconnected-host behavior, source attribution, privacy deletion/export and permission adversarial tests. Supply notices and runnable full desktop bundles, not lone executables. Distinguish Android local signing from distribution credentials, unsigned Windows artifacts from store-ready packages, and iOS unsigned validation from installable releases. Store/certificate costs and local free alternatives reviewed before publication; no automatic publishing.
