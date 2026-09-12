//
//  FlashCardsView.swift
//  Sarti SpritzX
//
//  Created by Vibe Code on 12.09.26.
//

import SwiftUI
import SwiftData

struct FlashCardsView: View {
    @Environment(GamificationStore.self) private var game
    @State private var selectedCategory: String? = nil
    @State private var deck: [VocabItem] = []
    @State private var index = 0
    @State private var showingDeck = false
    @State private var reverseMode = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                if showingDeck {
                    deckView
                } else {
                    setupView
                }
            }
            .navigationTitle("Karteikarten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    toggleReverseButton
                }
            }
        }
    }

    private var toggleReverseButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                reverseMode.toggle()
            }
        } label: {
            Image(systemName: reverseMode ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right.circle")
                .font(.title3)
                .foregroundStyle(.pinkRed)
        }
    }

    private var setupView: some View {
        ScrollView {
            VStack(spacing: 18) {
                headerCard
                categoryGrid
                startButton
            }
            .padding()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🃏 Karteikarten")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.ink)
            Text("Wische nach rechts, wenn du es wusstest – nach links zum Wiederholen. Tippe zum Umdrehen.")
                .font(.subheadline)
                .foregroundStyle(.mutedInk)
            HStack {
                Label(reverseMode ? "DE → IT" : "IT → DE", systemImage: "repeat")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.pinkRed)
                Spacer()
                Text("\(deck.count > 0 ? deck.count : ItalianData.shared.vocabulary.count) Karten bereit")
                    .font(.caption)
                    .foregroundStyle(.mutedInk)
            }
        }
        .funCardBackground(.white)
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(ItalianData.shared.categories, id: \.self) { cat in
                CategoryChip(
                    title: ItalianData.shared.categoryTitle(for: cat),
                    count: ItalianData.shared.vocab(in: cat).count,
                    selected: selectedCategory == cat
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedCategory = (selectedCategory == cat) ? nil : cat
                    }
                }
            }
        }
    }

    private var startButton: some View {
        Button {
            startDeck()
        } label: {
            Text("Lernen starten")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(colors: [.coral, .pinkRed], startPoint: .leading, endPoint: .trailing))
                )
                .shadow(color: .pinkRed.opacity(0.35), radius: 10, y: 6)
        }
        .disabled(selectedCategory == nil)
        .opacity(selectedCategory == nil ? 0.5 : 1)
    }

    private var deckView: some View {
        VStack(spacing: 20) {
            progressRow
            Spacer()
            if index < deck.count {
                FlipCard(item: deck[index], reverseMode: reverseMode) { known in
                    game.registerCardReview(correct: known, vocabItalian: deck[index].italian)
                    advance()
                }
                .id(index)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                completionCard
            }
            Spacer()
            if index < deck.count {
                hintRow
            }
        }
        .padding()
    }

    private var progressRow: some View {
        HStack {
            Text("Karte \(min(index + 1, deck.count)) / \(deck.count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.mutedInk)
            Spacer()
            Button("Beenden") {
                withAnimation { showingDeck = false }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.pinkRed)
        }
        ProgressView(value: Double(index), total: Double(deck.count))
            .tint(.coral)
    }

    private var hintRow: some View {
        HStack(spacing: 30) {
            Label("Nochmal", systemImage: "arrow.uturn.backward")
                .labelStyle(.iconOnly)
                .font(.title2)
                .foregroundStyle(.pinkRed)
            Label("Gewusst", systemImage: "checkmark.circle.fill")
                .labelStyle(.iconOnly)
                .font(.title2)
                .foregroundStyle(.deepGreen)
        }
        .padding(.top, 8)
    }

    private var completionCard: some View {
        VStack(spacing: 18) {
            ConfettiView()
            Text("🎉 Fertig!")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
            Text("Du hast alle Karten durchgearbeitet.")
                .font(.subheadline)
                .foregroundStyle(.mutedInk)
            Button("Nochmal") {
                index = 0
                deck.shuffle()
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(Capsule().fill(.deepGreen))
            Button("Zurück") {
                showingDeck = false
            }
            .foregroundStyle(.pinkRed)
        }
        .funCardBackground(.white)
        .padding(.horizontal, 24)
    }

    private func startDeck() {
        if let cat = selectedCategory {
            deck = ItalianData.shared.vocab(in: cat).shuffled()
        } else {
            deck = ItalianData.shared.vocabulary.shuffled()
        }
        index = 0
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showingDeck = true
        }
    }

    private func advance() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            index += 1
        }
    }
}

