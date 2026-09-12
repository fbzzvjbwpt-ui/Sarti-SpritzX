//
//  VocabBrowseView.swift
//  Sarti SpritzX
//
//  Created by Vibe Code on 12.09.26.
//

import SwiftUI
import SwiftData

struct VocabBrowseView: View {
    @Environment(GamificationStore.self) private var game
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var favoritesOnly = false
    @State private var speakingKey: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        searchBar
                        filterRow
                        if filteredVocab.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(filteredVocab) { item in
                                    VocabRow(item: item, speakingKey: $speakingKey, game: game)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Wörterbuch")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.mutedInk)
            TextField("Italienisch oder Deutsch suchen", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.mutedInk)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        )
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterPill("Alle", cat: nil)
                filterPill("⭐ Favoriten", cat: nil, fav: true)
                ForEach(ItalianData.shared.categories, id: \.self) { cat in
                    filterPill(ItalianData.shared.categoryTitle(for: cat), cat: cat)
                }
            }
        }
    }

    private func filterPill(_ title: String, cat: String?, fav: Bool = false) -> some View {
        let active = (fav && favoritesOnly) || (!fav && !favoritesOnly && selectedCategory == cat)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if fav { favoritesOnly.toggle() } else { selectedCategory = cat }
                if fav { selectedCategory = nil }
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(active ? .white : .ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(active ? AnyShapeStyle(LinearGradient(colors: [.warmGold, .coral], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(Color.white))
                )
                .overlay(Capsule().stroke(Color.mutedInk.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var filteredVocab: [VocabItem] {
        var pool = ItalianData.shared.vocabulary
        if let cat = selectedCategory {
            pool = pool.filter { $0.category == cat }
        }
        if favoritesOnly {
            let keys = game.favoriteKeys()
            pool = pool.filter { keys.contains($0.italian) }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            pool = pool.filter {
                $0.italian.lowercased().contains(q) || $0.german.lowercased().contains(q) || $0.pronunciation.lowercased().contains(q)
            }
        }
        return pool
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.mutedInk)
            Text("Keine Vokabeln gefunden")
                .font(.headline)
                .foregroundStyle(.ink)
            Text("Ändere die Suche oder den Filter.")
                .font(.subheadline)
                .foregroundStyle(.mutedInk)
        }
        .padding(.top, 60)
    }
}

struct VocabRow: View {
    let item: VocabItem
    @Binding var speakingKey: String?
    let game: GamificationStore
    @State private var isFav = false
    @State private var pulse = false

    var body: some View {
        let speaking = speakingKey == item.italian
        return HStack(alignment: .top, spacing: 12) {
            Button {
                SpeechManager.shared.speakItalian(item.italian)
                speakingKey = item.italian
                withAnimation(.easeInOut(duration: 0.4)) { pulse = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { speakingKey = nil; pulse = false }
            } label: {
                Image(systemName: speaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                    .font(.title3)
                    .foregroundStyle(.pinkRed)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.pinkRed.opacity(0.12)))
                    .scaleEffect(pulse ? 1.15 : 1.0)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.italian)
                    .font(.headline)
                    .foregroundStyle(.ink)
                Text(item.pronunciation)
                    .font(.caption)
                    .foregroundStyle(.deepGreen)
                    .italic()
                Text(item.german)
                    .font(.subheadline)
                    .foregroundStyle(.mutedInk)
                HStack {
                    Text(item.categoryTitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(LinearGradient(colors: [.lavender, .pinkRed], startPoint: .leading, endPoint: .trailing)))
                    if game.isKnown(item) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.deepGreen)
                            .font(.caption)
                    }
                    let b = game.box(for: item)
                    if b > 0 {
                        Text("Stufe \(b)")
                            .font(.caption2)
                            .foregroundStyle(.warmGold)
                    }
                }
            }

            Spacer()

            Button {
                game.toggleFavorite(item)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    isFav.toggle()
                }
            } label: {
                Image(systemName: isFav ? "star.fill" : "star")
                    .foregroundStyle(isFav ? .warmGold : .mutedInk)
                    .scaleEffect(isFav ? 1.2 : 1.0)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
        .onAppear { isFav = game.isFavorite(item) }
    }
}

#Preview {
    VocabBrowseView()
}
