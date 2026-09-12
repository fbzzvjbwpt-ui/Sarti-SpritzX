//
//  Sarti_SpritzXApp.swift
//  Sarti SpritzX
//
//  Created by Tobias Thiele on 12.09.26.
//

import SwiftUI
import SwiftData

@main
struct Sarti_SpritzXApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ProgressRecord.self,
            QuizStat.self,
            DailyStreak.self,
            Favorite.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var gamification = GamificationStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(gamification)
                .onAppear {
                    gamification.attach(sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
