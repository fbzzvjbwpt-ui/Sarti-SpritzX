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

            LessonsView()
                .tabItem {
                    Label("Lektionen", systemImage: "book.fill")
                }
                .tag(2)

            ProgressDashboardView()
                .tabItem {
                    Label("Fortschritt", systemImage: "flame.fill")
                }
                .tag(3)
        }
        .tint(.pinkRed)
    }
}

#Preview {
    RootTabView()
}
