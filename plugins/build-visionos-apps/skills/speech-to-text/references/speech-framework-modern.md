# SpeechAnalyzer + SpeechTranscriber (visionOS 26+ / iOS 26+)

Apple's modern on-device speech-to-text framework (introduced WWDC25). Faster and
more robust than `SFSpeechRecognizer`, ideal for longer/continuous transcription.
Runs on-device, outside your app's memory; models auto-update. Gate everything
with `#available(visionOS 26, *)` — it does not exist on earlier targets.

## Core types

- **`SpeechAnalyzer`** — the engine; you give it analysis modules and feed audio.
- **`SpeechTranscriber`** — the transcription module (the new model). Best for
  general conversation/dictation.
- **`DictationTranscriber`** — fallback module covering the same languages/devices
  as legacy on-device `SFSpeechRecognizer`; use when a locale/device isn't
  supported by `SpeechTranscriber`. Unlike legacy, no Settings toggle required.
- **`AssetInventory`** — manages downloading/allocating the on-device language
  model assets.

## Locale + model assets (required setup)

```swift
@available(visionOS 26, *)
func ensureModel(for locale: Locale) async throws {
    // Verify support
    guard await SpeechTranscriber.supportedLocales.contains(where: {
        $0.identifier(.bcp47) == locale.identifier(.bcp47)
    }) else { throw MyError.unsupportedLocale }

    // Reserve/download assets if needed (one-time per locale)
    let transcriber = SpeechTranscriber(locale: locale,
                                        transcriptionOptions: [],
                                        reportingOptions: [.volatileResults],
                                        attributeOptions: [.audioTimeRange])
    if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
        try await request.downloadAndInstall()
    }
}
```

Common beta error: *"SpeechTranscriber cannot be initialized with an unsupported
locale"* — always check `supportedLocales` and install assets first.

## Transcribe microphone input

```swift
@available(visionOS 26, *)
func transcribeMic(onText: @escaping (String) -> Void) async throws {
    let transcriber = SpeechTranscriber(locale: .current,
                                        transcriptionOptions: [],
                                        reportingOptions: [.volatileResults],
                                        attributeOptions: [])
    let analyzer = SpeechAnalyzer(modules: [transcriber])

    // Consume results (volatile = partials, then finalized)
    Task {
        for try await result in transcriber.results {
            onText(String(result.text.characters))   // result.text is AttributedString
        }
    }

    // Feed audio from AVAudioEngine
    let engine = AVAudioEngine()
    let input = engine.inputNode
    let (stream, continuation) = AsyncStream.makeStream(of: AnalyzerInput.self)
    input.installTap(onBus: 0, bufferSize: 4096,
                     format: input.outputFormat(forBus: 0)) { buffer, _ in
        continuation.yield(AnalyzerInput(buffer: buffer))
    }
    engine.prepare(); try engine.start()
    try await analyzer.start(inputSequence: stream)
}
```

Stop by finishing the input stream/continuation, removing the tap, and stopping
the engine and analyzer.

## Reporting options

- `.volatileResults` — emit partial (in-progress) results that get refined.
- `.audioTimeRange` (attribute) — per-segment timing (captioning, alignment).

## When to prefer this over SFSpeechRecognizer

- Long-form / continuous transcription (no legacy session time limits).
- Better accuracy and performance for media-style content.
- Targeting visionOS/iOS 26+ only.

For mixed targets, keep `SFSpeechRecognizer` as the `else` branch (see
`speech-framework-legacy.md`).

## Pitfalls

- Using these types without `#available(visionOS 26, *)` — unavailable on < 26.
- Initializing a transcriber with an unsupported locale — check `supportedLocales`.
- Not installing model assets before first use — first transcription fails/stalls.
- Forgetting `result.text` is an `AttributedString` (extract characters/string).
- Leaving the analyzer/engine running after you have the text.
