import SwiftUI

struct VocabularyView: View {
    @EnvironmentObject private var store: LearningStore

    @State private var searchText = ""
    @State private var selectedCategory: VocabularyCategory?
    @State private var favoritesOnly = false

    private var filteredItems: [VocabularyItem] {
        ItalianContent.vocabulary.filter { item in
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory
            let matchesFavorite = !favoritesOnly || store.isFavorite(item.id)
            let matchesSearch = searchText.isEmpty
                || item.italian.localizedCaseInsensitiveContains(searchText)
                || item.german.localizedCaseInsensitiveContains(searchText)
                || item.pronunciation.localizedCaseInsensitiveContains(searchText)

            return matchesCategory && matchesFavorite && matchesSearch
        }
    }

    private var groups: [VocabularyGroup] {
        ItalianContent.groups(from: filteredItems)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop()

                VStack(spacing: 0) {
                    filterBar

                    if filteredItems.isEmpty {
                        ContentUnavailableView(
                            favoritesOnly ? "Noch keine Favoriten" : "Nichts gefunden",
                            systemImage: favoritesOnly ? "heart" : "magnifyingglass",
                            description: Text(
                                favoritesOnly
                                ? "Markiere Wörter mit einem Herz, um sie hier zu sammeln."
                                : "Probiere einen anderen Suchbegriff oder Filter."
                            )
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 18, pinnedViews: [.sectionHeaders]) {
                                ForEach(groups) { group in
                                    Section {
                                        VStack(spacing: 9) {
                                            ForEach(group.items) { item in
                                                NavigationLink {
                                                    VocabularyDetailView(item: item)
                                                } label: {
                                                    VocabularyRow(
                                                        item: item,
                                                        isLearned: store.isLearned(item.id),
                                                        isFavorite: store.isFavorite(item.id)
                                                    )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    } header: {
                                        HStack {
                                            Text(group.title)
                                                .font(.headline.bold())
                                            Spacer()
                                            Text("\(group.items.count)")
                                                .font(.caption.monospacedDigit().weight(.bold))
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, 8)
                                        .background(.ultraThinMaterial)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationTitle("Wörter & Sätze")
            .searchable(text: $searchText, prompt: "Italienisch oder Deutsch")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                            favoritesOnly.toggle()
                        }
                    } label: {
                        Image(systemName: favoritesOnly ? "heart.fill" : "heart")
                            .foregroundStyle(favoritesOnly ? ItalianTheme.tomato : .primary)
                    }
                    .accessibilityLabel(favoritesOnly ? "Alle Wörter anzeigen" : "Nur Favoriten anzeigen")
                }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(nil, title: "Alle", icon: "square.grid.2x2.fill")

                ForEach(VocabularyCategory.allCases) { category in
                    categoryChip(category, title: category.title, icon: category.icon)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private func categoryChip(
        _ category: VocabularyCategory?,
        title: String,
        icon: String
    ) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                selectedCategory = category
            }
        } label: {
            Label(title, systemImage: icon)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .foregroundStyle(isSelected ? .white : ItalianTheme.forest)
                .background(isSelected ? ItalianTheme.forest : ItalianTheme.sage.opacity(0.7))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct VocabularyRow: View {
    let item: VocabularyItem
    let isLearned: Bool
    let isFavorite: Bool

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: item.category.icon)
                .font(.subheadline.bold())
                .foregroundStyle(ItalianTheme.forest)
                .frame(width: 39, height: 39)
                .background(ItalianTheme.sage.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.italian)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(item.german)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            VStack(spacing: 5) {
                if isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(ItalianTheme.tomato)
                }
                if isLearned {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ItalianTheme.leaf)
                }
                if !isFavorite && !isLearned {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
            }
            .font(.caption)
        }
        .padding(13)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct VocabularyDetailView: View {
    @EnvironmentObject private var store: LearningStore
    let item: VocabularyItem

    @State private var pulse = false

    var body: some View {
        ZStack {
            AppBackdrop()

            ScrollView {
                VStack(spacing: 20) {
                    wordCard
                    actionButtons
                    learningTip
                }
                .padding(18)
            }
        }
        .navigationTitle(item.category.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.toggleFavorite(item.id)
                } label: {
                    Image(systemName: store.isFavorite(item.id) ? "heart.fill" : "heart")
                        .foregroundStyle(ItalianTheme.tomato)
                }
                .accessibilityLabel("Favorit umschalten")
            }
        }
    }

    private var wordCard: some View {
        VStack(spacing: 21) {
            Label(item.section, systemImage: item.category.icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(ItalianTheme.forest)

            Spacer(minLength: 5)

            Text(item.italian)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.62)

            Text(item.pronunciation)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ItalianTheme.leaf)
                .multilineTextAlignment(.center)

            Divider()
                .frame(width: 90)

            Text(item.german)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer(minLength: 5)

            Button {
                SpeechManager.shared.speak(item.italian)
                Haptics.light()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.5)) {
                    pulse.toggle()
                }
            } label: {
                Label("Italienisch anhören", systemImage: "speaker.wave.2.fill")
                    .font(.headline.bold())
                    .padding(.horizontal, 17)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(ItalianTheme.forest)
            .scaleEffect(pulse ? 1.04 : 1)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 410)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(ItalianTheme.leaf.opacity(0.25), lineWidth: 1.5)
        }
        .shadow(color: ItalianTheme.forest.opacity(0.14), radius: 24, y: 12)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                store.toggleFavorite(item.id)
            } label: {
                Label(
                    store.isFavorite(item.id) ? "Favorit" : "Merken",
                    systemImage: store.isFavorite(item.id) ? "heart.fill" : "heart"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)
            .tint(ItalianTheme.tomato)

            Button {
                store.toggleLearned(item.id)
            } label: {
                Label(
                    store.isLearned(item.id) ? "Gelernt" : "Kann ich",
                    systemImage: store.isLearned(item.id) ? "checkmark.circle.fill" : "checkmark.circle"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
            }
            .buttonStyle(.borderedProminent)
            .tint(ItalianTheme.leaf)
        }
        .font(.subheadline.bold())
    }

    private var learningTip: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "waveform.and.mic")
                .font(.title3)
                .foregroundStyle(ItalianTheme.gold)

            VStack(alignment: .leading, spacing: 5) {
                Text("Sprich es dreimal laut")
                    .font(.headline)
                Text("Erst langsam mit der Aussprachehilfe, dann zweimal im natürlichen Tempo.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .softCard()
    }
}

#Preview {
    VocabularyView()
        .environmentObject(LearningStore())
}
