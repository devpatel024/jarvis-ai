> Earlier Phase 1b numbers below are historical. The UI has changed; use the Slice A harness and current evidence in the final section for reproduction.

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


## Slice A measured evidence — 2026-10-11

Actual reference laptop: Ubuntu 26.04.1 LTS/kernel 7.0.0-38-generic, i5-6300U 2 cores/4 threads, Intel HD 520/i915, 8 GB nominal (7.1 GiB OS-visible), Flutter 3.47.7/Dart 3.13.5. Profile build, actual JarvisApp with English/Gujarati scripted streams and code example, overlay off, no screenshots/tests during timed run. Each tier forced for a 12-second workload after 4 seconds warmup; 48.284 seconds total. Native window at final report: 3072×1436 physical, DPR 2.0 (1536×718 logical). Existing desktop load not controlled; GDK_BACKEND=x11 in a Wayland session; one startup GTK OpenGL resize/frame wait timeout. Timing report: performance/slice-a-linux-profile.json. Peak app RSS 223.6 MiB over the whole run, not per-stage memory.

| Forced tier | Frames | Build mean / p95 ms | Raster mean / p95 ms | Total span p95 ms |
|---|---:|---:|---:|---:|
| Ultra | 121 | 13.016 / 33.307 | 57.686 / 90.146 | 168.656 |
| Balanced | 127 | 11.426 / 32.484 | 54.362 / 85.208 | 166.569 |
| Lite | 121 | 12.856 / 33.016 | 43.724 / 84.876 | 145.325 |

30/60fps targets are NOT MET on this measured desktop. Animation timer caps are upper bounds on repaint requests, not delivered FPS. Lite uses a 10 Hz small cached-orb scale pulse on a static background, and is the conservative automatic starting mode; reduced motion stops the pulse entirely. Text/scene updates can also produce frames. No claim of universally smooth motion or sub-100 ms interaction latency; total span includes pipeline scheduling and is not a measured keyboard latency. Repeat on a quiet desktop and inspect the overlay. Higher tiers remain manual options and automatic recovery requires healthy measured windows.

Renderer decision: initial default Impeller OpenGLESSDF run was unacceptable (raster p95 Ultra 2982.404 ms / Balanced 684.764 ms / Lite 314.415 ms) with startup resize warnings; saved performance/slice-a-impeller-initial.json. A CLI Skia comparison improved results (Lite p95 81.614 ms), saved performance/slice-a-skia-comparison.json. Initial run used 2-second warmups versus 4 seconds for comparison/final; uncontrolled load/resize differences prevent a strict renderer-only A/B claim. Linux now explicitly selects the SDK's Skia backend via fl_dart_project_set_enable_impeller(project, FALSE), supported by the installed SDK header. Final run uses that normal default without command-line renderer override. Other runners are unchanged and unverified. Do not infer Windows/Android performance from Linux numbers.

Reproduce current measurement:

```sh
/home/dev/development/flutter/bin/flutter run -d linux --profile --no-pub -t tool/slice_a_benchmark.dart
```

Run normal app, Settings > Developer overlay/readouts, and compare actual tiers with Reduce motion off/on. Readouts keep the last 120 samples each and attribute by tier at engine report time; transition batches can straddle tiers. Reset only clears the measurements, not automatic policy. Lite cached painting reduces per-tick gradient geometry work; streaming still changes text. Native screenshots force Lite + reduced motion for repeatability and are not frame-time evidence. PNG index: screenshots/README.md; capture harness: tool/slice_a_capture.dart. Review dark/light, Gujarati shaping, desktop/phone layouts; native keyboard/IME/clipboard/screen-reader and physical mobile checks remain manual.
