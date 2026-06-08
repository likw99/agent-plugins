# OpenCode Install

OpenCode does not currently use the Claude/Codex marketplace manifest directly.
Use this repository as a skill source and load the relevant `SKILL.md` files
from `plugins/`.

Start with:

- `plugins/build-visionos-apps/README.md`
- `plugins/build-visionos-apps/skills/build-run-debug-visionos/SKILL.md`
- `plugins/build-visionos-apps/skills/visionos-scenes-and-spaces/SKILL.md`
- `plugins/build-visionos-apps/skills/realitykit-entities/SKILL.md`

For a quick agent prompt:

```text
Fetch and follow the relevant visionOS plugin instructions from
https://github.com/likw99/agent-plugins/tree/main/plugins/build-visionos-apps
```
