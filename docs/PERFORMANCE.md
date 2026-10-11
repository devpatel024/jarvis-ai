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


## Part 2 local Ollama evidence — 2026-10-11

Actual reference laptop, Ollama 0.40.3, CPU only (resident size_vram=0), two inference threads, context 2048, generated-token cap 256, temperature 0/seed 42, no models bundled. One model at a time, explicit unload after each group. Other desktop load was uncontrolled (including heavy browser/app activity); single samples are observations, not statistical rankings or promises. No Dart compilation ran during the final comparison. Peak RAM here is the sampled sum of ollama + llama-server process VmRSS every 100 ms, including server/runner and possibly double-counted shared pages; it excludes Flutter app RSS. TTFT measures request start to first nonempty content chunk; generation tokens/sec uses Ollama eval_count/eval_duration, excluding prompt evaluation/load. Cold and warm TTFT must not be compared as interchangeable.

The app now resolves the latest input's Gujarati Unicode block to an explicit Gujarati instruction, otherwise English; forced language settings override this. Earlier broad instructions made English answers drift into Gujarati; an English “Latin script” wording also produced unnatural Latin phrases and was removed. The final English two-case measurements replace only English rows; Gujarati rows retain the identical Gujarati prompt/options from the prior run. Raw dates, prompts, complete replies, digests, options and memory snapshots: [Llama raw comparison](performance/ollama-comparison.json). Every Gujarati result below contains Gujarati characters and zero Devanagari, which measures script compliance, not fluency.

| Model / prompt | TTFT seconds | Generation tokens/sec | Peak server+runner RSS GiB | Quality observation |
|---|---:|---:|---:|---|
| llama3.2:1b / English greeting (cold) | 12.75 | 3.35 | 1.40 | Correct greeting and day question |
| llama3.2:1b / English planning (warm) | 1.34 | 3.34 | 1.40 | Two relevant planning steps |
| llama3.2:1b / Gujarati greeting (warm) | 7.45 | 3.54 | 1.41 | Gujarati script, irrelevant property/business question |
| llama3.2:1b / Gujarati planning (warm) | 6.48 | 3.14 | 1.42 | Gujarati script, repetitive/irrelevant; cap hit before two useful steps |
| llama3.2:3b / English greeting (cold) | 33.17 | 2.08 | 2.22 | English greeting; does not actually ask the requested question |
| llama3.2:3b / English planning (warm) | 4.02 | 1.88 | 2.21 | Two clear planning steps |
| llama3.2:3b / Gujarati greeting (warm) | 19.03 | 2.03 | 2.24 | Gujarati script, understandable day-planning question |
| llama3.2:3b / Gujarati planning (warm) | 14.11 | 1.83 | 2.26 | Gujarati script, repeats first step; cap hit before two steps |

Both Llama models are poor on the Gujarati planning task. 3b's greeting is better, but neither is demonstrated as reliable Gujarati conversation. 1b remains the unchanged user-selected fast default, and 3b the selectable quality mode; no silent model change. English works better on these short tests. Gujarati voice is not implemented or verified. Model provenance and redistribution terms are separate from Ollama's MIT engine license; reviewed Llama license/details in dependencies/llama-models.json.

Reproduce existing-model English/Gujarati comparison (never pulls):

```sh
python3 tool/ollama_benchmark.py
```

### Approved Gujarati-only candidates

