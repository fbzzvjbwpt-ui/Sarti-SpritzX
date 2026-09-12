import SwiftUI

struct LessonsView: View {
    @EnvironmentObject private var store: LearningStore

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop()

                ScrollView {
                    LazyVStack(spacing: 14) {
                        pathHeader

                        ForEach(ItalianContent.lessons) { lesson in
                            NavigationLink {
                                LessonDetailView(lesson: lesson)
                            } label: {
                                LessonRow(
                                    lesson: lesson,
                                    isCompleted: store.isLessonCompleted(lesson.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle("Dein Lernweg")
        }
    }

    private var pathHeader: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(ItalianTheme.forest)
                Text("\(store.completedLessonIDs.count)")
                    .font(.title.bold())
                    .foregroundStyle(.white)
            }
            .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(store.completedLessonIDs.count) von \(ItalianContent.lessons.count) Lektionen")
                    .font(.headline.bold())
                Text("Vom ersten Ciao bis zum Familiengespräch")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .softCard()
    }
}

private struct LessonRow: View {
    let lesson: ItalianLesson
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .fill(ItalianTheme.lessonColor(lesson.id))

                Image(systemName: isCompleted ? "checkmark" : lesson.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 5) {
                Text("LEKTION \(lesson.id)")
                    .font(.caption2.weight(.heavy))
                    .tracking(1)
                    .foregroundStyle(ItalianTheme.lessonColor(lesson.id))

                Text(lesson.shortTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("\(lesson.phrases.count) Ausdrücke · \(lesson.notes.count) Erklärungen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(15)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    isCompleted ? ItalianTheme.leaf.opacity(0.45) : Color.white.opacity(0.36),
                    lineWidth: isCompleted ? 1.5 : 1
                )
        }
    }
}

struct LessonDetailView: View {
    @EnvironmentObject private var store: LearningStore
    let lesson: ItalianLesson

    @State private var showConfetti = false

    private var color: Color {
        ItalianTheme.lessonColor(lesson.id)
    }

    var body: some View {
        ZStack {
            AppBackdrop()

            ScrollView {
                LazyVStack(spacing: 20) {
                    lessonHeader
                    goalCard
                    phraseSection

                    if !lesson.notes.isEmpty {
                        noteSection
                    }

                    if !lesson.dialogue.isEmpty {
                        dialogueSection
                    }

                    ForEach(Array(lesson.memories.enumerated()), id: \.offset) { _, memory in
                        memoryCard(memory)
                    }

                    NavigationLink {
                        LessonQuizView(lesson: lesson)
                    } label: {
                        Label("Lektion testen", systemImage: "brain.head.profile.fill")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(color)

                    completionButton
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 34)
            }

            if showConfetti {
                ConfettiOverlay()
                    .zIndex(5)
            }
        }
        .navigationTitle(lesson.shortTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var lessonHeader: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [color, color.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.13))
                .frame(width: 150, height: 150)
                .offset(x: 235, y: -65)

            VStack(alignment: .leading, spacing: 13) {
                Image(systemName: lesson.icon)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 62, height: 62)
                    .background(.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))

                Text("LEKTION \(lesson.id)")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.75))

                Text(lesson.title)
                    .font(.system(size: 27, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(22)
        }
        .frame(minHeight: 260)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: color.opacity(0.25), radius: 20, y: 10)
    }

    private var goalCard: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: "scope")
                .font(.title3.bold())
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 5) {
                Text("Dein Ziel")
                    .font(.headline.bold())
                Text(lesson.goal)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .softCard()
    }

    private var phraseSection: some View {
        VStack(spacing: 13) {
            SectionHeading(
                "Sprechen",
                eyebrow: "Hören · Nachsprechen",
                trailing: "\(lesson.phrases.count)"
            )

            ForEach(lesson.phrases) { phrase in
                LessonPhraseCard(phrase: phrase, tint: color)
            }
        }
    }

    private var noteSection: some View {
        VStack(spacing: 13) {
            SectionHeading(
                "Muster verstehen",
                eyebrow: "Grammatik ohne Stress"
            )

            ForEach(lesson.notes) { note in
                LessonNoteCard(note: note, tint: color)
            }
        }
    }

    private var dialogueSection: some View {
        VStack(spacing: 13) {
            SectionHeading("Mini-Dialog", eyebrow: "So klingt es echt")

            VStack(spacing: 0) {
                ForEach(lesson.dialogue) { line in
                    HStack(alignment: .top, spacing: 12) {
                        Text(line.speaker)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(color)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top) {
                                Text(line.italian)
                                    .font(.subheadline.bold())

                                Spacer()

                                Button {
                                    SpeechManager.shared.speak(line.italian)
                                } label: {
                                    Image(systemName: "speaker.wave.2.fill")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(color)
                            }

                            Text(line.german)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 12)

                    if line.id != lesson.dialogue.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        }
    }

    private func memoryCard(_ memory: String) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: "lightbulb.max.fill")
                .font(.title3)
                .foregroundStyle(ItalianTheme.gold)

            Text(memory)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [ItalianTheme.forest, ItalianTheme.leaf],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
    }

    private var completionButton: some View {
        Button {
            let isNewCompletion = !store.isLessonCompleted(lesson.id)
            store.toggleLesson(lesson.id)

            if isNewCompletion {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                    showConfetti = false
                }
            }
        } label: {
            Label(
                store.isLessonCompleted(lesson.id) ? "Als erledigt markiert" : "Lektion abschließen",
                systemImage: store.isLessonCompleted(lesson.id) ? "checkmark.seal.fill" : "checkmark.seal"
            )
            .font(.headline.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
        }
        .buttonStyle(.bordered)
        .tint(store.isLessonCompleted(lesson.id) ? ItalianTheme.leaf : color)
    }
}

private struct LessonPhraseCard: View {
    let phrase: LessonPhrase
    let tint: Color

    @State private var isSpeaking = false

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            VStack(alignment: .leading, spacing: 6) {
                Text(phrase.italian)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(phrase.pronunciation)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)

                Text(phrase.german)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button {
                SpeechManager.shared.speak(phrase.italian)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                    isSpeaking.toggle()
                }
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.headline)
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.12))
                    .clipShape(Circle())
                    .scaleEffect(isSpeaking ? 1.12 : 1)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
    }
}

private struct LessonNoteCard: View {
    let note: LessonNote
    let tint: Color

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(note.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "text.book.closed.fill")
                    .foregroundStyle(tint)
                Text(note.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
        .tint(tint)
        .padding(16)
        .background(tint.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct LessonQuizView: View {
    let lesson: ItalianLesson

    private var questions: [QuizQuestion] {
        lesson.phrases.map { phrase in
            let alternatives = Set(lesson.phrases
                .filter { $0.id != phrase.id && $0.german != phrase.german }
                .map(\.german))
                .shuffled()
                .prefix(3)

            return QuizQuestion(
                wordID: -lesson.id,
                italian: phrase.italian,
                pronunciation: phrase.pronunciation,
                answers: ([phrase.german] + Array(alternatives)).shuffled(),
                correctAnswer: phrase.german
            )
        }
    }

    var body: some View {
        QuizEngineView(
            title: lesson.shortTitle,
            questions: Array(questions.shuffled().prefix(8)),
            mode: .translation
        )
    }
}

#Preview {
    NavigationStack {
        LessonsView()
            .environmentObject(LearningStore())
    }
}
