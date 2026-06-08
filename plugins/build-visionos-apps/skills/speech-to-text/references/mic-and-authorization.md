# Microphone & Speech Authorization (visionOS)

Speech capture requires both microphone permission and speech-recognition
authorization, plus two Info.plist usage strings. Missing either causes a denial
or a hard crash on access.

## Info.plist keys (mandatory)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>HiPtah uses the microphone so you can speak your 3D model prompt.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>HiPtah transcribes your speech to fill in the prompt.</string>
```

Accessing the mic or speech APIs without these strings crashes the app. (HiPtah's
Info.plist currently has neither — add both.)

## Requesting authorization

```swift
import Speech
import AVFoundation

// Speech recognition
func requestSpeech() async -> SFSpeechRecognizerAuthorizationStatus {
    await withCheckedContinuation { c in
        SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0) }
    }
}

// Microphone (modern API)
func requestMic() async -> Bool {
    await AVAudioApplication.requestRecordPermission()
}
```

Status values for speech: `.authorized`, `.denied`, `.restricted`,
`.notDetermined`. Only start capture when speech is `.authorized` **and** mic is
granted.

## Handling each state (UX)

- `.notDetermined` → trigger the request on first mic-button tap.
- `.denied` → show a message + a button to open Settings:
  ```swift
  if let url = URL(string: UIApplicationOpenSettingsURLString) {
      openURL(url)   // @Environment(\.openURL)
  }
  ```
- `.restricted` → feature unavailable (parental/MDM); hide or disable the mic button.
- Mic denied → same Settings deep-link pattern.

## visionOS specifics

- Microphone works in both the Shared Space and Full Space; the system shows a
  recording indicator while the mic is active.
- Remove the audio tap and stop the engine as soon as you're done so the mic
  indicator clears and battery isn't wasted.
- The system keyboard's **dictation** (mic key on the keyboard) needs no
  permission code at all — a zero-effort fallback if you only need field dictation.

## Lifecycle hygiene

- Request permissions before starting capture, not at launch (ask in context).
- Stop capture on `onDisappear`, scene background, and when the user toggles off.
- Don't re-request repeatedly if `.denied` — guide to Settings instead.

## Pitfalls

- Shipping without the two usage strings → crash on first access.
- Starting `AVAudioEngine` before permission is granted.
- Ignoring `.restricted` (can't be resolved by the user).
- Leaving the mic active (indicator stays on) after capturing text.
