# Agent Plugins

Cross-agent plugins and skills for solo-founder speed: small, practical bundles
that help AI agents build, ship, debug, and operate real products.

This repository is both:

- a Claude Code plugin marketplace, via `.claude-plugin/marketplace.json`
- a Codex plugin marketplace, via `.agents/plugins/marketplace.json`

It also keeps the underlying workflows as normal `SKILL.md` files so Gemini,
Hermes, OpenCode, and other agentskills-compatible runtimes can reuse the same
source material.

## Marketplace Name

```text
agent-plugins-marketplace
```

The name is intentionally broad because this repo will host more than
`build-visionos-apps` over time.

## Available Plugins

### build-visionos-apps

Build, refine, and debug visionOS apps with SwiftUI scenes, RealityKit, Reality
Composer Pro, immersive spaces, spatial gestures, and Xcode workflows.

Included skills:

- `build-run-debug-visionos`
- `visionos-scenes-and-spaces`
- `realitykit-entities`
- `reality-composer-pro`
- `spatial-gestures-interaction`

## Install

### Claude Code

Register this marketplace:

```text
/plugin marketplace add likw99/agent-plugins
```

Install the first plugin:

```text
/plugin install build-visionos-apps@agent-plugins-marketplace
```

### Codex CLI / Codex App

Register this marketplace:

```bash
codex plugin marketplace add likw99/agent-plugins
```

Install the first plugin:

```bash
codex plugin add build-visionos-apps@agent-plugins-marketplace
```

Start a new thread after install so newly exposed skills and tools are loaded.

### Gemini CLI

Gemini CLI uses extensions rather than the Claude/Codex marketplace manifest.
Install this repo as a lightweight catalog extension:

```bash
gemini extensions install https://github.com/likw99/agent-plugins
```

Then ask Gemini to use the relevant plugin docs under `plugins/`.

### Hermes

Hermes should consume the `SKILL.md` files directly. See `docs/hermes.md` for
the skill-first install path.

### OpenCode

OpenCode users can start from `.opencode/INSTALL.md`, which points agents at the
same durable plugin instructions.

## Repository Layout

```text
agent-plugins/
  .claude-plugin/
    marketplace.json
  .agents/
    plugins/
      marketplace.json
  plugins/
    build-visionos-apps/
      .claude-plugin/
        plugin.json
      .codex-plugin/
        plugin.json
      .mcp.json
      commands/
      skills/
      assets/
  docs/
    official-marketplaces.md
    hermes.md
```

## Validate

Claude:

```bash
claude plugin validate .
claude plugin validate ./plugins/build-visionos-apps
```

Codex plugin manifest:

```bash
python3 /Users/k/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py ./plugins/build-visionos-apps
```

## Official Marketplace Notes

See `docs/official-marketplaces.md`.

Short version:

- Claude has a documented public submission path through in-app forms.
- Codex has a documented plugin library, but no public self-serve official
  submission form was found in current public docs.
