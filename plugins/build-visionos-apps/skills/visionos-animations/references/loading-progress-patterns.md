# Loading & Progress Patterns for Long Async Jobs

A playbook for engaging in-progress UX during long work (e.g. text-to-3D
generation that runs seconds → minutes, polled for progress). Maps directly to
HiPtah's `ModelGenerationService` (`isGenerating`, `currentTask.progress`,
`currentTask.status`).

## Principles

- **Always communicate state**: pending → working → done/failed.
- **Determinate when you can** (a real 0...1 progress), **indeterminate when you
  can't** — don't fake a progress bar that stalls.
- **Make waiting feel alive** with subtle motion (symbol effects, a gently
  spinning 3D placeholder), not a frozen spinner.
- **Confirm completion** visually (and with sound — see `spatial-audio-sound`).

## SwiftUI progress section (2D)

```swift
@State private var phase = 0      // for staged status text

var progressSection: some View {
    VStack(spacing: 20) {
        Image(systemName: "cube.transparent")
            .font(.system(size: 56))
            .symbolEffect(.variableColor.iterative)          // "thinking"
            .symbolEffect(.bounce, value: service.currentTask?.status)

        if let p = service.currentTask?.progress, p > 0 {
            ProgressView(value: p) { Text(statusText) }
                .progressViewStyle(.linear)
            Text("\(Int(p * 100))%").contentTransition(.numericText())
        } else {
            ProgressView(statusText).controlSize(.large)     // indeterminate
        }
    }
    .animation(.smooth, value: service.currentTask?.progress)
}
```

## Spinning 3D placeholder while generating

Show a lightweight placeholder entity (a primitive or a stand-in model) that spins
while the real model is being generated, then swap it out:

```swift
RealityView { content in
    let placeholder = ModelEntity(
        mesh: .generateBox(size: 0.2, cornerRadius: 0.02),
        materials: [SimpleMaterial(color: .gray, roughness: 0.4, isMetallic: true)]
    )
    placeholder.name = "placeholder"
    content.add(placeholder)

    let spin = FromToByAnimation(
        from: Transform(rotation: simd_quatf(angle: 0,   axis: [0,1,0])),
        to:   Transform(rotation: simd_quatf(angle: .pi, axis: [0,1,0])),
        duration: 2, bindTarget: .transform)
    if let res = try? AnimationResource.generate(with: spin) {
        placeholder.playAnimation(res.repeat(duration: .infinity))
    }
} update: { content in
    // When the real model is ready, remove placeholder and add the model (faded in)
    if isLoaded, content.entities.contains(where: { $0.name == "placeholder" }) {
        content.entities.first { $0.name == "placeholder" }?.removeFromParent()
        if let model = loadedEntity { content.add(model) }
    }
}
```

## Fade in the finished model

```swift
loadedEntity.components.set(OpacityComponent(opacity: 0))
content.add(loadedEntity)
// animate opacity → 1 via a short FromToByAnimation on .opacity, or a System
```

## Staged status text

Mirror the job's status enum to friendly, animated copy:

```swift
var statusText: String {
    switch service.currentTask?.status {
    case .pending:    return "Preparing…"
    case .generating: return "Sculpting your model…"
    case .converting: return "Finishing touches…"
    case .completed:  return "Ready!"
    case .failed:     return "Couldn't generate"
    case .none:       return "Starting…"
    }
}
// Text(statusText).contentTransition(.opacity)  + .animation(_, value: status)
```

## Completion & failure

- On `.completed`: stop the spinner/placeholder animation, reveal the model
  (fade/scale in), play a chime (`spatial-audio-sound`), show the next action.
- On `.failed`: stop motion, show `ContentUnavailableView` with a retry.

## Cleanup

- Stop `AnimationPlaybackController`s and cancel polling `Task`s on completion and
  in `onDisappear`.
- Respect `accessibilityReduceMotion` (calmer/static variants).

## Pitfalls

- Determinate bar that jumps to 90% then hangs — prefer indeterminate if the
  backend can't report real progress for that phase.
- Spinner that never stops because the controller wasn't retained/stopped.
- Heavy placeholder model competing with the load — keep it a cheap primitive.
