import SwiftUI

enum ItalianTheme {
    static let forest = Color(red: 0.10, green: 0.38, blue: 0.27)
    static let leaf = Color(red: 0.20, green: 0.58, blue: 0.39)
    static let cream = Color(red: 0.97, green: 0.95, blue: 0.89)
    static let tomato = Color(red: 0.78, green: 0.22, blue: 0.19)
    static let coral = Color(red: 0.94, green: 0.45, blue: 0.35)
    static let gold = Color(red: 0.91, green: 0.65, blue: 0.21)
    static let ink = Color(red: 0.10, green: 0.15, blue: 0.12)
    static let sage = Color(red: 0.84, green: 0.91, blue: 0.85)

    static func lessonColor(_ id: Int) -> Color {
        switch id {
        case 1: leaf
        case 2: tomato
        case 3: Color(red: 0.18, green: 0.48, blue: 0.66)
        case 4: gold
        default: Color(red: 0.55, green: 0.34, blue: 0.65)
        }
    }
}

struct AppBackdrop: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)

            Circle()
                .fill(ItalianTheme.leaf.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 4)
                .offset(x: -150, y: -330)

            Circle()
                .fill(ItalianTheme.tomato.opacity(0.10))
                .frame(width: 250, height: 250)
                .blur(radius: 8)
                .offset(x: 170, y: 310)
        }
        .ignoresSafeArea()
    }
}

struct ItalianFlag: View {
    var cornerRadius: CGFloat = 5

    var body: some View {
        HStack(spacing: 0) {
            ItalianTheme.leaf
            Color.white
            ItalianTheme.tomato
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
        }
        .accessibilityLabel("Italienische Flagge")
    }
}

struct SoftCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.42), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.07), radius: 18, y: 8)
    }
}

extension View {
    func softCard() -> some View {
        modifier(SoftCardModifier())
    }
}

struct ProgressRing: View {
    let progress: Double
    var size: CGFloat = 88
    var lineWidth: CGFloat = 10
    var tint: Color = ItalianTheme.leaf
    var label: String? = nil

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.22), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(max(0.015, min(progress, 1))))
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.75), tint, ItalianTheme.gold],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.78), value: progress)

            VStack(spacing: 1) {
                Text("\(Int(progress * 100))")
                    .font(.system(size: size * 0.25, weight: .heavy, design: .rounded))
                Text(label ?? "%")
                    .font(.caption2.weight(.bold))
                    .opacity(0.75)
            }
            .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fortschritt \(Int(progress * 100)) Prozent")
    }
}

struct SectionHeading: View {
    let eyebrow: String?
    let title: String
    var trailing: String? = nil

    init(_ title: String, eyebrow: String? = nil, trailing: String? = nil) {
        self.title = title
        self.eyebrow = eyebrow
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
                if let eyebrow {
                    Text(eyebrow.uppercased())
                        .font(.caption2.weight(.heavy))
                        .tracking(1.2)
                        .foregroundStyle(ItalianTheme.tomato)
                }
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
            }

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ConfettiOverlay: View {
    @State private var falling = false

    private let colors: [Color] = [
        ItalianTheme.leaf,
        ItalianTheme.tomato,
        ItalianTheme.gold,
        .white,
        ItalianTheme.coral
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(0..<34, id: \.self) { index in
                let fraction = CGFloat((index * 37) % 101) / 100
                let duration = 1.35 + Double(index % 7) * 0.12
                let delay = Double(index % 11) * 0.035

                Capsule()
                    .fill(colors[index % colors.count])
                    .frame(width: index.isMultiple(of: 3) ? 8 : 6, height: 15)
                    .rotationEffect(.degrees(falling ? Double(index * 87) : 0))
                    .position(
                        x: max(12, fraction * proxy.size.width),
                        y: falling ? proxy.size.height + 30 : -30
                    )
                    .animation(
                        .easeIn(duration: duration).delay(delay),
                        value: falling
                    )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            falling = true
        }
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.13))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline.weight(.heavy))
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
}
