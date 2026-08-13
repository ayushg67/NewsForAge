import Foundation
import AVFoundation
import Observation

/// Reads article text aloud using the system speech synthesizer, preferring the
/// most natural (Premium ▸ Enhanced ▸ Default) voice available for the language.
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

    /// Speaks `text` in the given BCP-47 language, using `voiceIdentifier` when it
    /// matches that language, otherwise the best-quality installed voice for it.
    func speak(_ text: String, languageCode: String, voiceIdentifier: String?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        configureAudioSession()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = resolveVoice(languageCode: languageCode, voiceIdentifier: voiceIdentifier)
        // A touch below the default rate reads more naturally.
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.96
        utterance.pitchMultiplier = 1.0
        utterance.postUtteranceDelay = 0.1
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    /// Chosen voice if it fits the language; otherwise the best voice for it.
    private func resolveVoice(languageCode: String, voiceIdentifier: String?) -> AVSpeechSynthesisVoice? {
        let prefix = String(languageCode.prefix(2)).lowercased()
        if let id = voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: id),
           voice.language.lowercased().hasPrefix(prefix) {
            return voice
        }
        return Self.bestVoice(for: languageCode)
    }

    /// Installed voices for a language, best quality first.
    static func voices(for languageCode: String) -> [AVSpeechSynthesisVoice] {
        let prefix = String(languageCode.prefix(2)).lowercased()
        return AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.lowercased().hasPrefix(prefix) }
            .sorted { a, b in
                let aExact = a.language.caseInsensitiveCompare(languageCode) == .orderedSame
                let bExact = b.language.caseInsensitiveCompare(languageCode) == .orderedSame
                if aExact != bExact { return aExact }
                if a.quality.rawValue != b.quality.rawValue { return a.quality.rawValue > b.quality.rawValue }
                return a.name < b.name
            }
    }

    static func bestVoice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        voices(for: languageCode).first ?? AVSpeechSynthesisVoice(language: languageCode)
    }

    private func configureAudioSession() {
        // Allow playback even when the silent switch is on.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }
}

extension AVSpeechSynthesisVoiceQuality {
    var label: String {
        switch self {
        case .premium: return "Premium"
        case .enhanced: return "Enhanced"
        default: return "Default"
        }
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
