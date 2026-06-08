---
name: reality-composer-pro
description: Author visionOS 3D scenes with Reality Composer Pro and the RealityKitContent Swift package. Use when organizing 3D assets, building scenes, creating Shader Graph materials, adding particle emitters, or loading authored content into a RealityView.
---

# Reality Composer Pro

## Overview
Reality Composer Pro (RCP), bundled with Xcode, is the tool for authoring
RealityKit scenes, materials, and effects, then shipping them in a
`RealityKitContent` Swift package that your app loads by name. Use this skill to
structure the content package, build scenes, author Shader Graph materials, and
wire authored entities into code. HiPtah already contains a `RealityKitContent`
package — this skill governs working in it.

## The RealityKitContent package

A visionOS app template includes a local Swift package, typically at
`Packages/RealityKitContent/`, with:

```
RealityKitContent/
├── Package.swift
├── Sources/RealityKitContent/
│   ├── RealityKitContent.swift           # exposes `realityKitContentBundle`
│   └── RealityKitContent.rkassets/       # the RCP project (open this in RCP)
│       ├── Scene.usda                     # default scene
│       └── Materials/...
└── Package.realitycomposerpro/           # RCP project data
```

- Open `RealityKitContent.rkassets` (or the package) in Reality Composer Pro via
  Xcode: select the package and click "Open in Reality Composer Pro".
- The package vends `realityKitContentBundle`, used in code:
  `try await Entity(named: "Scene", in: realityKitContentBundle)`.

## Workflow

1. **Organize assets.** Import USDZ/USD, textures, audio into `.rkassets`. Group
   reusable pieces into separate `.usda` scenes; keep names stable (code loads by name).
2. **Compose scenes.** Add entities, set transforms, parent hierarchy, lights,
   and components in RCP. Add a `CollisionComponent` + `InputTargetComponent` here
   if the entity needs gestures, or do it in code.
3. **Author materials** with Shader Graph (see `references/shader-graph-materials.md`).
   Expose parameters ("Promote" inputs) to tweak them at runtime.
4. **Add effects** — particle emitters (`ParticleEmitterComponent`), audio sources,
   image-based lighting.
5. **Load in code** by entity/scene name from `realityKitContentBundle`; set
   promoted ShaderGraph parameters at runtime as needed.
6. **Iterate.** RCP saves into the package; rebuilding the app picks up changes.
   For tight loops, edit in RCP and re-run.

## Loading authored content

```swift
import RealityKit
import RealityKitContent

RealityView { content in
    if let scene = try? await Entity(named: "Scene", in: realityKitContentBundle) {
        content.add(scene)
    }
}
```

## Checklist

- Scenes/entities have stable names matching what code loads.
- Reusable content split into separate `.usda` scenes, not one mega-scene.
- Interaction entities carry collision + input target (in RCP or code).
- ShaderGraph inputs that code controls are **promoted** to parameters.
- Heavy textures sized sensibly (don't ship 8K textures for small props).
- Audio/particles previewed in RCP before wiring in code.

## References

- `references/rcp-workflow.md`: package layout, scenes, components, USD, iteration.
- `references/shader-graph-materials.md`: building and parameterizing materials.
- Apple: "Designing RealityKit content with Reality Composer Pro", "Creating a
  Shader Graph material"; samples *Diorama*, *Swift Splash*, *BOT-anist*.

## Guardrails

- Don't hardcode runtime model loads that belong in the content package, and
  vice versa — author static scenes in RCP, load dynamic/remote models in code.
- Don't rename scenes/entities without updating the code that loads them.
- Don't bake giant textures into the bundle; mind app size and GPU memory.
- Don't assume RCP changes are picked up without rebuilding the app/package.

## Output Expectations

State where content lives in the package, the scene/entity names, any promoted
material parameters, and the code that loads them.
