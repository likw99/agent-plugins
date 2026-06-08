# RealityKit Spatial Audio (visionOS)

RealityKit renders ray-traced spatial audio: sounds played on entities are
positioned in 3D and pick up environmental acoustics. Audio is **spatial by
default**.

## Loading audio resources

```swift
// From the app bundle
let res = try await AudioFileResource(named: "chime.wav")

// Looping config
let loop = try await AudioFileResource(
    named: "ambient.wav",
    configuration: .init(shouldLoop: true)
)

// From the RealityKitContent bundle / a USD scene
let res2 = try await AudioFileResource.load(
    named: "Chime", from: "Scene.usda", in: realityKitContentBundle
)
```

Preload once and reuse — don't load on the moment you need to play.

## Playing

```swift
// Fire-and-forget on an entity
entity.playAudio(res)

// Controlled playback
let controller = entity.prepareAudio(res)        // AudioPlaybackController
controller.play()
controller.pause()
controller.stop()
controller.gain  = -8.0                           // dB (negative = quieter)
controller.speed = 1.0
controller.completionHandler = { /* done */ }

entity.stopAllAudio()
```

## Audio components

### SpatialAudioComponent — positional sound from an entity
```swift
entity.spatialAudio = SpatialAudioComponent(gain: -6)
// Tight directional beam (e.g. a speaker):
entity.spatialAudio = SpatialAudioComponent(directivity: .beam(focus: 0.75))
// Aim it by rotating the entity (sound projects along its orientation).
```
Tip: use a dedicated empty child `Entity()` as the emitter so you can aim/position
sound independently of the visible model.

### AmbientAudioComponent — direction without distance attenuation
For environmental beds that should feel "all around" without falling off by
distance.

### ChannelAudioComponent — non-spatial, straight to output
```swift
let music = Entity()
music.components.set(ChannelAudioComponent())
music.playAudio(try await AudioFileResource(named: "bgm.m4a",
                  configuration: .init(shouldLoop: true)))
```
Ideal for background music not tied to any visible object.

### ReverbComponent — virtual-environment acoustics
```swift
let reverb = Entity()
reverb.components.set(ReverbComponent(reverb: .preset(.smallRoom)))
content.add(reverb)
```
Makes virtual sources sound like they're in the virtual space (use in
`.full`/`.progressive` immersion). Only one reverb is active at a time.

## Varying sounds — AudioFileGroupResource

```swift
let group = try await AudioFileGroupResource.load(named: "Footsteps",
              in: realityKitContentBundle)
entity.playAudio(group)   // plays a random member each call (less repetitive)
```

## Completion chime recipe

```swift
// preload at viewer setup
let chime = try await AudioFileResource(named: "done.wav")

// when the model is ready and added to the scene:
modelEntity.spatialAudio = SpatialAudioComponent(gain: -6)
modelEntity.playAudio(chime)   // emits from the model's location
```

## Pitfalls

- Loading `AudioFileResource` at trigger time (hitch) — preload.
- Forgetting it's spatial by default (sound seems to come "from somewhere") — set
  `ChannelAudioComponent` for true non-spatial.
- Looping with no `stop()` / not retaining the `AudioPlaybackController`.
- Expecting reverb to stack — only one active at a time.
- Aiming directional audio by rotating the model (unwanted) instead of a child emitter.
