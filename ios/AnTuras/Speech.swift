import AVFoundation

// MARK: - An Guth — the voice.
// Audio sources, in order of preference:
//   1. Bundled clips (Resources/Audio/<slug>.mp3|m4a|wav) — Chapter 1 clips
//      from the TTS bake-off. Playtest path: Gemini 3.1 Flash TTS; Azure ga-IE
//      follow-up; ABAIR eval-only until TCD licence. See winners.json + manifest.
//   2. A system Irish voice, if one ever exists — as of iOS 26 Apple ships
//      no ga-IE voice, so this is future-proofing, not a real path.
//   3. Silence: every listen affordance quietly steps aside per-line, and
//      the app remains fully usable without sound.

@MainActor
final class SpeechService: NSObject, ObservableObject {
    static let shared = SpeechService()

    @Published private(set) var speaking = false
    /// The text currently being spoken, so the view that owns the line can
    /// light its own ear and no one else's.
    @Published private(set) var currentText: String?

    private let synth = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?
    private let voice: AVSpeechSynthesisVoice?

    /// Learner rate: unhurried, the way Dáire says a line for you to keep.
    nonisolated static let learnerRate: Float = 0.42

    override private init() {
        let irish = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == "ga-IE" }
        voice = irish.first { $0.quality != .default } ?? irish.first
        super.init()
        synth.delegate = self
    }

    /// Whether this exact line can be heard on this device.
    func canSpeak(_ text: String) -> Bool {
        voice != nil || Self.bundledURL(for: text) != nil
    }

    func speak(_ text: String, rate: Float = SpeechService.learnerRate) {
        stop()
        if let url = Self.bundledURL(for: text) {
            playClip(url: url, text: text)
        } else if voice != nil {
            speakSynthesized(text, rate: rate)
        }
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        player?.stop()
        player = nil
        speaking = false
        currentText = nil
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
        speaking = true
        currentText = text
        p.play()
    }

    private func speakSynthesized(_ text: String, rate: Float) {
        guard let voice else { return }
        activateSession()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = rate
        speaking = true
        currentText = text
        synth.speak(utterance)
    }

    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
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

extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in speaking = false; currentText = nil }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in speaking = false; currentText = nil }
    }
}

extension SpeechService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer,
                                                 successfully flag: Bool) {
        Task { @MainActor in speaking = false; currentText = nil }
    }
}
