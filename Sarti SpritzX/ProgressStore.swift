//
//  ProgressStore.swift
//  Sarti SpritzX
//
//  Created by Vibe Code on 12.09.26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class ProgressRecord {
    var vocabItalian: String
    var timesShown: Int
    var timesCorrect: Int
    var lastSeen: Date
    var known: Bool
    var box: Int
    var nextReviewDate: Date

    init(vocabItalian: String, timesShown: Int = 0, timesCorrect: Int = 0, lastSeen: Date = .now, known: Bool = false, box: Int = 0, nextReviewDate: Date = .now) {
        self.vocabItalian = vocabItalian
        self.timesShown = timesShown
        self.timesCorrect = timesCorrect
        self.lastSeen = lastSeen
        self.known = known
        self.box = box
        self.nextReviewDate = nextReviewDate
    }
}

@Model
final class QuizStat {
    var date: Date
    var score: Int
    var total: Int
    var category: String

    init(date: Date = .now, score: Int, total: Int, category: String) {
        self.date = date
        self.score = score
        self.total = total
        self.category = category
    }
}

@Model
final class DailyStreak {
    var day: String
    var reviewedCount: Int

    init(day: String, reviewedCount: Int = 0) {
        self.day = day
        self.reviewedCount = reviewedCount
    }
}

@Model
final class Favorite {
    var vocabItalian: String
    var addedAt: Date

    init(vocabItalian: String, addedAt: Date = .now) {
        self.vocabItalian = vocabItalian
        self.addedAt = addedAt
    }
}

@Observable
final class GamificationStore {
    var context: ModelContext?

    var totalCardsReviewed: Int = 0
    var totalCorrect: Int = 0
    var streakDays: Int = 1
    var earnedBadges: [Badge] = []
    var lastActiveDay: String = ""

    enum BadgeKind: String, CaseIterable {
        case firstSteps, tenCards, fiftyCards, hundredCards
        case firstQuiz, perfectQuiz, streakThree, streakSeven, streakFourteen
        case categoryMaster, allCategories

        var title: String {
            switch self {
            case .firstSteps: "Erste Schritte"
            case .tenCards: "10 Karten"
            case .fiftyCards: "50 Karten"
            case .hundredCards: "100 Karten"
            case .firstQuiz: "Erstes Quiz"
            case .perfectQuiz: "Perfektes Quiz"
            case .streakThree: "3-Tage-Streak 🔥"
            case .streakSeven: "7-Tage-Streak 🔥"
            case .streakFourteen: "14-Tage-Streak 🔥"
            case .categoryMaster: "Kategorie-Meister"
            case .allCategories: "Alle Kategorien"
            }
        }

        var emoji: String {
            switch self {
            case .firstSteps: "👶"
            case .tenCards: "🃏"
            case .fiftyCards: "🎴"
            case .hundredCards: "🎯"
            case .firstQuiz: "📝"
            case .perfectQuiz: "🏆"
            case .streakThree: "🔥"
            case .streakSeven: "⚡"
            case .streakFourteen: "🌟"
            case .categoryMaster: "👑"
            case .allCategories: "🎖️"
            }
        }

        var condition: String {
            switch self {
            case .firstSteps: "Erste Karte gelernt"
            case .tenCards: "10 Karten wiederholt"
            case .fiftyCards: "50 Karten wiederholt"
            case .hundredCards: "100 Karten wiederholt"
            case .firstQuiz: "Erstes Quiz gespielt"
            case .perfectQuiz: "Quiz mit 100 % abgeschlossen"
            case .streakThree: "3 Tage in Folge gelernt"
            case .streakSeven: "7 Tage in Folge gelernt"
            case .streakFourteen: "14 Tage in Folge gelernt"
            case .categoryMaster: "Eine Kategorie vollständig gekonnt"
            case .allCategories: "Alle Kategorien einmal besucht"
            }
        }
    }

    struct Badge: Identifiable, Hashable {
        var id: String { kind.rawValue }
        let kind: BadgeKind
        var unlocked: Bool
    }

    init() {
        buildBadgeList()
    }

