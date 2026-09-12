import SwiftUI

@main
struct Sarti_SpritzXApp: App {
    @StateObject private var learningStore = LearningStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(learningStore)
                .tint(ItalianTheme.forest)
        }
    }
}
