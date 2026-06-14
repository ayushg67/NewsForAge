import Foundation
import AVFoundation
import Observation

/// Reads article text aloud using the system speech synthesizer.
@Observable
@MainActor
final class SpeechService {
    private let synthesizer = AVSpeechSynthesizer()
    private let delegate = SpeechDelegate()

    /// True while audio is actively playing (not paused, not stopped).
    private(set) var isSpeaking = false

    init() {
        delegate.onChange = { [weak self] speaking in
            self?.isSpeaking = speaking
        }
        synthesizer.delegate = delegate
    }

    /// Speaks the given text, replacing anything already in progress.
    func speak(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        configureAudioSession()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.postUtteranceDelay = 0.1
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    private func configureAudioSession() {
        // Allow playback even when the silent switch is on.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }
}

/// AVSpeechSynthesizerDelegate is not Sendable-friendly, so it lives in a small
/// helper that forwards start/finish/cancel events back to the service.
private final class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onChange: ((Bool) -> Void)?

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        onChange?(true)
    }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onChange?(false)
    }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onChange?(false)
    }
}