    func attach(_ context: ModelContext) {
        self.context = context
        refresh()
    }

    private func buildBadgeList() {
        earnedBadges = BadgeKind.allCases.map { Badge(kind: $0, unlocked: false) }
    }

    func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: .now)
    }

    func registerCardReview(correct: Bool, vocabItalian: String) {
        guard let context else { return }
        let fetch = FetchDescriptor<ProgressRecord>(predicate: #Predicate { $0.vocabItalian == vocabItalian })
        let existing = (try? context.fetch(fetch))?.first
        let now = Date.now
        if let rec = existing {
            rec.timesShown += 1
            rec.lastSeen = now
            if correct { rec.timesCorrect += 1 }
            rec.known = rec.timesCorrect >= 3
            rec.box = nextBox(current: rec.box, correct: correct)
            rec.nextReviewDate = nextReviewDate(for: rec.box)
        } else {
            let startBox = correct ? 1 : 0
            let rec = ProgressRecord(vocabItalian: vocabItalian, timesShown: 1, timesCorrect: correct ? 1 : 0, known: false, box: startBox, nextReviewDate: nextReviewDate(for: startBox))
            context.insert(rec)
        }
        try? context.save()
        totalCardsReviewed += 1
        if correct { totalCorrect += 1 }
        updateStreak()
        checkBadges()
    }

    func registerQuiz(score: Int, total: Int, category: String) {
        guard let context else { return }
        let stat = QuizStat(score: score, total: total, category: category)
        context.insert(stat)
        try? context.save()
        totalCorrect += score
        totalCardsReviewed += total
        updateStreak()
        checkBadges()
        if let idx = earnedBadges.firstIndex(where: { $0.kind == .firstQuiz && !$0.unlocked }) {
            earnedBadges[idx].unlocked = true
        }
        if score == total, total > 0 {
            if let idx = earnedBadges.firstIndex(where: { $0.kind == .perfectQuiz && !$0.unlocked }) {
                earnedBadges[idx].unlocked = true
            }
        }
    }

    private func updateStreak() {
        let today = todayKey()
        let cal = Calendar.current
        if lastActiveDay != today {
            if let last = dateFromString(lastActiveDay), cal.isDateInYesterday(last) {
                streakDays += 1
            } else if lastActiveDay.isEmpty {
                streakDays = 1
            } else if lastActiveDay != today {
                streakDays = 1
            }
            lastActiveDay = today
        }
        switch streakDays {
        case 3...:
            setBadge(.streakThree, unlocked: true)
        default: break
        }
        if streakDays >= 7 { setBadge(.streakSeven, unlocked: true) }
        if streakDays >= 14 { setBadge(.streakFourteen, unlocked: true) }
    }

    private func setBadge(_ kind: BadgeKind, unlocked: Bool) {
        if let idx = earnedBadges.firstIndex(where: { $0.kind == kind }) {
            earnedBadges[idx].unlocked = unlocked
        }
    }

    private func dateFromString(_ s: String) -> Date? {
        guard !s.isEmpty else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }

    func checkBadges() {
        if totalCardsReviewed >= 1 { setBadge(.firstSteps, unlocked: true) }
        if totalCardsReviewed >= 10 { setBadge(.tenCards, unlocked: true) }
        if totalCardsReviewed >= 50 { setBadge(.fiftyCards, unlocked: true) }
        if totalCardsReviewed >= 100 { setBadge(.hundredCards, unlocked: true) }
    }

    func refresh() {
        guard let context else { return }
        let cards = (try? context.fetch(FetchDescriptor<ProgressRecord>())) ?? []
        totalCardsReviewed = cards.reduce(0) { $0 + $1.timesShown }
        totalCorrect = cards.reduce(0) { $0 + $1.timesCorrect }
        let knownKeys = Set(cards.filter { $0.known }.map { $0.vocabItalian })
        let knownCategories = Set(knownKeys.compactMap { key in ItalianData.shared.vocabulary.first(where: { $0.italian == key })?.category })
        if knownCategories.count == ItalianData.shared.categories.count && !knownCategories.isEmpty {
            setBadge(.allCategories, unlocked: true)
        }
        for cat in knownCategories {
            let allInCat = ItalianData.shared.vocab(in: cat)
            let knownInCat = allInCat.filter { v in knownKeys.contains(v.italian) }
            if !allInCat.isEmpty && knownInCat.count == allInCat.count {
                setBadge(.categoryMaster, unlocked: true)
            }
        }
        checkBadges()
    }

    func knownCount(for category: String) -> Int {
        guard let context else { return 0 }
        let vocab = ItalianData.shared.vocab(in: category)
        let records = (try? context.fetch(FetchDescriptor<ProgressRecord>())) ?? []
        return vocab.filter { v in records.contains(where: { $0.vocabItalian == v.italian && $0.known }) }.count
    }

    func knownCountAll() -> Int {
        guard let context else { return 0 }
        let records = (try? context.fetch(FetchDescriptor<ProgressRecord>())) ?? []
        return records.filter { $0.known }.count
    }

    func isKnown(_ item: VocabItem) -> Bool {
        guard let context else { return false }
        let fetch = FetchDescriptor<ProgressRecord>(predicate: #Predicate { $0.vocabItalian == item.italian })
        return (try? context.fetch(fetch))?.first?.known ?? false
    }

    // MARK: - Spaced Repetition (Leitner-System)

    private func nextBox(current: Int, correct: Bool) -> Int {
        correct ? min(current + 1, 5) : 0
    }

    private func nextReviewDate(for box: Int) -> Date {
        let hours: TimeInterval
        switch box {
        case 0: hours = 1
        case 1: hours = 4
        case 2: hours = 24
        case 3: hours = 72
        case 4: hours = 168
        default: hours = 336
        }
        return Date.now + hours * 3600
    }

    func dueReviewItems() -> [VocabItem] {
        guard let context else { return [] }
        let now = Date.now
        let records = (try? context.fetch(FetchDescriptor<ProgressRecord>())) ?? []
        let dueKeys = Set(records.filter { $0.nextReviewDate <= now && !$0.known }.map { $0.vocabItalian })
        return ItalianData.shared.vocabulary.filter { dueKeys.contains($0.italian) }
    }

    func box(for item: VocabItem) -> Int {
        guard let context else { return 0 }
        let fetch = FetchDescriptor<ProgressRecord>(predicate: #Predicate { $0.vocabItalian == item.italian })
        return (try? context.fetch(fetch))?.first?.box ?? 0
    }

    // MARK: - Favoriten

    func toggleFavorite(_ item: VocabItem) {
        guard let context else { return }
        let fetch = FetchDescriptor<Favorite>(predicate: #Predicate { $0.vocabItalian == item.italian })
        if let existing = (try? context.fetch(fetch))?.first {
            context.delete(existing)
        } else {
            context.insert(Favorite(vocabItalian: item.italian))
        }
        try? context.save()
    }

    func isFavorite(_ item: VocabItem) -> Bool {
        guard let context else { return false }
        let fetch = FetchDescriptor<Favorite>(predicate: #Predicate { $0.vocabItalian == item.italian })
        return ((try? context.fetch(fetch))?.isEmpty) == false
    }

    func favoriteKeys() -> Set<String> {
        guard let context else { return [] }
        let favs = (try? context.fetch(FetchDescriptor<Favorite>())) ?? []
        return Set(favs.map { $0.vocabItalian })
    }

    func favoriteItems() -> [VocabItem] {
        let keys = favoriteKeys()
        return ItalianData.shared.vocabulary.filter { keys.contains($0.italian) }
    }

    // MARK: - Lernfortschritt (unbekannte Karten)

    func unknownItems() -> [VocabItem] {
        guard let context else { return ItalianData.shared.vocabulary }
        let knownKeys = Set((try? context.fetch(FetchDescriptor<ProgressRecord>()))?.filter { $0.known }.map { $0.vocabItalian } ?? [])
        return ItalianData.shared.vocabulary.filter { !knownKeys.contains($0.italian) }
    }
}
