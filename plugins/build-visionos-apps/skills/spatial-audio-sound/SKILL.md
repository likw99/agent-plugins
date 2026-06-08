---
name: spatial-audio-sound
description: Add sound to visionOS apps — RealityKit spatial audio on entities and simple non-spatial UI sound effects. Use when playing completion chimes, sound on events, ambient/background audio, or positional 3D sound.
---

# Spatial Audio & Sound

## Overview
Use this skill to add audio: **RealityKit spatial audio** (sound emitted from
entities, positioned in 3D, reverberant in immersive spaces — spatial by default)
and **simple UI sound effects** (a one-shot chime not tied to a 3D location). The
driving use case is a completion chime when a long async job finishes, plus a
general sound model for spatial apps.

## Decision Tree

1. **Sound from a 3D object / positional** (model "pings" when ready, ambience
   tied to a place) → RealityKit `playAudio` on an entity with
   `SpatialAudioComponent`.
2. **Non-spatial UI feedback** in a 2D window flow (a chime, a tap sound) and you
   have no scene entity handy → `AVAudioPlayer` or `AudioServicesPlaySystemSound`.
3. **Background music / non-diegetic** (not tied to anything visible) →
   `ChannelAudioComponent` (sends channels straight to output, no spatialization).
4. **Ambient bed across the scene** → `AmbientAudioComponent`.

## Completion chime (the core recipe)

Spatial (when you have the model entity in a RealityView):

```swift
// Preload once
let chime = try await AudioFileResource(named: "done.wav")   // or .load(named:in:)

// On task.status == .completed
modelEntity.spatialAudio = SpatialAudioComponent(gain: -6)    // dB attenuation
modelEntity.playAudio(chime)                                  // plays once
```

Non-spatial (2D generation screen, no entity):

```swift
import AVFoundation
var player: AVAudioPlayer?
func playChime() {
    guard let url = Bundle.main.url(forResource: "done", withExtension: "wav") else { return }
    player = try? AVAudioPlayer(contentsOf: url)
    player?.prepareToPlay(); player?.play()    // retain `player` or it deinits mid-play
}
```

## RealityKit audio essentials

```swift
// Load
let res = try await AudioFileResource(named: "loop.wav",
            configuration: .init(shouldLoop: true))
// or from the content bundle:
let res2 = try await AudioFileResource.load(named: "Chime", from: "Scene.usda",
            in: realityKitContentBundle)

// Play (fire-and-forget)
entity.playAudio(res)

// Control playback
let controller = entity.prepareAudio(res)   // AudioPlaybackController
controller.play(); controller.pause(); controller.stop()
controller.gain = -10; controller.speed = 1.0
controller.completionHandler = { /* finished */ }
```

- Audio is **spatial by default**. Add a `SpatialAudioComponent` to shape it
  (directivity beam, gain). Use a dedicated empty child entity as the emitter if
  you want to aim sound independently of the model.
- `AudioFileGroupResource` randomly varies among clips each `playAudio` (avoids
  repetitive SFX).
- `ReverbComponent` makes virtual sources sound like the virtual environment in a
  `.full`/`.progressive` space; only one reverb is active at a time.

## Checklist

- Audio assets bundled (app bundle or `RealityKitContent`) and preloaded, not
  loaded on the playback hot path.
- Chime plays on the right event (`.completed`), once, not on every state poll.
- Non-spatial player object is retained for its lifetime (no early deinit).
- Spatial emitter placement/gain is sensible; not jarringly loud.
- Loops are stopped on completion / scene disappear; controllers retained.
- Respects system volume / silent behavior; no audio in inappropriate states.

## References

- `references/realitykit-spatial-audio.md`: AudioFileResource, components, playback controllers, reverb.
- `references/sound-effects-and-playback.md`: AVAudioPlayer / AudioToolbox one-shots, AVAudioSession, assets.
- See also `realitykit-entities` (entities/RealityView) for emitter setup.
- Apple: visionOS "Playing spatial audio"; RealityKit `AudioFileResource`,
  `SpatialAudioComponent`, `Entity/playAudio`; WWDC24 "Enhance your spatial
  computing app with RealityKit audio".

## Guardrails

- Don't load audio synchronously on the playback path — preload `AudioFileResource`.
- Don't let a local `AVAudioPlayer` go out of scope mid-playback (store it).
- Don't trigger the chime repeatedly from a polled status — fire once on transition.
- Don't loop SFX without a stop path.
- Don't assume non-spatial when using RealityKit — it's spatial by default.

## Output Expectations

State spatial vs non-spatial choice, the event that triggers playback, how the
asset is preloaded/retained, and the stop/cleanup path.
