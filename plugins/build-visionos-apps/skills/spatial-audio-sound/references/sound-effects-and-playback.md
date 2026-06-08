# Non-Spatial Sound Effects & Playback (visionOS)

When you want a simple sound not tied to a 3D entity — a chime in a 2D window
flow, a short UI effect — use AVFoundation or AudioToolbox instead of RealityKit.

## AVAudioPlayer — short bundled clips (recommended for SFX)

```swift
import AVFoundation

final class SoundPlayer {
    private var player: AVAudioPlayer?       // MUST be retained for playback

    func play(_ name: String, ext: String = "wav", volume: Float = 1.0) {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = volume
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("sound error: \(error)")
        }
    }
}
```

The #1 bug: declaring `AVAudioPlayer` as a local variable — it deinits when the
function returns and the sound never plays (or cuts off). Store it as a property.

## AudioToolbox — fire-and-forget system sounds

```swift
import AudioToolbox

// Built-in system sound by ID
AudioServicesPlaySystemSound(1057)            // e.g. a "Tink"

// Or register a custom short sound file
var soundID: SystemSoundID = 0
if let url = Bundle.main.url(forResource: "pop", withExtension: "caf") {
    AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
    AudioServicesPlaySystemSound(soundID)
}
```

Best for very short, non-critical effects. No volume/seek control. Prefer
`AVAudioPlayer` when you need control.

## AVAudioSession (when needed)

For simple SFX/chimes you usually don't need to touch the session. If audio
won't play or you mix with other audio, configure once at launch:

```swift
import AVFoundation
let session = AVAudioSession.sharedInstance()
try? session.setCategory(.ambient, mode: .default)   // respects silent switch, mixes
try? session.setActive(true)
```

- `.ambient` — non-critical sounds, mixes with others, obeys silence.
- `.playback` — primary audio that should keep playing; can interrupt others.

## SwiftUI-only feedback

There is no built-in "play sound" SwiftUI modifier; wrap one of the above in a
small helper and call it from `.onChange`/button actions:

```swift
.onChange(of: status) { _, new in
    if new == .completed { sound.play("done") }   // fire once on transition
}
```

## Choosing assets

- Keep SFX short (< ~2s) and small; `.wav`/`.caf` for SFX, `.m4a` for music.
- Bundle them in the app target (or `RealityKitContent` for spatial use).
- Normalize loudness; a completion chime should be pleasant, not startling.

## Pitfalls

- Local (non-retained) `AVAudioPlayer` — sound doesn't play; store it.
- Triggering from a polled value every update — fire on the state *transition*.
- Using a heavy `.playback` session for a tiny chime (can duck other audio) — use
  `.ambient`.
- Hardcoding system sound IDs without testing — they vary; prefer your own asset.
