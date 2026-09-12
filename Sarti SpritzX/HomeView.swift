import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: LearningStore
    @State private var heroIsFloating = false

    private var nextLesson: ItalianLesson {
        ItalianContent.lessons.first { !store.isLessonCompleted($0.id) }
            ?? ItalianContent.lessons.last!
    }

    private var phraseOfTheDay: VocabularyItem {
        let phrases = ItalianContent.featuredVocabulary
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return phrases[day % phrases.count]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop()

                ScrollView {
                    LazyVStack(spacing: 22) {
                        hero
                        dailyGoal
                        continueLearning
                        quickPractice
                        dailyPhrase
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Ciao, Tobias!")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ItalianFlag()
                        .frame(width: 34, height: 23)
                }
            }
        }
    }

    private var hero: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [ItalianTheme.forest, ItalianTheme.leaf],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.10))
                .frame(width: 155, height: 155)
                .offset(x: heroIsFloating ? 34 : 50, y: heroIsFloating ? -55 : -36)

            Circle()
                .fill(ItalianTheme.gold.opacity(0.22))
                .frame(width: 92, height: 92)
                .offset(x: heroIsFloating ? -245 : -225, y: heroIsFloating ? 125 : 142)

            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("IL TUO VIAGGIO")
                        .font(.caption2.weight(.heavy))
                        .tracking(1.6)
                        .foregroundStyle(.white.opacity(0.75))

                    Text("Pronto per\nl’Italia?")
                        .font(.system(size: 33, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Label("\(store.xp) XP gesammelt", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.86))
                }

                Spacer(minLength: 4)

                ProgressRing(
                    progress: store.overallProgress,
                    size: 94,
                    lineWidth: 11,
                    tint: .white
                )
            }
            .padding(22)
        }
        .frame(minHeight: 205)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: ItalianTheme.forest.opacity(0.28), radius: 22, y: 12)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                heroIsFloating = true
            }
        }
    }

    private var dailyGoal: some View {
        VStack(spacing: 13) {
            HStack {
                Label("Dein Tagesziel", systemImage: "flame.fill")
                    .font(.headline.bold())
                    .foregroundStyle(ItalianTheme.tomato)

                Spacer()

                Text("\(store.todayCount) / \(store.dailyGoal)")
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(ItalianTheme.tomato.opacity(0.13))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [ItalianTheme.tomato, ItalianTheme.coral],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * CGFloat(store.dailyProgress))
                        .animation(.spring(response: 0.65, dampingFraction: 0.8), value: store.dailyProgress)
                }
            }
            .frame(height: 11)

            Text(store.dailyProgress >= 1
                 ? "Fantastico – Tagesziel geschafft!"
                 : "Noch \(max(store.dailyGoal - store.todayCount, 0)) kleine Schritte für heute.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .softCard()
    }

    private var continueLearning: some View {
        VStack(spacing: 13) {
            SectionHeading(
                "Weiterlernen",
                eyebrow: "Lektion \(nextLesson.id) von \(ItalianContent.lessons.count)"
            )

            NavigationLink {
                LessonDetailView(lesson: nextLesson)
            } label: {
                HStack(spacing: 15) {
                    Image(systemName: nextLesson.icon)
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(ItalianTheme.lessonColor(nextLesson.id))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(nextLesson.shortTitle)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(nextLesson.goal)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
                .padding(15)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var quickPractice: some View {
        VStack(spacing: 13) {
            SectionHeading("Schnell üben", eyebrow: "2 Minuten reichen")

            HStack(spacing: 12) {
                NavigationLink {
                    FlashcardSessionView()
                } label: {
                    quickTile(
                        icon: "rectangle.on.rectangle.angled",
                        title: "Karten",
                        subtitle: "Wischen & merken",
                        color: ItalianTheme.leaf
                    )
                }

                NavigationLink {
                    QuizSessionView(mode: .translation)
                } label: {
                    quickTile(
                        icon: "bolt.fill",
                        title: "Schnellquiz",
                        subtitle: "10 Fragen",
                        color: ItalianTheme.tomato
                    )
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func quickTile(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Image(systemName: icon)
                .font(.title2.bold())
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(color.opacity(0.11))
        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
    }

    private var dailyPhrase: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Satz des Tages", systemImage: "quote.bubble.fill")
                    .font(.headline.bold())
                    .foregroundStyle(ItalianTheme.forest)

                Spacer()

                Button {
                    store.toggleFavorite(phraseOfTheDay.id)
                } label: {
                    Image(systemName: store.isFavorite(phraseOfTheDay.id) ? "heart.fill" : "heart")
                        .foregroundStyle(ItalianTheme.tomato)
                }
                .buttonStyle(.plain)
            }

            Text(phraseOfTheDay.italian)
                .font(.title3.bold())

            Text(phraseOfTheDay.pronunciation)
                .font(.caption.weight(.medium))
                .foregroundStyle(ItalianTheme.leaf)

            Text(phraseOfTheDay.german)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                SpeechManager.shared.speak(phraseOfTheDay.italian)
                Haptics.light()
            } label: {
                Label("Anhören", systemImage: "speaker.wave.2.fill")
                    .font(.subheadline.bold())
            }
            .buttonStyle(.bordered)
            .tint(ItalianTheme.forest)
        }
        .softCard()
    }
}

#Preview {
    HomeView()
        .environmentObject(LearningStore())
}
