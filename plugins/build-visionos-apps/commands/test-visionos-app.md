---
description: Run visionOS app tests on the visionOS Simulator and triage failures.
argument-hint: "[scheme] [workspace|project] [simulator] [filter]"
---

# /test-visionos-app

Run a visionOS app's tests on the visionOS Simulator and triage failures.

## Arguments

- `scheme`: Xcode scheme name (optional)
- `workspace`: path to `.xcworkspace` (optional)
- `project`: path to `.xcodeproj` (optional)
- `simulator`: visionOS simulator device name (optional, default: `Apple Vision Pro`)
- `filter`: test target/class/method to run (optional)

## Workflow

1. Detect the workspace/project and the test-enabled scheme.
2. Pick a visionOS simulator destination
   (`platform=visionOS Simulator,name=Apple Vision Pro`).
3. Run tests:
   `xcodebuild test -scheme <S> -destination '<DEST>' [-only-testing:<filter>]`.
4. Summarize results: counts, the first real failure, and the smallest useful
   error snippet.
5. Triage each failure: classify as build error, assertion failure, simulator
   capability gap (hand/eye/world sensing not in simulator), timing/async flake,
   or environment issue.
6. Recommend the narrowest next action; note when a failure is only reproducible
   (or only valid) on an Apple Vision Pro device.

## Guardrails

- Do not treat simulator-only capability gaps as product bugs.
- Quote the smallest useful failure snippet; don't dump full logs.
- Prefer `-only-testing:` to iterate quickly on a single failing test.
