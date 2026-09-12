//
//  RootTabView.swift
//  Sarti SpritzX
//
//  Created by Vibe Code on 12.09.26.
//

import SwiftUI

struct RootTabView: View {
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            FlashCardsView()
                .tabItem {
                    Label("Karten", systemImage: "rectangle.on.rectangle.angled")
                }
                .tag(0)

            QuizView()
                .tabItem {
                    Label("Quiz", systemImage: "questionmark.bubble.fill")
                }
                .tag(1)

            VocabBrowseView()
                .tabItem {
                    Label("Wörter", systemImage: "character.book.closed.fill")
                }
                .tag(2)

            LessonsView()
                .tabItem {
                    Label("Lektionen", systemImage: "book.fill")
                }
                .tag(3)

            ProgressDashboardView()
                .tabItem {
                    Label("Fortschritt", systemImage: "flame.fill")
                }
                .tag(4)
        }
        .tint(.pinkRed)
    }
}

#Preview {
    RootTabView()
}
