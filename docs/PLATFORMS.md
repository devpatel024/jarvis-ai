# Platform capability plan

All entries are planned, not hardware/build verified. Official Flutter platform guidance: https://docs.flutter.dev/reference/supported-platforms and https://docs.flutter.dev/platform-integration . Reviewed 2026-10-10.

| Capability | Linux / Windows | Android | iOS |
|---|---|---|---|
| UI, local productivity/storage | Native desktop builds; Ubuntu 26.04 compatibility to test | Physical USB device; no emulator requirement | Shared source preserved; macOS build pending |
| Ollama text/embeddings/vision | CPU localhost, explicit models | Explicit trusted LAN host, disconnected productivity | Same LAN architecture; no native Ollama assumption |
| STT/TTS | whisper.cpp tiny/base or Vosk, Piper after approvals/offline proof | Native bindings and licenses must pass feasibility; offline only | Native bindings/OS offline proof pending; text fallback |
| Wake word | Explicit opt-in only after reliability/license review | Background/battery restrictions; push-to-talk baseline | Restricted background execution; push-to-talk baseline |
| Reminders | Running/restarted-app reconciliation; app-closed delivery platform dependent | OS permission and scheduling/battery limits tested | OS notification/background limits reviewed |
| Tray/hotkey/screenshots | Windows supported APIs to verify; X11/Wayland/portal differences; in-app shortcuts/manual image selection fallback | Desktop-only capabilities reported unsupported | Same |
| Files/clipboard | Scoped picker/grants; clipboard only triggered by user | Scoped storage/picker/share | Picker/share support reviewed |
| Widget/share/camera | Image selection where camera unavailable | Phase 10 physical-device validation | Shared fallback and source compatibility review |
| Packaging | Linux locally after SDK approval; Windows Actions explicit quota-aware build | Local APK/AAB; signing separated | macOS/Xcode and signing constraints; no verified build claim |

No toolchains installed in Phase 0. Reference machine 8 GB RAM/shared graphics: serialize heavy work; benchmark 1b and 3b; no emulator. User LAN destinations must be visible and transport security explicitly addressed. Do not open Ollama to the internet.
