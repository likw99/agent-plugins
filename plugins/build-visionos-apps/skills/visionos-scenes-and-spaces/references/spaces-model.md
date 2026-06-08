# The visionOS Spaces Model

visionOS organizes app content into **scenes** that live in one of two **spaces**.
Understanding which space content lives in determines what capabilities are
available (especially ARKit) and how the app coexists with others.

## Shared Space (the default)

When the user opens your app, it launches into the Shared Space — the equivalent
of the Mac desktop or iPad multitasking. Multiple apps run side by side; the
system places your content in the user's surroundings. You cannot control the
absolute position of content relative to the room here, and you cannot use ARKit
world sensing.

Two scene kinds live in the Shared Space:

### Windows
- Flat, primarily 2D SwiftUI content with a small amount of depth allowed.
- Created with `WindowGroup`. Default/`.plain` window style.
- Resizable by the user; use SwiftUI layout as on iPad/Mac.
- Can include 3D via `Model3D` or a small `RealityView`, but content stays within
  the window's bounds.
- Best for: navigation, controls, text, lists, forms, media browsing — the
  "control surface" of most apps.

### Volumes
- Bounded 3D containers with real depth; users can view them from any angle and
  reposition them in the Shared Space.
- Created with `WindowGroup` + `.windowStyle(.volumetric)`.
- Sized in real-world units: `.defaultSize(width:height:depth:in: .meters)`.
- Content is clipped to the volume's bounds.
- Best for: a single 3D object, a board game, a diorama, a 3D data viz, a model
  previewer (e.g. inspecting a generated 3D model).

## Full Space (exclusive)

Your app can request a Full Space to hide other apps and take over the user's
view. This is the only place ARKit data, hand tracking, scene reconstruction, and
world anchoring are available.

### Immersive Spaces
- Created with `ImmersiveSpace(id:) { ... }`.
- Unbounded — content can surround the user; you place entities in world space.
- Immersion style controls passthrough:
  - `.mixed` — your content blended with real-world passthrough (AR).
  - `.progressive` — a partial immersive portal; the user dials immersion with
    the Digital Crown (default range, can be customized).
  - `.full` — fully virtual; passthrough hidden (VR).
- Set via `.immersionStyle(selection: $style, in: .mixed, .progressive, .full)`
  where `style` is `@State ... : ImmersionStyle`.
- Only one immersive space open at a time across the system.

## Choosing

| Need | Container |
|---|---|
| 2D UI, controls, text | Window |
| One bounded 3D object, viewable from all sides | Volume |
| Content around the user / passthrough AR | Immersive Space `.mixed` |
| Fully virtual environment | Immersive Space `.full` |
| Hand tracking, world/plane/scene data | Immersive Space (required) |

Typical structure: a Window for entry + controls that **opens** a Volume or an
Immersive Space on demand, then dismisses it to return to the Shared Space.

## Privacy posture

In the Shared Space the system protects the user: you get no camera frames, no
precise world geometry, and only privacy-preserving input (eye-driven hover is
resolved by the system, not exposed to you). Richer sensing requires a Full Space
and explicit user authorization. Design entry UI so the user understands when the
app is about to take over their view.
