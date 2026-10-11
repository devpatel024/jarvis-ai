# Dependency and license approvals

2026-10-10 standing user approval: Flutter/Dart SDK; pub.dev packages verified MIT/BSD/Apache-2.0; Ollama with llama3.2:1b/3b. Always ask for GPL/LGPL/AGPL/noncommercial, unknown/paid terms, account/key, single download over 1 GB or new sudo-requiring native/system tool. These gates override pre-approval.

Manifest selected: flutter_riverpod 3.4.3 MIT, verified https://pub.dev/packages/flutter_riverpod ; Flutter/flutter_test SDK packages exact SDK version pending. No package downloaded; no lockfile/transitive graph resolved. Retain notices and review resolved package/native licenses before claiming clearance. Font assets unselected; system Gujarati font coverage must be tested, not assumed. OFL assets are not within current standing package-license approval.

## Phase 1b audit — 2026-10-11

No manifest/lockfile changes and no downloaded packages, native libraries or assets. Existing installed versions: flutter_riverpod 3.4.3 MIT, flutter_lints 6.0.0 BSD-3-Clause and its lints 6.1.0 BSD-3-Clause transitive; Flutter 3.47.7/Dart 3.13.5. Pure SDK drawing, scheduling, Timer and Riverpod APIs implement this phase. System font fallback is used without bundling a font. Future dependency/native/model approvals remain unchanged.

## Slice A bundled fonts — explicitly approved 2026-10-11

Space Grotesk 2.000, Noto Sans Gujarati 2.106, JetBrains Mono 2.211: SIL Open Font License 1.1. Unmodified TTFs, original notices bundled as Flutter assets under assets/fonts/. Preserve notices, do not sell fonts alone, and honor derivative/reserved-name obligations if modified later. Exact source URLs, pinned Google Fonts commit, sizes and SHA-256 checksums: assets/fonts/SOURCES.json. No runtime downloads or system installation. Approval recorded in PLAN Costs. The custom palette/orb/Markdown implementation adds no package/native dependency; existing locked dependencies retained.
