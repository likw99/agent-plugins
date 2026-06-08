---
description: Create or use a project-local visionOS build/run script, then launch on the visionOS Simulator.
argument-hint: "[scheme] [workspace|project] [bundle_id] [simulator] [mode]"
---

# /build-and-run-visionos-app

Create or update the project-local visionOS `build_and_run.sh` script, wire the
Codex app Run button, then use that script as the default build/run entrypoint on
the visionOS Simulator.

## Arguments

- `scheme`: Xcode scheme name (optional)
- `workspace`: path to `.xcworkspace` (optional)
- `project`: path to `.xcodeproj` (optional)
- `bundle_id`: app bundle identifier (optional; needed to launch + filter logs)
- `simulator`: visionOS simulator device name (optional, default: `Apple Vision Pro`)
- `mode`: `run`, `logs`, `debug`, `verify`, or `device` (optional, default: `run`)

## Workflow

1. Detect whether the repo uses an Xcode workspace or project, and confirm the
   platform is visionOS (deployment target, `ImmersiveSpace`/`RealityView`,
   `RealityKitContent` package).
2. If the workspace is not inside git yet, run `git init` at the project root so
   Codex app git-backed features unlock (never nest inside a parent repo).
3. List schemes (`xcodebuild -list`) and resolve the app scheme + bundle id.
4. Pick a simulator destination (`xcrun simctl list devices visionOS`); default to
   `platform=visionOS Simulator,name=Apple Vision Pro`.
5. Create or update `script/build_and_run.sh` so it boots the sim, builds,
   installs the `.app`, and launches. Follow the canonical contract in
   `../skills/build-run-debug-visionos/references/run-button-bootstrap.md`.
6. Write/update `.codex/environments/environment.toml` with a `Run` action
   pointing at `./script/build_and_run.sh` (exact shape in the reference).
7. Run the script in the requested mode and summarize any build/install/launch failure.

## Guardrails

- Do not initialize a nested git repo inside an existing parent checkout.
- Do not leave stale `Run` actions pointing at old script paths.
- Keep the no-flag script path simple: boot, build, install, launch.
- Use `logs`, `debug`, `verify`, or `device` only when the user asks for them.
- Do not claim hand/eye/world-sensing behavior from the simulator.
