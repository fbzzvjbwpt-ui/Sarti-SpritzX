//
//  ProgressDashboardView.swift
//  Sarti SpritzX
//
//  Created by Vibe Code on 12.09.26.
//

import SwiftUI
import SwiftData

struct ProgressDashboardView: View {
    @Environment(GamificationStore.self) private var game
    @State private var appear = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        streakHeader
                        statsRow
                        streakCalendar
                        badgeSection
                        categoryProgress
                    }
                    .padding()
                }
            }
            .navigationTitle("Fortschritt")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                game.refresh()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    appear = true
                }
            }
        }
    }

    private var streakHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.warmGold, .coral], startPoint: .top, endPoint: .bottom))
                    .frame(width: appear ? 120 : 0, height: appear ? 120 : 0)
                    .shadow(color: .coral.opacity(0.4), radius: 16, y: 8)
                    .rotationEffect(.degrees(appear ? 0 : 30))
                VStack(spacing: 0) {
                    Text("🔥")
                        .font(.system(size: 44))
                    Text("\(game.streakDays)")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("TAGE")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.white.opacity(0.9))
                        .tracking(2)
                }
            }
            Text("Lern-Streak")
                .font(.headline)
                .foregroundStyle(.ink)
            Text(game.streakDays >= 3 ? "Du bist heiß! Weiter so 🔥" : "Lerne jeden Tag, um deinen Streak aufzubauen.")
                .font(.caption)
                .foregroundStyle(.mutedInk)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .funCardBackground(Color.white)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatBadge(title: "Karten", value: game.totalCardsReviewed, icon: "rectangle.on.rectangle.angled", color: .lavender)
            StatBadge(title: "Richtig", value: game.totalCorrect, icon: "checkmark.circle.fill", color: .mintPop)
            StatBadge(title: "Gekonnt", value: game.knownCountAll(), icon: "star.fill", color: .warmGold)
            StatBadge(title: "Wiederholen", value: game.dueReviewItems().count, icon: "arrow.clockwise", color: .coral)
        }
    }

    private var streakCalendar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("📅 Diese Woche")
                .font(.headline)
            HStack(spacing: 6) {
                ForEach(lastSevenDayKeys(), id: \.self) { key in
                    let label = weekdayShort(from: key)
                    VStack(spacing: 4) {
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(.mutedInk)
                        Circle()
                            .fill(isToday(key) ? AnyShapeStyle(LinearGradient(colors: [.warmGold, .coral], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(Color.mintPop.opacity(0.5)))
                            .frame(width: 34, height: 34)
                            .overlay(
                                Text(String(key.suffix(2)))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.ink)
                            )
                            .scaleEffect(isToday(key) ? 1.08 : 1.0)
                    }
                }
            }
        }
        .funCardBackground(.white)
    }

    private func lastSevenDayKeys() -> [String] {
        let cal = Calendar.current
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let today = Date.now
        return (0..<7).reversed().map { delta in
            if let d = cal.date(byAdding: .day, value: -delta, to: today) {
                return f.string(from: d)
            }
            return f.string(from: today)
        }
    }

    private func isToday(_ key: String) -> Bool {
        key == game.todayKey()
    }

    private func weekdayShort(from key: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: key) else { return "" }
        let g = DateFormatter()
        g.locale = Locale(identifier: "de_DE")
        g.dateFormat = "EEEEE"
        return g.string(from: d)
    }

    private var badgeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎖️ Abzeichen")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(game.earnedBadges) { badge in
                    BadgeTile(badge: badge)
                }
            }
        }
        .funCardBackground(.white)
    }

    private var categoryProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Kategorien")
                .font(.headline)
            ForEach(ItalianData.shared.categories, id: \.self) { cat in
                let total = ItalianData.shared.vocab(in: cat).count
                let known = game.knownCount(for: cat)
                CategoryProgressRow(title: ItalianData.shared.categoryTitle(for: cat), known: known, total: total)
            }
        }
        .funCardBackground(.white)
    }
}

struct StatBadge: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text("\(value)")
                .font(.title2.weight(.heavy))
                .foregroundStyle(.ink)
            Text(title)
                .font(.caption)
                .foregroundStyle(.mutedInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color.opacity(0.12))
        )
    }
}

struct BadgeTile: View {
    let badge: GamificationStore.Badge
    @State private var pop = false

    var body: some View {
        VStack(spacing: 6) {
            Text(badge.kind.emoji)
                .font(.system(size: 32))
                .opacity(badge.unlocked ? 1 : 0.25)
                .grayscale(badge.unlocked ? 0 : 1)
                .scaleEffect(badge.unlocked && pop ? 1.1 : 1)
                .onAppear {
                    if badge.unlocked {
                        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { pop = true }
                    }
                }
            Text(badge.kind.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(badge.unlocked ? .ink : .mutedInk)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 84)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(badge.unlocked ? LinearGradient(colors: [.warmGold.opacity(0.2), .coral.opacity(0.15)], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [Color.gray.opacity(0.08)], startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(badge.unlocked ? .warmGold.opacity(0.4) : .clear, lineWidth: 1)
        )
    }
}

struct CategoryProgressRow: View {
    let title: String
    let known: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.ink)
                Spacer()
                Text("\(known)/\(total)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.mutedInk)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.mutedInk.opacity(0.15))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(colors: [.mintPop, .deepGreen], startPoint: .leading, endPoint: .trailing))
                        .frame(width: total > 0 ? geo.size.width * CGFloat(known) / CGFloat(total) : 0, height: 8)
                        .animation(.easeOut(duration: 0.6), value: known)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    ProgressDashboardView()
}
