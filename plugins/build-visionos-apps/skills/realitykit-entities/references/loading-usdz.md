# Loading USDZ / Reality Content

How to load 3D models from the app bundle, the RealityKitContent package, disk, or
the network — with scaling and error handling. Relevant to viewers that display
generated or downloaded models (e.g. Tripo3D USDZ output).

## Supported formats

- **USDZ / USD / USDA / USDC** — primary interchange format on visionOS.
- **`.reality`** — Reality Composer / Reality Composer Pro exported scenes.
- Reality Composer Pro `RealityKitContent` bundle — referenced by entity name.

## Model3D (SwiftUI, simplest)

```swift
import RealityKit

Model3D(url: usdzURL) { model in
    model.resizable().scaledToFit()
} placeholder: {
    ProgressView()
}
```

- Declarative, handles its own async load + placeholder.
- Good for a single model in a window or volume. Less control than RealityView.
- Also `Model3D(named: "Robot", bundle: realityKitContentBundle)`.

## From the RealityKitContent bundle

```swift
import RealityKitContent

let robot = try await Entity(named: "Robot", in: realityKitContentBundle)
content.add(robot)
```

`realityKitContentBundle` is provided by the generated `RealityKitContent` Swift
package (see the `reality-composer-pro` skill). Names match scenes/entities
authored in Reality Composer Pro.

## From a file URL (disk or downloaded)

```swift
// Entity (full scene, preferred)
let entity = try await Entity(contentsOf: localURL)

// ModelEntity (single model; supports physics/collision helpers)
let model = try await ModelEntity(contentsOf: localURL)
```

For remote models, download to a local file first, then load:

```swift
func loadRemoteUSDZ(_ remote: URL) async throws -> Entity {
    let (tmp, _) = try await URLSession.shared.download(from: remote)
    let dst = FileManager.default.temporaryDirectory
        .appendingPathComponent(remote.lastPathComponent.isEmpty ? "model.usdz" : remote.lastPathComponent)
    try? FileManager.default.removeItem(at: dst)
    try FileManager.default.moveItem(at: tmp, to: dst)
    return try await Entity(contentsOf: dst)   // load from a .usdz file URL
}
```

Note: RealityKit loads from **file URLs**, not arbitrary remote URLs — download first.

## Scale to fit a target size

Imported/generated models have unpredictable scale. Normalize to a max edge:

```swift
extension Entity {
    func scaleToFit(maxEdge: Float) {
        let bounds = visualBounds(relativeTo: nil)
        let longest = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
        guard longest > 0 else { return }
        setScale(.init(repeating: maxEdge / longest), relativeTo: nil)
    }
    func center() {
        let b = visualBounds(relativeTo: nil)
        position -= b.center
    }
}
```

## Error handling (always)

```swift
enum LoadPhase { case idle, loading, loaded, failed(String) }

@State private var phase: LoadPhase = .idle

RealityView { content in
    phase = .loading
    do {
        let entity = try await loadRemoteUSDZ(url)
        entity.scaleToFit(maxEdge: 0.5)
        entity.center()
        content.add(entity)
        phase = .loaded
    } catch {
        phase = .failed(error.localizedDescription)
    }
}
```

Surface `.loading` (spinner) and `.failed` (message + retry) in the UI. Runtime
loads fail for: corrupt/partial files, unsupported USD features, wrong extension,
or network errors.

## Pitfalls

- Trying to load a remote `https://` URL directly into `Entity(contentsOf:)` —
  download to a file first.
- Not normalizing scale — models appear giant or invisible.
- Not centering — model is offset from the volume/anchor origin.
- Loading large models on the main thread — use the async `make` closure or a `Task`.
- Reloading on every `update` — load once, keep a reference.
