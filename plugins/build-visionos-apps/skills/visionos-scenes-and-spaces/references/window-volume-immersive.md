# Windows, Volumes & Immersive Spaces — APIs

Concrete API patterns, sizing, ornaments, transitions, and pitfalls.

## Windows

```swift
WindowGroup {
    ContentView()
}
.windowStyle(.plain)                 // or default (automatic)
.defaultSize(width: 600, height: 800)
.windowResizability(.contentSize)    // size to content
```

- Multiple distinct windows: give each `WindowGroup` an `id` and optional value type.
- Reuse a single window instance with `Window("Title", id: "settings") { ... }`.

## Volumes

```swift
WindowGroup(id: "model") {
    RealityView { content in
        if let entity = try? await Entity(named: "Robot", in: realityKitContentBundle) {
            content.add(entity)
        }
    }
}
.windowStyle(.volumetric)
.defaultSize(width: 0.6, height: 0.6, depth: 0.6, in: .meters)
```

- Always size volumes in **meters**. Content is clipped to these bounds.
- `.volumeBaseplateVisibility(.hidden)` / window-controls placement can be tuned.
- Users grab and move volumes; design for viewing from any angle (no "back" that
  looks broken).

## Immersive Spaces

```swift
@State private var style: ImmersionStyle = .mixed

ImmersiveSpace(id: "immersive") {
    ImmersiveView()
}
.immersionStyle(selection: $style, in: .mixed, .progressive, .full)
```

- Switch immersion at runtime by assigning `style` (must be one of the styles
  listed in `in:`).
- `.progressive` can take a custom range, e.g.
  `.progressive(0.2...1.0, initialAmount: 0.5)`.

## Transitions

```swift
@Environment(\.openWindow) private var openWindow
@Environment(\.dismissWindow) private var dismissWindow
@Environment(\.openImmersiveSpace) private var openImmersiveSpace
@Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
@State private var immersiveOpen = false

// Open volume
openWindow(id: "model")

// Toggle immersive space safely
func toggleImmersive() {
    Task {
        if immersiveOpen {
            await dismissImmersiveSpace()
            immersiveOpen = false
        } else {
            switch await openImmersiveSpace(id: "immersive") {
            case .opened:                immersiveOpen = true
            case .userCancelled, .error: immersiveOpen = false
            @unknown default:            immersiveOpen = false
            }
        }
    }
}
```

`openImmersiveSpace` / `dismissImmersiveSpace` are async and **return a result** —
always branch on it and keep your `@State` flag in sync. The system may close an
immersive space without your code (user gesture, system event); observe scene
phase / `onDisappear` to reconcile.

## Ornaments

Float controls anchored to a window or volume without consuming its bounds:

```swift
ContentView()
    .ornament(attachmentAnchor: .scene(.bottom)) {
        HStack { Button("Reset") {} ; Button("Share") {} }
            .padding()
            .glassBackgroundEffect()
    }
```

## Scene phase

```swift
@Environment(\.scenePhase) private var scenePhase

.onChange(of: scenePhase) { _, phase in
    switch phase {
    case .background: pauseRealityKitUpdates()
    case .active:     resumeRealityKitUpdates()
    default:          break
    }
}
```

## Common pitfalls

- Putting world-anchored or room-scale content in a **volume** — volumes are
  bounded; use an immersive space instead.
- Assuming `openImmersiveSpace` succeeded — handle `.userCancelled`/`.error`.
- Opening a second immersive space — only one is allowed; dismiss first.
- Sizing volumes in points instead of meters.
- Requesting ARKit/hand tracking from a window or volume (Shared Space) — must be
  a Full Space with authorization.
- Leaving stale UI state ("Exit Immersive" button) when the system closed the
  space on its own.
