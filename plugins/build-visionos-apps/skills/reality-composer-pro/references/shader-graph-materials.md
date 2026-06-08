# Shader Graph Materials

Reality Composer Pro authors materials as node graphs (based on MaterialX). They
compile to `ShaderGraphMaterial`, which you load and parameterize at runtime.

## Authoring in RCP

1. In the `.rkassets`, create a new **Material** (Shader Graph).
2. Build the graph: connect texture/noise/math nodes into the surface output
   (PBR surface: base color, roughness, metallic, normal, emissive, opacity).
3. **Promote** inputs you want to control at runtime: right-click an input →
   "Promote". Promoted inputs become named parameters on the material.
4. Assign the material to entities in your scene.

## Loading & setting parameters in code

```swift
import RealityKit
import RealityKitContent

// Load a ShaderGraphMaterial authored in RCP
var material = try await ShaderGraphMaterial(
    named: "/Root/Materials/MyMaterial",      // path within the .usda
    from: "Scene",                            // scene name
    in: realityKitContentBundle
)

// Set a promoted parameter
try material.setParameter(name: "tintColor",
                          value: .color(.init(red: 1, green: 0, blue: 0, alpha: 1)))
try material.setParameter(name: "glowStrength", value: .float(2.0))

// Apply to an entity's ModelComponent
if var model = entity.components[ModelComponent.self] {
    model.materials = [material]
    entity.components.set(model)
}
```

## Parameter value types

`MaterialParameters.Value` cases include `.float`, `.int`, `.bool`, `.color`,
`.simd2/3/4`, and `.textureResource`. Match the promoted input's type.

## Common uses

- Tinting/recoloring a model at runtime (e.g. theme or selection state).
- Animated effects: drive a `time`/`phase` parameter from a `System` each frame.
- Dissolve/fade-in: drive an opacity/threshold parameter.
- Highlight on selection: boost emissive via a promoted parameter.

## Built-in vs Shader Graph

- Use `SimpleMaterial`/`PhysicallyBasedMaterial`/`UnlitMaterial` in code for
  straightforward PBR or unlit looks — no RCP needed.
- Use Shader Graph when you need procedural effects, custom blending, or
  runtime-tunable named parameters authored visually.

## Pitfalls

- Wrong material path/name in `ShaderGraphMaterial(named:from:in:)` — must match
  the USD path and scene exactly.
- Setting a parameter that wasn't promoted, or a type mismatch — `setParameter`
  throws; handle it.
- Forgetting to write the modified material back into the `ModelComponent`
  (set on a copy then assign).
- Animating by recreating the material each frame instead of mutating a promoted
  parameter — keep one material and update its parameter.