User approved qwen2.5:1.5b and qwen3:0.6b download/test only, with Qwen3 thinking disabled and unchanged app defaults. Both exact tags are Apache-2.0: [Qwen2.5 model page](https://ollama.com/library/qwen2.5:1.5b), [Qwen3 model page](https://ollama.com/library/qwen3:0.6b). Manifest/layer SHA-256 and actual approved sizes in dependencies/model-candidates.json. The benchmark sends think:false per [Ollama thinking controls](https://docs.ollama.com/capabilities/thinking), rejects unexpected thinking text and verifies one CPU-only resident model. Only Gujarati prompts are tested for candidates, per latest instruction; English candidate support is unmeasured.

[Candidate raw replies/metrics](performance/ollama-alternatives.json), with thinking_characters=0 in all four replies and resident_after=[] after explicit unload. Each model starts cold for the question; planning is warm. Human quality notes evaluate requested task completion and recognizable Gujarati wording, not a native-speaker fluency score. These are two prompts per model, not a comprehensive language evaluation.

| Candidate / Gujarati prompt | TTFT seconds | Tokens/sec | Peak server+runner RSS GiB | Gujarati / Devanagari characters | Makes sense as the requested answer? |
|---|---:|---:|---:|---:|---|
| qwen2.5:1.5b / question (cold) | 10.09 | 4.74 | 1.09 | 139 / 0 | No: rambling, grammatically broken, does not ask a useful day question; 256-token cap |
| qwen2.5:1.5b / planning (warm) | 3.02 | 4.75 | 1.09 | 139 / 0 | No: repetitive/irrelevant, no two practical steps; 256-token cap |
| qwen3:0.6b / question (cold) | 6.17 | 9.89 | 0.81 | 33 / 0 | No: echoes the user instruction instead of asking a question |
| qwen3:0.6b / planning (warm) | 1.45 | 10.19 | 0.83 | 31 / 0 | No: echoes the planning instruction instead of giving two steps |

Qwen2.5 produces poor, repetitive Gujarati; Qwen3 produces recognizable Gujarati but parrots the instructions. Neither is recommended as reliable Gujarati chat from these observations. Qwen3's high throughput/short completion reflects failure to do the task; it is not proof of faster useful answers. No app picker/default changes were made; these models are comparison-only installed assets. They remain on disk but are unloaded from RAM.

Reproduce approved comparison only, after setup (no downloads):

```sh
python3 tool/ollama_benchmark.py --models qwen2.5:1.5b qwen3:0.6b --gujarati-only --output docs/performance/ollama-alternatives.json
python3 tool/ollama_benchmark.py --models llama3.2:1b --gujarati-only --output docs/performance/ollama-gujarati-baseline.json
```

The second command supplies a matched cold-question/warm-planning Llama1b baseline without earlier English warmup. Run sequentially, with no other Ollama client. Engine options and system prompt are identical; other desktop load remains uncontrolled. Candidate testing is Gujarati-only by explicit latest instruction, overriding the earlier plan for English candidate comparisons.

Matched [Llama1b rerun](performance/ollama-gujarati-baseline.json) immediately followed the Qwen groups; no model remained loaded after it.

| Llama1b Gujarati prompt | TTFT seconds | Tokens/sec | Peak server+runner RSS GiB | Gujarati / Devanagari characters | Quality |
|---|---:|---:|---:|---:|---|
| Question (cold) | 12.61 | 3.89 | 1.41 | 87 / 0 | Irrelevant property/business question |
| Planning (warm) | 3.67 | 3.78 | 1.42 | 125 / 0 | Repetitive/irrelevant planning, 256-token cap; no useful two-step answer |

Neither candidate is clearly worse than Llama1b on both speed and Gujarati: both have higher measured token throughput, lower cold and warm TTFT, and lower sampled process RSS in this run, while task quality is poor across all three. Qwen2.5 is rambling and fails both tasks; Qwen3 echoes both instructions. Llama3b previously gave the most understandable greeting, but failed planning and was much slower. No tested model earns a recommendation for reliable Gujarati conversation. Keep the user's existing 1b fast / 3b quality defaults unchanged; any future default change requires separate approval. These tiny samples do not certify language quality.

### Part 2 build/cache verification

Dart format, clean analyzer, 61 passing tests, real-file database CRUD/reopen/migration/controller restart tests and Linux release build. Native release startup with a temporary application-support directory created schema v2; bundled libsqlite3.so is 1,788,664 bytes and SHA-256 0f947ebe629e8d9d02d7f408bef36e056bfc63ea47e02e0d45a7bae454f04ace. A subsequent release rebuild succeeded with IP socket creation denied (EPERM probe) by the existing execution sandbox, using --no-pub and the cached native artifact. Offline locked pub resolution also succeeded. First uncached package/native setup needs internet; this does not imply all future SDK/toolchain changes are cached. Windows CI remains unexecuted; Android/iOS native support is documented, not runtime verified. No new orb/frame-time claim: previous measured 30/60fps target remains unmet.
