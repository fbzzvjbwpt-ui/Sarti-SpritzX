import SwiftUI

struct ContentView: View {
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            MainTabView()
                .opacity(isShowingSplash ? 0 : 1)

            if isShowingSplash {
                WelcomeSplashView()
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
                    .zIndex(2)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_450_000_000)
            withAnimation(.easeInOut(duration: 0.55)) {
                isShowingSplash = false
            }
        }
    }
}

private struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Heute", systemImage: "sun.max.fill")
                }

            LessonsView()
                .tabItem {
                    Label("Lernen", systemImage: "book.pages.fill")
                }

            PracticeView()
                .tabItem {
                    Label("Üben", systemImage: "sparkles")
                }

            VocabularyView()
                .tabItem {
                    Label("Wörter", systemImage: "character.book.closed.fill")
                }

            AchievementsView()
                .tabItem {
                    Label("Erfolge", systemImage: "trophy.fill")
                }
        }
    }
}

private struct WelcomeSplashView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [ItalianTheme.forest, Color(red: 0.06, green: 0.25, blue: 0.19)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(ItalianTheme.tomato.opacity(0.28))
                .frame(width: 250, height: 250)
                .blur(radius: 2)
                .offset(x: isAnimating ? 155 : 120, y: isAnimating ? -290 : -250)

            Circle()
                .fill(ItalianTheme.gold.opacity(0.20))
                .frame(width: 210, height: 210)
                .offset(x: isAnimating ? -150 : -115, y: isAnimating ? 320 : 280)

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.14))
                        .frame(width: 126, height: 126)
                        .scaleEffect(isAnimating ? 1.08 : 0.94)

                    ItalianFlag(cornerRadius: 10)
                        .frame(width: 78, height: 52)
                        .shadow(color: .black.opacity(0.20), radius: 12, y: 7)
                }

                VStack(spacing: 8) {
                    Text("Benvenuto, Tobias")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                    Text("Il mio italiano")
                        .font(.headline)
                        .tracking(1.5)
                        .opacity(0.78)
                }
                .foregroundStyle(.white)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LearningStore())
}
