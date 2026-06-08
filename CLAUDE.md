# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A cross-agent plugin marketplace hosted at `likw99/agent-plugins`. It serves:

- **Claude Code** via `.claude-plugin/marketplace.json`
- **Codex CLI/App** via `.agents/plugins/marketplace.json`
- **Gemini CLI** via `gemini-extension.json` + `GEMINI.md`
- **Other agents** (Hermes, OpenCode) via raw `SKILL.md` files in `plugins/*/skills/`

The repo is both the plugin source and the marketplace registry — no build step, no transpilation.

## Plugin Structure

Each plugin lives under `plugins/<name>/` and contains:

```
.claude-plugin/plugin.json   # Claude plugin manifest
.codex-plugin/plugin.json    # Codex plugin manifest
.mcp.json                    # MCP server config (if the plugin needs tools)
commands/                    # Slash commands (*.md with YAML frontmatter)
skills/                      # Skills consumed by agents
  <skill-name>/
    SKILL.md                 # Primary skill content
    references/              # Supporting reference docs
    agents/openai.yaml       # OpenAI-compatible agent config
assets/                      # Icons and images
install.sh                   # Codex local install script
```

Skills in `skills/*/SKILL.md` are the canonical source — all agent runtimes read the same files.

## Validate a Plugin

```bash
# Claude plugin validation
claude plugin validate .
claude plugin validate ./plugins/build-visionos-apps

# Codex plugin validation
python3 /Users/k/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py ./plugins/build-visionos-apps
```

## Install Locally (Codex)

```bash
# Symlink into Codex plugin cache
./plugins/build-visionos-apps/install.sh

# Pull latest then re-link
./plugins/build-visionos-apps/install.sh --update
```

## Marketplace Registration

```bash
# Claude Code
/plugin marketplace add likw99/agent-plugins
/plugin install build-visionos-apps@agent-plugins-marketplace

# Codex CLI
codex plugin marketplace add likw99/agent-plugins
codex plugin add build-visionos-apps@agent-plugins-marketplace
```

## Current Plugin: build-visionos-apps v0.2.0

Skills: `build-run-debug-visionos`, `visionos-scenes-and-spaces`, `realitykit-entities`, `reality-composer-pro`, `spatial-gestures-interaction`, `spatial-audio-sound`, `speech-to-text`, `visionos-animations`

MCP server: `xcodebuildmcp` via `npx xcodebuildmcp@latest mcp` with workflows: `simulator,ui-automation,debugging,logging`

## Adding a New Plugin

1. Create `plugins/<name>/` following the structure above.
2. Add `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` manifests.
3. Register in `.claude-plugin/marketplace.json` (root) and `.agents/plugins/marketplace.json`.
4. Add skills under `skills/<skill-name>/SKILL.md`.
5. If tools are needed, add `.mcp.json`.

## Reference Docs

- [Claude Code Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Codex Plugins Build Guide](https://developers.openai.com/codex/plugins/build)

## Key Design Decisions

- **No build step** — everything is Markdown + JSON. Agents read files directly.
- **Skill-first** — `SKILL.md` files are runtime-agnostic; agent-specific shims (OpenAI YAML) live alongside them.
- **Strict mode** — the `build-visionos-apps` plugin uses `"strict": true` in the marketplace manifest, meaning Claude enforces the plugin's skill boundaries.
- **Codex install is a symlink** — `install.sh` creates `~/.codex/plugins/cache/custom/build-visionos-apps -> <repo>/plugins/build-visionos-apps`, so the repo is always the source of truth.
