# Setup — Phase 1b

Repository: /home/dev/projects/jarvis-ai. Existing Flutter 3.47.7/Dart 3.13.5 at /home/dev/development/flutter/bin; Linux toolchain is available. No SDK, package, model or native tool installation was performed in Phase 1b.

Run locally from the repository root:

```sh
/home/dev/development/flutter/bin/flutter run -d linux --no-pub
```

Home retains a session-only English/Gujarati scratchpad. Open Chat for a visibly labeled local scripted demo, with Stop and explicit Retry. Expand Demo controls to preview all orb states or simulate a failed reply. Microphone/audio are off. Dark is the default; Settings offers Light/System and Reduce motion. OS animation accessibility preferences take precedence. All data remains in memory and is lost on app exit; no accounts, keys, model files or internet are needed for the demo once existing dependencies are installed.

Actual Ollama setup remains Phase 2. Existing llama3.2:1b/3b downloads exceed the 1 GB approval threshold and must not be pulled silently. Text/embedding/vision capabilities need licensed models and hardware checks. Phones require an explicitly configured trusted user-owned LAN host for AI; local productivity must remain usable disconnected. No emulator prerequisite; physical Android over USB is the planned testing route. Gujarati voice remains unverified until real sample measurements (the user scheduled early voice evaluation in 1b.3; Phase 5 retains broader qualification); there is no cloud fallback.

Read PLAN/HANDOFF at the next session. The next user next begins 1b.3 engine comparison/approval, not 1c or Phase 2. The 1b.2 Developer panel is described in PERFORMANCE; use a profile build for measurements. PERFORMANCE describes native benchmark reproduction and current unmet 60fps goal.

Slice A starts on Chat. History holds session chats and the temporary Unicode scratchpad. Desktop list can collapse; tablet uses rail; phone uses bottom navigation. Ctrl+K commands, Ctrl+N new chat, Enter send, Shift+Enter newline, Esc Stop. Message menus are accessible by their button, hover controls or long press. History menus rename or confirm deletion. Settings > Appearance switches five palettes/light/dark and quality; Developer holds all demo controls and timing numbers. Attachments/voice are informational unavailable labels; paste text instead. All state resets on exit. No 1b.3/1c/Phase 2 authorization follows automatically from this redesign.

Linux uses Skia selected by its native runner on Flutter 3.47.7; reference-machine Impeller OpenGLESSDF measurements were unacceptable. Automatic quality starts Lite; manually select Balanced/Ultra only after checking Developer timings. Those tiers are not certified at 30/60 fps on this hardware. All motion stops with Reduce motion.
