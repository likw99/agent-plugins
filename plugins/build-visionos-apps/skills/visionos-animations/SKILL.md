---
name: visionos-animations
description: Animate visionOS UI and 3D content — SwiftUI animations, symbol effects, and RealityKit entity/skeletal animation. Use when building loading/in-progress indicators, animating views or entities, or showing engaging feedback during long async work.
---

# visionOS Animations

## Overview
Use this skill to add motion in two layers: **SwiftUI** (2D views, ornaments,
overlays, progress) and **RealityKit** (3D entities in volumes/immersive spaces).
The driving use case is engaging feedback during a long async job — e.g. a
text-to-3D generation that takes seconds to minutes — plus general view/entity
animation. Keep motion comfortable: spatial content should not loom, swing wide,
or fill the field of view.

## Decision Tree

1. **2D feedback (window/volume UI, ornaments, progress, status)** → SwiftUI:
   `ProgressView`, `.symbolEffect`, `.phaseAnimator`, transitions.
2. **In-scene 3D motion (spin a placeholder model, orbit, pulse)** → RealityKit:
   `playAnimation` with `FromToByAnimation`/`OrbitAnimation`, or a custom `System`.
3. **Authored timeline animation shipped with content** → Reality Composer Pro
   timelines on entities in the `RealityKitContent` package.
4. **Model has baked animations (USDZ/skeletal)** → play `entity.availableAnimations`.

## Loading-state pattern (the core recipe)

For a long async job, drive UI from the job's state/progress:

```swift
// Determinate when progress is known (e.g. task.progress 0...1)
ProgressView(value: progress)            // animates smoothly as value changes
// Indeterminate when unknown
ProgressView().controlSize(.large)

// Animated status icon
Image(systemName: "sparkles")
    .symbolEffect(.variableColor.iterative, isActive: isWorking)

// Engaging step transitions
Text(statusText)
    .contentTransition(.numericText())
    .transition(.opacity.combined(with: .scale))
```

Pair a 2D progress panel with a **spinning placeholder entity** in the
volume/space while generating, then swap in the real model on completion
(see `references/loading-progress-patterns.md`).

## SwiftUI quick snippets

```swift
withAnimation(.spring) { isExpanded.toggle() }          // imperative
view.animation(.easeInOut, value: isExpanded)           // value-driven

// Multi-step looping animation without manual timers
icon.phaseAnimator([1.0, 1.2, 1.0]) { view, scale in
    view.scaleEffect(scale)
} animation: { _ in .easeInOut(duration: 0.6) }
```

## RealityKit quick snippets

```swift
// Continuous spin on a placeholder/loading entity (visionOS 1.0+)
let spin = FromToByAnimation(
    to: Transform(rotation: .init(angle: .pi, axis: [0,1,0])),
    bindTarget: .transform
)
if let res = try? AnimationResource.generate(with: spin) {
    entity.playAnimation(res.repeat())                  // AnimationPlaybackController
}

// Play a baked/skeletal animation from a loaded USDZ
if let clip = entity.availableAnimations.first {
    entity.playAnimation(clip.repeat(), transitionDuration: 0.3)
}
```

## Checklist

- Loading UI is driven by job state/progress (determinate when known).
- Indeterminate + determinate states both handled; status transitions animate.
- 3D loading motion is subtle (gentle spin/pulse), not looming or wide-swinging.
- Animations stop/clean up when the job ends or the view/scene disappears.
- `playAnimation` controllers are retained if you need to stop them later.
- Respects Reduce Motion (`@Environment(\.accessibilityReduceMotion)`).

## References

- `references/swiftui-animations.md`: animations, transitions, phase/keyframe, symbol effects, progress.
- `references/realitykit-animations.md`: AnimationResource, playAnimation, FromTo/Orbit, skeletal, systems.
- `references/loading-progress-patterns.md`: async-job loading UX (HiPtah text-to-3D recipe).
- See also the `realitykit-entities` skill for entity/RealityView basics.
- Apple: SwiftUI "Animations"; Symbols `symbolEffect`; RealityKit `AnimationResource`,
  `Entity/playAnimation`; HIG > Motion.

## Guardrails

- Don't fill the user's view with large or fast spatial motion (discomfort).
- Don't drive animation with manual `Timer`s when `phaseAnimator`/`playAnimation`/
  value-driven `.animation` fit.
- Don't leak animation controllers/Tasks — stop on completion / `onDisappear`.
- Don't ignore Reduce Motion; offer a calmer fallback.
- Don't block the main thread building animations during loading.

## Output Expectations

State the layer (SwiftUI vs RealityKit), how motion maps to job state, the
stop/cleanup path, and any comfort/Reduce-Motion handling.
