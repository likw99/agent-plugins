# Hermes Support

Hermes can consume SKILL.md-style skills through GitHub/path-based skill sources.
This marketplace keeps each plugin's durable instructions in normal `SKILL.md`
files so Hermes and other agentskills-compatible runtimes can reuse them.

For `build-visionos-apps`, install or reference the skill directory:

```text
likw99/agent-plugins/plugins/build-visionos-apps/skills
```

Recommended first skills:

- `build-run-debug-visionos`
- `visionos-scenes-and-spaces`
- `realitykit-entities`
- `reality-composer-pro`
- `spatial-gestures-interaction`

Keep Hermes installs skill-first. The Codex/Claude plugin manifests are present
for those harnesses, but Hermes does not need to ingest the whole plugin package
unless its plugin loader grows native support for this marketplace shape.
## hermes-tweet

Hermes Tweet is already a native Hermes Agent plugin. Reference the source
repository or its exported skill directory:

```text
Xquik-dev/hermes-tweet
Xquik-dev/hermes-tweet/skills/hermes-tweet
```

Recommended first skill:

- `hermes-tweet`

Keep `tweet_action` approval-gated through the plugin runtime and configure
`XQUIK_API_KEY` only in the Hermes runtime environment.