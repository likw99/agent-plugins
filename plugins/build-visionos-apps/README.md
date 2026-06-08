# Build visionOS Apps Plugin

This plugin packages visionOS and spatial-computing development workflows for
Codex. It distills Apple's official visionOS documentation and sample code into
compact, high-signal skills.

It currently includes these skills:

- `build-run-debug-visionos`
- `visionos-scenes-and-spaces`
- `realitykit-entities`
- `reality-composer-pro`
- `spatial-gestures-interaction`

(Phase 3 adds `swiftui-visionos-patterns`, `visionos-hig-design`, `arkit-spatial`,
`spatial-audio-media`, `visionos-performance`, `visionos-testing-debug`, and
`packaging-signing-visionos`.)

## What It Covers

- choosing between windows, volumes, and immersive spaces, and wiring scene
  transitions (`openWindow`, `openImmersiveSpace`, immersion styles)
- building and refactoring SwiftUI scenes for spatial computing
- loading and composing RealityKit entities, `Model3D`, and USDZ content with
  `RealityView`, the Entity Component System, transforms, materials, and anchors
- authoring 3D scenes with Reality Composer Pro and the `RealityKitContent`
  Swift package, including Shader Graph materials and `.rkassets`
- wiring spatial gestures (tap, drag, rotate, magnify) targeted to entities,
  plus hover effects and the eye/hand input + privacy model
- building, running, and debugging apps on the visionOS Simulator and Apple
  Vision Pro with a project-local `build_and_run.sh` and XcodeBuildMCP

## What It Does Not Cover

- iOS, macOS, watchOS, or tvOS-specific workflows (use the sibling plugins)
- pixel-perfect visual design or design-system generation
- App Store Connect release management
- non-Apple XR platforms

## Plugin Structure

The plugin source of truth lives in this repo at:

- `tools/codex-plugins/build-visionos-apps/`

and is installed into the Codex cache via `install.sh` (symlink) at:

- `~/.codex/plugins/cache/custom/build-visionos-apps/`

with this shape:

- `.codex-plugin/plugin.json`
  - required plugin manifest; defines metadata and points Codex at the contents

- `.mcp.json`
  - plugin-local MCP config; wires in XcodeBuildMCP for visionOS simulator
    build/run/debug/logging workflows

- `agents/`
  - plugin-level agent metadata (`agents/openai.yaml`)

- `commands/`
  - reusable workflow entrypoints for common visionOS development tasks

- `skills/`
  - the actual skill payload; each skill keeps the normal structure
    (`SKILL.md`, optional `agents/`, `references/`, `assets/`, `scripts/`)

## Install

```bash
./install.sh
```

Then restart Codex or refresh plugins. Re-run `install.sh` if the Codex cache is
regenerated.

## Notes

The default posture is shell-first (`xcodebuild`, `swift`, `xcrun simctl`,
`lldb`, `log stream`), with XcodeBuildMCP available for simulator-aware
build/run/debug and UI inspection. visionOS skills assume the visionOS Simulator
for most flows and call out where real hand tracking, eye tracking, and full
ARKit world sensing require an Apple Vision Pro device.
