//
//  SpeechManager.swift
//  Sarti SpritzX
//
//  Created by Vibe Code on 12.09.26.
//

import AVFoundation
import SwiftUI

final class SpeechManager: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechManager()

    private let synthesizer = AVSpeechSynthesizer()
    var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
        configureSession()
    }

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
        }
    }

    func speak(_ text: String, language: String = "it-IT") {
        guard !text.isEmpty else { return }
        synthesizer.stop()
        let utterance = AVSpeechUtterance(string: text)
        if let voice = AVSpeechSynthesisVoice(language: language) {
            utterance.voice = voice
        } else if let fallback = AVSpeechSynthesisVoice(language: "it-IT") {
            utterance.voice = fallback
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func speakItalian(_ text: String) {
        speak(text, language: "it-IT")
    }

    func speakGerman(_ text: String) {
        speak(text, language: "de-DE")
    }

    func stop() {
        synthesizer.stop()
        isSpeaking = false
    }

    nonisolated func synthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
