# SFSpeechRecognizer + AVAudioEngine (visionOS 1.0+)

The broadly compatible speech-to-text path. Recommended when the deployment
target is below visionOS 26 (e.g. HiPtah at 1.2). On-device capable, streams
partial results.

## Full lifecycle (observable controller)

```swift
import Speech
import AVFoundation
import Observation

@Observable
final class DictationModel {
    var transcript = ""
    var isListening = false
    var errorMessage: String?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func requestAccess() async -> Bool {
        let speechOK = await withCheckedContinuation { c in
            SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0 == .authorized) }
        }
        let micOK = await AVAudioApplication.requestRecordPermission()
        return speechOK && micOK
    }

    func start() {
        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognition unavailable"; return
        }
        do {
            let req = SFSpeechAudioBufferRecognitionRequest()
            req.shouldReportPartialResults = true
            if recognizer.supportsOnDeviceRecognition { req.requiresOnDeviceRecognition = true }
            request = req

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak req] buf, _ in
                req?.append(buf)
            }
            engine.prepare()
            try engine.start()
            isListening = true

            task = recognizer.recognitionTask(with: req) { [weak self] result, error in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    if result.isFinal { self.stop() }
                }
                if let error { self.errorMessage = error.localizedDescription; self.stop() }
            }
        } catch {
            errorMessage = error.localizedDescription
            stop()
        }
    }

    func stop() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil; task = nil
        isListening = false
    }
}
```

## Wiring into a SwiftUI prompt field (HiPtah)

```swift
@State private var dictation = DictationModel()
@State private var prompt = ""

HStack {
    TextField("Describe your 3D model", text: $prompt, axis: .vertical)
    Button {
        Task {
            if dictation.isListening { dictation.stop() }
            else if await dictation.requestAccess() { dictation.start() }
        }
    } label: {
        Image(systemName: dictation.isListening ? "mic.fill" : "mic")
            .symbolEffect(.variableColor, isActive: dictation.isListening)
    }
}
.onChange(of: dictation.transcript) { _, text in prompt = text }   // stream partials
.onDisappear { dictation.stop() }
```

## Key APIs

- `SFSpeechRecognizer(locale:)` — nil if locale unsupported; check `.isAvailable`.
- `SFSpeechAudioBufferRecognitionRequest` — live mic; set
  `shouldReportPartialResults`, `requiresOnDeviceRecognition`.
- `SFSpeechRecognitionTask` — the running recognition; cancel to stop.
- `result.bestTranscription.formattedString` — current text; `result.isFinal`.
- `recognizer.supportsOnDeviceRecognition` — gate the on-device flag.

## Notes & pitfalls

- Request **both** speech auth and mic permission before `start()`.
- Always `removeTap(onBus:)` and `endAudio()` on stop — else the mic stays hot.
- Server-based recognition has session time limits; on-device avoids them and is
  private — prefer it when `supportsOnDeviceRecognition` is true.
- `inputNode.outputFormat(forBus:)` must be read after the engine is configured;
  use it as the tap format.
- Handle `recognizer.isAvailable` changing (e.g. no network for server mode).
