import Foundation
import Combine

@MainActor
final class LearningStore: ObservableObject {
    @Published private(set) var completedLessonIDs: Set<Int> {
        didSet { saveSet(completedLessonIDs, key: Keys.completedLessons) }
    }

    @Published private(set) var learnedWordIDs: Set<Int> {
        didSet { saveSet(learnedWordIDs, key: Keys.learnedWords) }
    }

    @Published private(set) var favoriteWordIDs: Set<Int> {
        didSet { saveSet(favoriteWordIDs, key: Keys.favoriteWords) }
    }

    @Published private(set) var quizCorrect: Int {
        didSet { defaults.set(quizCorrect, forKey: Keys.quizCorrect) }
    }

    @Published private(set) var quizAnswered: Int {
        didSet { defaults.set(quizAnswered, forKey: Keys.quizAnswered) }
    }

    @Published private(set) var mistakeCounts: [Int: Int] {
        didSet { saveMistakes() }
    }

    @Published private(set) var activityByDay: [String: Int] {
        didSet { saveActivity() }
    }

    @Published var dailyGoal: Int {
        didSet { defaults.set(dailyGoal, forKey: Keys.dailyGoal) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let completedLessons = "completedLessonIDs"
        static let learnedWords = "learnedWordIDs"
        static let favoriteWords = "favoriteWordIDs"
        static let quizCorrect = "quizCorrect"
        static let quizAnswered = "quizAnswered"
        static let mistakeCounts = "mistakeCounts"
        static let activity = "activityByDay"
        static let dailyGoal = "dailyGoal"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        completedLessonIDs = Set(defaults.array(forKey: Keys.completedLessons) as? [Int] ?? [])
        learnedWordIDs = Set(defaults.array(forKey: Keys.learnedWords) as? [Int] ?? [])
        favoriteWordIDs = Set(defaults.array(forKey: Keys.favoriteWords) as? [Int] ?? [])
        quizCorrect = defaults.integer(forKey: Keys.quizCorrect)
        quizAnswered = defaults.integer(forKey: Keys.quizAnswered)

        if
            let data = defaults.data(forKey: Keys.mistakeCounts),
            let decoded = try? JSONDecoder().decode([Int: Int].self, from: data)
        {
            mistakeCounts = decoded
        } else {
            mistakeCounts = [:]
        }

        if
            let data = defaults.data(forKey: Keys.activity),
            let decoded = try? JSONDecoder().decode([String: Int].self, from: data)
        {
            activityByDay = decoded
        } else {
            activityByDay = [:]
        }

        let savedGoal = defaults.integer(forKey: Keys.dailyGoal)
        dailyGoal = savedGoal > 0 ? savedGoal : 10
    }

    var todayCount: Int {
        activityByDay[dayKey(for: Date()), default: 0]
    }

    var dailyProgress: Double {
        min(Double(todayCount) / Double(max(dailyGoal, 1)), 1)
    }

    var streak: Int {
        var calendar = Calendar.current
        calendar.timeZone = .current
        var cursor = Date()

        if activityCount(on: cursor) == 0,
           let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) {
            cursor = yesterday
        }

        var result = 0
        while activityCount(on: cursor) > 0 {
            result += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }
        return result
    }

    var accuracy: Int {
        guard quizAnswered > 0 else { return 0 }
        return Int((Double(quizCorrect) / Double(quizAnswered) * 100).rounded())
    }

    var xp: Int {
        learnedWordIDs.count * 5 + completedLessonIDs.count * 50 + quizCorrect * 10
    }

    var overallProgress: Double {
        let lessonPart = Double(completedLessonIDs.count) / Double(max(ItalianContent.lessons.count, 1))
        let wordPart = Double(learnedWordIDs.count) / Double(max(ItalianContent.vocabulary.count, 1))
        return min((lessonPart * 0.55) + (wordPart * 0.45), 1)
    }

    var mistakeWordIDs: Set<Int> {
        Set(mistakeCounts.compactMap { key, count in count > 0 ? key : nil })
    }

    func isLessonCompleted(_ id: Int) -> Bool {
        completedLessonIDs.contains(id)
    }

    func toggleLesson(_ id: Int) {
        if completedLessonIDs.contains(id) {
            completedLessonIDs.remove(id)
        } else {
            completedLessonIDs.insert(id)
            recordActivity(count: 3)
            Haptics.success()
        }
    }

    func isLearned(_ id: Int) -> Bool {
        learnedWordIDs.contains(id)
    }

    func markLearned(_ id: Int) {
        guard !learnedWordIDs.contains(id) else { return }
        learnedWordIDs.insert(id)
        recordActivity()
    }

    func toggleLearned(_ id: Int) {
        if learnedWordIDs.contains(id) {
            learnedWordIDs.remove(id)
        } else {
            learnedWordIDs.insert(id)
            recordActivity()
            Haptics.success()
        }
    }

    func isFavorite(_ id: Int) -> Bool {
        favoriteWordIDs.contains(id)
    }

    func toggleFavorite(_ id: Int) {
        if favoriteWordIDs.contains(id) {
            favoriteWordIDs.remove(id)
        } else {
            favoriteWordIDs.insert(id)
            Haptics.light()
        }
    }

    func recordQuiz(correct: Bool, wordID: Int) {
        quizAnswered += 1
        if correct {
            quizCorrect += 1
            if wordID > 0, let count = mistakeCounts[wordID], count > 0 {
                if count == 1 {
                    mistakeCounts.removeValue(forKey: wordID)
                } else {
                    mistakeCounts[wordID] = count - 1
                }
            }
            recordActivity()
            Haptics.success()
        } else {
            if wordID > 0 {
                mistakeCounts[wordID, default: 0] += 1
            }
            Haptics.error()
        }
    }

    func recordActivity(count: Int = 1) {
        let key = dayKey(for: Date())
        activityByDay[key, default: 0] += count
    }

    func activityCount(on date: Date) -> Int {
        activityByDay[dayKey(for: date), default: 0]
    }

    func resetProgress() {
        completedLessonIDs = []
        learnedWordIDs = []
        favoriteWordIDs = []
        quizCorrect = 0
        quizAnswered = 0
        mistakeCounts = [:]
        activityByDay = [:]
    }

    private func dayKey(for date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            parts.year ?? 0,
            parts.month ?? 0,
            parts.day ?? 0
        )
    }

    private func saveSet(_ values: Set<Int>, key: String) {
        defaults.set(Array(values).sorted(), forKey: key)
    }

    private func saveActivity() {
        guard let data = try? JSONEncoder().encode(activityByDay) else { return }
        defaults.set(data, forKey: Keys.activity)
    }

    private func saveMistakes() {
        guard let data = try? JSONEncoder().encode(mistakeCounts) else { return }
        defaults.set(data, forKey: Keys.mistakeCounts)
    }
}
