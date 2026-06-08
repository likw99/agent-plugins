# SwiftUI Animations (visionOS)

SwiftUI animation works the same on visionOS as other platforms; this is the 2D
layer for windows, volumes' UI, ornaments, overlays, and progress.

## Value-driven vs imperative

```swift
// Imperative: animate the state change inside the closure
withAnimation(.spring(duration: 0.4)) { isOpen.toggle() }

// Declarative: animate whenever `value` changes
content.animation(.easeInOut(duration: 0.3), value: isOpen)
```

Prefer `.animation(_:value:)` (scoped to a specific value) over the deprecated
implicit `.animation(_:)`.

## Timing curves

`.linear`, `.easeIn/.easeOut/.easeInOut`, `.spring`, `.bouncy`, `.smooth`,
`.snappy`, plus `.interpolatingSpring`. Add `.delay(_:)`, `.speed(_:)`,
`.repeatForever(autoreverses:)`.

## Transitions

```swift
if showPanel {
    Panel().transition(.opacity.combined(with: .move(edge: .bottom)))
}
// asymmetric
.transition(.asymmetric(insertion: .scale, removal: .opacity))
```

## phaseAnimator (looping multi-step, no timers) — visionOS 1.0+/SwiftUI 17+

```swift
Image(systemName: "circle.dotted")
    .phaseAnimator([0.0, 1.0]) { view, phase in
        view.opacity(0.4 + 0.6 * phase)
            .scaleEffect(0.9 + 0.1 * phase)
    } animation: { _ in .easeInOut(duration: 0.7) }
```

Use a discrete trigger to step phases once per change:
`.phaseAnimator(Phase.allCases, trigger: tapCount) { ... }`.

## keyframeAnimator (independent tracks over time)

```swift
struct Wobble { var angle = Angle.zero; var scale = 1.0 }

icon.keyframeAnimator(initialValue: Wobble()) { view, v in
    view.rotationEffect(v.angle).scaleEffect(v.scale)
} keyframes: { _ in
    KeyframeTrack(\.angle) {
        CubicKeyframe(.degrees(10), duration: 0.2)
        CubicKeyframe(.degrees(-10), duration: 0.4)
        CubicKeyframe(.degrees(0), duration: 0.2)
    }
    KeyframeTrack(\.scale) {
        SpringKeyframe(1.1, duration: 0.4)
        SpringKeyframe(1.0, duration: 0.4)
    }
}
```

## SF Symbol effects — great for "working" states

```swift
Image(systemName: "sparkles").symbolEffect(.variableColor.iterative, isActive: isWorking)
Image(systemName: "arrow.triangle.2.circlepath").symbolEffect(.rotate, isActive: isWorking)
Image(systemName: "wifi").symbolEffect(.pulse)
Image(systemName: "bell").symbolEffect(.bounce, value: notificationCount)
Label("Saved", systemImage: "checkmark.circle")
    .contentTransition(.symbolEffect(.replace))   // swap symbols with animation
```

## ProgressView (loading)

```swift
ProgressView()                                   // indeterminate spinner
    .controlSize(.large)

ProgressView(value: progress)                    // determinate 0...1, animates
ProgressView(value: progress) { Text("Generating…") }
    .progressViewStyle(.linear)
```

Changing `value` animates the fill; wrap a manual jump in `withAnimation` if needed.

## Content transitions

```swift
Text("\(percent)%").contentTransition(.numericText())   // rolling digits
Text(label).contentTransition(.interpolate)
```

## ContentUnavailableView (empty/failed states)

```swift
ContentUnavailableView("No model yet", systemImage: "cube.transparent",
    description: Text("Describe something to generate."))
```

## Reduce Motion

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
let anim: Animation? = reduceMotion ? nil : .spring
withAnimation(anim) { ... }
```

## Pitfalls

- Implicit `.animation(_:)` (no value) is deprecated and over-animates — scope it.
- Driving loops with `Timer` when `phaseAnimator`/`repeatForever` suffice.
- Forgetting Reduce Motion — provide a calm fallback.
- Animating expensive layout each frame during loading — animate cheap transforms.
