# Hover Effects, Input Components & the Privacy Model

## Making an entity interactive

Two components are required before any gesture or hover can target an entity:

```swift
entity.components.set(InputTargetComponent())     // receives input
entity.generateCollisionShapes(recursive: true)   // builds CollisionComponent
```

- `InputTargetComponent()` can be tuned: `InputTargetComponent(allowedInputTypes: .indirect)`
  (look+pinch, the default), `.direct` (touch with the hand directly), or `.all`.
- `generateCollisionShapes(recursive:)` auto-creates collision from the mesh; for
  custom hit areas, set a `CollisionComponent` with explicit shapes.
- You can also add these in Reality Composer Pro instead of code.

## Hover effects

Hover gives feedback when the user looks at (eye) or points at (pointer) an entity
— without exposing gaze to your code.

```swift
// Default highlight
entity.components.set(HoverEffectComponent())

// Styles (highlight / spotlight) — visionOS 2+
entity.components.set(HoverEffectComponent(.spotlight(.init(color: .white, strength: 1.0))))

// Drive a Shader Graph material parameter on hover (custom looks)
entity.components.set(HoverEffectComponent(.shader(.default)))
```

In SwiftUI views (attachments, window content): `view.hoverEffect()`.

Use hover for affordance ("this is interactive") and selection feedback. Prefer it
over building a custom cursor — there is no system cursor in shared space.

## The eye/hand privacy model

visionOS is designed so apps cannot see where the user looks:
- **Gaze is private.** The system resolves the looked-at target and applies hover
  effects itself. Your code learns only what was interacted with (via gestures),
  not raw gaze direction or position.
- **Pinch/tap gestures** are delivered as input events (the recipes in
  spatial-gestures.md).
- **Raw hand tracking** (joint transforms, skeleton) is *not* part of gestures —
  it requires `ARKitSession` + `HandTrackingProvider`, a Full Space, and user
  authorization. Use only when you genuinely need joint data (see `arkit-spatial`).

## Ergonomics & comfort (HIG)

- **Target size:** make interactive targets comfortably large and well-spaced;
  small/dense targets are hard with look+pinch.
- **Feedback:** always provide hover + selection feedback so users know what's
  actionable and what they've hit.
- **Placement:** keep frequent interactions within a comfortable field of view and
  arm reach; avoid forcing large head movements.
- **Direct vs indirect:** indirect (look+pinch at a distance) suits most UI;
  reserve direct touch for content within arm's reach.

## Pitfalls

- Expecting hover/gesture without `InputTargetComponent` + collision.
- Trying to read gaze coordinates — unavailable by design.
- Conflating gestures with hand tracking — joint data needs ARKit + Full Space.
- Tiny/overlapping targets; no hover feedback; cursor-style UI that doesn't fit
  the look+pinch model.
