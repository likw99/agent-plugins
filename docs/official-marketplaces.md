# Official Marketplace Submission Notes

## Claude Code / Claude Plugin Directory

Anthropic documents a public submission path for third-party plugins:

1. Make the plugin repo public.
2. Run `claude plugin validate` against the plugin before submission.
3. Submit either a GitHub URL or a zip through one of Anthropic's in-app forms:
   - Claude.ai: `https://claude.ai/settings/plugins/submit`
   - Console: `https://platform.claude.com/plugins/submit`

The published directory appears in Claude Code as `claude-plugins-official`.
Anthropic runs automated review, and verified status is a separate deeper review.

## Codex Official Plugin Directory

OpenAI documents Codex plugins and the in-app plugin library, but a public
self-serve submission form for the official Codex directory was not found in the
current public docs. Practical path:

1. Keep this marketplace public and easy to install.
2. Validate the Codex manifest with the local plugin validator.
3. Add a crisp README, screenshots, privacy/security notes, and examples.
4. Build usage signals from the public marketplace.
5. Pursue official distribution through Codex/OpenAI partner or developer
   channels when a submission route is available.

## Third-party Discovery

Also consider submitting to community registries and awesome lists once the first
release is stable. They are not official marketplaces, but they help users find
the plugin while official Codex submission remains unclear.
