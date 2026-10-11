# Phase 1b performance evidence — 2026-10-11

Native Linux profile run, not widget-test timings. Host: Ubuntu 26.04.1 LTS, Intel i5-6300U, 2 cores/4 threads, about 7.1 GiB OS-visible RAM; Intel i915 driver, PCI 8086:1916; Wayland session with DISPLAY=:0. Flutter 3.47.7/Dart 3.13.5; engine reported Impeller OpenGLESSDF. App used an existing local SDK, no new graphics/native tools. Reference hardware matches the stated CPU/OS; other running applications and memory pressure were not controlled. The run is not a release-wide benchmark or a promise of sustained 60fps.

Harness renders the actual ChatScreen/CoreOrb in a dark Material shell, sends synthetic Gujarati at 3 seconds and English at 10 seconds, captures engine build/raster/total-span timings for 20 seconds excluding a 2-second startup warmup, then exits. Final timing run did not capture a screenshot. Source and raw timing-only JSON are included in tool/orb_benchmark.dart and docs/performance/phase1b-linux-profile.json.

| Metric | Mean ms | p95 ms | Maximum ms | Frames over 16.667 ms |
|---|---:|---:|---:|---:|
| Build | 6.266 | 20.303 | 25.379 | 8 / 93 |
| Raster | 29.055 | 68.411 | 124.128 | 68 / 93 |
| Total pipeline span | 56.339 | 112.545 | 166.786 | 93 / 93 |

The 60fps target is NOT MET by these measured frames. Build and raster timings are app-wide, not isolated painter costs. Sample count is not FPS: a static fallback intentionally produces no animation frames. The automatic fallback was visible in separate native dark/light captures and is tested via synthetic engine FrameTiming batches. On 12 budget misses in a bounded 60-frame window, the orb becomes static for that mount; timing labels stop generating frames. OS/app reduce motion also makes it static. One-shot error modulation is gentle; no heavy shaders, blur filters, particle systems or extra packages are used.

Reproduce from repository root:

```sh
/home/dev/development/flutter/bin/flutter run -d linux --profile --no-pub -t tool/orb_benchmark.dart
```

Optional synthetic screenshots (app-owned content only; excluded from timing reference run):

```sh
/home/dev/development/flutter/bin/flutter run -d linux --profile --no-pub -t tool/orb_benchmark.dart --dart-define=JARVIS_BENCHMARK_SCREENSHOT=/tmp/jarvis-demo.png
/home/dev/development/flutter/bin/flutter run -d linux --profile --no-pub -t tool/orb_benchmark.dart --dart-define=JARVIS_BENCHMARK_LIGHT=true --dart-define=JARVIS_BENCHMARK_SCREENSHOT=/tmp/jarvis-light.png
```

Dark/light captures were visually inspected: Gujarati sample has readable glyphs and no visible clipping on this Linux setup. fc-match :lang=gu reports installed Noto Sans Gujarati; no font was downloaded or bundled. Widget tests cover 390px and desktop widths, 2x text scaling, theme changes, glyph string preservation, Stop/error/Retry, all orb states, and reduced motion. Other-platform font fidelity is not inferred from widget tests.

Manual checks: launch normal app with flutter run -d linux, open Chat, test Stop midway and Simulate failure/Retry, preview all five states, toggle Settings Reduce motion, inspect Gujarati combining marks and input using your keyboard, and repeat profile timings on a quiet desktop. Keyboard/screen-reader walkthrough and physical Android/Windows/iOS rendering remain pending. Performance tuning and sustained 60fps certification remain Phase 12 gates; static fallback is the current honest alternative.


Phase 1b.2 Developer measurements: run `/home/dev/development/flutter/bin/flutter run -d linux --profile --no-pub`, open Settings > Developer and enable Flutter performance overlay if desired, then Chat. Return to Developer to inspect/refresh build and raster mean/p95 for Animated and Simple orb tiers. Enable Reduce motion to collect simple-tier samples from chat interactions; automatic fallback also selects Simple. Reset clears both retained windows without resetting the orb fallback latch. Toggle the overlay off for comparison; it adds work. Settings/tier buffers reset on app exit. Each tier retains only its last 120 frames. Attribution is at engine batch report time (transition batches may straddle tiers); samples are whole-app timings, not isolated painter timings or wall-clock FPS. Recording samples does not schedule frames; simple tier can legitimately have few/no samples. No new hardware timing claim is made for this UI polish; the table above remains the earlier 1b baseline.
