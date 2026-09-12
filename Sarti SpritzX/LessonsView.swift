//
//  LessonsView.swift
//  Sarti SpritzX
//
//  Created by Vibe Code on 12.09.26.
//

import SwiftUI

struct LessonsView: View {
    @State private var selectedLesson: Lesson?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        headerCard
                        ForEach(ItalianData.shared.lessons) { lesson in
                            LessonRow(lesson: lesson)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        selectedLesson = lesson
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Lektionen")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedLesson) { lesson in
                LessonDetailView(lesson: lesson)
                    .presentationDetents([.large])
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📚 Lektionen")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.ink)
            Text("\(ItalianData.shared.lessons.count) Lektionen mit Notizen, Beispielen und Tabellen. Tippe eine Lektion an zum Lesen.")
                .font(.subheadline)
                .foregroundStyle(.mutedInk)
        }
        .funCardBackground(.white)
    }
}

struct LessonRow: View {
    let lesson: Lesson

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.warmGold, .coral], startPoint: .top, endPoint: .bottom))
                    .frame(width: 48, height: 48)
                Text("\(lessonIndex(lesson))")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(.headline)
                    .foregroundStyle(.ink)
                Text("\(lesson.content.count) Blöcke")
                    .font(.caption)
                    .foregroundStyle(.mutedInk)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.mutedInk.opacity(0.6))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
    }

    private func lessonIndex(_ lesson: Lesson) -> String {
        if lesson.id.hasPrefix("lektion-") {
            return String(lesson.id.dropFirst("lektion-".count))
        }
        return "✓"
    }
}

struct LessonDetailView: View {
    let lesson: Lesson

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(lesson.title)
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(.ink)
                        .padding(.top, 8)
                    ForEach(Array(lesson.content.enumerated()), id: \.offset) { idx, block in
                        LessonBlockView(block: block)
                            .transition(.opacity)
                    }
                }
                .padding()
            }
            .background(Color.cream.opacity(0.4).ignoresSafeArea())
            .navigationTitle("Lektion")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct LessonBlockView: View {
    let block: LessonBlock

    var body: some View {
        switch block.type {
        case .h3:
            Text(block.displayText)
                .font(.title3.weight(.bold))
                .foregroundStyle(.pinkRed)
                .padding(.top, 6)
        case .h4:
            Text(block.displayText)
                .font(.headline)
                .foregroundStyle(.deepGreen)
        case .p:
            Text(block.displayText)
                .font(.body)
                .foregroundStyle(.ink)
        case .list:
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array((block.items ?? []).enumerated()), id: \.offset) { i, item in
                    HStack(alignment: .top, spacing: 8) {
                        if block.ordered ?? false {
                            Text("\(i + 1).")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.pinkRed)
                        } else {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(.coral)
                                .padding(.top, 8)
                        }
                        Text(item)
                            .font(.body)
                            .foregroundStyle(.ink)
                    }
                }
            }
        case .table:
            LessonTableView(rows: block.rows ?? [])
        case .quote:
            HStack(alignment: .top, spacing: 10) {
                Rectangle()
                    .fill(Color.warmGold)
                    .frame(width: 4)
                Text(block.displayText)
                    .font(.body.italic())
                    .foregroundStyle(.deepGreen)
            }
            .padding(12)
            .background(Color.warmGold.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

struct LessonTableView: View {
    let rows: [[String]]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIdx, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { colIdx, cell in
                        Text(cell)
                            .font(rowIdx == 0 ? .subheadline.weight(.heavy) : .subheadline)
                            .foregroundStyle(rowIdx == 0 ? .white : .ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(rowIdx == 0 ? AnyShapeStyle(Color.pinkRed) : AnyShapeStyle(colIdx % 2 == 0 ? Color.mintPop.opacity(0.18) : Color.clear))
                    }
                }
                if rowIdx < rows.count - 1 {
                    Divider().opacity(0.3)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.mutedInk.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    LessonsView()
}
