import SwiftUI

enum QuizMode {
    case translation
    case listening

    var title: String {
        switch self {
        case .translation: "Schnellquiz"
        case .listening: "Hörtraining"
        }
    }
}

struct PracticeView: View {
    @EnvironmentObject private var store: LearningStore

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop()

                ScrollView {
                    LazyVStack(spacing: 18) {
                        practiceHero

                        SectionHeading("Wähle dein Training", eyebrow: "Kurz, aber regelmäßig")

                        NavigationLink {
                            FlashcardSessionView()
                        } label: {
                            PracticeModeCard(
                                icon: "rectangle.on.rectangle.angled",
                                title: "Karteikarten",
                                subtitle: "Tippen zum Umdrehen, wischen zum Bewerten",
                                detail: "20 Karten",
                                color: ItalianTheme.leaf
                            )
                        }

                        NavigationLink {
                            QuizSessionView(mode: .translation)
                        } label: {
                            PracticeModeCard(
                                icon: "bolt.fill",
                                title: "Schnellquiz",
                                subtitle: "Finde die richtige deutsche Bedeutung",
                                detail: "10 Fragen",
                                color: ItalianTheme.tomato
                            )
                        }

                        NavigationLink {
                            QuizSessionView(mode: .listening)
                        } label: {
                            PracticeModeCard(
                                icon: "ear.fill",
                                title: "Hörtraining",
                                subtitle: "Hören statt lesen – wie im echten Gespräch",
                                detail: "10 Fragen",
                                color: Color(red: 0.20, green: 0.47, blue: 0.72)
                            )
                        }

                        NavigationLink {
                            TravelRouletteView()
                        } label: {
                            PracticeModeCard(
                                icon: "airplane.departure",
                                title: "Reise-Roulette",
                                subtitle: "Ein überraschender Satz für unterwegs",
                                detail: "Sofort",
                                color: ItalianTheme.gold
                            )
                        }

                        NavigationLink {
                            MistakeTrainerView()
                        } label: {
                            PracticeModeCard(
                                icon: "scope",
                                title: "Fehlertrainer",
                                subtitle: store.mistakeWordIDs.isEmpty
                                    ? "Füllt sich automatisch nach deinen Quizrunden"
                                    : "Übe gezielt deine kniffligen Wörter",
                                detail: store.mistakeWordIDs.isEmpty
                                    ? "Bereit"
                                    : "\(store.mistakeWordIDs.count) offen",
                                color: Color(red: 0.55, green: 0.34, blue: 0.65)
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle("Üben")
        }
    }

    private var practiceHero: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(ItalianTheme.tomato.opacity(0.14))
                    .frame(width: 76, height: 76)

                Image(systemName: "flame.fill")
                    .font(.system(size: 31, weight: .bold))
                    .foregroundStyle(ItalianTheme.tomato)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(store.streak == 1 ? "1 Tag in Folge" : "\(store.streak) Tage in Folge")
                    .font(.title3.bold())
                Text("\(store.todayCount) von \(store.dailyGoal) Tagespunkten")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .softCard()
    }
}

private struct PracticeModeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 7) {
                Text(detail)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(color.opacity(0.12))
                    .clipShape(Capsule())

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(15)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.38), lineWidth: 1)
        }
    }
}

struct FlashcardSessionView: View {
    @EnvironmentObject private var store: LearningStore

    @State private var cards: [VocabularyItem] = []
    @State private var currentIndex = 0
    @State private var isRevealed = false
    @State private var cardOffset: CGSize = .zero
    @State private var isTransitioning = false
    @State private var knownCount = 0
    @GestureState private var dragTranslation: CGSize = .zero

    private var currentCard: VocabularyItem? {
        guard cards.indices.contains(currentIndex) else { return nil }
        return cards[currentIndex]
    }

