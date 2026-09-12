import Charts
import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: LearningStore

    @State private var showSettings = false
    @State private var animateHero = false

    private var level: Int {
        max(1, (store.xp / 250) + 1)
    }

    private var levelProgress: Double {
        Double(store.xp % 250) / 250
    }

    private var achievements: [Achievement] {
        [
            Achievement(
                title: "Primi passi",
                subtitle: "Erste Lektion geschafft",
                icon: "shoeprints.fill",
                color: ItalianTheme.leaf,
                isUnlocked: !store.completedLessonIDs.isEmpty
            ),
            Achievement(
                title: "Auf Kurs",
                subtitle: "Drei Lektionen geschafft",
                icon: "map.fill",
                color: Color(red: 0.18, green: 0.48, blue: 0.66),
                isUnlocked: store.completedLessonIDs.count >= 3
            ),
            Achievement(
                title: "Cinque stelle",
                subtitle: "Alle fünf Lektionen geschafft",
                icon: "star.circle.fill",
                color: ItalianTheme.gold,
                isUnlocked: store.completedLessonIDs.count >= ItalianContent.lessons.count
            ),
            Achievement(
                title: "Paroliere",
                subtitle: "50 Wörter gelernt",
                icon: "character.book.closed.fill",
                color: ItalianTheme.tomato,
                isUnlocked: store.learnedWordIDs.count >= 50
            ),
            Achievement(
                title: "Vocabolario",
                subtitle: "100 Wörter gelernt",
                icon: "books.vertical.fill",
                color: Color(red: 0.55, green: 0.34, blue: 0.65),
                isUnlocked: store.learnedWordIDs.count >= 100
            ),
            Achievement(
                title: "Inarrestabile",
                subtitle: "Sieben Tage am Stück",
                icon: "flame.fill",
                color: ItalianTheme.coral,
                isUnlocked: store.streak >= 7
            ),
            Achievement(
                title: "Quasi perfetto",
                subtitle: "Mindestens 80 % im Quiz",
                icon: "brain.head.profile.fill",
                color: ItalianTheme.forest,
                isUnlocked: store.quizAnswered >= 10 && store.accuracy >= 80
            ),
            Achievement(
                title: "Tesori italiani",
                subtitle: "Zehn Favoriten gesammelt",
                icon: "heart.fill",
                color: Color.pink,
                isUnlocked: store.favoriteWordIDs.count >= 10
            )
        ]
    }

    private var unlockedCount: Int {
        achievements.filter(\.isUnlocked).count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop()

                ScrollView {
                    LazyVStack(spacing: 22) {
                        levelHero
                        statistics
                        weekCard
                        badges
                        nextMilestone
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle("Deine Erfolge")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Einstellungen")
                }
            }
            .sheet(isPresented: $showSettings) {
                LearningSettingsView()
                    .environmentObject(store)
            }
        }
    }

    private var levelHero: some View {
        ZStack {
            LinearGradient(
                colors: [ItalianTheme.forest, Color(red: 0.07, green: 0.23, blue: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(ItalianTheme.gold.opacity(0.22))
                .frame(width: 170, height: 170)
                .offset(x: animateHero ? 145 : 170, y: animateHero ? -75 : -45)

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 105, height: 105)
                .offset(x: animateHero ? -160 : -140, y: animateHero ? 95 : 75)

            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.15), lineWidth: 11)

                    Circle()
                        .trim(from: 0, to: CGFloat(max(0.015, levelProgress)))
                        .stroke(
                            AngularGradient(
                                colors: [ItalianTheme.gold.opacity(0.72), ItalianTheme.gold, .white],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 11, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8, dampingFraction: 0.78), value: levelProgress)

                    VStack(spacing: 0) {
                        Text("\(level)")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                        Text("LEVEL")
                            .font(.system(size: 8, weight: .heavy))
                            .tracking(0.8)
                    }
                    .foregroundStyle(.white)
                }
                .frame(width: 108, height: 108)

                VStack(alignment: .leading, spacing: 8) {
                    Text("IL TUO LIVELLO")
                        .font(.caption2.weight(.heavy))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.72))

                    Text("Avanti così!")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Noch \(250 - (store.xp % 250)) XP bis Level \(level + 1)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))
                }

                Spacer(minLength: 0)
            }
            .padding(22)
        }
        .frame(minHeight: 190)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: ItalianTheme.forest.opacity(0.28), radius: 22, y: 12)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                animateHero = true
            }
        }
    }

    private var statistics: some View {
        VStack(spacing: 13) {
            SectionHeading("Deine Zahlen", eyebrow: "Fortschritt")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 11) {
                StatPill(
                    icon: "sparkles",
                    value: "\(store.xp)",
                    label: "XP",
                    tint: ItalianTheme.gold
                )
                StatPill(
                    icon: "flame.fill",
                    value: "\(store.streak)",
                    label: "Tage Serie",
                    tint: ItalianTheme.tomato
                )
                StatPill(
                    icon: "checkmark.circle.fill",
                    value: "\(store.learnedWordIDs.count)",
                    label: "Wörter gelernt",
                    tint: ItalianTheme.leaf
                )
                StatPill(
                    icon: "scope",
                    value: store.quizAnswered == 0 ? "–" : "\(store.accuracy) %",
                    label: "Quizquote",
                    tint: Color(red: 0.18, green: 0.48, blue: 0.66)
                )
            }
        }
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeading("Letzte 7 Tage", eyebrow: "Dein Rhythmus")

            Chart(weekActivity) { day in
                BarMark(
                    x: .value("Tag", day.shortName),
                    y: .value("Aktivität", day.count)
                )
                .foregroundStyle(
                    day.isToday
                    ? ItalianTheme.tomato.gradient
                    : ItalianTheme.leaf.gradient
                )
                .cornerRadius(6)
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                }
            }
            .frame(height: 135)

            HStack {
                Label("Heute: \(store.todayCount)", systemImage: "sun.max.fill")
                Spacer()
                Text("Ziel: \(store.dailyGoal)")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .softCard()
    }

    private var badges: some View {
        VStack(spacing: 13) {
            SectionHeading(
                "Abzeichen",
                eyebrow: "Piccoli successi",
                trailing: "\(unlockedCount) / \(achievements.count)"
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(achievements) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
        }
    }

    private var nextMilestone: some View {
        let remainingWords = max(50 - (store.learnedWordIDs.count % 50), 1)

        return HStack(alignment: .top, spacing: 13) {
            Image(systemName: "flag.checkered")
                .font(.title3.bold())
                .foregroundStyle(ItalianTheme.tomato)

            VStack(alignment: .leading, spacing: 5) {
                Text("Nächster Meilenstein")
                    .font(.headline)
                Text("Noch \(remainingWords) Wörter bis zu deinem nächsten 50er-Schritt.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .softCard()
    }

    private var weekActivity: [ActivityDay] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EE"

        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else {
                return nil
            }

            return ActivityDay(
                date: date,
                shortName: String(formatter.string(from: date).prefix(2)),
                count: store.activityCount(on: date),
                isToday: calendar.isDateInToday(date)
            )
        }
    }
}

private struct ActivityDay: Identifiable {
    let date: Date
    let shortName: String
    let count: Int
    let isToday: Bool

    var id: Date { date }
}

private struct Achievement: Identifiable {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isUnlocked: Bool

    var id: String { title }
}

private struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(achievement.color.opacity(achievement.isUnlocked ? 0.16 : 0.07))

                Image(systemName: achievement.isUnlocked ? achievement.icon : "lock.fill")
                    .font(.title2.bold())
                    .foregroundStyle(achievement.isUnlocked ? achievement.color : Color.secondary.opacity(0.45))
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)

                Text(achievement.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        .padding(15)
        .background(
            achievement.isUnlocked
            ? achievement.color.opacity(0.09)
            : Color(uiColor: .secondarySystemGroupedBackground).opacity(0.7)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    achievement.isUnlocked ? achievement.color.opacity(0.25) : Color.secondary.opacity(0.08),
                    lineWidth: 1
                )
        }
        .saturation(achievement.isUnlocked ? 1 : 0)
    }
}

private struct LearningSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: LearningStore

    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Tagesziel", selection: $store.dailyGoal) {
                        Text("Entspannt · 5").tag(5)
                        Text("Regelmäßig · 10").tag(10)
                        Text("Motiviert · 15").tag(15)
                        Text("Intensiv · 25").tag(25)
                    }
                } header: {
                    Text("Lernrhythmus")
                } footer: {
                    Text("Ein Punkt entspricht einem Wort oder einer richtigen Quizantwort.")
                }

                Section("Inhalt") {
                    LabeledContent("Lektionen", value: "\(ItalianContent.lessons.count)")
                    LabeledContent("Wörter & Sätze", value: "\(ItalianContent.vocabulary.count)")
                    LabeledContent("Sprachausgabe", value: "Italienisch")
                }

                Section("Daten") {
                    Button("Lernfortschritt zurücksetzen", role: .destructive) {
                        showResetConfirmation = true
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Wirklich alles zurücksetzen?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Fortschritt löschen", role: .destructive) {
                    store.resetProgress()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Lektionen, Favoriten, Quizwerte und gelernte Wörter werden entfernt.")
            }
        }
    }
}

#Preview {
    AchievementsView()
        .environmentObject(LearningStore())
}
