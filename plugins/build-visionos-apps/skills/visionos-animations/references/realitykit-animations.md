# RealityKit Animations (visionOS)

Animate 3D entities in volumes and immersive spaces. Three sources of motion:
procedural (`AnimationResource` from `FromToByAnimation`/`OrbitAnimation`), baked
(USDZ/skeletal clips), and per-frame (`System`).

## Playing an animation

```swift
let controller: AnimationPlaybackController = entity.playAnimation(resource)
controller.pause(); controller.resume(); controller.stop()
controller.speed = 2.0
```

Retain the controller if you need to stop/adjust it later (e.g. stop the loading
spin when generation completes).

## FromToByAnimation (procedural) — visionOS 1.0+

```swift
// Continuous Y-axis spin for a loading placeholder
let spin = FromToByAnimation(
    name: "spin",
    from: Transform(rotation: simd_quatf(angle: 0,    axis: [0,1,0])),
    to:   Transform(rotation: simd_quatf(angle: .pi,  axis: [0,1,0])),
    duration: 2.0,
    bindTarget: .transform
)
if let res = try? AnimationResource.generate(with: spin) {
    entity.playAnimation(res.repeat(duration: .infinity))
}

// Pulse scale (subtle "alive" feel)
let pulse = FromToByAnimation(
    from: Transform(scale: .init(repeating: 1.0)),
    to:   Transform(scale: .init(repeating: 1.08)),
    duration: 0.8, bindTarget: .transform
)
if let res = try? AnimationResource.generate(with: pulse) {
    entity.playAnimation(res.repeat(autoreverses: true))
}
```

`bindTarget` can target `.transform`, `.position`, `.orientation`, `.scale`,
`.opacity` (with `OpacityComponent`), etc.

## OrbitAnimation (circle a point)

```swift
let orbit = OrbitAnimation(
    duration: 4,
    axis: [0,1,0],
    startTransform: entity.transform,
    spinClockwise: false,
    orientToPath: true,
    rotationCount: 1,
    bindTarget: .transform
)
if let res = try? AnimationResource.generate(with: orbit) {
    entity.playAnimation(res.repeat())
}
```

## Baked / skeletal animations from USDZ

```swift
// Models exported with animation expose clips here
for clip in entity.availableAnimations {
    print(clip.name ?? "unnamed")
}
if let first = entity.availableAnimations.first {
    entity.playAnimation(first.repeat(), transitionDuration: 0.3, startsPaused: false)
}
```

Blend/crossfade by playing a new clip with a `transitionDuration`.

## Animating opacity (fade-in loaded model)

```swift
entity.components.set(OpacityComponent(opacity: 0))
let fade = FromToByAnimation(from: Transform(), to: Transform(),
                             duration: 0.4, bindTarget: .opacity)
// Simpler: animate the component value over time via a System, or set opacity
entity.components.set(OpacityComponent(opacity: 1))   // with an animation context
```

## Per-frame motion via a System (most control)

```swift
struct SpinComponent: Component { var radiansPerSecond: Float = 1 }

struct SpinSystem: System {
    static let q = EntityQuery(where: .has(SpinComponent.self))
    init(scene: Scene) {}
    func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        for e in context.entities(matching: Self.q, updatingSystemWhen: .rendering) {
            let s = e.components[SpinComponent.self]!.radiansPerSecond
            e.orientation *= simd_quatf(angle: s * dt, axis: [0,1,0])
        }
    }
}
// register once at launch:
SpinComponent.registerComponent(); SpinSystem.registerSystem()
```

## Reality Composer Pro timelines

Author timeline animations on entities in the content package and trigger them in
code (notifications / behaviors). Good for complex, designed sequences. See the
`reality-composer-pro` skill.

## Comfort (HIG)

- Keep spatial motion small and slow; avoid content moving toward the user
  (looming) or large sweeping motion across the field of view.
- Honor Reduce Motion: substitute a static or cross-fade state.

## Pitfalls

- Not retaining `AnimationPlaybackController` → can't stop the loading spin later.
- `repeat()` without ever stopping → motion continues after the job ends.
- Expecting `availableAnimations` on a model exported without animation (empty).
- Large/fast motion causing discomfort.
- Mutating entities off the main actor.
