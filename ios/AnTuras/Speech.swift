import AVFoundation

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

    func speak(_ text: String) {
        stop()
        if let url = Self.bundledURL(for: text) {
            playClip(url: url, text: text)
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

    private func playClip(url: URL, text: String) {
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return }
        activateSession()
        player = p
        p.delegate = self
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
        for ext in ["mp3", "m4a", "wav", "caf"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }

    nonisolated static func bundledURL(named assetName: String) -> URL? {
        let safeName = URL(fileURLWithPath: assetName).lastPathComponent
        let file = (safeName as NSString).deletingPathExtension
        let ext = (safeName as NSString).pathExtension
        guard !file.isEmpty, !ext.isEmpty else { return nil }
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
