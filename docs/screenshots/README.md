# Slice A native captures

Captured from the actual JarvisApp in a Linux profile build using the final Skia default, using synthetic English/Gujarati messages only. Every palette has both dark/light variants, desktop 1200×900 empty/chat captures. Aurora also has phone-layout 390×900 empty/chat captures. These are constrained native Linux renders, not physical Android or Windows screenshots. Captures force Lite + reduced motion for repeatability; animation performance is measured separately. No external images or runtime fonts.

| Palette | Desktop dark | Desktop light |
|---|---|---|
| Aurora | [Empty](aurora-dark-1200-empty.png) · [Chat](aurora-dark-1200-chat.png) | [Empty](aurora-light-1200-empty.png) · [Chat](aurora-light-1200-chat.png) |
| Neon Cyber | [Empty](neonCyber-dark-1200-empty.png) · [Chat](neonCyber-dark-1200-chat.png) | [Empty](neonCyber-light-1200-empty.png) · [Chat](neonCyber-light-1200-chat.png) |
| Sunset | [Empty](sunset-dark-1200-empty.png) · [Chat](sunset-dark-1200-chat.png) | [Empty](sunset-light-1200-empty.png) · [Chat](sunset-light-1200-chat.png) |
| Emerald | [Empty](emerald-dark-1200-empty.png) · [Chat](emerald-dark-1200-chat.png) | [Empty](emerald-light-1200-empty.png) · [Chat](emerald-light-1200-chat.png) |
| Mono Glow | [Empty](monoGlow-dark-1200-empty.png) · [Chat](monoGlow-dark-1200-chat.png) | [Empty](monoGlow-light-1200-empty.png) · [Chat](monoGlow-light-1200-chat.png) |

Aurora phone: [dark empty](aurora-dark-390-empty.png), [dark chat](aurora-dark-390-chat.png), [light empty](aurora-light-390-empty.png), [light chat](aurora-light-390-chat.png).

Reproduce from repo root:

```sh
/home/dev/development/flutter/bin/flutter run -d linux --profile --no-pub -t tool/slice_a_capture.dart
```

Review all generated PNGs after code/font changes. Phone empty states and conversations can scroll; code fences use horizontal scrolling rather than clipping long lines. Timestamp values reflect capture time; no personal user content is captured.
