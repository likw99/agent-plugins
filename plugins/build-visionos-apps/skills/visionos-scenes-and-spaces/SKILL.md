---
name: visionos-scenes-and-spaces
description: Choose and wire visionOS windows, volumes, and immersive spaces. Use when structuring a visionOS app's scenes, switching between shared and full space, or opening/dismissing windows and immersive spaces.
---

# visionOS Scenes & Spaces

## Overview
visionOS apps are built from three scene types living in two "spaces". Getting
this mental model right is the single most important visionOS-specific decision.
Use this skill to pick the right container, structure the `App`/`Scene` tree, and
wire transitions with the environment actions.

## The Model

**Shared Space** (default): apps coexist side by side. Contains:
- **Windows** — flat, resizable 2D SwiftUI content (`WindowGroup`, `.windowStyle(.plain)`/automatic).
- **Volumes** — bounded 3D content with depth, viewable from any angle
  (`WindowGroup` + `.windowStyle(.volumetric)`).

**Full Space** (exclusive): only your app is shown. Contains:
- **Immersive Spaces** — unbounded 3D content (`ImmersiveSpace`), with an
  immersion style: `.mixed` (passthrough + your content), `.progressive` (Digital
  Crown dial between mixed and full), `.full` (no passthrough). ARKit world
  sensing, hand tracking, and scene reconstruction require a Full Space.

## Decision Tree

1. **2D UI, controls, lists, forms** → Window (`WindowGroup`, plain style).
2. **A single bounded 3D object/diorama users walk around** → Volume
   (`.windowStyle(.volumetric)`, set `defaultSize(... in: .meters)`).
3. **Content that surrounds the user / needs ARKit (hands, world, planes)** →
   Immersive Space (`ImmersiveSpace` + `immersionStyle`).
4. **Most apps** start with a Window for entry/controls and *open* a Volume or
   Immersive Space on demand (HiPtah's pattern: `WindowGroup` + `ImmersiveSpace`).

## Scene Tree Skeleton

```swift
@main
struct MyApp: App {
    @State private var immersionStyle: ImmersionStyle = .mixed

    var body: some Scene {
        WindowGroup {                       // 2D entry / controls
            ContentView()
        }

        WindowGroup(id: "model") {          // bounded 3D volume
            ModelVolumeView()
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.6, height: 0.6, depth: 0.6, in: .meters)

        ImmersiveSpace(id: "immersive") {   // unbounded 3D
            ImmersiveView()
        }
        .immersionStyle(selection: $immersionStyle, in: .mixed, .progressive, .full)
    }
}
```

## Transitions (environment actions)

```swift
@Environment(\.openWindow) private var openWindow
@Environment(\.dismissWindow) private var dismissWindow
@Environment(\.openImmersiveSpace) private var openImmersiveSpace
@Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

// Open a volume by id
openWindow(id: "model")

// Open an immersive space (async; check the result)
Task {
    switch await openImmersiveSpace(id: "immersive") {
    case .opened:        break
    case .userCancelled, .error: /* revert UI state */ break
    @unknown default:    break
    }
}

// Leave the full space
await dismissImmersiveSpace()
```

Only **one** immersive space can be open at a time. Track open/closed state in
`@State` and react to `openImmersiveSpace` results — don't assume it succeeded.

## Ornaments & Scene Phase

- **Ornaments** float UI alongside a window/volume:
  `.ornament(attachmentAnchor: .scene(.bottom)) { Toolbar() }`.
- Observe lifecycle with `@Environment(\.scenePhase)` (`.active/.inactive/.background`)
  to pause RealityKit updates or audio when the scene backgrounds.

## Checklist

- Each scene has a stable `id` if it's opened/dismissed programmatically.
- Volumes use `.windowStyle(.volumetric)` and a `defaultSize(... in: .meters)`.
- Immersive space uses an `ImmersionStyle` state binding via `immersionStyle(selection:in:)`.
- `openImmersiveSpace` results are handled; UI state reverts on cancel/error.
- Only one immersive space open at a time; entry UI reflects current space state.
- ARKit/hand/world features are only attempted inside a Full Space.

## References

- `references/spaces-model.md`: shared vs full space, when to use each container.
- `references/window-volume-immersive.md`: APIs, sizing, ornaments, transitions, pitfalls.
- Apple: `developer.apple.com/documentation/visionos` — "Presenting windows and
  spaces", "Adding a volume", "Creating fully immersive experiences"; HIG > Spatial layout.

## Guardrails

- Don't put unbounded/world-anchored content in a volume — volumes are bounded.
- Don't request hand tracking, world sensing, or scene reconstruction outside a
  Full Space; it will fail or be denied.
- Don't open a second immersive space without dismissing the first.
- Size volumes in meters, not points.

## Output Expectations

State the chosen container(s) and why, the scene tree, the transition wiring, and
any space-state/ARKit constraints the choice implies.
