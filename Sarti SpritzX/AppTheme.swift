//
//  AppTheme.swift
//  Sarti SpritzX
//
//  Created by Vibe Code on 12.09.26.
//

import SwiftUI
import UIKit

extension Color {
    static let pinkRed = Color(red: 0.72, green: 0.27, blue: 0.24)
    static let deepGreen = Color(red: 0.14, green: 0.45, blue: 0.32)
    static let warmGold = Color(red: 0.98, green: 0.76, blue: 0.18)
    static let cream = Color(red: 0.96, green: 0.94, blue: 0.88)
    static let coral = Color(red: 1.0, green: 0.43, blue: 0.38)
    static let sunYellow = Color(red: 1.0, green: 0.88, blue: 0.36)
    static let lavender = Color(red: 0.66, green: 0.58, blue: 0.93)
    static let mintPop = Color(red: 0.36, green: 0.87, blue: 0.72)
    static let ink = Color(red: 0.12, green: 0.16, blue: 0.13)
    static let mutedInk = Color(red: 0.41, green: 0.45, blue: 0.42)
    static let cardBg = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(white: 0.16, alpha: 1.0) : UIColor.white
    })
    static let appBg = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(white: 0.10, alpha: 1.0) : UIColor(red: 0.96, green: 0.94, blue: 0.88, alpha: 1.0)
    })
}

struct CardBackgroundModifier: ViewModifier {
    var color: Color = .cream

    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(color)
                    .shadow(color: .black.opacity(0.12), radius: 14, y: 8)
            )
    }
}

extension View {
    func funCardBackground(_ color: Color = .cream) -> some View {
        modifier(CardBackgroundModifier(color: color))
    }
}
