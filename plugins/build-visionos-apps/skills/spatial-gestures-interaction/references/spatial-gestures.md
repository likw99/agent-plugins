# Spatial Gesture Recipes

SwiftUI gestures, targeted to RealityKit entities, are the primary way to make 3D
content interactive on visionOS. Entities must have `InputTargetComponent` + a
collision shape (see hover-and-input.md).

## Tap to select / place

```swift
.gesture(
    SpatialTapGesture()
        .targetedToAnyEntity()
        .onEnded { value in
            let entity = value.entity              // the hit entity
            let worldPoint = value.location3D      // hit location (3D)
            select(entity)
        }
)
```

`TapGesture().targetedToAnyEntity()` also works for a simple tap without location.

## Drag to move

Convert the drag's 3D location into the entity's parent space and apply relative
to a captured start position:

```swift
@State private var dragStart: SIMD3<Float>? = nil

.gesture(
    DragGesture()
        .targetedToAnyEntity()
        .onChanged { value in
            let entity = value.entity
            if dragStart == nil { dragStart = entity.position }
            let translation = value.convert(value.translation3D, from: .local, to: entity.parent!)
            entity.position = (dragStart ?? entity.position) + translation
        }
        .onEnded { _ in dragStart = nil }
)
```

`value.convert(_:from:to:)` bridges SwiftUI/gesture space to RealityKit space.

## Rotate (3D)

```swift
@State private var startOrientation: simd_quatf? = nil

.gesture(
    RotateGesture3D()
        .targetedToAnyEntity()
        .onChanged { value in
            let entity = value.entity
            if startOrientation == nil { startOrientation = entity.orientation }
            entity.orientation = simd_quatf(value.rotation) * (startOrientation ?? entity.orientation)
        }
        .onEnded { _ in startOrientation = nil }
)
```

`RotateGesture3D` gives a 3D rotation (`Rotation3D`). For a turntable-style single
axis, use a 2D `RotateGesture` and map to a Y-axis rotation instead.

## Magnify (scale)

```swift
@State private var startScale: SIMD3<Float>? = nil

.gesture(
    MagnifyGesture()
        .targetedToAnyEntity()
        .onChanged { value in
            let entity = value.entity
            if startScale == nil { startScale = entity.scale }
            entity.scale = (startScale ?? entity.scale) * Float(value.magnification)
        }
        .onEnded { _ in startScale = nil }
)
```

## Combine / simultaneous

Chain multiple `.gesture(...)` modifiers, or use
`SimultaneousGesture` / `.simultaneousGesture(...)` so rotate + magnify can run at
once (common for inspecting a model).

## Targeting a specific entity

```swift
.gesture(
    DragGesture().targetedToEntity(handleEntity).onChanged { ... }
)
```

## Key gesture value fields

- `value.entity` — the entity the gesture targeted.
- `value.location3D` / `value.translation3D` — 3D point / delta.
- `value.convert(_:from:to:)` — coordinate space conversion.
- `value.rotation` (RotateGesture3D) / `value.magnification` (MagnifyGesture).

## Pitfalls

- Applying absolute values each `onChanged` → jumps; capture a start value and
  apply deltas, reset in `onEnded`.
- Forgetting coordinate conversion → entity moves in the wrong space.
- Heavy work in `onChanged` (fires per frame) → hitches.
- No input target/collision → gesture never targets the entity.
