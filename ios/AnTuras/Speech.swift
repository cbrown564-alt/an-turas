import AVFoundation

private struct SpeechRuntimeManifest: Decodable {
    let lines: [SpeechRuntimeLine]
    let dynamicExclusions: [SpeechRuntimeExclusion]

    enum CodingKeys: String, CodingKey {
        case lines
        case dynamicExclusions = "dynamic_exclusions"
    }
}

fileprivate struct SpeechRuntimeLine: Decodable {
    let slug: String
    let text: String
    let file: String
    let qaState: String

    enum CodingKeys: String, CodingKey {
        case slug
        case text
        case file
        case qaState = "qa_state"
    }
}

private struct SpeechRuntimeExclusion: Decodable {
    let slug: String
}

struct SpeechRuntimeIndex {
    let isLoaded: Bool
    fileprivate let linesBySlug: [String: SpeechRuntimeLine]
    fileprivate let linesByFile: [String: SpeechRuntimeLine]
    fileprivate let exclusions: Set<String>

    static let unavailable = SpeechRuntimeIndex(
        isLoaded: false,
        linesBySlug: [:],
        linesByFile: [:],
        exclusions: []
    )

    func isLearnerUsable(_ line: SpeechRuntimeLine) -> Bool {
        ["generated_unreviewed", "spot_flagged", "qa_passed"].contains(line.qaState)
            && !exclusions.contains(line.slug)
    }
}

enum SpeechRuntimeCatalog {
    static let index: SpeechRuntimeIndex = load()

    static func index(from data: Data?) -> SpeechRuntimeIndex {
        guard let data,
              let manifest = try? JSONDecoder().decode(SpeechRuntimeManifest.self, from: data)
        else { return .unavailable }

        var linesBySlug: [String: SpeechRuntimeLine] = [:]
        var linesByFile: [String: SpeechRuntimeLine] = [:]
        for line in manifest.lines {
            guard line.file == "\(line.slug).mp3",
                  URL(fileURLWithPath: line.file).lastPathComponent == line.file,
                  linesBySlug[line.slug] == nil,
                  linesByFile[line.file] == nil
            else { return .unavailable }
            linesBySlug[line.slug] = line
            linesByFile[line.file] = line
        }

        return SpeechRuntimeIndex(
            isLoaded: true,
            linesBySlug: linesBySlug,
            linesByFile: linesByFile,
            exclusions: Set(manifest.dynamicExclusions.map(\.slug))
        )
    }

    private static func load() -> SpeechRuntimeIndex {
        guard let url = Bundle.main.url(forResource: "manifest", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return .unavailable }
        return index(from: data)
    }
}

// MARK: - An Guth — the voice.
// All release-path speech uses reviewed, bundled clips generated with the
// ElevenLabs Irish Cultural Guide house voice. We deliberately do not fall
// through to a device voice: that would change accent and quality by device.
// Missing or personalized lines remain visibly usable without pretending a
// different voice belongs to the same recording set.

@MainActor
final class SpeechService: NSObject, ObservableObject {
    static let shared = SpeechService()

    @Published private(set) var speaking = false
    /// The text currently being spoken, so the view that owns the line can
    /// light its own ear and no one else's.
    @Published private(set) var currentText: String?

    private var player: AVAudioPlayer?

    override private init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMediaServicesReset(_:)),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    /// Whether this exact line can be heard on this device.
    func canSpeak(_ text: String) -> Bool {
        Self.bundledURL(for: text) != nil
    }

    /// Plays the bundled clip for `text`. Pass `rate` below 1 for a slower
    /// teaching listen (AVAudioPlayer rate; 1 is normal, ~0.7 is the Slow control).
    func speak(_ text: String, rate: Float = 1) {
        stop()
        if let url = Self.bundledURL(for: text) {
            playClip(url: url, text: text, rate: rate)
        }
    }

    func stop() {
        player?.stop()
        player = nil
        speaking = false
        currentText = nil
        deactivateSession()
    }

    func isSpeaking(_ text: String) -> Bool {
        speaking && currentText == text
    }

    /// Personal names and local voices use this explicit bundled-asset path only.
    /// It never falls through to system or synthetic speech.
    func playVerifiedAsset(named assetName: String, displayText: String) {
        stop()
        guard let url = Self.bundledURL(named: assetName) else { return }
        playClip(url: url, text: displayText)
    }

    func canPlayVerifiedAsset(named assetName: String) -> Bool {
        Self.bundledURL(named: assetName) != nil
    }

    // MARK: Sources

    private func playClip(url: URL, text: String, rate: Float = 1) {
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return }
        activateSession()
        player = p
        p.delegate = self
        p.enableRate = true
        p.rate = min(max(rate, 0.5), 2)
        p.prepareToPlay()
        speaking = true
        currentText = text
        if !p.play() { finishPlayback() }
    }

    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }

    private func finishPlayback() {
        player = nil
        speaking = false
        currentText = nil
        deactivateSession()
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard
            let rawValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            AVAudioSession.InterruptionType(rawValue: rawValue) == .began
        else { return }
        stop()
    }

    @objc private func handleMediaServicesReset(_ notification: Notification) {
        stop()
    }

    // MARK: Clip naming
    // A line of Irish maps to a filename by a fixed, boring rule so that any
    // provider's bake-off script can emit files the app finds unaided.
    // Rule: lowercase; fada vowels double (á→aa é→ee í→ii ó→oo ú→uu);
    // every other non-ASCII-letter becomes a word break; breaks join with "-".
    //   "Seo Bríd, m'iníon."  →  seo-briid-miniion
    //   "Cén t-ainm atá ort?" →  ceen-t-ainm-ataa-ort
    nonisolated static func slug(for text: String) -> String {
        let fadas: [Character: String] = [
            "á": "aa", "é": "ee", "í": "ii", "ó": "oo", "ú": "uu",
        ]
        var flat = ""
        for ch in text.lowercased() {
            if let doubled = fadas[ch] {
                flat += doubled
            } else if ch.isASCII && ch.isLetter {
                flat.append(ch)
            } else {
                flat.append(" ")
            }
        }
        return flat.split(separator: " ").joined(separator: "-")
    }

    nonisolated static func bundledURL(for text: String) -> URL? {
        let name = slug(for: text)
        let index = SpeechRuntimeCatalog.index
        guard let line = index.linesBySlug[name],
              line.text == text,
              index.isLearnerUsable(line)
        else { return nil }

        return Bundle.main.url(forResource: name, withExtension: "mp3")
    }

    nonisolated static func bundledURL(named assetName: String) -> URL? {
        bundledURL(named: assetName, using: SpeechRuntimeCatalog.index)
    }

    nonisolated static func bundledURL(
        named assetName: String,
        using index: SpeechRuntimeIndex
    ) -> URL? {
        let safeName = URL(fileURLWithPath: assetName).lastPathComponent
        let file = (safeName as NSString).deletingPathExtension
        let ext = (safeName as NSString).pathExtension
        guard !file.isEmpty, !ext.isEmpty else { return nil }

        guard index.isLoaded else { return nil }
        if let line = index.linesByFile[safeName] {
            guard index.isLearnerUsable(line) else { return nil }
        }

        return Bundle.main.url(forResource: file, withExtension: ext, subdirectory: "Audio")
            ?? Bundle.main.url(forResource: file, withExtension: ext)
    }
}

extension SpeechService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer,
                                                 successfully flag: Bool) {
        Task { @MainActor in finishPlayback() }
    }
}
