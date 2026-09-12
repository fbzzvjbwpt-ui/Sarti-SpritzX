import Foundation

enum VocabularyCategory: String, CaseIterable, Identifiable, Codable {
    case essential
    case greetings
    case wellbeing
    case grammar
    case alphabet
    case restaurant
    case everyday
    case origin
    case travel
    case smallTalk
    case family
    case numbers

    var id: String { rawValue }

    var title: String {
        switch self {
        case .essential: "Wichtig"
        case .greetings: "Begrüßung"
        case .wellbeing: "Befinden"
        case .grammar: "Grammatik"
        case .alphabet: "Alphabet"
        case .restaurant: "Restaurant"
        case .everyday: "Alltag"
        case .origin: "Herkunft"
        case .travel: "Unterwegs"
        case .smallTalk: "Small Talk"
        case .family: "Familie"
        case .numbers: "Zahlen"
        }
    }

    var icon: String {
        switch self {
        case .essential: "star.fill"
        case .greetings: "hand.wave.fill"
        case .wellbeing: "heart.fill"
        case .grammar: "text.book.closed.fill"
        case .alphabet: "character.book.closed.fill"
        case .restaurant: "fork.knife"
        case .everyday: "sun.max.fill"
        case .origin: "globe.europe.africa.fill"
        case .travel: "car.fill"
        case .smallTalk: "bubble.left.and.bubble.right.fill"
        case .family: "figure.2.and.child.holdinghands"
        case .numbers: "number"
        }
    }
}

struct VocabularyItem: Identifiable, Hashable {
    let id: Int
    let category: VocabularyCategory
    let section: String
    let italian: String
    let pronunciation: String
    let german: String
}

struct LessonPhrase: Identifiable, Hashable {
    let id: String
    let italian: String
    let pronunciation: String
    let german: String
}

struct LessonNote: Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
}

struct DialogueLine: Identifiable, Hashable {
    let id: String
    let speaker: String
    let italian: String
    let german: String
}

struct ItalianLesson: Identifiable, Hashable {
    let id: Int
    let shortTitle: String
    let title: String
    let goal: String
    let icon: String
    let phrases: [LessonPhrase]
    let notes: [LessonNote]
    let memories: [String]
    let dialogue: [DialogueLine]
}

struct QuizQuestion: Identifiable {
    let id = UUID()
    let wordID: Int
    let italian: String
    let pronunciation: String
    let answers: [String]
    let correctAnswer: String
}

struct VocabularyGroup: Identifiable {
    let title: String
    let items: [VocabularyItem]
    var id: String { title }
}
