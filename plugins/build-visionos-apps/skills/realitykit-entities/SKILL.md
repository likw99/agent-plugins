---
name: realitykit-entities
description: Load and compose RealityKit 3D content in visionOS with RealityView, entities, Model3D, and USDZ. Use when displaying 3D models, building scenes from entities, applying materials/transforms/anchors, or bridging SwiftUI to RealityKit.
---

# RealityKit Entities

## Overview
RealityKit is visionOS's 3D engine; `RealityView` bridges SwiftUI to it. Use this
skill to display 3D models (including generated/downloaded USDZ), build scenes
from entities using the Entity Component System (ECS), and wire transforms,
materials, lighting, and anchors. This is the core of any 3D viewer (e.g. HiPtah's
model viewer / immersive view).

## Decision Tree

1. **Quick, declarative single model in a window/volume** → `Model3D` (SwiftUI).
2. **Custom scene, multiple entities, interaction, or updates** → `RealityView`.
3. **Author-time scene with materials/animation** → load an `Entity(named:in:)`
   from a Reality Composer Pro `RealityKitContent` bundle (see `reality-composer-pro`).
4. **Runtime model from disk/network (USDZ/Reality)** → `Entity(contentsOf: url)`
   or `ModelEntity(contentsOf:)`, loaded async (see `references/loading-usdz.md`).

## RealityView essentials

```swift
import SwiftUI
import RealityKit

struct ModelView: View {
    var body: some View {
        RealityView { content in            // make: async, runs once
            let model = try? await ModelEntity(named: "Robot")
            if let model { content.add(model) }
        } update: { content in              // runs on SwiftUI state change
            // reconcile entities with state
        }
    }
}
```

- The **make** closure is async — `await` model loading there.
- The **update** closure runs when observed SwiftUI state changes; keep it cheap
  and idempotent (reconcile, don't rebuild every time).
- Use **attachments** to anchor SwiftUI views to entities (see references).

## Entity Component System (ECS)

Entities are containers; behavior comes from components:
- `Transform` / `position` / `orientation` / `scale` — placement.
- `ModelComponent` (mesh + materials) — what's drawn.
- `CollisionComponent` + `InputTargetComponent` — required for gestures/hits.
- `HoverEffectComponent` — eye/pointer hover highlight.
- Custom `Component` + `System` — your own per-frame logic.

```swift
let box = ModelEntity(mesh: .generateBox(size: 0.2),
                      materials: [SimpleMaterial(color: .blue, isMetallic: true)])
box.position = [0, 1.2, -0.5]                       // meters, +Y up, -Z forward
box.components.set(InputTargetComponent())
box.generateCollisionShapes(recursive: true)        // enables hit testing
parent.addChild(box)
```

## Transforms, materials, lighting

- Units are **meters**; coordinate space is +X right, +Y up, −Z forward.
- Scale a model to fit a target size by comparing `visualBounds(relativeTo:)`.
- Materials: `SimpleMaterial`, `PhysicallyBasedMaterial`, `UnlitMaterial`, or
  ShaderGraph materials authored in Reality Composer Pro.
- In `.mixed` immersion, RealityKit uses image-based lighting from the real
  environment by default; add an `ImageBasedLightComponent` or virtual lights for
  `.full`.

## Async loading & error states (mirror HiPtah's viewer)

```swift
@State private var phase: LoadPhase = .idle   // idle/loading/loaded/failed

RealityView { content in
    do {
        let entity = try await Entity(contentsOf: usdzURL)
        entity.scaleToFit(maxEdge: 0.5)       // your helper
        content.add(entity)
        phase = .loaded
    } catch {
        phase = .failed(error)
    }
}
```

Always show loading and failure UI — runtime USDZ loads fail (bad file,
unsupported features, network). See `references/loading-usdz.md`.

## Checklist

- Picked `Model3D` vs `RealityView` deliberately.
- Model load is async with explicit loading + failure states.
- Models scaled/positioned in meters; fit to the volume/space.
- Entities that need interaction have `InputTargetComponent` + collision shapes.
- `update` closure is cheap and idempotent (no per-frame allocation/rebuild).
- Lighting addressed for the chosen immersion style.
- Entities are removed/released when the scene closes (no leaks).

## References

- `references/realityview.md`: RealityView make/update/attachments, content API.
- `references/entities-ecs.md`: entities, components, systems, transforms, materials.
- `references/loading-usdz.md`: loading USDZ/Reality from bundle/disk/network, scaling, errors.
- Apple: RealityKit framework, `RealityView`, `Model3D`, "Composing interactive
  3D content with RealityKit and Reality Composer Pro".

## Guardrails

- Don't block the main thread loading models; use the async `make` closure / `Task`.
- Don't rebuild the whole scene in `update`; reconcile existing entities.
- Don't forget `InputTargetComponent` + collision shapes, or gestures silently no-op.
- Don't assume model scale; generated/imported USDZ vary wildly — measure and fit.
- Sizes are meters — a "1.0" cube is 1 meter, not tiny.

## Output Expectations

State the chosen API, how the model is loaded and scaled, interaction/lighting
setup, and how loading/failure states are surfaced.
