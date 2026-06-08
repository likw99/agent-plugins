# Agent Plugins Marketplace

This repository is a cross-agent plugin marketplace. For Gemini CLI, treat this
extension as a lightweight catalog and install individual plugin guidance from
the `plugins/` directory.

Available plugins:

- `build-visionos-apps`: visionOS, RealityKit, Reality Composer Pro, spatial
  gestures, and Xcode workflows.

When a user asks for visionOS app work, read:

- `plugins/build-visionos-apps/README.md`
- the relevant `plugins/build-visionos-apps/skills/*/SKILL.md` files

Prefer the smallest relevant skill file for the current task.
