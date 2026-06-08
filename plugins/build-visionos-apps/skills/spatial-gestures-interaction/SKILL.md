---
name: spatial-gestures-interaction
description: Wire visionOS input — spatial taps, drags, rotate, magnify gestures on RealityKit entities, plus hover effects and the eye/hand privacy model. Use when making 3D content interactive or adding gestures to entities.
---

# Spatial Gestures & Interaction

## Overview
On visionOS the user looks at a target (eyes) and pinches/taps (hands); the system
resolves this privately and delivers it to your content. Use this skill to make
RealityKit entities interactive with SwiftUI gestures, add hover feedback, and
respect the eye/hand privacy model. This makes a model viewer manipulable (rotate,
scale, move, tap-to-select).

## The non-negotiable prerequisite

A gesture only hits an entity if that entity has **both**:
1. `InputTargetComponent()` — marks it as interactive, and
2. a collision shape (`CollisionComponent`, e.g. via `generateCollisionShapes`).

```swift
entity.components.set(InputTargetComponent())
entity.generateCollisionShapes(recursive: true)
```

Missing either → the gesture silently does nothing. This is the #1 cause of
"my gesture doesn't fire".

## Targeted gestures

Attach SwiftUI gestures to a `RealityView` and target them to entities:

```swift
RealityView { content in /* add entities w/ input target + collision */ }
    // Tap to select
    .gesture(
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                let entity = value.entity
                // value.location3D is the world hit point
            }
    )
    // Drag to move
    .gesture(
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                value.entity.position = value.convert(value.location3D,
                                                      from: .local, to: value.entity.parent!)
            }
    )
    // Rotate (one-/two-handed) and Magnify (scale)
    .gesture(rotateGesture)
    .gesture(magnifyGesture)
```

```swift
var rotateGesture: some Gesture {
    RotateGesture3D()                       // 3D rotation
        .targetedToAnyEntity()
        .onChanged { value in
            value.entity.orientation = simd_quatf(value.rotation)
        }
}

var magnifyGesture: some Gesture {
    MagnifyGesture()
        .targetedToAnyEntity()
        .onChanged { value in
            let s = Float(value.magnification)
            value.entity.scale = SIMD3(repeating: s)
        }
}
```

Use `.targetedToEntity(_:)` to bind to one specific entity, or
`.targetedToAnyEntity()` for any interactive entity hit.

## Capturing the starting transform

For smooth drag/scale, capture the entity transform at gesture start so changes
are relative, not absolute (store in `@State` or a gesture-scoped value), then
apply deltas. Reset on `.onEnded`.

## Hover effects

Give eye/pointer feedback without code knowing where the user looks:

```swift
entity.components.set(HoverEffectComponent())          // RealityKit entity
// or in SwiftUI views:
someView.hoverEffect()
```

`HoverEffectComponent` supports styles (highlight/spotlight) and can drive a
ShaderGraph parameter for custom hover looks.

## Eye/hand privacy model

- You **cannot** read raw gaze. The system resolves the looked-at target and
  hover privately; you only learn what was interacted with.
- Hand **gestures** (pinch, tap) arrive as input events; raw hand **tracking**
  (joint positions) requires ARKit + a Full Space + authorization (see
  `arkit-spatial`).
- Design for "look + pinch": make targets reasonably large and well-spaced; rely
  on hover effects for feedback rather than custom cursors.

## Checklist

- Interactive entities have `InputTargetComponent` + collision shapes.
- Gestures are `.targetedTo...Entity` and attached to the `RealityView`.
- Drag/rotate/scale apply deltas from a captured start transform (no jumps).
- Hover feedback present (`HoverEffectComponent`/`.hoverEffect`).
- Targets are large/spaced enough for look+pinch; no reliance on raw gaze.
- Gesture handlers are cheap (run per-frame during a drag).

## References

- `references/spatial-gestures.md`: tap/drag/rotate/magnify recipes, coordinate conversion.
- `references/hover-and-input.md`: hover effects, input components, privacy model, ergonomics.
- Apple: "Adding 3D content to your app", RealityKit gestures, HIG > Eyes and hands.

## Guardrails

- Never assume a gesture works without input target + collision.
- Don't try to read gaze position — it's intentionally unavailable.
- Don't apply absolute transforms mid-gesture; use deltas from a start state.
- Don't make tiny, tightly packed targets — they're hard with look+pinch.
- Don't do heavy work in `onChanged` (fires every frame).

## Output Expectations

State which entities are interactive, the gestures wired, how transforms are
applied (delta vs absolute), and the hover/feedback approach.
