//
//  SpeechManager.swift
//  Sarti SpritzX
//
//  Created by Vibe Code on 12.09.26.
//

import AVFoundation
import SwiftUI

@Observable
final class SpeechManager {
    static let shared = SpeechManager()

    private let synthesizer = AVSpeechSynthesizer()
    var isSpeaking = false

    private init() {
        configureSession()
    }

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Session-Konfiguration ist optional – App läuft auch ohne
        }
    }

    var isAvailable: Bool {
        true
    }

    func speak(_ text: String, language: String = "it-IT") {
        guard !text.isEmpty else { return }
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language) ?? AVSpeechSynthesisVoice(language: "it-IT")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        isSpeaking = true
        synthesizer.speak(utterance)
        // Reset state after a reasonable delay if no delegate
        DispatchQueue.main.asyncAfter(deadline: .now() + max(1.0, Double(text.count) * 0.08)) { [weak self] in
            self?.isSpeaking = false
        }
    }

    func speakItalian(_ text: String) {
        speak(text, language: "it-IT")
    }

    func speakGerman(_ text: String) {
        speak(text, language: "de-DE")
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stop()
        }
        isSpeaking = false
    }
}
