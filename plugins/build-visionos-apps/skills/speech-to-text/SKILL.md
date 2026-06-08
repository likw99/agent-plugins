---
name: speech-to-text
description: Add Apple-native on-device speech-to-text to visionOS apps. Use when letting users dictate input by voice, transcribing microphone audio, or choosing between SFSpeechRecognizer, SpeechAnalyzer, and keyboard dictation.
---

# Speech-to-Text

## Overview
Use this skill to capture spoken input and turn it into text — e.g. a mic button
that lets users *speak* a prompt instead of typing. Apple offers three paths;
pick by deployment target. Microphone + speech permission and Info.plist keys are
mandatory and easy to forget.

## Decision Tree (choose by deployment target)

1. **Deployment target < visionOS 26 (e.g. HiPtah at 1.2)** → **`SFSpeechRecognizer`**
   + `AVAudioEngine`. Available visionOS 1.0+. The default, broadly compatible path.
2. **Deployment target ≥ visionOS 26** → **`SpeechAnalyzer` + `SpeechTranscriber`**
   (new on-device API, faster/more robust, runs outside your app's memory,
   auto-updating models). Use `DictationTranscriber` as a fallback for
   unsupported locales/devices.
3. **Just need free, zero-code dictation in a text field** → rely on the system
   **keyboard's dictation** (mic key). No Speech framework, no entitlement code —
   but it's user-initiated via the keyboard, not programmatic.

> Gate the modern API: `if #available(visionOS 26, *) { /* SpeechAnalyzer */ } else { /* SFSpeechRecognizer */ }`.

## Permissions first (always)

Add to Info.plist (HiPtah currently has neither):
- `NSMicrophoneUsageDescription` — why you record audio.
- `NSSpeechRecognitionUsageDescription` — why you transcribe speech.

Request at runtime before starting:
```swift
SFSpeechRecognizer.requestAuthorization { status in /* .authorized? */ }
AVAudioApplication.requestRecordPermission { granted in /* mic */ }
```

## SFSpeechRecognizer recipe (HiPtah default)

> **Critical:** configure `AVAudioSession` **before** touching `engine.inputNode`.
> Without an active recording session the input node has no valid hardware format
> (0 channels / 0 sample rate) and `installTap` throws `NSException` / crashes the app.

```swift
import Speech
import AVFoundation

let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
let engine = AVAudioEngine()
var request: SFSpeechAudioBufferRecognitionRequest?
var task: SFSpeechRecognitionTask?

func start(onText: @escaping (String) -> Void) throws {
    // 1. Activate audio session FIRST — must precede any inputNode access
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playAndRecord, mode: .measurement,
                            options: [.duckOthers, .allowBluetoothHFP])
    try session.setActive(true, options: .notifyOthersOnDeactivation)

    let req = SFSpeechAudioBufferRecognitionRequest()
    req.shouldReportPartialResults = true
    // Gate on-device flag — simulator may not have the model
    if recognizer.supportsOnDeviceRecognition { req.requiresOnDeviceRecognition = true }
    request = req

    // 2. Pass nil format — lets AVFAudio use the live hardware format.
    //    Reading outputFormat(forBus:) before the session is active returns
    //    garbage (0 channels/rate) and also crashes installTap.
    engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { buffer, _ in
        req.append(buffer)
    }
    engine.prepare(); try engine.start()

    task = recognizer.recognitionTask(with: req) { result, error in
        if let result { onText(result.bestTranscription.formattedString) }  // streams partials
        if error != nil || (result?.isFinal ?? false) { /* stop() */ }
    }
}

func stop() {
    engine.stop(); engine.inputNode.removeTap(onBus: 0)
    request?.endAudio(); task?.cancel()
    request = nil; task = nil
    try? AVAudioSession.sharedInstance().setActive(false,
                                                   options: .notifyOthersOnDeactivation)
}
```

Stream `onText` straight into your bound prompt `String`. See
`references/speech-framework-legacy.md` for the full lifecycle.

## SpeechAnalyzer (visionOS 26+) — at a glance

```swift
@available(visionOS 26, *)
func transcribe() async throws {
    let transcriber = SpeechTranscriber(locale: .current,
                                        transcriptionOptions: [],
                                        reportingOptions: [.volatileResults],
                                        attributeOptions: [])
    let analyzer = SpeechAnalyzer(modules: [transcriber])
    // ensure model assets for the locale are installed (AssetInventory), then
    // feed AVAudioEngine buffers and consume transcriber.results (async stream)
}
```
Check `SpeechTranscriber.supportedLocales` and allocate/download the locale model
before use. Full flow in `references/speech-framework-modern.md`.

## Checklist

- Info.plist has `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription`.
- Authorization requested and denial/restricted handled with clear UX.
- Correct API for the deployment target (gate the 26+ path).
- **`AVAudioSession` configured and activated before any `inputNode` access.**
- `installTap` called with `format: nil` (not `outputFormat(forBus:)` before session is live).
- `requiresOnDeviceRecognition` gated on `recognizer.supportsOnDeviceRecognition` (not hardcoded `true`).
- Partial results stream into the field; mic button shows listening state.
- Audio engine tap removed and task ended on stop / `onDisappear`.
- `AVAudioSession.setActive(false)` called in `stop()`.
- On-device recognition preferred for privacy; locale set explicitly.

## References

- `references/speech-framework-legacy.md`: SFSpeechRecognizer + AVAudioEngine full lifecycle.
- `references/speech-framework-modern.md`: SpeechAnalyzer/SpeechTranscriber, model assets, DictationTranscriber.
- `references/mic-and-authorization.md`: permissions, Info.plist, visionOS mic behavior, error states.
- Apple: Speech framework; `SpeechTranscriber`/`SpeechAnalyzer`; `SFSpeechRecognizer`;
  AVAudioEngine; WWDC25 session 277 "Bring advanced speech-to-text with SpeechAnalyzer".

## Guardrails

- Never start capture before authorization + mic permission are granted.
- Don't ship without the two Info.plist usage strings — the app will crash on access.
- Don't use `SpeechAnalyzer` unguarded on a < 26 target — it won't compile/run.
- **Don't touch `engine.inputNode` before `AVAudioSession` is active** — `installTap` throws `NSException` and crashes.
- **Don't pass `outputFormat(forBus:)` as the tap format** — use `nil`; the format is invalid until the session is live.
- Don't hardcode `requiresOnDeviceRecognition = true` — gate it on `recognizer.supportsOnDeviceRecognition` (simulator often lacks the model).
- Don't leave the audio tap installed or the task running after stop (battery, mic indicator).
- Don't forget to call `AVAudioSession.setActive(false)` in `stop()`.
- Prefer on-device recognition; warn if falling back to server-based.

## Output Expectations

State the chosen API (and why, per target), the permission/Info.plist setup, how
partial text streams into the field, and the stop/cleanup path.
