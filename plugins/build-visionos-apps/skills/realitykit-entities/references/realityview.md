# RealityView

`RealityView` is the SwiftUI view that hosts RealityKit content. It bridges
declarative SwiftUI state to the imperative RealityKit scene graph.

## Initializer shapes

```swift
// make only
RealityView { content in ... }

// make + update
RealityView { content in ... } update: { content in ... }

// make + update + attachments (SwiftUI views anchored to entities)
RealityView { content, attachments in
    // use attachments.entity(for: "id") to place a SwiftUI attachment
} update: { content, attachments in
    ...
} attachments: {
    Attachment(id: "label") {
        Text("Hello").padding().glassBackgroundEffect()
    }
}
```

## Closures

- **make** `(content) async -> Void` — runs once when the view appears. It is
  async: `await` your model loads here. Add root entities with `content.add(_:)`.
- **update** `(content) -> Void` — runs whenever SwiftUI state the view reads
  changes. Reconcile existing entities (move, toggle, restyle). Keep it cheap and
  idempotent; do not reload assets or allocate every call.
- **attachments** builder — declares SwiftUI views you can attach to entities.

## Content API (`RealityViewContent`)

- `content.add(entity)` / `content.remove(entity)`
- `content.entities` — root entities
- In a volume/window the content is bounded; in an immersive space it's unbounded.
- Coordinate conversions: `content.convert(_:from:to:)` between SwiftUI and
  RealityKit spaces (e.g. to place an entity at a tapped location).

## Attachments

Attachments render SwiftUI views in 3D, parented to entities — ideal for labels,
controls, or info panels that track a model.

```swift
RealityView { content, attachments in
    let model = try? await Entity(named: "Robot", in: realityKitContentBundle)
    if let model { content.add(model) }
    if let label = attachments.entity(for: "label") {
        label.position = [0, 0.4, 0]     // above the model, in meters
        model?.addChild(label)
    }
} attachments: {
    Attachment(id: "label") {
        Text("Robot").font(.title).padding().glassBackgroundEffect()
    }
}
```

## Gestures on RealityView

Attach SwiftUI gestures targeted to entities (entities need
`InputTargetComponent` + collision shapes):

```swift
RealityView { ... }
    .gesture(
        TapGesture().targetedToAnyEntity().onEnded { value in
            value.entity.scale *= 1.1
        }
    )
```

See the `spatial-gestures-interaction` skill for the full input model.

## Pitfalls

- Loading models in `update` (re-runs frequently) — load in `make` or a `Task`.
- Forgetting that `make` is async — wrap throwing loads in `try? await`.
- Heavy work in `update` causing frame hitches — reconcile minimally.
- Expecting gestures to hit entities without `InputTargetComponent`/collision.
