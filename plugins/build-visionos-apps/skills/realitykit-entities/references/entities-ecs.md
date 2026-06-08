# Entities, Components & Systems (ECS)

RealityKit uses an Entity Component System. An `Entity` is a node in the scene
graph; **components** give it data/behavior; **systems** run logic over entities
each frame.

## Entities

```swift
let entity = Entity()                 // empty container
let model = ModelEntity(              // entity with a ModelComponent
    mesh: .generateSphere(radius: 0.1),
    materials: [SimpleMaterial(color: .red, isMetallic: false)]
)
parent.addChild(model)                // build a hierarchy
```

Hierarchy: `addChild` / `removeFromParent`. Child transforms are relative to the
parent. Find by name with `entity.findEntity(named:)`.

## Transforms

```swift
model.position = [0, 1.0, -0.5]                      // SIMD3<Float>, meters
model.orientation = simd_quatf(angle: .pi/4, axis: [0,1,0])
model.scale = [2, 2, 2]
model.transform = Transform(scale: .one,
                            rotation: .init(),
                            translation: [0, 1, -1])
```

- Coordinate space: +X right, +Y up, **−Z forward** (toward the user's back is +Z).
- Units are meters. `[1,1,1]` scale = authored size.
- Measure with `model.visualBounds(relativeTo: nil)` to fit/scale to a target.

## Key components

| Component | Purpose |
|---|---|
| `ModelComponent` | mesh + materials (what's rendered) |
| `Transform` | position/rotation/scale (implicit on every entity) |
| `CollisionComponent` | collision shape for hit testing / physics |
| `InputTargetComponent` | makes the entity receive gestures/input |
| `HoverEffectComponent` | highlight on eye/pointer hover |
| `PhysicsBodyComponent` / `PhysicsMotionComponent` | physics simulation |
| `OpacityComponent` | per-entity opacity / fades |
| `AnchoringComponent` | anchor to head/hand/world/image/plane |
| `ImageBasedLightComponent` | IBL lighting (esp. `.full` immersion) |

Set/get/remove:

```swift
entity.components.set(InputTargetComponent())
entity.components.set(HoverEffectComponent())
entity.generateCollisionShapes(recursive: true)     // builds CollisionComponent
let hasInput = entity.components.has(InputTargetComponent.self)
entity.components.remove(HoverEffectComponent.self)
```

## Materials

- `SimpleMaterial(color:isMetallic:)` — quick PBR-ish.
- `PhysicallyBasedMaterial` — full PBR (baseColor, roughness, metallic, normal,
  emissive maps).
- `UnlitMaterial` — ignores lighting (UI-like, glows).
- `ShaderGraphMaterial(named:from:)` — authored in Reality Composer Pro; set
  parameters at runtime via `setParameter(name:value:)`.

## Custom components & systems

```swift
struct SpinComponent: Component { var speed: Float = 1 }

struct SpinSystem: System {
    static let query = EntityQuery(where: .has(SpinComponent.self))
    init(scene: Scene) {}
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            let s = entity.components[SpinComponent.self]!.speed
            entity.orientation *= simd_quatf(angle: s * Float(context.deltaTime), axis: [0,1,0])
        }
    }
}
// Register once at app launch:
SpinComponent.registerComponent()
SpinSystem.registerSystem()
```

## Anchoring (immersive space)

```swift
let anchor = AnchorEntity(.head)              // or .hand(.left, location:), .plane(...), .world(...)
anchor.addChild(model)
content.add(anchor)
```

World/plane/hand anchoring with live tracking requires a Full Space and ARKit
authorization (see the `arkit-spatial` skill).

## Pitfalls

- Gestures no-op without **both** `InputTargetComponent` and a collision shape.
- Forgetting `registerComponent()`/`registerSystem()` before use.
- Mutating the scene graph from a background thread — do entity mutations on the
  main actor / within RealityKit closures.
- Assuming authored scale; always measure `visualBounds` for imported models.
