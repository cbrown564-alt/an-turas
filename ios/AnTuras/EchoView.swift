import AVFoundation
import SwiftUI

// MARK: - Echo: abair é — say it aloud.
// The learner records themselves and plays their voice beside the model.
// Deliberately ungraded (STRATEGY U8 punts pronunciation scoring): the
// comparison is the teacher, the ear is the judge. Recording once earns the
// stroke; the shy can stay silent today and still pass through.

struct EchoView: View {
    let block: EchoBlock
    @Binding var activeGloss: Gloss?
    let onSolved: () -> Void

    @StateObject private var recorder = EchoRecorder()
    @ObservedObject private var speech = SpeechService.shared
    @State private var solved = false

    var body: some View {
        ExerciseFrame(context: block.context, prompt: "Abair é — say it aloud.") {
            SpeechBeatView(beat: block.beat) { activeGloss = block.beat.gloss }
                .padding(.bottom, 4)

            if recorder.denied {
                deniedNote
            } else {
                controls
            }

            if solved && recorder.state == .recorded {
                Verdict(ok: true,
                        headline: "Sin do ghlór, ar an tseanteanga.",
                        detail: "No score here — the ear is the judge. Play the model, then yourself, until the shapes agree.")
            }

            if !solved {
                Button {
                    markSolved()
                } label: {
                    Text("Ag éisteacht amháin inniu — just listening today →")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkFaint)
                        .underline(true, pattern: .dot, color: Theme.inkFaint.opacity(0.5))
                }
                .buttonStyle(CarvePress())
                .padding(.top, 6)
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch recorder.state {
        case .idle, .recording:
            Button {
                Haptics.tap()
                if recorder.state == .recording {
                    recorder.stop()
                    markSolved()
                } else {
                    speech.stop()
                    recorder.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Theme.rust)
                        .frame(width: 11, height: 11)
                        .modifier(RecordingPulse(active: recorder.state == .recording))
                    Text(recorder.state == .recording ? "Stad — stop" : "Taifead — record yourself")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.vertical, 13)
                .padding(.horizontal, 18)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(recorder.state == .recording ? Theme.rust : Theme.line, lineWidth: 1))
            }
            .buttonStyle(CarvePress())

        case .recorded:
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    if speech.canSpeak(block.s) {
                        playbackChip(
                            icon: speech.isSpeaking(block.s) ? "speaker.wave.2.fill" : "speaker.wave.2",
                            label: "An múnla — the model") {
                            recorder.stopPlayback()
                            speech.speak(block.s)
                        }
                    }
                    playbackChip(
                        icon: recorder.playing ? "waveform" : "play.fill",
                        label: "Do ghlórsa — your voice") {
                        speech.stop()
                        recorder.playBack()
                    }
                }
                Button {
                    Haptics.tap()
                    speech.stop()
                    recorder.toggle()
                } label: {
                    Text("Taifead arís — record again")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkFaint)
                        .underline(true, pattern: .dot, color: Theme.inkFaint.opacity(0.5))
                }
                .buttonStyle(CarvePress())
            }
        }
    }

    private func playbackChip(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.moss)
                    .contentTransition(.symbolEffect(.replace))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)
            .background(Theme.raised)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 1))
        }
        .buttonStyle(CarvePress())
    }

    private var deniedNote: some View {
        Text("The microphone is closed to us (you can open it in Settings → An Turas). Listening is plenty for today.")
            .font(.system(size: 14))
            .foregroundStyle(Theme.inkSoft)
            .lineSpacing(4)
    }

    private func markSolved() {
        guard !solved else { return }
        withAnimation(Motion.pop) { solved = true }
        onSolved()
    }
}

/// The recording dot breathes while the microphone is open.
private struct RecordingPulse: ViewModifier {
    let active: Bool
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(active ? (pulsing ? 0.35 : 1) : 1)
            .onChange(of: active) { _, on in
                if on {
                    withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                        pulsing = true
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) { pulsing = false }
                }
            }
    }
}

// MARK: - Recorder

@MainActor
final class EchoRecorder: NSObject, ObservableObject {
    enum RecState { case idle, recording, recorded }

    @Published var state: RecState = .idle
    @Published var playing = false
    @Published var denied = false

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("an-turas-echo.m4a")

    func toggle() {
        switch state {
        case .recording:
            stop()
        case .idle, .recorded:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                Task { @MainActor in
                    guard let self else { return }
                    if granted { self.startRecording() } else { self.denied = true }
                }
            }
        }
    }

    func stop() {
        guard state == .recording else { return }
        recorder?.stop()
        recorder = nil
        state = .recorded
    }

    func playBack() {
        stopPlayback()
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try? session.setActive(true)
        player = p
        p.delegate = self
        playing = true
        p.play()
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        playing = false
    }

    private func startRecording() {
        stopPlayback()
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try? session.setActive(true)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        guard let r = try? AVAudioRecorder(url: url, settings: settings) else { return }
        recorder = r
        r.record()
        state = .recording
    }
}

extension EchoRecorder: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer,
                                                 successfully flag: Bool) {
        Task { @MainActor in playing = false }
    }
}
