//
//  ItalianData.swift
//  Sarti SpritzX
//
//  Created by Vibe Code on 12.09.26.
//

import Foundation
import SwiftUI

// MARK: - Vokabel-Modell

struct VocabItem: Identifiable, Hashable, Codable {
    var id: String { italian }
    let italian: String
    let german: String
    let pronunciation: String
    let category: String

    var categoryTitle: String {
        ItalianData.shared.categoryTitle(for: category)
    }
}

// MARK: - Lektions-Modell

struct LessonBlock: Codable, Hashable {
    enum Kind: String, Codable { case h3, h4, p, list, table, quote }
    let type: Kind
    var text: String?
    var ordered: Bool?
    var items: [String]?
    var rows: [[String]]?

    var displayText: String { text ?? "" }
}

struct Lesson: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let content: [LessonBlock]
}

// MARK: - DataLoader

final class ItalianData {
    static let shared = ItalianData()

    private(set) var vocabulary: [VocabItem] = []
    private(set) var lessons: [Lesson] = []
    private(set) var categoryTitles: [String: String] = [:]

    private init() {
        loadVocabulary()
        loadLessons()
    }

    var categories: [String] {
        categoryTitles.keys.sorted { (a, b) -> Bool in
            order(a) < order(b)
        }
    }

    private func order(_ cat: String) -> Int {
        [
            "phrasen": 0, "gruss": 1, "befinden": 2, "grammatik": 3,
            "alphabet": 4, "restaurant": 5, "alltag": 6, "herkunft": 7,
            "unterwegs": 8, "smalltalk": 9, "familie": 10, "zahlen": 11
        ][cat] ?? 99
    }

    func categoryTitle(for cat: String) -> String {
        categoryTitles[cat] ?? cat.capitalized
    }

    func vocab(in category: String) -> [VocabItem] {
        vocabulary.filter { $0.category == category }
    }

    private func loadVocabulary() {
        guard let url = Bundle.main.url(forResource: "vocabulary", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(VocabularyFile.self, from: data) else {
            return
        }
        categoryTitles = decoded.categories
        vocabulary = decoded.vocab
    }

    private func loadLessons() {
        guard let url = Bundle.main.url(forResource: "lessons", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Lesson].self, from: data) else {
            return
        }
        lessons = decoded
    }
}

private struct VocabularyFile: Codable {
    let categories: [String: String]
    let vocab: [VocabItem]
}
