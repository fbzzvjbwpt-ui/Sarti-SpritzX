//
//  QuizView.swift
//  Sarti SpritzX
//
//  Created by Vibe Code on 12.09.26.
//

import SwiftUI

struct QuizView: View {
    @Environment(GamificationStore.self) private var game
    @State private var quiz: QuizSession?
    @State private var selectedAnswer: String? = nil
    @State private var timeRemaining: Double = 15
    @State private var timerActive = false
    @State private var showSetup = true
    @State private var reverseMode = false
    @State private var selectedCategory: String? = nil
    @State private var answeredCorrect = false
    @State private var pulse = false
    @State private var shakeAmount: CGFloat = 0
    @State private var showResult = false

    private let totalQuestions = 10
    private let questionTime: Double = 15

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                if showSetup {
                    setupView
                } else if showResult, let quiz {
                    resultView(quiz)
                } else if let quiz {
                    questionView(quiz)
                }
            }
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showSetup {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Abbrechen") {
                            stopQuiz()
                        }
                        .foregroundStyle(.pinkRed)
                    }
                }
            }
        }
    }

    // MARK: - Setup

    private var setupView: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("❓ Quiz")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.ink)
                    Text("\(totalQuestions) Fragen · 15 Sekunden pro Frage · maximal 100 Punkte")
                        .font(.subheadline)
                        .foregroundStyle(.mutedInk)
                }
                .funCardBackground(.white)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Richtung")
                        .font(.headline)
                    Picker("", selection: $reverseMode) {
                        Text("Italienisch → Deutsch").tag(false)
                        Text("Deutsch → Italienisch").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                .funCardBackground(.white)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Kategorie")
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            categoryPill("Alle", cat: nil)
                            ForEach(ItalianData.shared.categories, id: \.self) { cat in
                                categoryPill(ItalianData.shared.categoryTitle(for: cat), cat: cat)
                            }
                        }
                    }
                }
                .funCardBackground(.white)

                Button {
                    startQuiz()
                } label: {
                    Text("Quiz starten")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(LinearGradient(colors: [.lavender, .pinkRed], startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        .shadow(color: .lavender.opacity(0.4), radius: 10, y: 6)
                }
            }
            .padding()
        }
    }

    private func categoryPill(_ title: String, cat: String?) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = cat
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selectedCategory == cat ? .white : .ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(selectedCategory == cat ? AnyShapeStyle(LinearGradient(colors: [.lavender, .pinkRed], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(Color.white))
                )
                .overlay(Capsule().stroke(Color.mutedInk.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Question

    private func questionView(_ quiz: QuizSession) -> some View {
        let q = quiz.currentQuestion()
        return VStack(spacing: 20) {
            topBar(quiz)
            Spacer()
            questionCard(q)
            Spacer()
            answerGrid(q)
        }
        .padding()
        .onAppear {
            timeRemaining = questionTime
            timerActive = true
            runTimer(quiz)
        }
    }

    private func topBar(_ quiz: QuizSession) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("Frage \(quiz.currentIndex + 1) / \(quiz.questions.count)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Punkte: \(quiz.score)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.pinkRed)
            }
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.mutedInk.opacity(0.15))
                    .frame(height: 10)
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [.warmGold, .coral], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, min(1, timeRemaining / questionTime)) * UIScreen.main.bounds.width * 0.85), height: 10)
                    .animation(.linear(duration: 0.1), value: timeRemaining)
            }
        }
    }

    private func questionCard(_ q: QuizQuestion) -> some View {
        VStack(spacing: 14) {
            Text("WAS HEISST")
                .font(.caption.weight(.heavy))
                .foregroundStyle(.mutedInk)
                .tracking(2)
            Text(q.prompt)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.ink)
                .multilineTextAlignment(.center)
            if !q.hint.isEmpty {
                Text(q.hint)
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(.deepGreen)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white)
                .shadow(color: .coral.opacity(0.25), radius: 16, y: 8)
        )
        .scaleEffect(pulse ? 1.03 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .onDisappear { pulse = false }
    }

    private func answerGrid(_ q: QuizQuestion) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(q.options, id: \.self) { option in
                answerButton(option, correct: option == q.answer)
            }
        }
    }

    private func answerButton(_ option: String, correct: Bool) -> some View {
        let isSelected = selectedAnswer == option
        let reveal = selectedAnswer != nil
        return Button {
            answer(option, correct: correct)
        } label: {
            Text(option)
                .font(.headline)
                .foregroundStyle(reveal && correct ? .white : (reveal && isSelected && !correct ? .white : .ink))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(reveal && correct ? AnyShapeStyle(LinearGradient(colors: [.mintPop, .deepGreen], startPoint: .top, endPoint: .bottom)) :
                              (reveal && isSelected && !correct ? AnyShapeStyle(Color.pinkRed) : AnyShapeStyle(Color.white)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(reveal && correct ? .clear : Color.mutedInk.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: (reveal && correct) ? .deepGreen.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(selectedAnswer != nil)
        .scaleEffect(isSelected && reveal && !correct ? 0.95 : 1)
        .offset(x: (isSelected && reveal && !correct) ? shakeAmount : 0)
    }

    // MARK: - Result

    private func resultView(_ quiz: QuizSession) -> some View {
        let percent = quiz.total > 0 ? Double(quiz.score) / Double(quiz.total) : 0
        let perfect = quiz.score == quiz.total
        return VStack(spacing: 22) {
            ConfettiView()
            Text(perfect ? "🏆 Perfekt!" : "Quiz fertig!")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(.ink)
            VStack(spacing: 6) {
                Text("\(quiz.score) / \(quiz.total)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.pinkRed)
                Text("\(Int(percent * 100)) % richtig")
                    .font(.headline)
                    .foregroundStyle(.mutedInk)
            }
            Text(percent >= 0.8 ? "Bravissimo! 🇮🇹" : percent >= 0.5 ? " Gut gemacht! Weiter so 💪" : "Übung macht den Meister – nochmal probieren!")
                .font(.subheadline)
                .foregroundStyle(.deepGreen)
            Button("Nochmal") {
                startQuiz()
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(Capsule().fill(LinearGradient(colors: [.coral, .pinkRed], startPoint: .leading, endPoint: .trailing)))
            Button("Neues Quiz") {
                stopQuiz()
            }
            .foregroundStyle(.pinkRed)
        }
        .funCardBackground(.white)
        .padding(.horizontal, 24)
        .onAppear {
            game.registerQuiz(score: quiz.score, total: quiz.total, category: selectedCategory ?? "alle")
        }
    }

    // MARK: - Logic

    private func startQuiz() {
        let pool: [VocabItem]
        if let cat = selectedCategory {
            pool = ItalianData.shared.vocab(in: cat)
        } else {
            pool = ItalianData.shared.vocabulary
        }
        guard pool.count >= 4 else { return }
        let questions = (0..<totalQuestions).map { _ in makeQuestion(from: pool) }
        quiz = QuizSession(questions: questions)
        selectedAnswer = nil
        showSetup = false
        showResult = false
        timeRemaining = questionTime
        timerActive = true
    }

    private func makeQuestion(from pool: [VocabItem]) -> QuizQuestion {
        let correct = pool.randomElement()!
        let prompt = reverseMode ? correct.german : correct.italian
        let answer = reverseMode ? correct.italian : correct.german
        let hint = reverseMode ? "" : correct.pronunciation
        let distractors = Set(pool.filter { $0 != correct }.map { reverseMode ? $0.german : $0.italian })
            .filter { $0 != answer }
            .shuffled()
            .prefix(3)
        let options = ([answer] + distractors).shuffled()
        return QuizQuestion(prompt: prompt, answer: answer, options: Array(options), hint: hint)
    }

    private func answer(_ option: String, correct: Bool) {
        selectedAnswer = option
        answeredCorrect = correct
        timerActive = false
        if !correct {
            withAnimation(.default) { shakeAmount = -10 }
            withAnimation(.spring(repeatCount: 3)) { shakeAmount = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            nextQuestion()
        }
    }

    private func nextQuestion() {
        guard var quiz else { return }
        if answeredCorrect { quiz.score += 1 }
        quiz.currentIndex += 1
        self.quiz = quiz
        selectedAnswer = nil
        if quiz.currentIndex >= quiz.questions.count {
            showResult = true
        } else {
            timeRemaining = questionTime
            timerActive = true
            runTimer(quiz)
        }
    }

    private func runTimer(_ quiz: QuizSession) {
        guard timerActive else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard self.timerActive else { return }
            self.timeRemaining -= 0.1
            if self.timeRemaining <= 0 {
                self.timeRemaining = 0
                self.timerActive = false
                self.selectedAnswer = "__timeout__"
                self.answeredCorrect = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.nextQuestion()
                }
            } else {
                self.runTimer(quiz)
            }
        }
    }

    private func stopQuiz() {
        timerActive = false
        quiz = nil
        selectedAnswer = nil
        showSetup = true
        showResult = false
    }
}

struct QuizQuestion: Identifiable {
    let id = UUID()
    let prompt: String
    let answer: String
    let options: [String]
    let hint: String
}

struct QuizSession {
    var questions: [QuizQuestion]
    var currentIndex = 0
    var score = 0
    var total: Int { questions.count }
    func currentQuestion() -> QuizQuestion { questions[currentIndex] }
}

#Preview {
    QuizView()
}