    var body: some View {
        ZStack {
            AppBackdrop()

            if let card = currentCard {
                VStack(spacing: 22) {
                    progressHeader

                    Spacer(minLength: 2)

                    FlipCard(item: card, isRevealed: $isRevealed)
                        .offset(
                            x: cardOffset.width + dragTranslation.width,
                            y: cardOffset.height + dragTranslation.height * 0.25
                        )
                        .rotationEffect(.degrees(Double(cardOffset.width + dragTranslation.width) / 24))
                        .gesture(
                            DragGesture()
                                .updating($dragTranslation) { value, state, _ in
                                    state = value.translation
                                }
                                .onEnded { value in
                                    if value.translation.width > 90 {
                                        moveToNext(known: true)
                                    } else if value.translation.width < -90 {
                                        moveToNext(known: false)
                                    }
                                }
                        )

                    HStack(spacing: 14) {
                        Button {
                            moveToNext(known: false)
                        } label: {
                            Label("Noch mal", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                        .tint(ItalianTheme.tomato)

                        Button {
                            moveToNext(known: true)
                        } label: {
                            Label("Gewusst", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(ItalianTheme.leaf)
                    }

                    Text("Nach links: noch mal · Nach rechts: gewusst")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(18)
            } else if !cards.isEmpty {
                SessionCompleteView(
                    icon: "rectangle.stack.fill",
                    title: "Ottimo!",
                    message: "Du kanntest \(knownCount) von \(cards.count) Karten.",
                    actionTitle: "Noch eine Runde",
                    action: restart
                )
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Karteikarten")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if cards.isEmpty {
                cards = makeDeck()
            }
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 9) {
            HStack {
                Text("Karte \(currentIndex + 1) von \(cards.count)")
                    .font(.subheadline.bold())
                Spacer()
                Label("\(knownCount)", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(ItalianTheme.leaf)
            }

            GeometryReader { proxy in
                Capsule()
                    .fill(Color.secondary.opacity(0.14))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(ItalianTheme.leaf)
                            .frame(
                                width: proxy.size.width
                                    * CGFloat(currentIndex)
                                    / CGFloat(max(cards.count, 1))
                            )
                    }
            }
            .frame(height: 8)
        }
    }

    private func moveToNext(known: Bool) {
        guard !isTransitioning, let card = currentCard else { return }
        isTransitioning = true

        if known {
            knownCount += 1
            store.markLearned(card.id)
            Haptics.success()
        } else {
            Haptics.light()
        }

        withAnimation(.easeIn(duration: 0.22)) {
            cardOffset = CGSize(width: known ? 520 : -520, height: 12)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            currentIndex += 1
            isRevealed = false
            cardOffset = .zero
            isTransitioning = false
        }
    }

    private func restart() {
        cards = makeDeck()
        currentIndex = 0
        knownCount = 0
        isRevealed = false
        cardOffset = .zero
    }

    private func makeDeck() -> [VocabularyItem] {
        let newWords = ItalianContent.vocabulary
            .filter { !store.isLearned($0.id) }
            .shuffled()
        let reviewWords = ItalianContent.vocabulary
            .filter { store.isLearned($0.id) }
            .shuffled()

        return Array((newWords + reviewWords).prefix(20))
    }
}

private struct FlipCard: View {
    let item: VocabularyItem
    @Binding var isRevealed: Bool

    var body: some View {
        ZStack {
            cardFront
                .opacity(isRevealed ? 0 : 1)

            cardBack
                .opacity(isRevealed ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(
            .degrees(isRevealed ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.55
        )
        .animation(.spring(response: 0.55, dampingFraction: 0.72), value: isRevealed)
        .onTapGesture {
            Haptics.light()
            isRevealed.toggle()
        }
        .accessibilityAction(named: "Karte umdrehen") {
            isRevealed.toggle()
        }
    }

    private var cardFront: some View {
        VStack(spacing: 22) {
            HStack {
                Label(item.category.title, systemImage: item.category.icon)
                    .font(.caption.bold())
                    .foregroundStyle(ItalianTheme.leaf)
                Spacer()
                Text("ITALIANO")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.italian)
                .font(.system(size: 31, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.65)

            Text(item.pronunciation)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ItalianTheme.leaf)
                .multilineTextAlignment(.center)

            Button {
                SpeechManager.shared.speak(item.italian)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(ItalianTheme.forest)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Label("Tippen zum Umdrehen", systemImage: "hand.tap.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(23)
        .frame(maxWidth: .infinity)
        .frame(height: 390)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 31, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 31, style: .continuous)
                .stroke(ItalianTheme.leaf.opacity(0.25), lineWidth: 1.5)
        }
        .shadow(color: ItalianTheme.forest.opacity(0.16), radius: 24, y: 12)
    }

    private var cardBack: some View {
        VStack(spacing: 22) {
            HStack {
                Label("Bedeutung", systemImage: "lightbulb.fill")
                    .font(.caption.bold())
                    .foregroundStyle(ItalianTheme.tomato)
                Spacer()
                Text("DEUTSCH")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.german)
                .font(.system(size: 27, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.65)

            Divider()
                .frame(width: 80)

            Text(item.italian)
                .font(.headline)
                .foregroundStyle(ItalianTheme.forest)
                .multilineTextAlignment(.center)

            Spacer()

            Label("Tippen für Italienisch", systemImage: "arrow.triangle.2.circlepath")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(23)
        .frame(maxWidth: .infinity)
        .frame(height: 390)
        .background(ItalianTheme.cream)
        .foregroundStyle(ItalianTheme.ink)
        .clipShape(RoundedRectangle(cornerRadius: 31, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 31, style: .continuous)
                .stroke(ItalianTheme.tomato.opacity(0.25), lineWidth: 1.5)
        }
        .shadow(color: ItalianTheme.tomato.opacity(0.14), radius: 24, y: 12)
    }
}

struct QuizSessionView: View {
    let mode: QuizMode

    var body: some View {
        QuizEngineView(
            title: mode.title,
            questions: ItalianContent.makeQuiz(limit: 10),
            mode: mode
        )
    }
}

struct QuizEngineView: View {
    @EnvironmentObject private var store: LearningStore

    let title: String
    let mode: QuizMode
    private let seedQuestions: [QuizQuestion]

    @State private var questions: [QuizQuestion]
    @State private var currentIndex = 0
    @State private var selectedAnswer: String?
    @State private var score = 0
    @State private var isFinished = false

    init(title: String, questions: [QuizQuestion], mode: QuizMode) {
        self.title = title
        self.mode = mode
        seedQuestions = questions
        _questions = State(initialValue: questions)
    }

    private var currentQuestion: QuizQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var body: some View {
        ZStack {
            AppBackdrop()

            if isFinished {
                quizSummary
            } else if let question = currentQuestion {
                ScrollView {
                    VStack(spacing: 22) {
                        quizProgress
                        prompt(for: question)
                        answerOptions(for: question)
                    }
                    .padding(18)
                }
            } else {
                ContentUnavailableView(
                    "Keine Fragen verfügbar",
                    systemImage: "questionmark.circle",
                    description: Text("Bitte versuche es gleich noch einmal.")
                )
            }

            if isFinished && score >= 7 {
                ConfettiOverlay()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if mode == .listening {
                speakCurrentQuestion()
            }
        }
    }

    private var quizProgress: some View {
        VStack(spacing: 9) {
            HStack {
                Text("Frage \(currentIndex + 1) von \(questions.count)")
                    .font(.subheadline.bold())
                Spacer()
                Label("\(score)", systemImage: "star.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(ItalianTheme.gold)
            }

            GeometryReader { proxy in
                Capsule()
                    .fill(Color.secondary.opacity(0.14))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(ItalianTheme.tomato)
                            .frame(
                                width: proxy.size.width
                                    * CGFloat(currentIndex + 1)
                                    / CGFloat(max(questions.count, 1))
                            )
                    }
            }
            .frame(height: 8)
        }
    }

    @ViewBuilder
    private func prompt(for question: QuizQuestion) -> some View {
        VStack(spacing: 18) {
            if mode == .translation {
                Text("Was bedeutet …?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(question.italian)
                    .font(.system(size: 31, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)

                Text(question.pronunciation)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ItalianTheme.leaf)
                    .multilineTextAlignment(.center)

                Button {
                    SpeechManager.shared.speak(question.italian)
                } label: {
                    Label("Anhören", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.bordered)
            } else {
                Text("Hör genau hin")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Button {
                    SpeechManager.shared.speak(question.italian)
                    Haptics.light()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [ItalianTheme.forest, ItalianTheme.leaf],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 116, height: 116)
                            .shadow(color: ItalianTheme.forest.opacity(0.25), radius: 18, y: 9)

                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 39, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)

                Text("Tippe auf den Lautsprecher, um den Satz noch einmal zu hören.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func answerOptions(for question: QuizQuestion) -> some View {
        VStack(spacing: 11) {
            ForEach(Array(question.answers.enumerated()), id: \.offset) { _, answer in
                Button {
                    select(answer, for: question)
                } label: {
                    HStack(spacing: 12) {
                        Text(answer)
                            .font(.subheadline.weight(.semibold))
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(optionForeground(answer, question: question))

                        Spacer()

                        if let selectedAnswer {
                            if answer == question.correctAnswer {
                                Image(systemName: "checkmark.circle.fill")
                            } else if answer == selectedAnswer {
                                Image(systemName: "xmark.circle.fill")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(optionBackground(answer, question: question))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(optionBorder(answer, question: question), lineWidth: 1.3)
                    }
                }
                .buttonStyle(.plain)
                .disabled(selectedAnswer != nil)
            }
        }
    }

    private var quizSummary: some View {
        SessionCompleteView(
            icon: score >= 7 ? "trophy.fill" : "arrow.up.heart.fill",
            title: score >= 7 ? "Bravissimo!" : "Weiter geht’s!",
            message: "\(score) von \(questions.count) Antworten waren richtig.",
            actionTitle: "Noch einmal",
            action: restartQuiz
        )
    }

    private func select(_ answer: String, for question: QuizQuestion) {
        guard selectedAnswer == nil else { return }
        selectedAnswer = answer
        let isCorrect = answer == question.correctAnswer

        if isCorrect {
            score += 1
        }
        store.recordQuiz(correct: isCorrect, wordID: question.wordID)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            if currentIndex + 1 >= questions.count {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                    isFinished = true
                }
            } else {
                currentIndex += 1
                selectedAnswer = nil
                if mode == .listening {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        speakCurrentQuestion()
                    }
                }
            }
        }
    }

    private func optionBackground(_ answer: String, question: QuizQuestion) -> Color {
        guard let selectedAnswer else {
            return Color(uiColor: .secondarySystemGroupedBackground)
        }

        if answer == question.correctAnswer {
            return ItalianTheme.leaf.opacity(0.18)
        }
        if answer == selectedAnswer {
            return ItalianTheme.tomato.opacity(0.16)
        }
        return Color(uiColor: .secondarySystemGroupedBackground).opacity(0.65)
    }

    private func optionBorder(_ answer: String, question: QuizQuestion) -> Color {
        guard let selectedAnswer else { return Color.secondary.opacity(0.12) }
        if answer == question.correctAnswer { return ItalianTheme.leaf }
        if answer == selectedAnswer { return ItalianTheme.tomato }
        return .clear
    }

    private func optionForeground(_ answer: String, question: QuizQuestion) -> Color {
        guard let selectedAnswer else { return .primary }
        if answer == question.correctAnswer { return ItalianTheme.forest }
        if answer == selectedAnswer { return ItalianTheme.tomato }
        return .secondary
    }

    private func speakCurrentQuestion() {
        guard let currentQuestion else { return }
        SpeechManager.shared.speak(currentQuestion.italian)
    }

    private func restartQuiz() {
        questions = seedQuestions.shuffled()
        currentIndex = 0
        selectedAnswer = nil
        score = 0
        isFinished = false

        if mode == .listening {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                speakCurrentQuestion()
            }
        }
    }
}

struct MistakeTrainerView: View {
    @EnvironmentObject private var store: LearningStore
    @State private var questions: [QuizQuestion] = []

    var body: some View {
        Group {
            if questions.isEmpty {
                ZStack {
                    AppBackdrop()

                    VStack(spacing: 18) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 58, weight: .bold))
                            .foregroundStyle(ItalianTheme.leaf)

                        Text("Noch keine Problemwörter")
                            .font(.title2.bold())

                        Text("Falsche Quizantworten landen automatisch hier. Richtige Wiederholungen bauen die Liste wieder ab.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                }
            } else {
                QuizEngineView(
                    title: "Fehlertrainer",
                    questions: questions,
                    mode: .translation
                )
            }
        }
        .navigationTitle("Fehlertrainer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if questions.isEmpty && !store.mistakeWordIDs.isEmpty {
                questions = ItalianContent.makeQuiz(
                    wordIDs: store.mistakeWordIDs,
                    limit: 12
                )
            }
        }
    }
}

private struct SessionCompleteView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: icon)
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(ItalianTheme.gold)
                .frame(width: 126, height: 126)
                .background(ItalianTheme.gold.opacity(0.14))
                .clipShape(Circle())
                .scaleEffect(isVisible ? 1 : 0.55)
                .rotationEffect(.degrees(isVisible ? 0 : -16))

            VStack(spacing: 7) {
                Text(title)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                Text(message)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: action) {
                Label(actionTitle, systemImage: "arrow.clockwise")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .buttonStyle(.borderedProminent)
            .tint(ItalianTheme.forest)
        }
        .padding(26)
        .softCard()
        .padding(20)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.58)) {
                isVisible = true
            }
        }
    }
}

struct TravelRouletteView: View {
    @EnvironmentObject private var store: LearningStore

    @State private var phrase = ItalianContent.featuredVocabulary.randomElement()
        ?? ItalianContent.vocabulary[0]
    @State private var spin = 0.0
    @State private var cardScale = 1.0

    var body: some View {
        ZStack {
            AppBackdrop()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    ItalianTheme.leaf,
                                    ItalianTheme.gold,
                                    ItalianTheme.tomato,
                                    ItalianTheme.leaf
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 9, dash: [7, 9])
                        )
                        .frame(width: 118, height: 118)
                        .rotationEffect(.degrees(spin))

                    Image(systemName: phrase.category.icon)
                        .font(.system(size: 39, weight: .bold))
                        .foregroundStyle(ItalianTheme.forest)
                }

                VStack(spacing: 13) {
                    Text(phrase.category.title.uppercased())
                        .font(.caption2.weight(.heavy))
                        .tracking(1.4)
                        .foregroundStyle(ItalianTheme.tomato)

                    Text(phrase.italian)
                        .font(.system(size: 31, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text(phrase.pronunciation)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ItalianTheme.leaf)
                        .multilineTextAlignment(.center)

                    Divider()
                        .frame(width: 90)

                    Text(phrase.german)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        SpeechManager.shared.speak(phrase.italian)
                        store.recordActivity()
                    } label: {
                        Label("Satz anhören", systemImage: "speaker.wave.2.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(ItalianTheme.forest)
                }
                .frame(maxWidth: .infinity)
                .softCard()
                .scaleEffect(cardScale)

                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        spin += 180
                        cardScale = 0.92
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        phrase = ItalianContent.featuredVocabulary.randomElement()
                            ?? ItalianContent.vocabulary[0]
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.62)) {
                            spin += 180
                            cardScale = 1
                        }
                        Haptics.light()
                    }
                } label: {
                    Label("Neuer Reisesatz", systemImage: "shuffle")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .buttonStyle(.borderedProminent)
                .tint(ItalianTheme.tomato)

                Spacer()
            }
            .padding(20)
        }
        .navigationTitle("Reise-Roulette")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PracticeView()
            .environmentObject(LearningStore())
    }
}
