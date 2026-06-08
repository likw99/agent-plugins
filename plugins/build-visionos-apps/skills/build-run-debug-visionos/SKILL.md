---
name: build-run-debug-visionos
description: Build, run, and debug visionOS apps on the visionOS Simulator or Apple Vision Pro. Use when launching a visionOS app, wiring a run entrypoint, or diagnosing build, startup, or runtime failures.
---

# Build / Run / Debug (visionOS)

## Quick Start

Use this skill to set up one project-local `script/build_and_run.sh` entrypoint,
wire `.codex/environments/environment.toml` so the Codex app shows a Run button,
then use that script as the default build/run path for the **visionOS Simulator**.

Prefer shell-first workflows:

- `./script/build_and_run.sh` as the single boot + build + install + launch entrypoint once it exists
- `xcodebuild` with a visionOS destination for Xcode projects/workspaces
- `xcrun simctl` to boot the simulator, install the `.app`, launch, and stream logs
- `log stream` / `xcrun simctl spawn booted log stream` for unified logging

visionOS apps are GUI apps that must run in the Simulator or on device — there is
no raw-executable launch path. Do not assume macOS desktop launch or iOS
touch-only flows.

If XcodeBuildMCP is available (this plugin wires it via `.mcp.json`), prefer it
for simulator-aware build/run/install/launch, UI inspection, and log capture.
Fall back to `xcodebuild` + `xcrun simctl` immediately when the MCP does not
provide a clean visionOS path.

## Workflow

1. Discover the project shape.
   - Check `git rev-parse --is-inside-work-tree`; if absent, `git init` at the
     project root (never nest inside an existing parent repo).
   - Find `.xcworkspace`, `.xcodeproj`, `Package.swift`.
   - Confirm the platform is visionOS (look for `xrOS`/`visionOS` deployment
     target, `ImmersiveSpace`/`RealityView` usage, a `RealityKitContent` package).

2. Resolve the runnable target, scheme, and bundle id.
   - `xcodebuild -list` to enumerate schemes; prefer the app scheme.
   - Read the bundle identifier (`PRODUCT_BUNDLE_IDENTIFIER`) — needed to launch
     and to filter logs.

3. Pick a simulator destination.
   - `xcrun simctl list devices visionOS` to find a booted/available device.
   - Default destination: `platform=visionOS Simulator,name=Apple Vision Pro`.
   - Boot if needed: `xcrun simctl boot "Apple Vision Pro"` then `open -a Simulator`.

4. Create or update `script/build_and_run.sh` (see `references/run-button-bootstrap.md`).
   - It should always: boot the sim → build → install the `.app` → launch → (optional) stream logs.
   - Keep the no-flag path simple: boot, build, install, launch.
   - Add optional flags: `--logs`, `--debug` (lldb attach), `--device`, `--verify`.

5. Write `.codex/environments/environment.toml` once the script exists, with a
   `Run` action pointing at `./script/build_and_run.sh` (exact shape in references).

6. Build and run through the script. Default to `./script/build_and_run.sh`.

7. Summarize failures correctly.
   - Classify: compiler, linker, signing/provisioning, missing visionOS SDK,
     wrong destination, RealityKitContent build failure, script bug, or runtime crash.
   - Quote the smallest useful error snippet and explain it.

8. Debug the right way.
   - Use `--logs` (unified logging filtered to the app subsystem) for lifecycle,
     immersive-space, and authorization issues.
   - Use `--debug` / `lldb` for symbolicated crash debugging.
   - For RealityKit scene issues, enable the RealityKit debugger in Xcode
     (Debug > RealityKit) when running from Xcode.

## Simulator vs Device (call this out honestly)

The visionOS Simulator does **not** provide:
- real hand tracking or eye tracking (eye-driven hover is simulated via pointer),
- full ARKit world sensing / scene reconstruction / plane detection fidelity,
- accurate Spatial Audio or passthrough lighting.

Recommend an Apple Vision Pro device when the task depends on hand/eye input,
world sensing, or true immersive rendering. Never claim simulator behavior proves
device behavior for those features.

## Preferred Commands

- Discovery: `find . -name '*.xcworkspace' -o -name '*.xcodeproj' -o -name 'Package.swift'`
- Schemes: `xcodebuild -list -workspace <ws>` / `-project <proj>`
- Devices: `xcrun simctl list devices visionOS`
- Build: `xcodebuild -scheme <S> -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build`
- Boot/install/launch: `xcrun simctl boot`, `xcrun simctl install booted <app>`, `xcrun simctl launch booted <bundle-id>`
- Logs: `xcrun simctl spawn booted log stream --level debug --predicate 'subsystem == "<bundle-id>"'`

## References

- `references/run-button-bootstrap.md`: canonical visionOS `build_and_run.sh` and
  `.codex/environments/environment.toml` contract.
- Apple: `developer.apple.com/documentation/visionos` (Getting started),
  "Running your app in the simulator or on a device".

## Guardrails

- Prefer the narrowest command that proves or disproves the current theory.
- Do not leave the user with a one-off manual command chain once a stable
  `build_and_run.sh` can own the workflow.
- Do not write `.codex/environments/environment.toml` before the script exists,
  and do not point the Run action at a stale path.
- Do not claim hand/eye/world-sensing behavior from the simulator.
- Keep the run script out of app source; it belongs in `script/build_and_run.sh`.
- If build output is huge, summarize the first real blocker and point to follow-ups.

## Output Expectations

Provide: detected project type and platform; the script path and Codex Run action
configured; the destination used; whether build/install/launch succeeded; the top
blocker if they failed; and the smallest sensible next action.