struct CategoryChip: View {
    let title: String
    let count: Int
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(selected ? .white : .ink)
                    .multilineTextAlignment(.leading)
                Text("\(count) Vokabeln")
                    .font(.caption)
                    .foregroundStyle(selected ? .white.opacity(0.85) : .mutedInk)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? AnyShapeStyle(LinearGradient(colors: [.coral, .warmGold], startPoint: .topLeading, endPoint: .bottomTrailing)) : AnyShapeStyle(Color.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? .clear : Color.mutedInk.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: selected ? .coral.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(selected ? 1.04 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selected)
    }
}

// MARK: - FlipCard

struct FlipCard: View {
    let item: VocabItem
    let reverseMode: Bool
    let onAnswer: (Bool) -> Void

    @State private var flipped = false
    @State private var dragOffset: CGSize = .zero
    @State private var swipeFeedback: CGFloat = 0

    var body: some View {
        ZStack {
            frontFace
                .opacity(flipped ? 0 : 1)
                .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            backFace
                .opacity(flipped ? 1 : 0)
                .rotation3DEffect(.degrees(flipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .offset(x: dragOffset.width)
        .rotationEffect(.degrees(Double(dragOffset.width / 30)))
        .gesture(
            DragGesture()
                .onChanged { dragOffset = $0.translation }
                .onEnded { value in
                    if value.translation.width < -100 {
                        swipeFeedback = -1
                        triggerAnswer(false)
                    } else if value.translation.width > 100 {
                        swipeFeedback = 1
                        triggerAnswer(true)
                    } else {
                        withAnimation(.spring()) { dragOffset = .zero }
                    }
                }
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                flipped.toggle()
            }
        }
    }

    private var frontFace: some View {
        cardFace(primary: reverseMode ? item.german : item.italian,
                 secondary: reverseMode ? nil : item.pronunciation,
                 accent: .coral, label: reverseMode ? "Deutsch" : "Italiano")
    }

    private var backFace: some View {
        cardFace(primary: reverseMode ? item.italian : item.german,
                 secondary: reverseMode ? item.pronunciation : nil,
                 accent: .deepGreen, label: reverseMode ? "Italiano" : "Deutsch")
    }

    private func cardFace(primary: String, secondary: String?, accent: Color, label: String) -> some View {
        VStack(spacing: 18) {
            Text(label.uppercased())
                .font(.caption.weight(.heavy))
                .foregroundStyle(accent)
                .tracking(2)
            Spacer()
            Text(primary)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.ink)
                .multilineTextAlignment(.center)
            if let secondary, !secondary.isEmpty {
                Text(secondary)
                    .font(.subheadline)
                    .foregroundStyle(.mutedInk)
                    .italic()
            }
            Spacer()
            HStack(spacing: 18) {
                Button {
                    triggerAnswer(false)
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(LinearGradient(colors: [.pinkRed, .coral], startPoint: .top, endPoint: .bottom)))
                }
                Button {
                    triggerAnswer(true)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(LinearGradient(colors: [.mintPop, .deepGreen], startPoint: .top, endPoint: .bottom)))
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Color.white, Color.white.opacity(0.95)], startPoint: .top, endPoint: .bottom))
                .shadow(color: accent.opacity(0.3), radius: 20, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(accent.opacity(0.25), lineWidth: 2)
        )
    }

    private func triggerAnswer(_ known: Bool) {
        let direction: CGFloat = known ? 1 : -1
        withAnimation(.easeIn(duration: 0.25)) {
            dragOffset = CGSize(width: 400 * direction, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onAnswer(known)
            dragOffset = .zero
            flipped = false
        }
    }
}

// MARK: - Confetti

struct ConfettiView: View {
    @State private var animate = false
    private let colors: [Color] = [.coral, .warmGold, .mintPop, .lavender, .sunYellow, .pinkRed]

    var body: some View {
        ZStack {
            ForEach(0..<30, id: \.self) { i in
                Circle()
                    .fill(colors[i % colors.count])
                    .frame(width: 10, height: 10)
                    .offset(x: animate ? CGFloat.random(in: -160...160) : 0,
                            y: animate ? CGFloat.random(in: -220...220) : 0)
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? CGFloat.random(in: 0.3...1.2) : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.4)) {
                animate = true
            }
        }
    }
}

#Preview {
    FlashCardsView()
}
